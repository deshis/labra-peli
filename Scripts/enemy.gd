extends CharacterBody3D

@export var WALK_SPEED = 2.5
@export var RUN_SPEED = 5
var current_speed

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
var close_to_player = false

@onready var skeleton = $enemy_guy/DRV_Armature/Skeleton3D
@onready var ragdoll_skeleton = $enemy_ragdoll/DRV_Armature/Skeleton3D
@onready var animation_tree = $enemy_guy/AnimationTree
@onready var default_material = preload("res://Materials/default.tres")

@onready var attack_timer = $AttackTimer
@export var attack_cooldown_min = 1.25
@export var attack_cooldown_max = 2.5
@export var attack_range = 2.5
var can_attack = true
var rng = RandomNumberGenerator.new()

signal enemyDied(guy)

var hitbox = preload("res://Scenes/EnemyHitBox.tscn")
@export var attack_damage = 10
@export var attack_knockback_strength = 10


@onready var collider = $CollisionShape3D
@onready var hurtbox = $HurtBox/CollisionShape3D
var collider_offset=0.65


func _ready():
	update_health_bar()
	skeleton.get_node("Guy").set_surface_override_material(0, default_material)
	$enemy_ragdoll.visible = false

func _physics_process(delta):
	#sync colliders with animation
	if(collider!=null and hurtbox!=null):
		collider.global_position = skeleton.get_node("ColliderAttachment").global_position
		collider.position.y=collider_offset
		hurtbox.global_position = skeleton.get_node("ColliderAttachment").global_position
		hurtbox.position.y=collider_offset
	
	
	var next_location 
	var current_location
	var new_velocity
	
	if(abs(global_position - player.global_position).length()<5): #if close to player
		close_to_player = true
		if(!can_attack):
			current_speed = 0
		else:
			current_speed = WALK_SPEED
	else:
		close_to_player = false
		current_speed = RUN_SPEED
	
	if aggro and not dead:
		#calculate path towards player
		next_location = nav.get_next_path_position()
		current_location = global_transform.origin
		new_velocity = (next_location - current_location).normalized() * current_speed
		nav.set_velocity(new_velocity)
		
		if(close_to_player or new_velocity.length()<0.001): #look at player and strafe
			skeleton.look_at(player.global_position)
			ragdoll_skeleton.look_at(player.global_position)
			animation_tree.set("parameters/isStrafe/blend_amount", 1.0)
			animation_tree.set("parameters/strafe/blend_position", velocity)
		else: #else look at navigation path direction and run
			skeleton.look_at(to_global(new_velocity), Vector3.UP)
			ragdoll_skeleton.look_at(to_global(new_velocity), Vector3.UP)
			animation_tree.set("parameters/isStrafe/blend_amount", 0.0)
			animation_tree.set("parameters/idle-run/blend_position", velocity.length() / current_speed)
		skeleton.rotate_object_local(Vector3.UP, PI)
		ragdoll_skeleton.rotate_object_local(Vector3.UP, PI)
		skeleton.rotation.x = 0
		skeleton.rotation.z = 0
		ragdoll_skeleton.rotation.x = 0
		ragdoll_skeleton.rotation.z = 0
		
		if(abs(global_position - player.global_position).length()<attack_range and can_attack):
			attack()
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
			get_tree().current_scene._on_main_enemy_switch_timer_timeout() #force main enemy to switch when new enemy aggros

func update_health_bar(): #call this when take dmg
	health_bar.value = health

func die():
	aggro = false 
	dead = true
	remove_from_group("enemies")
	get_tree().current_scene._on_main_enemy_switch_timer_timeout() #force main enemy to switch when enemy dies
	$enemy_guy.visible=false
	$enemy_ragdoll.visible = true
	ragdoll_skeleton.physical_bones_start_simulation()
	
	#add random impulse to make ragdoll more interesting
	var random_direction = Vector3(rng.randf_range(-1,1), rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized()
	ragdoll_skeleton.get_node("Physical Bone Hip").apply_central_impulse(random_direction*20)
	dead = true
	
	enemyDied.emit(self)
	
	#remove everything except ragdoll
	var children = get_children()
	children.erase($enemy_ragdoll)
	for node in children:
		node.queue_free()

func take_damage(dmg):
	health-=dmg
	update_health_bar()
	if(health <=0 and not dead):
		die()

func attack():
	if(can_attack):
		can_attack = false
		var combo = false
		
		#33% chance to do combo attack
		if(rng.randf_range(0,1)<0.33):
			combo=true
		if(combo):
			attack_timer.start(0.1)
		else:
			attack_timer.start(rng.randf_range(attack_cooldown_min, attack_cooldown_max))
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
		#prevent multiple hitboxes from spawning
		if(hand.get_children().size()>0):
			for child in hand.get_children():
				child.queue_free()
		var punch_hitbox = hitbox.instantiate()
		punch_hitbox.damage = attack_damage
		punch_hitbox.knockback_strength = attack_knockback_strength
		hand.add_child(punch_hitbox)
		#hitbox gets deleted in animationtree signal

func _on_hurt_box_area_entered(area): #only PlayerHitBox should trigger this
	if area.get_groups().has("player_hitbox"):
		take_damage(area.damage)
		#set flincher
		animation_tree.set("parameters/Flinch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#knockback
		var dir = global_position - area.get_parent().get_parent().global_position
		dir.y=0
		velocity += dir*area.knockback_strength
		move_and_slide()
		area.queue_free()

func _on_attack_timer_timeout():
	can_attack = true

func animation_finished(anim_name):
	match anim_name:
		"attack_l1":
			for child in skeleton.get_node("LeftHandAttachment").get_children():
				child.queue_free()
		"attack_l2":
			for child in skeleton.get_node("RightHandAttachment").get_children():
				child.queue_free()
