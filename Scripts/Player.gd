extends CharacterBody3D

class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 10

@export var max_health = 100
var health = max_health

signal healthChanged
signal playerDied

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_controller = $CameraController
@onready var skeleton = $guy/DRV_Armature/Skeleton3D
@onready var animation_tree = $guy/AnimationTree

var dead = false

func _physics_process(delta):
	#Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if(!dead):
		#Jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (camera_controller.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			if(!$CameraController.camera_locked_on):
				rotation = Vector3.ZERO;
				skeleton.look_at(to_global(-direction), Vector3.UP)
				skeleton.rotation.x=0
			else:
				skeleton.rotation = Vector3(0, deg_to_rad(180), 0)
				skeleton.rotation.x=0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		move_and_slide()
		if(!$CameraController.camera_locked_on):
			animation_tree.set("parameters/isStrafe/blend_amount", 0.0)
			animation_tree.set("parameters/idle-run/blend_position", velocity.length() / SPEED)
		else:
			animation_tree.set("parameters/isStrafe/blend_amount", 1.0)
			animation_tree.set("parameters/strafe/blend_position", input_dir)
	
	if Input.is_action_just_pressed("testi"):
		take_damage(50)

func update_health():
	if(health <= 0):
		die()
	health = clamp(health, 0, max_health)
	healthChanged.emit()

func take_damage(dmg):
	health-=dmg
	update_health()

func die():
	skeleton.physical_bones_start_simulation()
	dead = true
	playerDied.emit()

func _on_hurt_box_area_entered(area): #only enemy hitbox should trigger this
	print(area)
	if area.get_groups().has("enemy_hitbox"):
		print(area.damage)
		take_damage(area.damage)
