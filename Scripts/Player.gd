class_name Player

extends CharacterBody3D

@export var WALK_SPEED := 4.0
@export var RUN_SPEED := 6.0
var current_speed: float

@export var JUMP_VELOCITY := 10.0

@export var max_health := 100.0
var health := max_health

signal healthChanged
signal playerDied

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_controller: CameraController = $CameraController
@onready var skeleton: Skeleton3D = $guy/DRV_Armature/Skeleton3D
@onready var ragdoll_skeleton: Skeleton3D = $player_ragdoll/DRV_Armature/Skeleton3D
@onready var animation_tree: AnimationTree = $guy/AnimationTree

var hitbox := preload("res://Scenes/PlayerHitBox.tscn")
@export var attack_damage := 50.0
@export var attack_knockback_strength := 10.0

var dead := false

var rng := RandomNumberGenerator.new()

var can_start_new_attack_combo := true

@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var hurtbox: CollisionShape3D = $HurtBox/CollisionShape3D
var collider_offset := -0.35 

var blocking := false

@onready var footsteps_player: AudioStreamPlayer3D = $FootstepsPlayer
var footstep_sounds: Array[AudioStream]= []
@onready var punch_player: AudioStreamPlayer3D = $PunchPlayer
var punch_sounds: Array[AudioStream] = []
@onready var hit_player: AudioStreamPlayer3D = $HitPlayer
var hit_sounds: Array[AudioStream] = []
@onready var block_player: AudioStreamPlayer3D = $BlockPlayer
var block_sounds: Array[AudioStream]= []
var sfx_dir := "res://Assets/Audio/SFX"

@onready var player_ragdoll: Node3D = $player_ragdoll
@onready var player_guy:Node3D = $guy

enum Movement {WALK, RUN}

func _ready()->void:
	player_ragdoll.visible = false
	#disable ragdoll collision while alive
	for node in ragdoll_skeleton.get_children():
		if node is PhysicalBone3D:
			var bone := node as PhysicalBone3D
			bone.collision_layer = 0
			bone.collision_mask = 0
	
	#create audio arrays
	for file in DirAccess.open(sfx_dir+"/footsteps").get_files():
		if file.reverse().left(4) =="3pm.":
			footstep_sounds.append(load(sfx_dir+"/footsteps/"+file))
	for file in DirAccess.open(sfx_dir+"/swing").get_files():
		if file.reverse().left(4) =="3pm.":
			punch_sounds.append(load(sfx_dir+"/swing/"+file))
	for file in DirAccess.open(sfx_dir+"/hit").get_files():
		if file.reverse().left(4) =="3pm.":
			hit_sounds.append(load(sfx_dir+"/hit/"+file))
	for file in DirAccess.open(sfx_dir+"/block").get_files():
		if file.reverse().left(4) =="3pm.":
			block_sounds.append(load(sfx_dir+"/block/"+file))

