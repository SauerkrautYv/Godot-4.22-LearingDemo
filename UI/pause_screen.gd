extends Control
@onready var resume: Button = $VBoxContainer/Actions/HBoxContainer/Resume


func _ready() -> void:
	hide()#开始时隐藏
	SoundManager.setup_ui_sounds(self)#绑定声音

	visibility_changed.connect(#暂停其他节点
		func():
			get_tree().paused =visible
	)

func show_pause() ->void:
	show()
	resume.grab_focus()#聚焦

func _on_resume_pressed() -> void:#按键关闭
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		hide()
		get_window().set_input_as_handled()#停止事件传播，防止ESC关闭后又ESC开启

func _on_quit_pressed() -> void:
	hide()
	Game.back_to_title()

