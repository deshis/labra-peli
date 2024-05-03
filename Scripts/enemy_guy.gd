extends Node3D

@onready var enemy: Enemy = get_parent() as Enemy
@onready var skeleton:Skeleton3D = $DRV_Armature/Skeleton3D

func _on_animation_tree_animation_finished(anim_name: String)->void:
	match anim_name:
		"attack_l2_stop":
			var offset := skeleton.get_bone_pose_position(skeleton.find_bone("ROOT_CTRL")).z
			enemy.translate(Vector3(0, 0, offset).rotated(Vector3.UP, skeleton.rotation.y))
	
	enemy.animation_finished(anim_name)

func _on_animation_tree_animation_started(anim_name:String)->void:
	enemy.animation_started(anim_name)
