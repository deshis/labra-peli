extends CharacterBody3D

@export var SPEED = 5.0

@onready var player = get_node('/root/Main/Player')
@onready var nav = $NavigationAgent3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var aggro = false

var formation_offset = Vector3.ZERO

@onready var ray = $PlayerDetectionRayCast

@export var max_health = 100
var health = max_health
@onready var health_bar = $HealthBar/SubViewport/TextureProgressBar

var dead = false

func _ready():
	update_health_bar()

func _physics_process(delta):
	var next_location 
	var current_location
	var new_velocity
	
	if aggro and not dead:
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
	if not dead:
		velocity.x = velocity.move_toward(safe_velocity,0.5).x
		velocity.z = velocity.move_toward(safe_velocity,0.5).z
		#dont set velocity.y because it screws up gravity...
		move_and_slide()

#called in main script of game scene
func update_target_location(target_location):
	if aggro:
		nav.set_target_position(target_location+formation_offset) #formation offset is set in main script
	elif not dead: #aggro to player if have line of sight
		ray.set_target_position(to_local(target_location))
		ray.force_raycast_update()
		if(ray.get_collider() == player):
			aggro = true 

func update_health_bar(): #call this when take dmg
	health_bar.value = health

func die():
	aggro = false 
	dead = true

func take_damage(dmg):
	health-=dmg
	update_health_bar()
	if(health <=0):
		die()

func _on_hurt_box_area_entered(area): #only PlayerHitBox should trigger this
	if area.get_groups().has("player_hitbox"):
		take_damage(area.damage)

