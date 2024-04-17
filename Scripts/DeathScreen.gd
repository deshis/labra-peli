extends CanvasLayer

@export var ui_layer:CanvasLayer
@export var pause_layer:CanvasLayer
@export var player:CharacterBody3D
@onready var buttons = $DeathButtonsContainer
@onready var restart_button = $DeathButtonsContainer/RestartButton

func _ready():
	player.playerDied.connect(open_death_screen)

func open_death_screen():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#ui_layer.visible = false
	pause_layer.visible = false
	buttons.visible = true
	restart_button.grab_focus()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_quit_game_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
