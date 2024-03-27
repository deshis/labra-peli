extends CharacterBody3D


@export var SPEED = 5.0


@onready var camera_controller = $CameraController
@onready var camera_target = $CameraController/CameraTarget
@export var camera_sensitivity = 0.01
var twist_input = 0.0
var pitch_input = 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (camera_controller.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	
	#press esc to get mouse back
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	#make camera follow player with lerp smoothing
	camera_controller.position = lerp(camera_controller.position, position, 0.15)
	
	#camera rotation with mouse
	camera_controller.rotate_y(twist_input)
	camera_target.rotate_x(pitch_input)
	camera_target.rotation.x = clamp(camera_target.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0
	
	


func _unhandled_input(event):
	
	#moving camera with mouse
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * camera_sensitivity
			pitch_input = - event.relative.y * camera_sensitivity
