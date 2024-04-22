extends AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	if(Global.main_menu_music_time):
		play(Global.main_menu_music_time)
	else:
		play()
		
		
func _process(_delta):
	Global.main_menu_music_time = get_playback_position()

func _on_finished():
	play()
