extends HSlider

@export var bus_name: String
var bus_index

var config = ConfigFile.new()
var volume_type


func _ready():
	bus_index = AudioServer.get_bus_index(bus_name)
	value_changed.connect(_on_value_changed)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	match bus_index:
		0:
			volume_type = "volume_master"
		1:
			volume_type = "volume_sfx"
		2:
			volume_type = "volume_music"
	config.load("user://settings.cfg")
	value = config.get_value("Audio", volume_type)
	
func _on_value_changed(val):
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(val))
	config.load("user://settings.cfg")
	config.set_value("Audio", volume_type, val)
	config.save("user://settings.cfg")
