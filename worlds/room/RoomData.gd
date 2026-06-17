class_name RoomDatabase
extends Resource

@export var rooms: Array[PackedScene] = []

# 按类型获取房间
func get_rooms_by_type(type: String) -> Array:
	return rooms.filter(func(r): return r.room_type == type)
