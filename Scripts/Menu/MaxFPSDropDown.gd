extends OptionButton


func _ready():
	match Engine.get_max_fps():
		0:
			selected = 0
		30:
			selected = 1
		60:
			selected = 2
		120:
			selected = 3
		144:
			selected = 4


func _on_item_selected(index):
	match index:
		0:
			Engine.set_max_fps(0)
		1:
			Engine.set_max_fps(30)
		2:
			Engine.set_max_fps(60)
		3:
			Engine.set_max_fps(120)
		4:
			Engine.set_max_fps(144)
