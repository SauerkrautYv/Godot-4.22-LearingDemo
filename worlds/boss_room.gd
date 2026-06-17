extends World


func _on_knight_died() -> void:
	await get_tree().create_timer(1).timeout
	Game.change_scene("res://UI/game_end_screen.tscn",{
		duration = 0.8,
	})
