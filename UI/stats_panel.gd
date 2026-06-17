extends HBoxContainer

@export var stats: Stats

@onready var health_bar: TextureProgressBar = $VBoxContainer/HealthBar
@onready var eased_health_bar: TextureProgressBar = $VBoxContainer/HealthBar/EasedHealthBar
@onready var energy_bar: TextureProgressBar = $VBoxContainer/EnergyBar


func _ready() -> void:
	if not stats:
		stats = Game.player_stats
	stats.health_change.connect(update_health)#连接到定义的health_change信号
	update_health(true)
	stats.energy_change.connect(update_energy)
	update_energy()
	
	tree_exited.connect(func ():
		#防止更换场景时调用update_health，更换场景树时旧场景不会立即销毁
		#，而是在帧末尾统一销毁，此时更改血量会调用update_health
		#，但update_health不会不会访问到节点,因此在节点退出树时断开连接
		stats.health_change.disconnect(update_health)
		stats.energy_change.disconnect(update_energy)
	)


func update_health(skip_anim := false) ->void:
	var percentage := stats.health / float(stats.max_health)
	health_bar.value = percentage
	if skip_anim:
		eased_health_bar.value = percentage
	else:
		create_tween().tween_property(eased_health_bar ,"value" ,percentage,0.3)

func update_energy() ->void:
	var percentage := stats.energy/stats.max_energy
	energy_bar.value = percentage
