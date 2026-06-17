class_name Teleporter
extends Interactable

@export_file("*.tscn") var path:String
@export var entry_point: String

func interact() ->void:
	super()#调用父类同名函数，否则只会执行子类
	print({entry_point=entry_point})
	Game.change_scene(path, {entry_point=entry_point})
