extends Camera3D

func _ready():
	get_viewport().set_msaa_3d(Global.msaa)
