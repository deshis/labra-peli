extends Node3D

@onready var player = $Player
@onready var enemy_formation_timer = $EnemyFormationTimer
@onready var main_enemy_switch_timer = $MainEnemySwitchTimer
var rng = RandomNumberGenerator.new()

var enemy_formation_lower = 1.0
var enemy_formation_higher = 4.0

var main_enemy_switch_lower = 7.0
var main_enemy_switch_higher = 13.0

@export var passive_enemy_distance = 6.0
@export var main_enemy_distance = 1.5

var main_enemy_index = 0
var enemy_array = []

func _ready():
	enemy_formation_timer.start(0.2)
	main_enemy_switch_timer.start(0.2)

func _on_enemy_pathfinding_timer_timeout():
	#set enemy path finding target
	get_tree().call_group("enemies", "update_target_location", player.position)


func _on_enemy_formation_timer_timeout():
	#reset timer
	enemy_formation_timer.start(rng.randf_range(enemy_formation_lower, enemy_formation_higher))
	
	#sets enemy pathfinding target offsets. 
	#one of the enemies will be the 'main' enemy who is closer, while the others are passive furter away.
	#this will prevent the enemies from clumping together next to the player. 
	enemy_array = get_tree().get_nodes_in_group("enemies")
	
	for i in range(0, enemy_array.size()):
		var enemy = enemy_array[i]
		var player_camera_vector = -player.camera_controller.basis.z
		var offset_direction = player_camera_vector.rotated(Vector3i.UP, deg_to_rad(rng.randf_range(-15, 15)))
		if(i==main_enemy_index):
			enemy.formation_offset =  offset_direction * main_enemy_distance
		else:
			enemy.formation_offset =  offset_direction * passive_enemy_distance * rng.randf_range(0.8, 1.2)


func _on_main_enemy_switch_timer_timeout():
	#reset timer
	main_enemy_switch_timer.start(rng.randf_range(main_enemy_switch_lower, main_enemy_switch_higher))
	main_enemy_index = rng.randi_range(0,enemy_array.size()-1)