func _physics_process(delta: float)->void:
	
	#keep colliders synced with animation
	var attachment:BoneAttachment3D = skeleton.get_node("CameraAttachment")
	collider.global_position = attachment.global_position
	collider.position.y=collider_offset
	hurtbox.global_position = attachment.global_position
	hurtbox.position.y=collider_offset
	
	#Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if not can_start_new_attack_combo:
		current_speed = 0
	elif camera_controller.camera_locked_on:
		current_speed = WALK_SPEED
	else:
		current_speed = RUN_SPEED
	
	if not dead:
		if Input.is_action_just_pressed("attack"):
			attack()
		if Input.is_action_just_pressed("heavy_attack"):
			heavy_attack()
		
		if can_start_new_attack_combo:
			if(Input.is_action_pressed("block") && (animation_tree.get("parameters/GuardState/playback") as AnimationNodeStateMachinePlayback).get_current_node() != "guard"):
				blocking = true
				animation_tree.set("parameters/GuardState/conditions/guard_stop", false)
				animation_tree.set("parameters/Guard/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
			
			if(Input.is_action_just_released("block") && blocking):
				animation_tree.set("parameters/GuardState/conditions/guard_stop", true)
				blocking = false
			
			if Input.is_action_just_pressed("jump") and is_on_floor() and can_start_new_attack_combo:
				velocity.y = JUMP_VELOCITY
		
		
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var stick_Force := input_dir.length()
		var direction := (camera_controller.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * current_speed * stick_Force
			velocity.z = direction.z * current_speed * stick_Force
			
			if can_start_new_attack_combo:
				if camera_controller.camera_locked_on:
					skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
					ragdoll_skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
					rotate_object_local(Vector3.UP, PI) #look_at points in the opposite direction so we have to flip 180
				else:
					rotation = Vector3.ZERO;
					skeleton.look_at(to_global(-direction), Vector3.UP)
					ragdoll_skeleton.look_at(to_global(-direction), Vector3.UP)
			
			skeleton.rotation.x=0
			skeleton.rotation.z=0
			ragdoll_skeleton.rotation.x=0
			ragdoll_skeleton.rotation.z=0
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		
		move_and_slide()
		
		if not camera_controller.camera_locked_on:
			animation_tree.set("parameters/isStrafe/blend_amount", 0.0)
			animation_tree.set("parameters/idle-run/blend_position", stick_Force)
		else:
			animation_tree.set("parameters/isStrafe/blend_amount", 1.0)
			animation_tree.set("parameters/strafe/blend_position", Vector2(input_dir.x, -input_dir.y))
	
	if Input.is_action_just_pressed("testi"):
		take_damage(50)

func attack()->void:
	var hand: BoneAttachment3D
	if not blocking:
		if can_start_new_attack_combo:
			hand = skeleton.get_node("LeftHandAttachment")
			animation_tree.set("parameters/AttackState/conditions/light", true)
			animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
			can_start_new_attack_combo = false
		else:
			match (animation_tree.get("parameters/AttackState/playback") as AnimationNodeStateMachinePlayback).get_current_node():
				"l1":
					animation_tree.set("parameters/AttackState/conditions/light", true)
					hand = skeleton.get_node("RightHandAttachment")
				
			
		if camera_controller.camera_locked_on: # look at locked on enemy
			skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
			ragdoll_skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
			rotate_object_local(Vector3.UP, PI)
			skeleton.rotation.x=0
			skeleton.rotation.z=0
			ragdoll_skeleton.rotation.x=0
			ragdoll_skeleton.rotation.z=0
		
	if hand!=null :
		if(hand.get_children().size()>0):#prevent multiple hitboxes from spawning
			for child in hand.get_children():
				child.queue_free()
		var punch_hitbox: HitBox = hitbox.instantiate()
		punch_hitbox.damage = attack_damage
		punch_hitbox.knockback_strength = attack_knockback_strength
		hand.add_child(punch_hitbox)
		#hitbox gets deleted in animationtree signal


func heavy_attack()->void:
	var foot: BoneAttachment3D
	if not blocking:
		if can_start_new_attack_combo:
			animation_tree.set("parameters/AttackState/conditions/heavy", true)
			foot = skeleton.get_node("RightFootAttachment")
			animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
			can_start_new_attack_combo = false
		else:
			match (animation_tree.get("parameters/AttackState/playback") as AnimationNodeStateMachinePlayback).get_current_node():
				"l1":
					animation_tree.set("parameters/AttackState/conditions/heavy", true)
					foot = skeleton.get_node("RightFootAttachment")
				"l2":
					animation_tree.set("parameters/AttackState/conditions/heavy", true)
					foot = skeleton.get_node("LeftFootAttachment")
		
		if camera_controller.camera_locked_on: # look at locked on enemy
			skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
			ragdoll_skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
			rotate_object_local(Vector3.UP, PI)
			skeleton.rotation.x=0
			skeleton.rotation.z=0
			ragdoll_skeleton.rotation.x=0
			ragdoll_skeleton.rotation.z=0
	
	if foot!=null:
		if foot.get_children().size()>0:#prevent multiple hitboxes from spawning
			for child in foot.get_children():
				child.queue_free()
		var kick_hitbox:HitBox = hitbox.instantiate()
		kick_hitbox.damage = attack_damage
		kick_hitbox.knockback_strength = attack_knockback_strength
		foot.add_child(kick_hitbox)
		#hitbox gets deleted in animationtree signal


func update_health()->void:
	if health <= 0.0 and not dead:
		die()
	health = clamp(health, 0.0, max_health)
	healthChanged.emit()


func take_damage(dmg:float)->void:
	health-=dmg
	update_health()


func die()->void:
	player_guy.visible = false
	player_ragdoll.visible = true
	#re-enable ragdoll collision
	for node in ragdoll_skeleton.get_children():
		if node is PhysicalBone3D:
			var bone := node as PhysicalBone3D
			bone.collision_layer = 128
			bone.collision_mask = 129
	
	ragdoll_skeleton.physical_bones_start_simulation()
	
	#add random impulse to make ragdoll more interesting
	var random_direction := Vector3(rng.randf_range(-1,1), rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized()
	(ragdoll_skeleton.get_node("Physical Bone Hip") as PhysicalBone3D).apply_central_impulse(random_direction*20)
	dead = true
	playerDied.emit()


func _on_hurt_box_area_entered(area:HitBox)->void: #only enemy hitbox should trigger this
	if area.get_groups().has("enemy_hitbox"):
		if blocking:#block sound effect
			block_player.set_stream(block_sounds[rng.randi_range(0, block_sounds.size()-1)])
			block_player.play()
		else:
			take_damage(area.damage)
			#set flincher
			cancel_attack()
			animation_tree.set("parameters/Flinch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			#knockback
			var dir := global_position - (area.get_parent().get_parent() as Node3D).global_position
			dir.y=0
			velocity = dir.normalized()*area.knockback_strength
			move_and_slide()
			#hit sound effect
			hit_player.set_stream(hit_sounds[rng.randi_range(0, hit_sounds.size()-1)])
			hit_player.play()
		
		area.queue_free()


func cancel_attack()->void:
	animation_tree.set("parameters/AttackState/conditions/light", false)
	animation_tree.set("parameters/AttackState/conditions/heavy", false)	
	animation_tree.set("parameters/AttackState/conditions/stop", false)	
	
	for child in skeleton.get_node("LeftHandAttachment").get_children():
		child.queue_free()
	for child in skeleton.get_node("RightHandAttachment").get_children():
		child.queue_free()
	for child in skeleton.get_node("LeftFootAttachment").get_children():
		child.queue_free()
	for child in skeleton.get_node("RightFootAttachment").get_children():
		child.queue_free()
	
	
	var offset := skeleton.get_bone_pose_position(skeleton.find_bone("ROOT_CTRL")).z
	translate(Vector3(0, 0, offset).rotated(Vector3.UP, skeleton.rotation.y))
	can_start_new_attack_combo = true
	animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)


func animation_finished(anim_name: String)->void:
	if "attack_" in anim_name:
		if "_stop" in anim_name:
			can_start_new_attack_combo = true
			animation_tree.set("parameters/AttackState/conditions/stop", false)
			
			for child in skeleton.get_node("LeftHandAttachment").get_children():
				child.queue_free()
			for child in skeleton.get_node("RightHandAttachment").get_children():
				child.queue_free()
			for child in skeleton.get_node("LeftFootAttachment").get_children():
				child.queue_free()
			for child in skeleton.get_node("RightFootAttachment").get_children():
				child.queue_free()
		else:
			if !animation_tree.get("parameters/AttackState/conditions/light") and !animation_tree.get("parameters/AttackState/conditions/heavy"):
				animation_tree.set("parameters/AttackState/conditions/stop", true)
			match anim_name:
				"attack_l1":
					for child in skeleton.get_node("LeftHandAttachment").get_children():
						child.queue_free()
				"attack_l2":
					for child in skeleton.get_node("RightHandAttachment").get_children():
						child.queue_free()
				"attack_h1":
					for child in skeleton.get_node("RightFootAttachment").get_children():
						child.queue_free()
				"attack_l1h1":
					for child in skeleton.get_node("RightFootAttachment").get_children():
						child.queue_free()
				"attack_l2h1":
					for child in skeleton.get_node("LeftFootAttachment").get_children():
						child.queue_free()


func animation_started(anim_name:String)->void:
	if "attack_" in anim_name:
		animation_tree.set("parameters/AttackState/conditions/light", false)
		animation_tree.set("parameters/AttackState/conditions/heavy", false)
		if "_stop" not in anim_name: #swing sound effect
			punch_player.set_stream(punch_sounds[rng.randi_range(0, punch_sounds.size()-1)])
			punch_player.play()


func play_footsteps()->void:
	footsteps_player.set_stream(footstep_sounds[rng.randi_range(0, footstep_sounds.size()-1)])
	footsteps_player.play()
