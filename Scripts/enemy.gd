class_name Enemy

extends CharacterBody3D

@export var WALK_SPEED := 2.5
@export var RUN_SPEED := 5.0
var current_speed: float

@onready var player: CharacterBody3D = get_node('/root/Main/Player')
@onready var nav: NavigationAgent3D = $NavigationAgent3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var aggro := false

var formation_offset := Vector3.ZERO

@onready var ray: RayCast3D = $PlayerDetectionRayCast

@export var max_health := 100.0
var health := max_health
@onready var health_bar: TextureProgressBar = $HealthBar/SubViewport/TextureProgressBar

var dead := false
var close_to_player := false

@onready var skeleton: Skeleton3D = $enemy_guy/DRV_Armature/Skeleton3D
@onready var ragdoll_skeleton: Skeleton3D = $enemy_ragdoll/DRV_Armature/Skeleton3D
@onready var animation_tree: AnimationTree = $enemy_guy/AnimationTree
@onready var default_material := preload("res://Materials/default.tres")

@onready var attack_timer: Timer = $AttackTimer
@export var attack_cooldown_min := 1.25
@export var attack_cooldown_max := 2.5
@export var attack_range := 2.5
var can_attack := true
var can_combo := false
var rng := RandomNumberGenerator.new()

signal enemyDied(guy: Enemy)

var hitbox := preload("res://Scenes/EnemyHitBox.tscn")
@export var attack_damage := 10
@export var attack_knockback_strength := 10

@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var hurtbox: CollisionShape3D = $HurtBox/CollisionShape3D
var collider_offset := 0.65

@onready var footsteps_player: AudioStreamPlayer3D = $FootstepsPlayer
var footstep_sounds: Array[AudioStream] = []
@onready var punch_player:AudioStreamPlayer3D = $PunchPlayer
var punch_sounds: Array[AudioStream] = []
@onready var hit_player:AudioStreamPlayer3D = $HitPlayer
var hit_sounds: Array[AudioStream] = []
var sfx_dir := "res://Assets/Audio/SFX"

@onready var enemy_ragdoll: Node3D = $enemy_ragdoll
@onready var enemy_guy: Node3D = $enemy_guy

@onready var current_scene: Main = get_tree().current_scene

func _ready() -> void:
	update_health_bar()
	var skeleton_surface:MeshInstance3D = skeleton.get_node("Guy")
	skeleton_surface.set_surface_override_material(0, default_material)
	enemy_ragdoll.visible = false
	#disable ragdoll collision while alive
	for node in ragdoll_skeleton.get_children():
		if node is PhysicalBone3D:
			var bone := node as PhysicalBone3D
			bone.collision_layer = 0
			bone.collision_mask = 0
			
	#create audio arrays
	for file in DirAccess.open(sfx_dir+"/footsteps").get_files():
		if file.reverse().left(4) =="3pm.":
			footstep_sounds.append(load(sfx_dir+"/footsteps/"+file))
	for file in DirAccess.open(sfx_dir+"/swing").get_files():
		if file.reverse().left(4) =="3pm.":
			punch_sounds.append(load(sfx_dir+"/swing/"+file))
	for file in DirAccess.open(sfx_dir+"/hit").get_files():
		if file.reverse().left(4) =="3pm.":
			hit_sounds.append(load(sfx_dir+"/hit/"+file))

