extends Control

@onready var quit: Button = $HBoxContainer/Quit
@onready var bag_grid: GridContainer = $PanelContainer/BagGrid


func _ready() -> void:
	#hide()#开始时隐藏
	SoundManager.setup_ui_sounds(self)

func show_screen() ->void:
	bag_grid.updata_inventory()
	show()
	quit.grab_focus()#聚焦

func _on_quit_pressed() -> void:
	hide()

func _on_hidden() -> void:
	bag_grid.clear_inventory()
