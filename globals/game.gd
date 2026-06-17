extends Node

const SAVE_PATH := "user://data.sav"#保存
const CONFIG_PATH := "user://config.ini"
#场景的名称 =>
var world_states := {}
var key = PackedByteArray([
	0x3a, 0x1f, 0x4e, 0x8d, 0x7c, 0x9b, 0x2a, 0x5f,
	0x6e, 0x8c, 0x3d, 0x1a, 0x2b, 0x4e, 0x5f, 0x6a,
	0x7c, 0x8d, 0x9e, 0x0f, 0x1a, 0x2b, 0x3c, 0x4d,
	0x5e, 0x6f, 0x7a, 0x8b, 0x9c, 0x0d, 0x1e, 0x2f
])
@onready var player_stats: Stats = $PlayerStats
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var default_player_stats :=player_stats.to_dict()
const PLAYER_INVENTORY = preload("res://UI/inventory/player_inventory.tres")
signal camera2D_should_shake(amount:float)

func _ready() -> void:
	color_rect.color.a = 0
	load_config()

func change_scene(path: String,params:={}) ->void:
	var duration := params.get("duration",0.2) as float
	var tree:=get_tree()
	#tree.paused = true
	
	# 淡入过渡
	var tween := create_tween()#淡入
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)#暂停
	tween.tween_property(color_rect,"color:a",1,duration)
	await tween.finished
	
	# 保存当前场景状态
	if tree.current_scene is World:#不是标题
		#获取到文件名除去扩展名的部分
		var old_name := tree.current_scene.scene_file_path.get_file().get_basename()
		world_states[old_name] = tree.current_scene.to_dict()#保存旧场景状态
	
	# 加载新场景
	tree.change_scene_to_file(path)
	if "init" in params:
		params.init.call()#调用匿名函数
	
	# 等待场景完全加载
	await tree.tree_changed
	await tree.process_frame#确保所有节点都已初始化
	# 恢复新场景状态
	if tree.current_scene is World:#不是标题
		var new_name := tree.current_scene.scene_file_path.get_file().get_basename()
		if new_name in world_states:
			tree.current_scene.from_dict(world_states[new_name])#更新场景/读取之前保存的场景
		
		# 处理玩家位置
		if "entry_point" in params:
			for node in tree.get_nodes_in_group("entry_points"):
				#获取新场景所有entry_points分组节点
				if node.name == params.entry_point:
					tree.current_scene.update_player(node.global_position,node.direction)
					break
		if "position" in params and "direction" in params:
			tree.current_scene.update_player(params.position,params.direction)
	#tree.paused = false
	# 淡出过渡
	tween = create_tween()#淡出
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)#暂停
	tween.tween_property(color_rect,"color:a",0,duration)

func save_game() ->void:
	var scene := get_tree().current_scene
	var scene_name := scene.scene_file_path.get_file().get_basename()#返回文件路径的不包括扩展的文件名
	
	#scene_name——对应的世界场景，（world.gd）to_dict（）会读取
	world_states[scene_name] = scene.to_dict()
	
	var data := {
		world_states=world_states,
		stats=player_stats.to_dict(),
		scene=scene.scene_file_path,
		player={
			direction=scene.player.direction,
			position={
				y=scene.player.global_position.y,
				x=scene.player.global_position.x,
			},
			items=PLAYER_INVENTORY.get_save_data(),
		},
	}
	
	var json := JSON.stringify(data)
	#var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	var file := FileAccess.open_encrypted(SAVE_PATH,FileAccess.WRITE,key)
	if not file:
		return
	file.store_string(json)

func load_game() ->void:
	#var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
	var file := FileAccess.open_encrypted(SAVE_PATH,FileAccess.READ,key)
	if not file:
		return
	
	var json := file.get_as_text()
	var data := JSON.parse_string(json) as Dictionary
	#print(data)

	PLAYER_INVENTORY.parse_save_data(data.player.items)
	change_scene(data.scene,{
		direction = data.player.direction,
		position = Vector2(
			data.player.position.x,
			data.player.position.y 
		),
		init=func ():#匿名函数
				world_states = data.world_states
				player_stats.from_dict(data.stats)
	})


func new_game() ->void:
	change_scene("res://worlds/forest.tscn",{
		duration = 1,
		init=func ():#匿名函数
				world_states = {}
				player_stats.from_dict(default_player_stats)
	})

func back_to_title() ->void:
	change_scene("res://scenes/title_screen.tscn",{
		duration = 1,
	})

func has_save() ->bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_config() ->void:
	var config := ConfigFile.new()
	
	config.set_value("audio","master",SoundManager.get_volume(SoundManager.Bus.MASTER))
	config.set_value("audio","sfx",SoundManager.get_volume(SoundManager.Bus.SFX))
	config.set_value("audio","bgm",SoundManager.get_volume(SoundManager.Bus.BGM))
	
	config.save(CONFIG_PATH)
	
func load_config() ->void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	
	SoundManager.set_volume(
		SoundManager.Bus.MASTER,
		config.get_value("audio","master",0.5)
	)
	SoundManager.set_volume(
		SoundManager.Bus.SFX,
		config.get_value("audio","sfx",1.0)
	)
	SoundManager.set_volume(
		SoundManager.Bus.BGM,
		config.get_value("audio","bgm",1.0)
	)

func shack_camera(amount:float) ->void:
	camera2D_should_shake.emit(amount)
