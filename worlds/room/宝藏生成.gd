extends Marker2D
const TREASURE_CHESTS = preload("res://Objects/treasure_chests.tscn")

func _ready() -> void:
	if randf() <= 1.0:
		var treasure_chest = TREASURE_CHESTS.instantiate() as Chest  # 明确转换为Chest类型
		# 获取Marker2D在全局世界中的位置
		var chest_global_pos = global_position
		# 设置宝箱掉落物
		setup_chest_drops(treasure_chest)
		# 添加到大地图的TileMap下
		var world_tilemap = get_node("/root/World/TileMap")
		treasure_chest.global_position = chest_global_pos
		world_tilemap.add_child(treasure_chest)

# 设置宝箱掉落物的函数
func setup_chest_drops(chest: Chest):
	var new_drops: Array[DropData] = []

	#预设几个固定掉落物
	var drop1 = DropData.new()
	drop1.item = preload("res://Objects/item/coin.tres")  # 替换为实际资源路径
	drop1.probability = 100  # 100%掉落
	drop1.min_amount = 3
	drop1.max_amount = 10

	var drop2 = DropData.new()
	drop2.item = preload("res://Objects/item/healing_potin.tres")
	drop2.probability = 100  # 50%掉落
	drop2.min_amount = 1
	drop2.max_amount = 2

	new_drops.append(drop1)
	new_drops.append(drop2)
	
	chest.drops = new_drops
