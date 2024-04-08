extends OptionButton


var res_dict : Dictionary = {
	"1152 x 648" : Vector2i(1152, 648),
	"1280 x 720" : Vector2i(1280, 720),
	"1366 x 768" : Vector2i(1366, 768),
	"1920 x 1080" : Vector2i(1920, 1080),
	"2560 x 1440" : Vector2i(2560, 1440),
	"3840 x 2160" : Vector2i(3840, 2160)
}

func _ready():
	get_tree().get_root().size_changed.connect(update_list)
	update_list()

func update_list():
	clear()
	for res_size in res_dict:
		add_item(res_size)
	selected = res_dict.values().find(DisplayServer.window_get_size())
	if(res_dict.values().find(DisplayServer.window_get_size())==-1):
		text="Custom"

func _on_item_selected(index):
	DisplayServer.window_set_size(res_dict.values()[index])
	update_list()
