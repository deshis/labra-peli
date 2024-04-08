extends MarginContainer

func _on_mouse_slider_value_changed(value):
	Global.mouse_sensitivity = value

func _on_controller_slider_value_changed(value):
	Global.controller_sensitivity = value
