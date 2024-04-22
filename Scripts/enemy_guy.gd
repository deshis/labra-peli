extends Node3D


func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"attack_l2_stop":
			var offset =  $DRV_Armature/Skeleton3D.get_bone_pose_position($DRV_Armature/Skeleton3D.find_bone("ROOT_CTRL")).z
			get_parent().translate(Vector3(0, 0, offset).rotated(Vector3.UP, $DRV_Armature/Skeleton3D.rotation.y))
	
	get_parent().animation_finished(anim_name)

func _on_animation_tree_animation_started(anim_name):
	get_parent().animation_started(anim_name)
