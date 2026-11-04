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
	actor.clip=old_clip
	return true
