class_name DropData
extends Resource

@export var item : ItemData
@export_range(0 , 100, 1,"suffix:%") var probability : float = 0
@export_range(0 , 24 , 1) var min_amount : int = 1
@export_range(0 , 24 , 1) var max_amount : int = 1

#判断掉落
func get_drop_count() ->int:
	if randf_range(0,100) >= probability:
		return 0
	return randf_range(min_amount,max_amount)
