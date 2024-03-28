extends Node3D

@onready var player = $Player

func _ready():
	pass

func _physics_process(_delta):
	#enemy pathfinding
	get_tree().call_group("enemies", "update_target_location", player.position)
