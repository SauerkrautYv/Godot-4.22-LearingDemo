extends HBoxContainer

@export var stats: Stats
@onready var health_bar: TextureProgressBar = $VBoxContainer/HealthBar

func _ready() -> void:
	update_health(true)
	stats.health_change.connect(update_health)#连接到定义的health_change信号

func update_health(skip_anim := false) ->void:
	var percentage := stats.health / float(stats.max_health)
	health_bar.value = percentage
