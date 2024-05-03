extends Control

@onready var back_button: Button = $BackButtonMargin/BackButton
@onready var music_player: AudioStreamPlayer = $MainMenuMusicPlayer

func _ready() -> void:
	back_button.grab_focus()
	if(Global.main_menu_music_time):
		music_player.play(Global.main_menu_music_time)
	else:
		music_player.play()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
