extends MarginContainer

var config := ConfigFile.new()

@onready var mouse_slider: Slider = $VBoxContainer/MouseSlider
@onready var controller_slider: Slider = $VBoxContainer/ControllerSlider

func _ready() -> void:
	config.load("user://settings.cfg")
	mouse_slider.value = config.get_value("Controls", "mouse_sensitivity")
	controller_slider.value = config.get_value("Controls", "controller_sensitivity")


func _on_mouse_slider_value_changed(value: float) -> void:
	config.set_value("Controls", "mouse_sensitivity", value)
	config.save("user://settings.cfg")


func _on_controller_slider_value_changed(value: float) -> void:
	config.set_value("Controls", "controller_sensitivity", value)
	config.save("user://settings.cfg")
