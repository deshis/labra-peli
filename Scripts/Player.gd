extends CharacterBody3D

class_name Player

@export var WALK_SPEED = 4.0
@export var RUN_SPEED = 6.0
var current_speed

@export var JUMP_VELOCITY = 10

@export var max_health = 100
var health = max_health

signal healthChanged
signal playerDied

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_controller = $CameraController
@onready var skeleton = $guy/DRV_Armature/Skeleton3D
@onready var ragdoll_skeleton = $player_ragdoll/DRV_Armature/Skeleton3D
@onready var animation_tree = $guy/AnimationTree

var hitbox = preload("res://Scenes/PlayerHitBox.tscn")
@export var attack_damage = 10

var dead = false

func _ready():
	$player_ragdoll.visible = false

func _physics_process(delta):
	
	if Input.is_action_just_pressed("attack"):
		attack()
	
	#Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if camera_controller.camera_locked_on:
		current_speed=WALK_SPEED
	else:
		current_speed=RUN_SPEED
	
	if(!dead):
		#Jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (camera_controller.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			if(!camera_controller.camera_locked_on):
				rotation = Vector3.ZERO;
				skeleton.look_at(to_global(-direction), Vector3.UP)
				ragdoll_skeleton.look_at(to_global(-direction), Vector3.UP)
			else:
				skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
				ragdoll_skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
				rotate_object_local(Vector3.UP, PI) #look_at points in the opposite direction so we have to flip 180
			skeleton.rotation.x=0
			skeleton.rotation.z=0
			ragdoll_skeleton.rotation.x=0
			ragdoll_skeleton.rotation.z=0
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		
		move_and_slide()
		if(!camera_controller.camera_locked_on):
			animation_tree.set("parameters/isStrafe/blend_amount", 0.0)
			animation_tree.set("parameters/idle-run/blend_position", velocity.length() / current_speed)
		else:
			animation_tree.set("parameters/isStrafe/blend_amount", 1.0)
			animation_tree.set("parameters/strafe/blend_position", input_dir)
	
	if Input.is_action_just_pressed("testi"):
		take_damage(50)
	

func attack():
	var hand
	if(animation_tree.get("parameters/AttackState/playback").get_current_node() == "punch"): #right hand punch
		hand = skeleton.get_node("RightHandAttachment")
		animation_tree.set("parameters/AttackState/conditions/combo", true)
		animation_tree.set("parameters/AttackState/conditions/stop", false)
	else: #left hand punch
		hand = skeleton.get_node("LeftHandAttachment")
		animation_tree.set("parameters/AttackState/conditions/combo", false)
		animation_tree.set("parameters/AttackState/conditions/stop", true)
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
	if(camera_controller.camera_locked_on):
		skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
		ragdoll_skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
		rotate_object_local(Vector3.UP, PI) #look_at points in the opposite direction so we have to flip 180
		skeleton.rotation.x=0
		skeleton.rotation.z=0
		ragdoll_skeleton.rotation.x=0
		ragdoll_skeleton.rotation.z=0
	
	#prevent multiple hitboxes from spawning
	if(hand.get_children().size()>0):
		for child in hand.get_children():
			child.queue_free()
	var punch_hitbox = hitbox.instantiate()
	punch_hitbox.damage = attack_damage
	hand.add_child(punch_hitbox)
	#hitbox gets deleted in animationtree signal

func update_health():
	if(health <= 0 and not dead):
		die()
	health = clamp(health, 0, max_health)
	healthChanged.emit()

func take_damage(dmg):
	health-=dmg
	update_health()

func die():
	$guy.visible = false
	$player_ragdoll.visible = true
	ragdoll_skeleton.physical_bones_start_simulation()
	
	#add random impulse to make ragdoll more interesting
	var rng = RandomNumberGenerator.new()
	var random_direction = Vector3(rng.randf_range(-1,1), rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized()
	ragdoll_skeleton.get_node("Physical Bone Hip").apply_central_impulse(random_direction*20)
	dead = true
	playerDied.emit()

func _on_hurt_box_area_entered(area): #only enemy hitbox should trigger this
	if area.get_groups().has("enemy_hitbox"):
		take_damage(area.damage)
		area.queue_free()

func _on_animation_tree_animation_finished(anim_name):
	if(anim_name=="punch"):
		for child in skeleton.get_node("LeftHandAttachment").get_children():
			child.queue_free()
	elif(anim_name == "punch2"):
		for child in skeleton.get_node("RightHandAttachment").get_children():
			child.queue_free()
