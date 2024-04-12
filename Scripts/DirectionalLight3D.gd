extends DirectionalLight3D

var config = ConfigFile.new()

func _ready():
	update_directional_light_settings()

func update_directional_light_settings():
	config.load("user://settings.cfg")
	var shadow_quality = config.get_value("Graphics", "shadow_quality_index")
	match shadow_quality:
		0:
			set_shadow_mode(SHADOW_ORTHOGONAL)
		1:
			set_shadow_mode(SHADOW_PARALLEL_2_SPLITS)
		2:
			set_shadow_mode(SHADOW_PARALLEL_4_SPLITS)
