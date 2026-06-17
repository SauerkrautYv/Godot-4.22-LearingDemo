class_name World
extends Node2D

@export var bgm: AudioStream

@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $player/Camera2D
@onready var player: Player = $player


func _ready() -> void:
	var used := tile_map.get_used_rect().grow(-1)
	#get_used_rect()用来获取 TileMap 中所有被使用的瓦片（tiles）的矩形区域。
	var tile_size := tile_map.tile_set.tile_size
	
	camera_2d.limit_top = used.position.y * tile_size.y	#position表示左上坐标
	camera_2d.limit_bottom = used.end.y * tile_size.y	#end表示右下坐标
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.limit_right = used.end.x * tile_size.x
	#camera_2d.reset_smoothing()
	#reset_smoothing() 是 Godot 引擎中 Camera2D 类的一个方法，用来立即重置相机的平滑移动（smoothing）状态。
	if bgm:
		SoundManager.play_bgm(bgm)

func update_player(pos: Vector2,direction: Player.Direction) ->void:
	player.global_position = pos
	player.fall_form_y = pos.y#防止触发坠落
	player.direction = direction
	camera_2d.reset_smoothing()
	camera_2d.force_update_scroll()

func to_dict() -> Dictionary:
	var enemies_alive := []
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node) as String#get_path_to得到的是nodePath，转化string用于json储存->存档
		enemies_alive.append(path)
	# 收集场景中所有宝箱的状态
	var chest_states := {}
	for node in  get_tree().get_nodes_in_group("chests"):
			chest_states[node.name] = {
				"is_opened": node.是否开启,
				"position": {
				"x": node.global_position.x,
				"y": node.global_position.y
				}
			}
			
	print(chest_states)
	return {
		enemies_alive=enemies_alive,
		chest_states=chest_states,
	}

func from_dict(dict:Dictionary) -> void:
	print("原始字典内容:")
	for key in dict:
		print("Key: '%s'" % key, " | Value: ", dict[key])
	#怪物存活情况
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node) as String
		if path not in dict.enemies_alive:
			node.queue_free()
	#print(dict)
	#处理宝箱状态
	var chest_data = dict.get("chest_states", {})
	print(chest_data)
	if chest_data:  # 等价于 chest_data != {}
		if not chest_data.is_empty():
			for chest_name in dict.chest_states:
				print("正在处理宝箱: ", chest_name, " | 类型: ", typeof(chest_name))
				var chest_state = dict.chest_states[chest_name]
				#var chest = get_node_or_null(chest_name) #or          # 尝试直接获取
				var chest = get_node_or_null("TileMap/" + chest_name)
				if !chest:
					chest = get_node_or_null(chest_name)
				if chest:
					print("恢复宝箱状态: ", chest.name, " -> ", chest_state["is_opened"])
					chest.是否开启 = chest_state["is_opened"]
					#if chest.是否开启:
						###确保宝箱保持打开状态
						#chest.animation_player.play("打开")
						#chest.treasure_chests.monitoring = false  # 禁用交互
						#chest.animation_player.advance(1.0)  # 直接跳到动画最后一帧
				else:
					printerr("找不到宝箱节点: ", chest_name)
