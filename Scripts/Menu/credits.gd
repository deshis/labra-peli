class_name Credits

extends Control

@onready var back_button: Button = $BackButtonMargin/BackButton
@onready var buttons_container: VBoxContainer = $"../ButtonsContainer"
@onready var start_game_button: Button = $"../ButtonsContainer/StartGameButton"

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		close()


func _on_back_button_pressed() -> void:
	close()


func open() -> void:
	visible = true
	back_button.grab_focus()


func close() -> void:
	visible = false
	buttons_container.visible = true
	start_game_button.grab_focus()
