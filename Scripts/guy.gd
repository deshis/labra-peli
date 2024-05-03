extends Node3D

@onready var player: Player = get_parent() as Player
@onready var skeleton:Skeleton3D = $DRV_Armature/Skeleton3D

func _on_animation_tree_animation_finished(anim_name:String)->void:
	if "_stop" in anim_name:
			var offset := skeleton.get_bone_pose_position(skeleton.find_bone("ROOT_CTRL")).z
			player.translate(Vector3(0, 0, offset).rotated(Vector3.UP, skeleton.rotation.y))
	
	player.animation_finished(anim_name)


func _on_animation_tree_animation_started(anim_name:String)->void:
	player.animation_started(anim_name)

