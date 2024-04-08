extends OptionButton

func _ready():
	selected = Global.msaa

func _on_item_selected(index):
	match index:
		0:
			Global.msaa = RenderingServer.VIEWPORT_MSAA_DISABLED
		1:
			Global.msaa = RenderingServer.VIEWPORT_MSAA_2X
		2:
			Global.msaa = RenderingServer.VIEWPORT_MSAA_4X
		3:
			Global.msaa = RenderingServer.VIEWPORT_MSAA_8X