func _physics_process(delta: float)->void:
	#sync colliders with animation
	if(collider!=null and hurtbox!=null):
		var attachment:BoneAttachment3D = skeleton.get_node("ColliderAttachment")
		collider.global_position = attachment.global_position
		collider.position.y=collider_offset
		hurtbox.global_position = attachment.global_position
		hurtbox.position.y=collider_offset
	
	
	var next_location: Vector3
	var current_location: Vector3
	var new_velocity: Vector3
	
	if((global_position - player.global_position).abs().length()<5): #if close to player
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
			animation_tree.set("parameters/strafe/blend_position", Vector2((next_location - current_location).normalized().rotated(Vector3.UP, skeleton.rotation.y).x, (next_location - current_location).normalized().rotated(Vector3.UP, skeleton.rotation.y).z))
		else: #else look at navigation path direction and run
			skeleton.look_at(to_global(new_velocity), Vector3.UP)
			ragdoll_skeleton.look_at(to_global(new_velocity), Vector3.UP)
			animation_tree.set("parameters/isStrafe/blend_amount", 0.0)
			animation_tree.set("parameters/idle-run/blend_position", (current_speed != 0 if 0.5 else 0))
		skeleton.rotate_object_local(Vector3.UP, PI)
		ragdoll_skeleton.rotate_object_local(Vector3.UP, PI)
		skeleton.rotation.x = 0
		skeleton.rotation.z = 0
		ragdoll_skeleton.rotation.x = 0
		ragdoll_skeleton.rotation.z = 0
		
		if((global_position - player.global_position).abs().length()<attack_range and can_attack):
			if(rng.randf_range(0,1)<0.5):
				attack()
			else:
				heavy_attack()
		elif((global_position - player.global_position).abs().length()<attack_range and can_combo):
			can_combo = false
			match (animation_tree.get("parameters/AttackState/playback") as AnimationNodeStateMachinePlayback).get_current_node():
				"l1":
					if(rng.randf_range(0,1)<0.5):
						attack()
					else:
						heavy_attack()
				"l2":
					if(rng.randf_range(0,1)<0.5):
						heavy_attack()
		
	else:
		velocity.x = 0
		velocity.z = 0
	
	#gravity
	if not is_on_floor():
		velocity.y -= gravity*delta

#calculating safe velocity for avoidance to prevent enemies clumping together
func _on_navigation_agent_3d_velocity_computed(safe_velocity:Vector3)->void:
	if not dead:
		velocity.x = velocity.move_toward(safe_velocity,0.5).x
		velocity.z = velocity.move_toward(safe_velocity,0.5).z
		#dont set velocity.y because it screws up gravity...
		move_and_slide()

#called in main script of game scene
func update_target_location(target_location:Vector3)->void:
	if aggro:
		nav.set_target_position(target_location+formation_offset) #formation offset is set in main script
	elif not dead: #aggro to player if have line of sight
		ray.set_target_position(to_local(target_location))
		ray.force_raycast_update()
		if(ray.get_collider() == player):
			aggro = true 
			(get_tree().current_scene as Main)._on_main_enemy_switch_timer_timeout() #force main enemy to switch when new enemy aggros

func update_health_bar()->void: #call this when take dmg
	health_bar.value = health

