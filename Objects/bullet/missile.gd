class_name Bullet
extends Node2D

@export var speed = 180
@export var rotation_speed = 10
#@onready var target = null

var target: Array[CharacterBody2D] = []#存储敌人节点
var pending_damage:Damage

func _process(delta: float) -> void:
	target = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is CharacterBody2D:
			target.append(node as CharacterBody2D)
	if target.size() > 0:
		move(delta)
		pass
	else:
		global_translate(transform.x * speed * delta)

func get_nearest_enemy() -> CharacterBody2D:
	var nearest_enemy: CharacterBody2D = null
	var nearest_distance: float = INF
	
	for enemy in target:
		var distance = position.distance_to(enemy.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	return nearest_enemy

func move(delta: float) -> void:
	var nearest_enemy = get_nearest_enemy()
	if nearest_enemy:
		# 计算方向
		var direction = (nearest_enemy.position - position).normalized()
		# 计算旋转量
		var rotate_amount = direction.cross(transform.y)
		rotate(rotate_amount * rotation_speed * delta)
		global_translate(-transform.y * speed * delta)

#碰撞敌人
func _on_hitbox_hit(hurtbox: Variant) -> void:
	$AnimatedSprite2D.play("boom")
	$Hitbox/CollisionShape2D.call_deferred("set_disabled",true)
	speed = 0

#碰撞环境
func _on_hitbox_body_entered(body: Node2D) -> void:
	$AnimatedSprite2D.play("boom")
	$Hitbox/CollisionShape2D.call_deferred("set_disabled",true)
	speed = 0
#到点删除
func _on_timer_timeout() -> void:
	$AnimatedSprite2D.play("boom")
	speed = 0

#动画播放完后删除
func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "boom":
		queue_free()


