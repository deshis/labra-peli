extends Camera3D

func _ready()->void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	var msaa: int = config.get_value("Graphics","anti_aliasing_index")
	get_viewport().set_msaa_3d(msaa)
