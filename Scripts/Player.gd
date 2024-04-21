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
@export var attack_damage = 50
@export var attack_knockback_strength = 3.5

var dead = false

var rng = RandomNumberGenerator.new()

var can_start_new_attack_combo = true

@onready var collider = $CollisionShape3D
@onready var hurtbox = $HurtBox/CollisionShape3D
var collider_offset = -0.35 

func _ready():
	$player_ragdoll.visible = false

func _physics_process(delta):
	#keep colliders synced with animation
	collider.global_position = skeleton.get_node("CameraAttachment").global_position
	collider.position.y=collider_offset
	hurtbox.global_position = skeleton.get_node("CameraAttachment").global_position
	hurtbox.position.y=collider_offset
	
	if Input.is_action_just_pressed("attack"):
		attack()
	
	#Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if camera_controller.camera_locked_on and can_start_new_attack_combo:
		current_speed = WALK_SPEED
	elif(!can_start_new_attack_combo):
		current_speed = 0
	else:
		current_speed = RUN_SPEED
	
	if(!dead):
		#Jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (camera_controller.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			if(can_start_new_attack_combo):
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
	if(animation_tree.get("parameters/AttackState/playback").get_current_node() == "l1"): #right hand punch
		hand = skeleton.get_node("RightHandAttachment")
		animation_tree.set("parameters/AttackState/conditions/combo", true)
		animation_tree.set("parameters/AttackState/conditions/stop", false)
	elif(can_start_new_attack_combo): #left hand punch
		can_start_new_attack_combo = false
		hand = skeleton.get_node("LeftHandAttachment")
		animation_tree.set("parameters/AttackState/conditions/combo", false)
		animation_tree.set("parameters/AttackState/conditions/stop", true)
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
		
	if(camera_controller.camera_locked_on): # look at locked on enemy
		skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
		ragdoll_skeleton.look_at(camera_controller.current_target.global_position, Vector3.UP)
		rotate_object_local(Vector3.UP, PI)
		skeleton.rotation.x=0
		skeleton.rotation.z=0
		ragdoll_skeleton.rotation.x=0
		ragdoll_skeleton.rotation.z=0
	

	if(hand!=null):
		if(hand.get_children().size()>0):#prevent multiple hitboxes from spawning
			for child in hand.get_children():
				child.queue_free()
		var punch_hitbox = hitbox.instantiate()
		punch_hitbox.damage = attack_damage
		punch_hitbox.knockback_strength = attack_knockback_strength
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
	var random_direction = Vector3(rng.randf_range(-1,1), rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized()
	ragdoll_skeleton.get_node("Physical Bone Hip").apply_central_impulse(random_direction*20)
	dead = true
	playerDied.emit()

func _on_hurt_box_area_entered(area): #only enemy hitbox should trigger this
	if area.get_groups().has("enemy_hitbox"):
		take_damage(area.damage)
		#set flincher
		animation_tree.set("parameters/Flinch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#knockback
		var dir = global_position - area.get_parent().get_parent().global_position
		dir.y=0
		velocity += dir*area.knockback_strength
		move_and_slide()
		#flinch animation here (?)
		
		area.queue_free()

func animation_finished(anim_name):
	match anim_name:
		"attack_l1":
			for child in skeleton.get_node("LeftHandAttachment").get_children():
				child.queue_free()
		"attack_l2":
			for child in skeleton.get_node("RightHandAttachment").get_children():
				child.queue_free()
		"attack_l1_stop":
			can_start_new_attack_combo = true
		"attack_l2_stop":
			can_start_new_attack_combo = true
