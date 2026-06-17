extends Control
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var new_game: Button = $VBoxContainer/NewGame
@onready var load_game: Button = $VBoxContainer/LoadGame

func _ready() -> void:
	load_game.disabled = not Game.has_save()
	new_game.grab_focus()#初始获得键盘焦点（选择匡）
	

	
	SoundManager.setup_ui_sounds(self)
	SoundManager.play_bgm(preload("res://assets/Audio/Infinity Crystal_ Awakening/02 1 titles LOOP.mp3"))

func _on_new_game_pressed() -> void:
	Game.new_game()


func _on_load_game_pressed() -> void:
	Game.load_game()


func _on_exit_pressed() -> void:
	get_tree().quit()
