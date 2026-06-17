extends Node2D

enum ExitDirection { LEFT, RIGHT, TOP, BOTTOM }

const ROOM_SIZE = Vector2(16*8*4, 16*8*4)  # 房间尺寸（根据实际设计调整）
const TILE_SIZE = 16  # 单个图块的实际像素尺寸
const ROOM_TILE_DIMENSIONS = Vector2i(ROOM_SIZE.x / TILE_SIZE, ROOM_SIZE.y / TILE_SIZE)  # 房间的图块维度

@export var main_tilemap: TileMap # 场景中必须有一个名为 TileMap 的子节点

@onready var player: Player = $"../player"

var grid = []  # 用于记录房间位置的二维数组

var boss_gate := preload("res://Objects/coin_gate.tscn")
var boss_room := preload("res://worlds/room/forest/room_forest_boss.tscn")
var wall_room := preload("res://worlds/room/forest/room_forest_wall.tscn")
var start_room := preload("res://worlds/room/forest/room_forest_start.tscn")
var room_prefabs = [
	preload("res://worlds/room/forest/room_forest_1.tscn"),
	preload("res://worlds/room/forest/room_forest_2.tscn"),
	preload("res://worlds/room/forest/room_forest_3.tscn"),
	preload("res://worlds/room/forest/room_forest_4.tscn")
]
var room_corridor = [
	preload("res://worlds/room/forest/forest_corridor_horizontal.tscn")
	#preload("res://worlds/room/forest/forest_corridor_vertical.tscn")
]


func _ready():
	generate_grid()
	spawn_rooms()
	update_all_terrain()
	#generate_corridors()

func update_all_terrain():
	var all_cells = main_tilemap.get_used_cells(1)
	main_tilemap.set_cells_terrain_connect(1,all_cells,1,3)#有BUG。。。


func generate_grid():
	grid = []
	for x in range(9):
		grid.append([])
		for y in range(3):
			grid[x].append(null)  # 初始化为空

func spawn_rooms():
	# 选择中心作为起始点
	var start_x = 3  # 12列的中间位置大约是5或6
	var start_y = 1  # 3行的中间是1

	# 生成起始房间
	var room = start_room.instantiate()
	room.position = Vector2(start_x, start_y) * ROOM_SIZE
	add_child(room)
	grid[start_x][start_y] = room

	#候选列表
	var candidates = []
	add_candidates(start_x, start_y, candidates)# 将起点周围位置加入候选列表


	while not candidates.is_empty():
		# 随机选择一个候选位置	
		var index = randi() % candidates.size()
		var pos = candidates[index]
		candidates.remove_at(index)
		
		var x = pos.x
		var y = pos.y
		if grid[x][y] == null:
			# 检查是否有相邻房间
			if has_adjacent_room(x, y):
				if randf() <= 0.7:  # 70%生成房间
					var new_room = room_prefabs[randi() % room_prefabs.size()].instantiate()
					new_room.position = Vector2(x, y) * ROOM_SIZE
					add_child(new_room)
					grid[x][y] = new_room
					for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
						var nx = x + dir.x
						var ny = y + dir.y
						if nx >= 0 and nx < grid.size() and ny >= 0 and ny < grid[0].size():
							if grid[nx][ny] is Object:
								new_room.open_exit(vector_to_exit_direction(dir))
								# 相邻房间开启反方向出口
								var adjacent_room = grid[nx][ny]
								adjacent_room.open_exit(vector_to_exit_direction(-dir))
					add_candidates(x, y, candidates)
				else:
					grid[x][y] = false  # 标记为不生成
	var farthest_room_pos = find_farthest_room_position(start_x, start_y)
	if farthest_room_pos:
		replace_with_boss_room(farthest_room_pos.x, farthest_room_pos.y)
	# 查找房间中的 Marker2D 节点
	var spawn_marker = room.get_node("出生点") as Marker2D
	if spawn_marker:
		player.global_position = spawn_marker.global_position
	
	for x in range(grid.size()):
		for y in range(grid[0].size()):
			if grid[x][y] is Object and is_instance_valid(grid[x][y]):
				var room_instance = grid[x][y]
				copy_room_tiles(room_instance, Vector2i(x, y))
				room_instance.queue_free()
	update_all_terrain()

