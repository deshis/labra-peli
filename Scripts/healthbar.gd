extends TextureProgressBar

@export var player: Player

func _ready()->void:
	player.healthChanged.connect(update)
	update() 


func update()->void:
	value = player.health * 100 / player.max_health
