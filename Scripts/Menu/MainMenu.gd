extends CanvasLayer

func _ready():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK: 
		#if settings file does not exist, create it with default settings
		
		config.set_value("Audio", "volume_master", 0.5)
		config.set_value("Audio", "volume_sfx", 0.5)
		config.set_value("Audio", "volume_music", 0.5)
		
		config.set_value("Controls", "mouse_sensitivity", 0.01)
		config.set_value("Controls", "controller_sensitivity", 0.1)
		
		config.set_value("Graphics", "global_illumination", true)
		config.set_value("Graphics", "ambient_occlusion", true)
		config.set_value("Graphics", "glow", true)
		config.set_value("Graphics", "reflections", true)
		config.set_value("Graphics", "shadow_quality_index", 2)
		config.set_value("Graphics", "vsync", false)
		config.set_value("Graphics", "anti_aliasing_index", RenderingServer.VIEWPORT_MSAA_8X)
		config.set_value("Graphics", "fullscreen", false)
		
		config.save("user://settings.cfg")
	
	
	#set vsync and fullscreen mode. other graphics settings get set in game scene
	if(config.get_value("Graphics", "vsync")):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if(config.get_value("Graphics", "fullscreen")):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	#set audio levels 
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(config.get_value("Audio", "volume_master")))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(config.get_value("Audio", "volume_sfx")))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(config.get_value("Audio", "volume_music")))
	$ButtonsContainer/StartGameButton.grab_focus()

func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

func _on_credits_pressed():
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")

func _on_quit_game_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


