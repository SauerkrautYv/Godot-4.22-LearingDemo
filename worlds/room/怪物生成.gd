extends Marker2D

@export var 生成的怪物 : PackedScene

func _ready() -> void:
	if randf() <= 1.0:
		var 怪物 = 生成的怪物.instantiate() as Enemy  # 明确转换为Chest类型
		# 获取Marker2D在全局世界中的位置
		var 怪物_global_pos = global_position
		# 添加到大地图
		var world_tilemap = get_node("/root/World")
		怪物.global_position = 怪物_global_pos
		world_tilemap.call_deferred("add_child", 怪物)
