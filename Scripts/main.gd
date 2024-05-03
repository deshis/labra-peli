class_name Main

extends Node3D

@onready var player: Player = $Player
@onready var main_enemy_switch_timer: Timer = $MainEnemySwitchTimer
var rng := RandomNumberGenerator.new()

var main_enemy_switch_lower := 7.0
var main_enemy_switch_higher := 13.0

@export var passive_enemy_distance := 5.0
@export var main_enemy_distance := 1.25

var main_enemy_index := 0
var enemy_array := []

@onready var music_player:AudioStreamPlayer = $MusicPlayer
var music_dir := "res://Assets/Audio/Music"
var music_files: Array[AudioStream] = []
var music_index := 0

func _ready()->void:
	Global.main_menu_music_time = 0.0
	
	main_enemy_switch_timer.start(0.3)
	enemy_array = get_tree().get_nodes_in_group("enemies")
	Global.can_pause = true
	
	var dir := DirAccess.open(music_dir)
	for file in dir.get_files():
		if file.reverse().left(4) =="3pm.":
			music_files.append(load(music_dir+'/'+file))
	music_files.shuffle()
	music_player.set_stream(music_files[music_index])
	music_player.play()

func _on_enemy_pathfinding_timer_timeout()->void:
	#set enemy path finding target
	get_tree().call_group("enemies", "update_target_location", player.position)
	
	#sets enemy pathfinding target offsets. 
	#one of the enemies will be the 'main' enemy who is closer, while the others are passive furter away.
	#this will prevent the enemies from clumping together next to the player. 
	for i in range(0, enemy_array.size()):
		var enemy:Enemy = enemy_array[i]
		var offset_direction := (enemy.global_position-player.global_position).normalized()
		
		if(i==main_enemy_index):
			enemy.formation_offset =  offset_direction * main_enemy_distance
		else:
			enemy.formation_offset =  offset_direction * passive_enemy_distance

func _on_main_enemy_switch_timer_timeout()->void:
	#reset timer
	main_enemy_switch_timer.start(rng.randf_range(main_enemy_switch_lower, main_enemy_switch_higher))
	
	#only aggrod enemies can be main enemy...
	var aggrod_enemies := []
	for enemy: Enemy in enemy_array:
		if(enemy.aggro):
			aggrod_enemies.push_back(enemy)
			
	if(aggrod_enemies.size()>0):
		var random_aggrod_enemy_index := rng.randi_range(0,aggrod_enemies.size()-1)
		if(aggrod_enemies.size()>0):
			main_enemy_index = enemy_array.find(aggrod_enemies[random_aggrod_enemy_index])
	else: #if there are no aggrod enemies, pick random enemy
		main_enemy_index = rng.randi_range(0,enemy_array.size()-1)


func _on_music_player_finished()->void:
	music_index+=1
	if(music_index>=music_files.size()):
		music_index=0
	music_player.set_stream(music_files[music_index])
	music_player.play()
