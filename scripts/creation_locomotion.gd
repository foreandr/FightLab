extends RefCounted
## Shared eight-way movement poses for Create and its playtest controller.
const Movement=preload("res://scripts/character_movement.gd")
const CastPose=preload("res://scripts/spell_cast_motion.gd")

static func axes(held:Dictionary) -> Vector2:
	return Vector2(float(held.get(KEY_D,false))-float(held.get(KEY_A,false)),float(held.get(KEY_W,false))-float(held.get(KEY_S,false))).limit_length(1.0)

static func direction(input:Vector2,forward:Vector3) -> Vector3:
	return Movement.direction_from_forward(input,forward)

static func clips(input:Vector2,sprinting:bool) -> Array[String]:
	var result:Array[String]=[]
	if absf(input.y)>0.001:result.append(("duel/run" if sprinting else "ual1/Jog_Fwd") if input.y>0.0 else "duel/walk_back")
	if absf(input.x)>0.001:result.append("duel/strafe_left" if input.x<0.0 else "duel/strafe_right")
	return result

static func pose(actor:Node,input:Vector2,time:float,sprinting:bool) -> void:
	var choices:=clips(input,sprinting)
	if choices.is_empty():return
	var first:Array[Transform3D]=[]
	var rate:=1.75 if sprinting else 1.0
	for index in choices.size():
		var clip:String=choices[index]
		var length:float=actor.player.get_animation(clip).length
		CastPose.pose(actor,{"clip":clip,"step":"Run","store_raw":true},fposmod(time*rate/maxf(0.001,length),1.0))
		if choices.size()>1 and index==0:
			for bone in actor.skeleton.get_bone_count():first.append(actor.skeleton.get_bone_pose(bone))
	if not first.is_empty():
		var weight:=absf(input.x)/(absf(input.x)+absf(input.y))
		for bone in first.size():actor.skeleton.set_bone_pose(bone,first[bone].interpolate_with(actor.skeleton.get_bone_pose(bone),weight))
		actor.skeleton.force_update_all_bone_transforms()
	actor.set_meta("creation_locomotion_clips",choices)
	actor.set_meta("creation_locomotion_axes",input)
