class_name Settings

extends Control

@onready var cont: TabContainer = $TabContainer
@onready var buttons_container: VBoxContainer = $"../ButtonsContainer"
@onready var start_game_button: Button = $"../ButtonsContainer/StartGameButton"


func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		close()


func _on_back_button_pressed() -> void:
	close()


func open() -> void:
	visible = true
	cont.get_tab_bar().grab_focus()
	cont.current_tab = 0


func close() -> void:
	visible = false
	buttons_container.visible = true
	start_game_button.grab_focus()
