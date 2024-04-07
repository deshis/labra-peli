extends CharacterBody3D

class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 10

@onready var camera_controller = $CameraController
@onready var spring_arm = $CameraController/SpringArm3D

@onready var camera_mouse_sensitivity = Global.mouse_sensitivity
@onready var camera_controller_sensitivity = Global.controller_sensitivity

var twist_input = 0.0
var pitch_input = 0.0

@export var maxHealth = 10
@onready var currentHealth = maxHealth
signal healthChanged

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	
	#moving camera with controller. mouse input is handled in _unhandled_input
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if(look_dir):
		twist_input = - look_dir.x * camera_controller_sensitivity
		pitch_input = - look_dir.y * camera_controller_sensitivity
	
	#camera follows player with lerp smoothing
	camera_controller.position = lerp(camera_controller.position, position, 0.15)
	
	#camera rotation
	camera_controller.rotate_y(twist_input)	
	spring_arm.rotate_x(pitch_input)
	
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(50))
	twist_input = 0.0
	pitch_input = 0.0


func updateHealth(amount):
	if(currentHealth >= 0):
		currentHealth = clamp(currentHealth+amount, 0, maxHealth)
		healthChanged.emit()

func _unhandled_input(event):
	#moving camera with mouse
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * camera_mouse_sensitivity
			pitch_input = - event.relative.y * camera_mouse_sensitivity
