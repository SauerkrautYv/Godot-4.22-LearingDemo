class_name InventorySlotUI

extends Button

var slot_data : SlotData : set = set_slot_data
#当给 slot_data 赋值时（如 slot_data = some_value），会自动调用 set_slot_data

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var item_description: Label = $ItemDescription

func _ready() -> void:
	texture_rect.texture = null
	label.text = ""

func set_slot_data(value :SlotData) -> void:
	slot_data = value
	if slot_data == null:
		return
	texture_rect.texture = slot_data.item_data.texture
	label.text = str(slot_data.quantity)#quantity是int需要转换


func update_item_description(new_text:String) -> void:
	item_description.text = new_text

func update_quantity() -> void:
	label.text = str(slot_data.quantity)

#显示描述
func _on_focus_entered() -> void:
	if slot_data != null:
		update_item_description(slot_data.item_data.description)
#离开清除描述
func _on_focus_exited() -> void:
	update_item_description("")

#按下按钮使用
func _on_pressed() -> void:
	if slot_data:
		if slot_data.item_data:
			var was_used = slot_data.item_data.use()
			if was_used == false:
				return
			if slot_data.quantity > 0:
				slot_data.quantity -= 1
				update_quantity()
			return
