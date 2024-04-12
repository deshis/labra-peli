extends MarginContainer

var config = ConfigFile.new()

func _ready():
	config.load("user://settings.cfg")
	$VBoxContainer/MouseSlider.value = config.get_value("Controls", "mouse_sensitivity")
	$VBoxContainer/ControllerSlider.value = config.get_value("Controls", "controller_sensitivity")


func _on_mouse_slider_value_changed(value):
	config.set_value("Controls", "mouse_sensitivity", value)
	config.save("user://settings.cfg")

func _on_controller_slider_value_changed(value):
	config.set_value("Controls", "controller_sensitivity", value)
	config.save("user://settings.cfg")
