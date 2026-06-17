class_name Enemy
extends CharacterBody2D

enum Direction{
	LEFT = -1,
	RIGHT = 1,
}

signal died

@export_category("掉落物")
@export var drops : Array[DropData]
@export_category("属性")
@export var direction = Direction.LEFT:#导出变量，在根节点显示
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction
@export var max_speed: float = 180
@export var acceleration: float = 1800#加速度

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats
@onready var enemy: Enemy = $"."

const ITEMPICK = preload("res://Objects/item/pick/itempick.tscn")
func _ready() -> void:
	add_to_group("enemies") #也可以在节点->分组中添加分组

func move(speed:float,delta:float,flying: bool = false,direction_vertical:float = 0) ->void:
	velocity.x = move_toward(velocity.x, direction * speed,acceleration * delta)
	
	if flying:
		 # 飞行状态下，不受重力影响，可以自由控制垂直移动
		velocity.y = move_toward(velocity.y, direction_vertical * speed, acceleration * delta)
	else:
		# 非飞行状态下，受重力影响
		velocity.y += default_gravity * delta
	move_and_slide()
	
func die() ->void:
	drop_items()
	died.emit()
	queue_free()

func drop_items() ->void:
	if drops.size() == 0:
		return
	
	for i in drops.size():
		if drops[i] == null or drops[i].item == null:
			continue
		var drop_count : int  = drops[i].get_drop_count()
		if drop_count:
			var drop : 	ItemPick = ITEMPICK.instantiate() as ItemPick
			drop.item_data = drops[i].item
			drop.quantity = drop_count
			enemy.get_parent().add_child(drop)
			drop.global_position = enemy.global_position + Vector2(randf()*3,randf()*3-16)
	pass
