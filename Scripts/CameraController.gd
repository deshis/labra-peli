extends Node3D

@onready var spring_arm = $SpringArm3D
@onready var player = get_parent()
@onready var ray = $LockOnRayCast

var camera_mouse_sensitivity
var camera_controller_sensitivity

var twist_input = 0.0
var pitch_input = 0.0

var camera_locked_on = false
var lock_on_targets = null
var camera_target_index = 0

var enemy

@onready var highlight_material = preload("res://Materials/highlighted.tres")
@onready var default_material = preload("res://Materials/default.tres")

var lock_on_change_angle_threshold = 0.0
var lock_on_change_angle_max = 180

var current_target

var enemy_material_node_path = "guy/DRV_Armature/Skeleton3D/Guy"



func _ready():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	camera_mouse_sensitivity = config.get_value("Controls", "mouse_sensitivity")
	camera_controller_sensitivity = config.get_value("Controls", "controller_sensitivity")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Input.set_use_accumulated_input(false)
	
	for group_enemy in get_tree().get_nodes_in_group("enemies"):
		group_enemy.enemyDied.connect(_on_enemy_death)

func _physics_process(_delta):
	#camera follows player with lerp smoothing
	position = lerp(position, player.position, 0.15)
	
	if Input.is_action_just_pressed("camera_lock_on"):
		#reset camera to prevent weird behaviour
		spring_arm.rotation.x = 0
		spring_arm.rotation.y = 0
		spring_arm.rotation.z = 0
		rotation.x = 0
		rotation.z = 0
		
		if(!camera_locked_on):
			lock_on_targets = get_tree().get_nodes_in_group("enemies")
			camera_locked_on = true
			
			#find closest target to camera center.
			#1. draw a line forward from the camera
			#2. calculate the point on the line closest to the enemys location
			#3. use the difference vector from point to enemy to calculate angle from camera to enemy
			#4. figure out which enemy has the smallest angle
			#5. check if enemy is visible with raycast and lock onto it.
			var smallest_angle_left = lock_on_change_angle_max
			var smallest_angle_right = -lock_on_change_angle_max
			var closest_to_right_index
			var closest_to_left_index
			var look_dir = -basis.z.normalized()
			for i in range(lock_on_targets.size()):
				enemy = lock_on_targets[i]
				var closest_point = Geometry3D.get_closest_point_to_segment_uncapped(enemy.position, player.position, look_dir)
				var difference = enemy.position-closest_point
				var angle_to_enemy = rad_to_deg(look_dir.signed_angle_to(difference, Vector3i.UP))
				if(!enemy.dead):
					if(!is_wall_in_way(enemy)):
						if(angle_to_enemy<=smallest_angle_left and angle_to_enemy>=0):
							smallest_angle_left = angle_to_enemy
							closest_to_left_index=i
						elif(angle_to_enemy>=smallest_angle_right and angle_to_enemy<=0):
							smallest_angle_right = angle_to_enemy
							closest_to_right_index=i
					else: #raycast does not find enemy, dont lock on
						camera_target_index = null
			
			if(abs(smallest_angle_left)<=abs(smallest_angle_right)):
				camera_target_index = closest_to_left_index
			elif(abs(smallest_angle_right)<=abs(smallest_angle_left)):
				camera_target_index = closest_to_right_index
			
			#highlight the locked on enemy
			if(camera_target_index != null):
				if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
					lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, highlight_material)
			else: #lock on failed.
				lock_on_targets = null
				camera_target_index = null
				camera_locked_on = false
		
		else:
			#unhighlight deselected enemy
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, default_material)
			lock_on_targets = null
			camera_target_index = null
			camera_locked_on = false
	
	if(camera_locked_on and lock_on_targets):
		#same as finding closest to camera center, except only on one side
		if Input.is_action_just_pressed("camera_switch_target_left"):
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, default_material)
			var next_to_left_index
			var smallest_angle = lock_on_change_angle_max
			var look_dir = -basis.z.normalized()
			for i in range(lock_on_targets.size()):
				enemy = lock_on_targets[i]
				var closest_point = Geometry3D.get_closest_point_to_segment_uncapped(enemy.position, player.position, look_dir)
				var difference = enemy.position-closest_point
				var angle_to_enemy = rad_to_deg(look_dir.signed_angle_to(difference, Vector3i.UP))
				if(!enemy.dead):
					if(!is_wall_in_way(enemy)):
						if(angle_to_enemy>=lock_on_change_angle_threshold): #only check ones to the left. ones to right are negative
							if(angle_to_enemy<=smallest_angle):
								if(i!=camera_target_index):
									smallest_angle = angle_to_enemy
									next_to_left_index=i
			if(next_to_left_index!=null):
				camera_target_index = next_to_left_index
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, highlight_material)
		
		#same as left...
		if Input.is_action_just_pressed("camera_switch_target_right"):
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, default_material)
			var next_to_right_index
			var smallest_angle = -lock_on_change_angle_max
			var look_dir = -basis.z.normalized()
			for i in range(lock_on_targets.size()):
				enemy = lock_on_targets[i]
				var closest_point = Geometry3D.get_closest_point_to_segment_uncapped(enemy.position, player.position, look_dir)
				var difference = enemy.position-closest_point
				var angle_to_enemy = rad_to_deg(look_dir.signed_angle_to(difference, Vector3i.UP))
				if(!enemy.dead):
					if(!is_wall_in_way(enemy)):
						if(angle_to_enemy<=lock_on_change_angle_threshold):
							if(angle_to_enemy>=smallest_angle):
								if(i!=camera_target_index):
									smallest_angle = angle_to_enemy
									next_to_right_index=i
			if(next_to_right_index!=null):
				camera_target_index = next_to_right_index
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, highlight_material)
		
		if Input.is_action_just_pressed("camera_switch_target_closest"):
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, default_material)
			#find closest to player
			camera_target_index = 0
			for i in range(lock_on_targets.size()):
				if lock_on_targets[i].global_position.distance_to(global_position) < lock_on_targets[camera_target_index].global_position.distance_to(global_position):
					camera_target_index = i
			if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
				lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, highlight_material)
		
		current_target = lock_on_targets[camera_target_index]
		#lock on camera. lerping breaks the lock on system so we have to use a stiff camera...
		look_at(current_target.position, Vector3.UP)
		
		rotation.x=0 #x rotation is handled by spring_arm
		spring_arm.look_at(current_target.position)
		spring_arm.rotation.x += deg_to_rad(-25) #aim camera a bit down so you can see the enemy better
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(50)) #prevent upside down camera
		
	else:
		#moving camera with controller. mouse input is handled in _unhandled_input
		var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if(look_dir):
			twist_input = - look_dir.x * camera_controller_sensitivity
			pitch_input = - look_dir.y * camera_controller_sensitivity
		
		#camera rotation
		rotate_y(twist_input)	
		spring_arm.rotate_x(pitch_input)
		
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(50))
		twist_input = 0.0
		pitch_input = 0.0

