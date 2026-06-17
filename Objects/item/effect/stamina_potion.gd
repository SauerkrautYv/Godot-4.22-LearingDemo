class_name ItemEffectStaminaPotin
extends ItemEffect

@export var stamina_amount : float = 1
@export var sound_name :String

func use() ->void:
	Game.player_stats.energy += stamina_amount
	SoundManager.play_sfx(sound_name)
