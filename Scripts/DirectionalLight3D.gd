extends DirectionalLight3D

func _ready():
	update_directional_light_settings()

func update_directional_light_settings():
	match Global.shadow_quality:
		0:
			set_shadow_mode(SHADOW_ORTHOGONAL)
		1:
			set_shadow_mode(SHADOW_PARALLEL_2_SPLITS)
		2:
			set_shadow_mode(SHADOW_PARALLEL_4_SPLITS)
