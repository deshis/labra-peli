extends AudioStreamPlayer

func _process(_delta: float)->void:
	Global.main_menu_music_time = get_playback_position()

func _on_finished()->void:
	play()
