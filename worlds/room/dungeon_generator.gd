class_name DungeonGenerator
extends Node

@export var room_db: RoomDatabase
@export var max_rooms := 20
@export var start_room: PackedScene

var spawned_rooms := []
var open_exits := []  # 修复：将open_exits提升为成员变量

func generate():
	# 1. 放置起始房间
	var start = _spawn_room(start_room, Vector2.ZERO)
	spawned_rooms.append(start)
	
	# 2. 初始化开放出口列表
	open_exits = start.get_exits()
	
	# 3. 从开放出口开始生成
	while open_exits.size() > 0 and spawned_rooms.size() < max_rooms:
		var exit = open_exits.pop_back()
		_attempt_room_connection(exit)

#房间实例化方法
func _spawn_room(room_scene: PackedScene, position: Vector2) -> Node2D:
	var room = room_scene.instantiate()
	room.position = position
	add_child(room)
	return room

#连接验证方法
func _validate_connection(exit_a: Dictionary, new_room: Node2D) -> bool:
	# 1. 寻找匹配方向的出口
	var valid_exits = new_room.get_exits().filter(
		func(exit_b): return exit_b["direction"] == -exit_a["direction"]
	)
	
	if valid_exits.is_empty():
		return false
	
	# 2. 自动选择最近的出口
	var exit_b = valid_exits.reduce(func(a, b):
		return a if a["position"].distance_to(exit_a["position"]) < b["position"].distance_to(exit_a["position"]) else b
	)
	
	# 3. 计算偏移量并定位房间
	var offset = exit_a["position"] - exit_b["position"]
	new_room.position += offset
	
	# 4. 检查重叠
	return !_check_room_overlap(new_room)

#重叠检测
func _check_room_overlap(room: Node2D) -> bool:
	var room_rect = _get_room_rect(room)
	return spawned_rooms.any(func(r):
		return r != room and _get_room_rect(r).intersects(room_rect)
	)

#获取房间边界
func _get_room_rect(room: Node2D) -> Rect2:
	if room.has_method("get_boundary_rect"):
		return room.call("get_boundary_rect")
	else:
		# 默认实现（假设房间有TileMap）
		var tilemap = room.get_node_or_null("TileMap")
		if tilemap:
			var used = tilemap.get_used_rect()
			return Rect2(
				room.position + used.position * tilemap.cell_size,
				used.size * tilemap.cell_size
			)
		return Rect2(room.position, Vector2(256, 256))  # 默认大小

func _attempt_room_connection(exit: Dictionary):
	# 获取匹配方向的候选房间
	var candidates = room_db.get_rooms_by_type("normal").filter(
		func(r): 
			var meta = r.instantiate().get_node_or_null("RoomMeta")
			return meta and meta.min_connections <= r.instantiate().get_exits().size()
	)
	
	if candidates.is_empty():
		return
	
	# 随机选择并尝试连接
	var room_scene = candidates.pick_random()
	var new_room = _spawn_room(room_scene, exit["position"])
	
	if _validate_connection(exit, new_room):
		spawned_rooms.append(new_room)
		open_exits += new_room.get_exits().filter(func(e): return !e["connected"])
	else:
		new_room.queue_free()