#
func vector_to_exit_direction(dir: Vector2) -> ExitDirection:
	match dir:
		Vector2.LEFT:
			return ExitDirection.LEFT
		Vector2.RIGHT:
			return ExitDirection.RIGHT
		Vector2.UP:
			return ExitDirection.TOP   # 注意：Vector2.UP 对应 TOP（上方）
		Vector2.DOWN:
			return ExitDirection.BOTTOM
		_:
			push_error("Invalid direction vector!")
			return ExitDirection.LEFT
#候选位置管理
func add_candidates(x: int, y: int, candidates: Array):
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for dir in directions:
		var nx = x + dir.x
		var ny = y + dir.y
		# 边界检查
		if nx >= 0 and nx < grid.size() and ny >= 0 and ny < grid[0].size():
			var key = str(nx) + "_" + str(ny)  # 用字符串作为唯一键
			var exists = false
			# 检查是否已存在于候选列表
			for pos in candidates:
				if pos is Vector2 and pos.x == nx and pos.y == ny:
					exists = true
					break
			if not exists and grid[nx][ny] == null:
				candidates.append(Vector2(nx, ny))

#连通性检查
func has_adjacent_room(x: int, y: int) -> bool:
	for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var nx = x + dir.x
		var ny = y + dir.y
		if nx >= 0 and nx < grid.size() and ny >= 0 and ny < grid[0].size():
			# 关键修复：使用 is 检查是否为房间对象（Object 类型）
			if grid[nx][ny] is Object:
				return true
	return false


func copy_room_tiles(room_instance: Node2D, grid_pos: Vector2i):
	# 获取房间内的 Tilemap 节点（根据实际节点结构调整路径）
	var room_tilemap := room_instance.get_node("TileMap") as TileMap

	# 计算图块偏移量（将网格位置转换为图块坐标）
	var offset := grid_pos * ROOM_TILE_DIMENSIONS

	# 遍历所有图层
	for layer in room_tilemap.get_layers_count():
		# 获取所有已使用图块位置
		var used_cells = room_tilemap.get_used_cells(layer)
		
		for cell in used_cells:
			# 获取图块数据
			var source_id = room_tilemap.get_cell_source_id(layer, cell)
			var atlas_coords = room_tilemap.get_cell_atlas_coords(layer, cell)
			var alternative_tile = room_tilemap.get_cell_alternative_tile(layer, cell)

			# 计算目标位置
			var target_pos := Vector2i(cell) + offset

			# 设置到主 Tilemap
			main_tilemap.set_cell(
				layer, 
				target_pos,
				source_id,
				atlas_coords,
				alternative_tile
			)

# 新添加的辅助函数
func find_farthest_room_position(from_x: int, from_y: int) -> Vector2i:
	var max_distance = 0
	var farthest_pos = null

	for x in range(grid.size()):
		for y in range(grid[0].size()):
			if grid[x][y] is Object:  # 如果是房间
				var dist = abs(x - from_x) + abs(y - from_y)  # 曼哈顿距离
				if dist > max_distance:
					max_distance = dist
					farthest_pos = Vector2i(x, y)

	return farthest_pos

func replace_with_boss_room(x: int, y: int):
	# 移除原有房间
	if is_instance_valid(grid[x][y]):
		grid[x][y].queue_free()

	# 生成Boss房
	var boss = boss_room.instantiate()
	boss.position = Vector2(x, y) * ROOM_SIZE
	add_child(boss)
	grid[x][y] = boss
	# 查找房间中的 Marker2D 节点
	var spawn_marker = boss.get_node("Marker") as Marker2D
	if spawn_marker:
		var new_gate = boss_gate.instantiate()
		new_gate.position = spawn_marker.global_position
		var world_tilemap = get_node("/root/World/TileMap")
		world_tilemap.add_child(new_gate)
	
	# 确保所有出口关闭（Boss房通常只有一个入口）
	for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var nx = x + dir.x
		var ny = y + dir.y
		if nx >= 0 and nx < grid.size() and ny >= 0 and ny < grid[0].size():
			if grid[nx][ny] is Object:
				boss.open_exit(vector_to_exit_direction(dir))
