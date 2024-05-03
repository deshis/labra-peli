extends MarginContainer

var world_environment: WorldEnvironment
var light: DirectionalLight3D

var config := ConfigFile.new()

@onready var sdfgi_button: Button = $VBoxContainer/SDFGIButton
@onready var ssao_button: Button = $VBoxContainer/SSAOButton
@onready var glow_button: Button = $VBoxContainer/GlowButton
@onready var ssr_button: Button = $VBoxContainer/SSRButton
@onready var shadow_quality: OptionButton = $VBoxContainer/ShadowBoxContainer/ShadowQualityDropDown
@onready var anti_aliasing_quality: OptionButton = $VBoxContainer/AntiAliasingContainer2/AntiAliasingDropDown
@onready var vsync_button: Button = $VBoxContainer/VSyncButton
@onready var full_screen_button: Button = $VBoxContainer/FullScreenButton



func _ready() -> void:
	config.load("user://settings.cfg")
	sdfgi_button.button_pressed = config.get_value("Graphics", "global_illumination")
	ssao_button.button_pressed = config.get_value("Graphics", "ambient_occlusion")
	glow_button.button_pressed = config.get_value("Graphics", "glow")
	ssr_button.button_pressed = config.get_value("Graphics", "reflections")
	shadow_quality.selected = config.get_value("Graphics", "shadow_quality_index")
	anti_aliasing_quality.selected = config.get_value("Graphics", "anti_aliasing_index")
	vsync_button.button_pressed = config.get_value("Graphics", "vsync")
	full_screen_button.button_pressed = config.get_value("Graphics", "fullscreen")

func _on_sdfgi_button_toggled(toggled_on: bool) -> void:
	config.set_value("Graphics", "global_illumination", toggled_on)
	config.save("user://settings.cfg")

func _on_ssao_button_toggled(toggled_on: bool) -> void:
	config.set_value("Graphics", "ambient_occlusion", toggled_on)
	config.save("user://settings.cfg")

func _on_glow_button_toggled(toggled_on: bool) -> void:
	config.set_value("Graphics", "glow", toggled_on)
	config.save("user://settings.cfg")

func _on_shadow_quality_drop_down_item_selected(index: int) -> void:
	config.set_value("Graphics", "shadow_quality_index", index)
	config.save("user://settings.cfg")

func _on_ssr_button_toggled(toggled_on: bool) -> void:
	config.set_value("Graphics", "reflections", toggled_on)
	config.save("user://settings.cfg")

func _on_anti_aliasing_drop_down_item_selected(index: int) -> void:
	config.set_value("Graphics", "anti_aliasing_index", index)
	config.save("user://settings.cfg")

func _on_v_sync_button_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	config.set_value("Graphics", "vsync", toggled_on)
	config.save("user://settings.cfg")

func _on_full_screen_button_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	config.set_value("Graphics", "fullscreen", toggled_on)
	config.save("user://settings.cfg")
