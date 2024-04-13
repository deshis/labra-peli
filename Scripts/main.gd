extends Node3D

@onready var player = $Player
@onready var main_enemy_switch_timer = $MainEnemySwitchTimer
var rng = RandomNumberGenerator.new()

var main_enemy_switch_lower = 7.0
var main_enemy_switch_higher = 13.0

@export var passive_enemy_distance = 4.5
@export var main_enemy_distance = 1.5

var main_enemy_index = 0
var enemy_array = []

func _ready():
	main_enemy_switch_timer.start(0.3)
	enemy_array = get_tree().get_nodes_in_group("enemies")

func _on_enemy_pathfinding_timer_timeout():
	#set enemy path finding target
	get_tree().call_group("enemies", "update_target_location", player.position)
	
	#sets enemy pathfinding target offsets. 
	#one of the enemies will be the 'main' enemy who is closer, while the others are passive furter away.
	#this will prevent the enemies from clumping together next to the player. 
	for i in range(0, enemy_array.size()):
		var enemy = enemy_array[i]
		var offset_direction = (enemy.global_position-player.global_position).normalized()
		
		if(i==main_enemy_index):
			enemy.formation_offset =  offset_direction * main_enemy_distance
		else:
			enemy.formation_offset =  offset_direction * passive_enemy_distance

func _on_main_enemy_switch_timer_timeout():

	#reset timer
	main_enemy_switch_timer.start(rng.randf_range(main_enemy_switch_lower, main_enemy_switch_higher))
	
	#only aggrod enemies can be main enemy...
	var aggrod_enemies = []
	for enemy in enemy_array:
		if(enemy.aggro):
			aggrod_enemies.push_back(enemy)
	var random_aggrod_enemy_index = rng.randi_range(0,aggrod_enemies.size()-1)
	main_enemy_index = enemy_array.find(aggrod_enemies[random_aggrod_enemy_index])
