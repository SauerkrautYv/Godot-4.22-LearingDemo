extends World





func _on_skeleton_died() -> void:
	await get_tree().create_timer(1).timeout
	Game.change_scene("res://worlds/boss_room.tscn",{
		duration = 0.8,
	})
