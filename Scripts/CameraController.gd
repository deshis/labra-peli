class_name CameraController

extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var player: BoneAttachment3D = get_parent().get_node("guy/DRV_Armature/Skeleton3D/CameraAttachment")
@onready var ray: RayCast3D = $LockOnRayCast

var camera_mouse_sensitivity: float
var camera_controller_sensitivity: float

var twist_input := 0.0
var pitch_input := 0.0

var camera_locked_on := false
var lock_on_targets: Array[Enemy]
var camera_target_index := -1

var enemy: Enemy

@onready var highlight_material := preload("res://Materials/highlighted.tres")
@onready var default_material := preload("res://Materials/default.tres")

var lock_on_change_angle_threshold := 0.0
var lock_on_change_angle_max := 180.0

var current_target: Node3D

var enemy_material_node_path := "enemy_guy/DRV_Armature/Skeleton3D/Guy"

enum Direction {LEFT, RIGHT} 

func _ready()->void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	camera_mouse_sensitivity = config.get_value("Controls", "mouse_sensitivity")
	camera_controller_sensitivity = config.get_value("Controls", "controller_sensitivity")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Input.set_use_accumulated_input(false)
	
	for group_enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		group_enemy.enemyDied.connect(_on_enemy_death)

func _physics_process(_delta: float)->void:
	#camera follows player with lerp smoothing
	position = lerp(position, player.global_position, 0.15)
	
	if Input.is_action_just_pressed("camera_lock_on"):
		
		#reset camera to prevent weird behaviour
		reset_camera_direction()
		
		if not camera_locked_on:
			camera_locked_on = true
			lock_on_targets.assign(get_tree().get_nodes_in_group("enemies"))
			select_closest_enemy_to_camera_center()
			
			#highlight the locked on enemy
			if(camera_target_index > -1):
				highlight_enemy()
			else: #lock on failed.
				reset_lock_on()
		else:
			#unhighlight deselected enemy
			unhighlight_enemy()
			reset_lock_on()
	
	if camera_locked_on and lock_on_targets.size()>0:
		#same as finding closest to camera center, except only on one side
		if Input.is_action_just_pressed("camera_switch_target_left"):
			unhighlight_enemy()
			switch_lock_on_target(Direction.LEFT)
			highlight_enemy()
		
		if Input.is_action_just_pressed("camera_switch_target_right"):
			unhighlight_enemy()
			switch_lock_on_target(Direction.RIGHT)
			highlight_enemy()
		
		if Input.is_action_just_pressed("camera_switch_target_closest"):
			unhighlight_enemy()
			select_closest_enemy_to_player()
			highlight_enemy()
		
		#lock the camera onto selected enemy. 
		if camera_target_index>-1:
			current_target = lock_on_targets[camera_target_index]
			
			#smooth camera movement while locked on. look_at cannot be lerped directly so we have to use quaternions...
			var current_horizontal_rotation := global_transform.basis.get_rotation_quaternion()
			look_at(current_target.position)
			var target_horizontal_rotation := global_transform.basis.get_rotation_quaternion()
			rotation = current_horizontal_rotation.slerp(target_horizontal_rotation, 0.15).get_euler()
			
			rotation.z = 0 #z rotation is weird
			rotation.x = 0 #x rotation is handled by spring_arm
			
			spring_arm.look_at(current_target.position)
			spring_arm.rotation.y = 0
			spring_arm.rotation.z = 0
			spring_arm.rotation.x += deg_to_rad(-25) #aim camera a bit down so you can see the enemy better
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(50)) #prevent upside down camera
		
	else:
		camera_locked_on = false
		#moving camera with controller. mouse input is handled in _unhandled_input
		var look_dir := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if(look_dir):
			twist_input = - look_dir.x * camera_controller_sensitivity
			pitch_input = - look_dir.y * camera_controller_sensitivity
		
		#camera rotation
		rotate_y(twist_input)	
		spring_arm.rotate_x(pitch_input)
		
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(50))
		twist_input = 0.0
		pitch_input = 0.0


func _unhandled_input(event: InputEvent)->void:
	#moving camera with mouse
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var mouse_movement_event := event as InputEventMouseMotion
			twist_input = - mouse_movement_event.relative.x * camera_mouse_sensitivity
			pitch_input = - mouse_movement_event.relative.y * camera_mouse_sensitivity


