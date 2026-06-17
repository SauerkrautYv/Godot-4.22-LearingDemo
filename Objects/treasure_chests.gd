class_name Chest
extends Interactable

const ITEMPICK = preload("res://Objects/item/pick/itempick.tscn")

@export var 是否开启 :bool = false
@export var drops : Array[DropData]

@onready var treasure_chests: Area2D = $"."
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Label

func _ready():
	add_to_group("chests")
	label.visible = false

func interact() ->void:
	super()
	animation_player.play("打开")
	if 是否开启 :
		label.visible = true
		#label.text = "里面是空的！"
		label.visible_characters = 0  # 初始隐藏所有字符
		label.modulate.a = 1.0  # 确保不透明
		
		# 1. 逐字显示
		var tween_typing = create_tween()
		for i in range("里面是空的！".length() + 1):
			tween_typing.tween_callback(func(): label.visible_characters = i)
			tween_typing.tween_interval(0.05)
		# 2. 淡出
		await tween_typing.finished  # 等待打字完成
		animation_player.play("提示消失")
		#var tween_fade = create_tween()
		#tween_fade.tween_property(label, "modulate:a", 0.0, 1.0)
		#await tween_fade.finished
		label.visible = false
	else :
		treasure_chests.monitoring = false  # 禁用 Area2D 检测
		是否开启 = true
		await animation_player.animation_finished  # 等待动画结束
		if drops.size() > 0:
			drop_items()
	#Game.save_game()

func drop_items() ->void:
	if drops.size() == 0:
		return
	
	for i in drops.size():
		if drops[i] == null or drops[i].item == null:
			continue
		var drop_count : int  = drops[i].get_drop_count()
		var drop : 	ItemPick = ITEMPICK.instantiate() as ItemPick
		drop.item_data = drops[i].item
		drop.quantity = drop_count
		treasure_chests.get_parent().add_child(drop)
		drop.global_position = treasure_chests.global_position + Vector2(randf()*3,randf()*3-16)
	pass
