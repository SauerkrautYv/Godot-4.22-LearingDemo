@tool
class_name ItemPick extends CharacterBody2D

const PLAYER_INVENTORY : InventoryData = preload("res://UI/inventory/player_inventory.tres")

var target_position: Vector2

@export var item_data : ItemData : set = _set_item_data
@export var quantity : int = 0

@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	_updata_texture()
	if Engine.is_editor_hint():
		return
	
	pass

func _physics_process(delta):
	if Engine.is_editor_hint():  # 如果是编辑器，直接返回
		return
	position.y += 200 * delta  # 垂直下落
	move_and_slide()  # 处理碰撞
	if position.y > target_position.y + 1000:  # 超出屏幕下方
		print("4")
		queue_free()

func _set_item_data(value:ItemData) -> void:
	item_data =value
	_updata_texture()
	pass

func item_pickup(count:int) -> void:
	area_2d.set_deferred("monitoring",false)
	quantity = count
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	if quantity:
		area_2d.set_deferred("monitoring",true)
	else:
		queue_free()


func _updata_texture() -> void:
	if item_data and sprite_2d:
		sprite_2d.texture = item_data.texture
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	#if body == Player:
	if item_data:
		var count = PLAYER_INVENTORY.add_item(item_data,quantity)
		#PLAYER_INVENTORY.add_item(item_data,conut)
		if count != quantity:
			item_pickup(count)
	pass # Replace with function body.