func select_closest_enemy_to_camera_center()->void:
	#1. draw a line forward from the camera
	#2. draw a vector from player to every enemy
	#3. figure out which enemy has the smallest angle
	#4. check if enemy is visible with raycast and lock onto it.
	var smallest_angle_left := lock_on_change_angle_max
	var smallest_angle_right := -lock_on_change_angle_max
	var closest_to_right_index:int
	var closest_to_left_index:int
	var look_dir := -basis.z.normalized()
	for i in range(lock_on_targets.size()):
		enemy = lock_on_targets[i]
		var enemy_dir := enemy.global_position - player.global_position
		var angle_to_enemy := rad_to_deg(look_dir.signed_angle_to(enemy_dir, Vector3i.UP))
		if(!enemy.dead):
			if(!is_wall_in_way(enemy)):
				if(angle_to_enemy<=smallest_angle_left and angle_to_enemy>=0):
					smallest_angle_left = angle_to_enemy
					closest_to_left_index=i
				elif(angle_to_enemy>=smallest_angle_right and angle_to_enemy<=0):
					smallest_angle_right = angle_to_enemy
					closest_to_right_index=i
	
	if(abs(smallest_angle_left)<abs(smallest_angle_right)):
		camera_target_index = closest_to_left_index
	elif(abs(smallest_angle_right)<abs(smallest_angle_left)):
		camera_target_index = closest_to_right_index
	else: #lock on failed
		camera_target_index = -1


func switch_lock_on_target(dir:Direction)->void: 
	#same logic as select_closest_enemy_to_camera_center, except only on one side
	match dir:
		Direction.LEFT:
			var next_to_left_index := -1
			var smallest_angle := lock_on_change_angle_max
			var current_enemy_dir := current_target.global_position - player.global_position
			for i in range(lock_on_targets.size()):
				enemy = lock_on_targets[i]
				var enemy_dir := enemy.global_position - player.global_position
				var angle_to_enemy := rad_to_deg(current_enemy_dir.signed_angle_to(enemy_dir, Vector3i.UP))
				if(!enemy.dead):
					if(!is_wall_in_way(enemy)):
						if(angle_to_enemy >= lock_on_change_angle_threshold): #only check ones to the left. ones to right are negative
							if(angle_to_enemy <= smallest_angle):
								if(i != camera_target_index):
									smallest_angle = angle_to_enemy
									next_to_left_index = i
			if(next_to_left_index > -1):
				camera_target_index = next_to_left_index
			
		Direction.RIGHT:
			var next_to_right_index := -1
			var smallest_angle := -lock_on_change_angle_max
			var current_enemy_dir := current_target.global_position - player.global_position
			for i in range(lock_on_targets.size()):
				enemy = lock_on_targets[i]
				var enemy_dir := enemy.global_position - player.global_position
				var angle_to_enemy := rad_to_deg(current_enemy_dir.signed_angle_to(enemy_dir, Vector3i.UP))
				if(!enemy.dead):
					if(!is_wall_in_way(enemy)):
						if(angle_to_enemy <= lock_on_change_angle_threshold):
							if(angle_to_enemy >= smallest_angle):
								if(i != camera_target_index):
									smallest_angle = angle_to_enemy
									next_to_right_index = i
			if(next_to_right_index > -1):
				camera_target_index = next_to_right_index


func select_closest_enemy_to_player()->void:
	camera_target_index = 0
	for i in range(lock_on_targets.size()):
		if lock_on_targets[i].global_position.distance_to(global_position) < lock_on_targets[camera_target_index].global_position.distance_to(global_position):
			camera_target_index = i


func highlight_enemy()->void:
	if camera_target_index > -1:
		if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)!=null):
			(lock_on_targets[camera_target_index].get_node(enemy_material_node_path) as MeshInstance3D).set_surface_override_material(0, highlight_material)


func unhighlight_enemy()->void:
	if camera_target_index > -1:
		if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)!=null):
			(lock_on_targets[camera_target_index].get_node(enemy_material_node_path) as MeshInstance3D).set_surface_override_material(0, default_material)


func reset_camera_direction() -> void:
	spring_arm.rotation.x = 0
	spring_arm.rotation.y = 0
	spring_arm.rotation.z = 0
	rotation.x = 0
	rotation.z = 0	


func reset_lock_on()->void:
	lock_on_targets = []
	camera_target_index = -1
	camera_locked_on = false
	current_target = null


func _on_enemy_death(guy: CharacterBody3D)->void:
	if(camera_locked_on):
		if (guy == lock_on_targets[camera_target_index]):
			unhighlight_enemy()
			spring_arm.rotation.x = 0
			spring_arm.rotation.y = 0
			spring_arm.rotation.z = 0
			rotation.x = 0
			rotation.z = 0
			camera_locked_on = false
			Input.action_press("camera_lock_on")
			Input.action_release("camera_lock_on")


func is_wall_in_way(target:CharacterBody3D)->bool:
	ray.set_target_position(to_local(target.position))
	ray.force_raycast_update()
	
	var objects_collide: Array[CollisionObject3D] = [] #The colliding objects go here.
	while ray.is_colliding():
		var obj: CollisionObject3D = ray.get_collider() #get the next object that is colliding.
		objects_collide.append(obj) #add it to the array.
		ray.add_exception(obj) #add to ray's exception. That way it could detect something being behind it.
		ray.force_raycast_update() #update the ray's collision query.
	var collided_with_wall := false
	for obj in objects_collide:
		if(obj.get_class()=="StaticBody3D"):
			collided_with_wall=true
		ray.remove_exception(obj)
		
	return collided_with_wall
