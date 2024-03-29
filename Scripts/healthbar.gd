extends TextureProgressBar

@export var player : CharacterBody3D


func _ready():
	player.healthChanged.connect(update)
	update() 


func update():
	value = player.currentHealth * 100 / player.maxHealth
