extends Control

func _ready():
	$BackButtonMargin/BackButton.grab_focus()
	if(Global.main_menu_music_time):
		$MainMenuMusicPlayer.play(Global.main_menu_music_time)
	else:
		$MainMenuMusicPlayer.play()

func _process(_delta):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
