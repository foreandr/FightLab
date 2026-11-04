extends RefCounted
## Shared charge pose: interpolate existing standing/crouching animation assets.
static func apply(actor:Node)->bool:
	if actor.mode!="takeoff" or not actor.motion_jump_variable:return false
	var rig_pose=preload("res://scripts/editor_rig_pose.gd")
	var pose=preload("res://scripts/spell_cast_motion.gd")
	var old_clip:String=actor.clip
	rig_pose.idle(actor,0.0)
	var standing:Array[Transform3D]=pose.capture(actor)
	rig_pose.sample(actor,"ual1/Crouch_Idle",0.0)
	pose.blend_from(actor,standing,smoothstep(0.0,1.0,actor.motion_jump_fraction))
	var lean:Vector2=actor.get_meta("jump_charge_lean",Vector2.ZERO)
	var aim=preload("res://scripts/character_aim_pose.gd")
	aim.rotate_bone(actor,"spine_01",actor.global_basis.x,deg_to_rad(6.0)*lean.y)
	aim.rotate_bone(actor,"spine_01",actor.global_basis.z,-deg_to_rad(5.0)*lean.x)
	actor.skeleton.force_update_all_bone_transforms()
	actor.clip=old_clip
	return true
