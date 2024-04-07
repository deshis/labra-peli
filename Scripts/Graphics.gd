extends MarginContainer

var world_environment: WorldEnvironment
var light: DirectionalLight3D

func _on_sdfgi_button_toggled(toggled_on):
	Global.sdfgi = toggled_on

func _on_ssao_button_toggled(toggled_on):
	Global.ssao = toggled_on

func _on_glow_button_toggled(toggled_on):
	Global.glow = toggled_on

func _on_shadow_quality_drop_down_item_selected(index):
	Global.shadow_quality = index
