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

var camera_locked_on = false
var lock_on_targets = null
var camera_target_index = 0

@onready var highlight_material = preload("res://Materials/highlighted.tres")
@onready var default_material = preload("res://Materials/default.tres")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Input.set_use_accumulated_input(false)


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
	
	#camera follows player with lerp smoothing
	camera_controller.position = lerp(camera_controller.position, position, 0.15)
	
	
	if Input.is_action_just_pressed("camera_lock_on"):
		#reset camera to prevent weird behaviour
		spring_arm.rotation.x = 0
		spring_arm.rotation.y = 0
		spring_arm.rotation.z = 0
		camera_controller.rotation.x = 0
		camera_controller.rotation.z = 0
		
		if(!camera_locked_on):
			lock_on_targets = get_tree().get_nodes_in_group("enemies")
			camera_locked_on = true
			#find closest target
			camera_target_index = 0
			for i in range(lock_on_targets.size()):
				if lock_on_targets[i].global_position.distance_to(global_position) < lock_on_targets[camera_target_index].global_position.distance_to(global_position):
					camera_target_index = i
			
			#highlight the locked on enemy
			lock_on_targets[camera_target_index].get_node("capsule/Mball_001").set_surface_override_material(0, highlight_material)
			
		
		else:
			#highlight the locked on enemy
			lock_on_targets[camera_target_index].get_node("capsule/Mball_001").set_surface_override_material(0, default_material)
			lock_on_targets = null
			camera_locked_on = false
	
	
	if(camera_locked_on and lock_on_targets):
		if Input.is_action_just_pressed("camera_switch_target_left"):
			if(camera_target_index<=0):
				camera_target_index = lock_on_targets.size()-1
				#unhighlight deselected target
				lock_on_targets[0].get_node("capsule/Mball_001").set_surface_override_material(0, default_material)
			else:
				camera_target_index-=1
				#unhighlight deselected target
				lock_on_targets[camera_target_index+1].get_node("capsule/Mball_001").set_surface_override_material(0, default_material)
			#highlight selected target
			lock_on_targets[camera_target_index].get_node("capsule/Mball_001").set_surface_override_material(0, highlight_material)

		if Input.is_action_just_pressed("camera_switch_target_right"):
			if(camera_target_index>=lock_on_targets.size()-1):
				camera_target_index = 0
				#unhighlight deselected target
				lock_on_targets[lock_on_targets.size()-1].get_node("capsule/Mball_001").set_surface_override_material(0, default_material)
			else:
				camera_target_index+=1
				#unhighlight deselected target
				lock_on_targets[camera_target_index-1].get_node("capsule/Mball_001").set_surface_override_material(0, default_material)
			#highlight selected target
			lock_on_targets[camera_target_index].get_node("capsule/Mball_001").set_surface_override_material(0, highlight_material)
		
		
		var current_target = lock_on_targets[camera_target_index]
		
		#lock on camera
		camera_controller.look_at(current_target.position, Vector3.UP)
		camera_controller.rotation.x=0 #x rotation is handled by spring_arm
		
		spring_arm.look_at(current_target.position)
		#aim camera a bit down so you can see the enemy better
		spring_arm.rotation.x += deg_to_rad(-20)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(50)) #prevent upside down camera
		
	else:
		#moving camera with controller. mouse input is handled in _unhandled_input
		var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if(look_dir):
			twist_input = - look_dir.x * camera_controller_sensitivity
			pitch_input = - look_dir.y * camera_controller_sensitivity
		
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
