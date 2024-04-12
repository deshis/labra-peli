extends WorldEnvironment

var config = ConfigFile.new()

func _ready():
	update_world_environment_settings()

func update_world_environment_settings():
	config.load("user://settings.cfg")
	environment.ssao_enabled = config.get_value("Graphics", "ambient_occlusion")
	environment.sdfgi_enabled = config.get_value("Graphics", "global_illumination")
	environment.glow_enabled = config.get_value("Graphics", "glow")
	environment.ssr_enabled = config.get_value("Graphics", "reflections")
