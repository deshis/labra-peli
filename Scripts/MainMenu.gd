extends CanvasLayer

func _ready():
	$ButtonsContainer/StartGameButton.grab_focus()

func _process(_delta):
	pass

func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_settings_button_pressed():
	print("yeah...")

func _on_quit_game_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
