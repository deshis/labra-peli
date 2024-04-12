extends CharacterBody3D

class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 10

@export var maxHealth = 10
@onready var currentHealth = maxHealth
signal healthChanged

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_controller = $CameraController

func _physics_process(delta):
	#Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	#Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (camera_controller.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("testi"):
		updateHealth(-1)

func updateHealth(amount):
	if(currentHealth >= 0):
		currentHealth = clamp(currentHealth+amount, 0, maxHealth)
		healthChanged.emit()
