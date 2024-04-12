extends MarginContainer

var world_environment: WorldEnvironment
var light: DirectionalLight3D

var config = ConfigFile.new()

func _ready():
	config.load("user://settings.cfg")
	$VBoxContainer/SDFGIButton.button_pressed = config.get_value("Graphics", "global_illumination")
	$VBoxContainer/SSAOButton.button_pressed = config.get_value("Graphics", "ambient_occlusion")
	$VBoxContainer/GlowButton.button_pressed = config.get_value("Graphics", "glow")
	$VBoxContainer/SSRButton.button_pressed = config.get_value("Graphics", "reflections")
	$VBoxContainer/ShadowBoxContainer/ShadowQualityDropDown.selected = config.get_value("Graphics", "shadow_quality_index")
	$VBoxContainer/AntiAliasingContainer2/AntiAliasingDropDown.selected = config.get_value("Graphics", "anti_aliasing_index")
	$VBoxContainer/VSyncButton.button_pressed = config.get_value("Graphics", "vsync")
	$VBoxContainer/FullScreenButton.button_pressed = config.get_value("Graphics", "fullscreen")

func _on_sdfgi_button_toggled(toggled_on):
	config.set_value("Graphics", "global_illumination", toggled_on)
	config.save("user://settings.cfg")

func _on_ssao_button_toggled(toggled_on):
	config.set_value("Graphics", "ambient_occlusion", toggled_on)
	config.save("user://settings.cfg")

func _on_glow_button_toggled(toggled_on):
	config.set_value("Graphics", "glow", toggled_on)
	config.save("user://settings.cfg")

func _on_shadow_quality_drop_down_item_selected(index):
	config.set_value("Graphics", "shadow_quality_index", index)
	config.save("user://settings.cfg")

func _on_ssr_button_toggled(toggled_on):
	config.set_value("Graphics", "reflections", toggled_on)
	config.save("user://settings.cfg")

func _on_anti_aliasing_drop_down_item_selected(index):
	config.set_value("Graphics", "anti_aliasing_index", index)
	config.save("user://settings.cfg")

func _on_v_sync_button_toggled(toggled_on):
	if(toggled_on):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	config.set_value("Graphics", "vsync", toggled_on)
	config.save("user://settings.cfg")

func _on_full_screen_button_toggled(toggled_on):
	if(toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	config.set_value("Graphics", "fullscreen", toggled_on)
	config.save("user://settings.cfg")