func die()->void:
	aggro = false 
	dead = true
	remove_from_group("enemies")
	current_scene._on_main_enemy_switch_timer_timeout() #force main enemy to switch when enemy dies
	enemy_guy.visible=false
	enemy_ragdoll.visible = true
	
	#re-enabe ragdoll collision
	for node in ragdoll_skeleton.get_children():
		if node is PhysicalBone3D:
			var bone := node as PhysicalBone3D
			bone.collision_layer = 128
			bone.collision_mask = 129
	
	ragdoll_skeleton.physical_bones_start_simulation()
	
	#add random impulse to make ragdoll more interesting
	var random_direction := Vector3(rng.randf_range(-1,1), rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized()
	(ragdoll_skeleton.get_node("Physical Bone Hip") as PhysicalBone3D).apply_central_impulse(random_direction*20)
	dead = true
	
	enemyDied.emit(self)
	
	#remove everything except ragdoll and hitplaye
	var children := get_children()
	children.erase($enemy_ragdoll)
	children.erase($HitPlayer)
	for node in children:
		node.queue_free()

func take_damage(dmg:float)->void:
	health-=dmg
	update_health_bar()
	if(health <=0 and not dead):
		die()

func attack()->void:
	var hand: BoneAttachment3D
	can_combo = false
	if can_attack:
		hand = skeleton.get_node("LeftHandAttachment")
		animation_tree.set("parameters/AttackState/conditions/light", true)
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
		can_attack = false
	else:
		match (animation_tree.get("parameters/AttackState/playback") as AnimationNodeStateMachinePlayback).get_current_node():
			"l1":
				animation_tree.set("parameters/AttackState/conditions/light", true)
				hand = skeleton.get_node("RightHandAttachment")
	#prevent multiple hitboxes from spawning
	if(hand != null):
		if(hand.get_children().size()>0):
			for child in hand.get_children():
				child.queue_free()
		var punch_hitbox: HitBox = hitbox.instantiate()
		punch_hitbox.damage = attack_damage
		punch_hitbox.knockback_strength = attack_knockback_strength
		hand.add_child(punch_hitbox)
		#hitbox gets deleted in animationtree signal

func heavy_attack()->void:
	var foot: BoneAttachment3D
	can_combo = false	
	if can_attack:
		animation_tree.set("parameters/AttackState/conditions/heavy", true)
		foot = skeleton.get_node("RightFootAttachment")
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)	
		can_attack = false
	else:
		match (animation_tree.get("parameters/AttackState/playback") as AnimationNodeStateMachinePlayback).get_current_node():
			"l1":
				animation_tree.set("parameters/AttackState/conditions/heavy", true)
				foot = skeleton.get_node("RightFootAttachment")
			"l2":
				animation_tree.set("parameters/AttackState/conditions/heavy", true)
				foot = skeleton.get_node("LeftFootAttachment")
	
	#prevent multiple hitboxes from spawning
	if(foot != null):
		if(foot.get_children().size()>0):
			for child in foot.get_children():
				child.queue_free()
		var punch_hitbox:HitBox = hitbox.instantiate()
		punch_hitbox.damage = attack_damage
		punch_hitbox.knockback_strength = attack_knockback_strength
		foot.add_child(punch_hitbox)

func _on_hurt_box_area_entered(area:HitBox)->void: #only PlayerHitBox should trigger this
	if area.get_groups().has("player_hitbox"):
		hit_player.set_stream(hit_sounds[rng.randi_range(0, hit_sounds.size()-1)])
		hit_player.play()
		
		take_damage(area.damage)
		#set flincher
		animation_tree.set("parameters/Flinch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#knockback
		var dir := global_position - (area.get_parent().get_parent() as Node3D).global_position
		dir.y=0
		velocity = dir.normalized()*area.knockback_strength
		move_and_slide()
		area.queue_free()

func _on_attack_timer_timeout()->void:
	can_attack = true

func animation_finished(anim_name:String)->void:
	if "attack_" in anim_name:
		if "_stop" in anim_name:
			attack_timer.start(rng.randf_range(attack_cooldown_min, attack_cooldown_max))
			animation_tree.set("parameters/AttackState/conditions/stop", false)
		else:
			if !animation_tree.get("parameters/AttackState/conditions/light") and !animation_tree.get("parameters/AttackState/conditions/heavy"):
				animation_tree.set("parameters/AttackState/conditions/stop", true)
				can_combo = false
				
			for child in skeleton.get_node("LeftHandAttachment").get_children():
				child.queue_free()
			for child in skeleton.get_node("RightHandAttachment").get_children():
				child.queue_free()
			for child in skeleton.get_node("LeftFootAttachment").get_children():
				child.queue_free()
			for child in skeleton.get_node("RightFootAttachment").get_children():
				child.queue_free()


func play_footsteps()->void:
	footsteps_player.set_stream(footstep_sounds[rng.randi_range(0, footstep_sounds.size()-1)])
	footsteps_player.play()


func animation_started(anim_name:String)->void:
	if "attack_" in anim_name:
		animation_tree.set("parameters/AttackState/conditions/light", false)
		animation_tree.set("parameters/AttackState/conditions/heavy", false)
		if "_stop" not in anim_name:
			punch_player.set_stream(punch_sounds[rng.randi_range(0, punch_sounds.size()-1)])
			punch_player.play()
			if (rng.randf_range(0,1)<0.5):
				can_combo = true
