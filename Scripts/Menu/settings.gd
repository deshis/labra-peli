extends Control

@onready var cont: TabContainer = $TabContainer
@onready var music: AudioStreamPlayer = $MainMenuMusicPlayer

func _ready() -> void:
	cont.get_tab_bar().grab_focus()
	cont.current_tab = 0
	
	if(Global.main_menu_music_time):
		music.play(Global.main_menu_music_time)
	else:
		music.play()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
