extends Node
@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

enum Bus{
	MASTER,SFX,BGM
}

#SoundManger：process->mode->always总是，不受暂停影响
func play_sfx(name:String) ->void:
	var player := sfx.get_node(name) as AudioStreamPlayer
	if not player:
		return
	player.play()

func play_bgm(stream:AudioStream) ->void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()
#UI/鼠标和键盘焦点绑定
func setup_ui_sounds(node:Node) ->void:
	var button := node as Button
	if button:
		button.pressed.connect(play_sfx.bind("UIPress"))#音效
		button.focus_entered.connect(play_sfx.bind("UIFocus"))
			#for button:Button in v_box_container.get_children():
		button.mouse_entered.connect(button.grab_focus)#把鼠标的焦点和手柄/键盘的焦点绑定

	var slider := node as Slider
	if slider:
		slider.value_changed.connect(play_sfx.bind("UIPress").unbind(1))
		slider.focus_entered.connect(play_sfx.bind("UIFocus"))
		slider.mouse_entered.connect(slider.grab_focus)#把鼠标的焦点和手柄/键盘的焦点绑定

	for child in node.get_children():
		setup_ui_sounds(child)

func get_volume(bus_index: int) ->float:
	var db := AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(db)
	
func set_volume(bus_index: int,v: float) ->void:
	var db := linear_to_db(v)
	AudioServer.set_bus_volume_db(bus_index,db)
