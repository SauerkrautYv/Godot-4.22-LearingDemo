class_name InventoryUI

extends Control

const INVENTORY_SLOT = preload("res://UI/inventory/inventory_slot.tscn")

@export var data : InventoryData

var focus_index : int = 0

func _ready() -> void:
	data.changed.connect(on_inventory_changed)
	pass

func clear_inventory() -> void:
	for i in get_children():
		i.queue_free()

func updata_inventory(f:int = 0) -> void:
	for i in data.slots:
		var new_slot = INVENTORY_SLOT.instantiate()
		add_child(new_slot)
		new_slot.slot_data = i
		#聚焦更新的库存上
		new_slot.focus_entered.connect(item_focused)
	get_child(f).grab_focus()

func item_focused() ->void:
	for i in get_child_count():
		if get_child(i).has_focus():
			focus_index = i
			return
	pass

func on_inventory_changed() -> void:
	clear_inventory()
	updata_inventory(focus_index)
