extends WorldEnvironment

var config := ConfigFile.new()

func _ready()->void:
	update_world_environment_settings()

func update_world_environment_settings()->void:
	config.load("user://settings.cfg")
	if(config.get_value("Graphics", "ambient_occlusion")!=null):
		environment.ssao_enabled = config.get_value("Graphics", "ambient_occlusion")
	if(config.get_value("Graphics", "global_illumination")!=null):
		environment.sdfgi_enabled = config.get_value("Graphics", "global_illumination")
	if(config.get_value("Graphics", "glow")!=null):
		environment.glow_enabled = config.get_value("Graphics", "glow")
	if(config.get_value("Graphics", "reflections")!=null):
		environment.ssr_enabled = config.get_value("Graphics", "reflections")
