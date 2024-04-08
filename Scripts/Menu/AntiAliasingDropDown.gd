extends OptionButton

func _ready():
	selected = Global.msaa

func _on_item_selected(index):
	Global.msaa = selected