func _unhandled_input(event):
	#moving camera with mouse
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * camera_mouse_sensitivity
			pitch_input = - event.relative.y * camera_mouse_sensitivity

func _on_enemy_death(guy):
	if (guy == lock_on_targets[camera_target_index]):
		if(lock_on_targets[camera_target_index].get_node(enemy_material_node_path)):
			lock_on_targets[camera_target_index].get_node(enemy_material_node_path).set_surface_override_material(0, default_material)
		spring_arm.rotation.x = 0
		spring_arm.rotation.y = 0
		spring_arm.rotation.z = 0
		rotation.x = 0
		rotation.z = 0
		camera_locked_on = false
		Input.action_press("camera_lock_on")


func is_wall_in_way(target):
	ray.set_target_position(to_local(target.position))
	ray.force_raycast_update()
	
	var objects_collide = [] #The colliding objects go here.
	while ray.is_colliding():
		var obj = ray.get_collider() #get the next object that is colliding.
		objects_collide.append( obj ) #add it to the array.
		ray.add_exception( obj ) #add to ray's exception. That way it could detect something being behind it.
		ray.force_raycast_update() #update the ray's collision query.
	var collided_with_wall = false
	for obj in objects_collide:
		if(obj.get_class()=="StaticBody3D"):
			collided_with_wall=true
		ray.remove_exception(obj)
		
	return collided_with_wall
