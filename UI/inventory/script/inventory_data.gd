class_name InventoryData

extends Resource

@export var slots : Array[SlotData]

func _init() -> void:
	connect_slot()
	pass

func add_item(item : ItemData ,count : int = 1) -> int:
	for s in slots:
		if s:
			if s.item_data==item:
				if s.quantity+count<=99:
					s.quantity+= count
					return 0
				if s.quantity+count>99:
					count = count-99-s.quantity
					s.quantity = 99
	for i in slots.size():
		if slots[i]==null:
			var new = SlotData.new()
			new.item_data = item
			new.quantity = count
			slots[i] = new
			new.changed.connect(slot_change)
			return 0
	return count

func connect_slot() ->void:
	for s in slots:
		if s:
			s.changed.connect(slot_change)

func slot_change() ->void:
	for s in slots:
		if s:
			if s.quantity < 1:
				s.changed.disconnect(slot_change)
				var index = slots.find(s)
				slots[index] = null
				emit_changed()#当物品数量到0时发出信号
	pass

#为存档保存物品栏收集数据
func get_save_data() -> Array:
	var item_save : Array =[]
	for i in slots.size():
		item_save.append(item_to_save(slots[i]))
	return item_save

#将每个库存项目转换为字典
func item_to_save( slot :SlotData) -> Dictionary:
	var result = { item = "", quantity=0 }
	if slot != null:
		result.quantity = slot.quantity
		if slot.item_data != null:
			result.item =slot.item_data.resource_path
	return result

func parse_save_data( save_data :Array ) ->void:
	var array_size = slots.size()
	slots.clear()
	slots.resize( array_size)
	for i in save_data.size():
		slots[i]=item_from_save( save_data[i])
	connect_slot()

func item_from_save( save_object :Dictionary ) ->SlotData:
	if save_object.item == "":
		return null
	var new_slot : SlotData = SlotData.new()
	new_slot.item_data = load(save_object.item )
	new_slot.quantity = int(save_object.quantity)
	return new_slot
