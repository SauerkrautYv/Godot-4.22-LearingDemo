class_name ItemEffectHealingPotin
extends ItemEffect

@export var heal_amount : float = 1
@export var sound_name :String

func use() ->void:
	Game.player_stats.health += heal_amount
	SoundManager.play_sfx(sound_name)
