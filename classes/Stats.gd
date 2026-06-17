class_name Stats
extends Node

@export var max_health: int = 5
@export var max_energy: float = 10
@export var energy_regen: float = 1.2

signal health_change
signal energy_change

#先初始化export再初始化onready，普通变量初始化发生在export之前
@onready var health : int = max_health:
	set(v):
		v = clampi(v,0,max_health)
		if(health == v):
			return
		health = v
		health_change.emit()
@onready var energy : float = max_energy:
	set(v):
		v = clampf(v,0,max_energy)
		if(energy == v):
			return
		energy = v
		energy_change.emit()


func _process(delta: float) -> void:
	energy += delta * energy_regen

func health_recover(amount:float) ->void:
	health += amount

func energy_recover(amount:float) ->void:
	energy += amount

func to_dict() -> Dictionary:
	return {
		max_health=max_health,
		health=health,
		max_energy=max_energy,
	}

func from_dict(dict: Dictionary) -> void:
	max_health=dict.max_health
	health=dict.health
	max_energy=dict.max_energy
