extends CharacterBody3D


@export var SPEED = 5.0

@onready var player = get_node('/root/Main/Player')
@onready var nav = $NavigationAgent3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var aggro = false

var formation_offset = Vector3.ZERO

@onready var ray = $PlayerDetectionRayCast

func _physics_process(delta):
	var next_location 
	var current_location
	var new_velocity
	
	if aggro:
		#calculate path towards player
		next_location = nav.get_next_path_position()
		current_location = global_transform.origin
		new_velocity = (next_location - current_location).normalized() * SPEED
		nav.set_velocity(new_velocity)
	else:
		velocity.x = 0
		velocity.z = 0
	
	#gravity
	if not is_on_floor():
		velocity.y -= gravity*delta

#calculating safe velocity for avoidance to prevent enemies clumping together
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity.x = velocity.move_toward(safe_velocity,0.5).x
	velocity.z = velocity.move_toward(safe_velocity,0.5).z
	#dont set velocity.y because it screws up gravity...
	move_and_slide()

#called in main script of game scene
func update_target_location(target_location):
	if(aggro):
		nav.set_target_position(target_location+formation_offset) #formation offset is set in main script
	else: #aggro to player if have line of sight
		ray.set_target_position(to_local(target_location))
		ray.force_raycast_update()
		if(ray.get_collider() == player):
			aggro = true 
