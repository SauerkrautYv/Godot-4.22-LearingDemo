class_name BossBullet
extends Node2D

@export var damage := 1
@export var fall_speed := 300.0
var target_position: Vector2
@onready var timer: Timer = $Timer

func _ready():
	timer.timeout.connect(queue_free)  # 超出屏幕后自动删除

func _physics_process(delta):
	position.y += fall_speed * delta  # 垂直下落
	if position.y > target_position.y + 1000:  # 超出屏幕下方
		queue_free()

