extends DirectionalLight3D

func _ready():
	update_directional_light_settings()

func update_directional_light_settings():
	directional_shadow_mode = Global.shadow_quality
