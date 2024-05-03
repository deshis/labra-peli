extends CanvasLayer

@export var ui_layer:CanvasLayer
@onready var buttons: Container = $PauseButtonsContainer
@onready var continue_button: Button = $PauseButtonsContainer/ContinueButton

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel") and Global.can_pause:
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: #pause
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
		ui_layer.visible = false
		buttons.visible = true
		continue_button.grab_focus()
	else: #unpause
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
		get_tree().paused = false
		ui_layer.visible = true
		buttons.visible = false

func _on_continue_button_pressed() -> void:
	toggle_pause_menu()

func _on_quit_game_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
