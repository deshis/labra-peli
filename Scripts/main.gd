extends Node3D

@onready var player = $Player

func _on_enemy_pathfinding_timer_timeout():
	#enemy pathfinding
	get_tree().call_group("enemies", "update_target_location", player.position)
