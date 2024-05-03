extends CanvasLayer

@export var ui_layer:CanvasLayer
@export var pause_layer:CanvasLayer
@export var player:Player
@onready var buttons: Container = $DeathButtonsContainer
@onready var restart_button: Button = $DeathButtonsContainer/RestartButton

func _ready()->void:
	player.playerDied.connect(open_death_screen)

func open_death_screen()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.can_pause = false
	pause_layer.visible = false
	buttons.visible = true
	restart_button.grab_focus()

func _on_restart_button_pressed()->void:
	get_tree().reload_current_scene()

func _on_quit_game_button_pressed()->void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
