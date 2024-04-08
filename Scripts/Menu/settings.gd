extends Control

func _ready():
	$TabContainer.get_tab_bar().grab_focus()
	$TabContainer.current_tab = 0

func _process(_delta):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
