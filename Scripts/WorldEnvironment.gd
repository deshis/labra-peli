extends WorldEnvironment

func _ready():
	update_world_environment_settings()

func update_world_environment_settings():
	environment.ssao_enabled = Global.ssao
	environment.sdfgi_enabled = Global.sdfgi
	environment.glow_enabled = Global.glow
	environment.ssr_enabled = Global.ssr
	
