extends Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	hide()#隐藏
	set_process_input(false)#禁用输入处理
	

func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()#把事件标记为已处理
	
	if animation_player.is_playing():
		return
	
	if (
		event is InputEventKey 
		or event is InputEventMouseButton 
		or event is InputEventJoypadButton
	):
		if event.is_pressed() and not event.is_echo():#后一个条件“回显事件”
			if Game.has_save():
				Game.load_game()
			else:
				Game.back_to_title()
			
func show_game_over() ->void:
	show()
	set_process_input(true)
	animation_player.play("enter")
