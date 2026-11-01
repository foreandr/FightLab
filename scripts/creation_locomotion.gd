extends RefCounted
## Shared eight-way movement poses for Create and its playtest controller.
const Movement=preload("res://scripts/character_movement.gd")
const CastPose=preload("res://scripts/spell_cast_motion.gd")

static func axes(held:Dictionary) -> Vector2:
	return Vector2(float(held.get(KEY_D,false))-float(held.get(KEY_A,false)),float(held.get(KEY_W,false))-float(held.get(KEY_S,false))).limit_length(1.0)

static func direction(input:Vector2,forward:Vector3) -> Vector3:
	return Movement.direction_from_forward(input,forward)

static func clips(input:Vector2,sprinting:bool,walking:bool=false) -> Array[String]:
	var result:Array[String]=[]
	if absf(input.y)>0.001:result.append(("duel/walk_forward" if walking else ("duel/run" if sprinting else "ual1/Jog_Fwd")) if input.y>0.0 else "duel/walk_back")
	if absf(input.x)>0.001:result.append("duel/strafe_left" if input.x<0.0 else "duel/strafe_right")
	return result

static func pose(actor:Node,input:Vector2,time:float,sprinting:bool) -> void:
	var walking:=Movement.walking_only(actor)
	var choices:=clips(input,sprinting,walking)
	if choices.is_empty():return
	var first:Array[Transform3D]=[]
	var rate:=0.6 if walking else (1.75 if sprinting else 1.0)
	for index in choices.size():
		var clip:String=choices[index]
		var length:float=actor.player.get_animation(clip).length
		CastPose.pose(actor,{"clip":clip,"step":"Run","store_raw":true},fposmod(time*rate/maxf(0.001,length),1.0))
		if choices.size()>1 and index==0:
			first=CastPose.capture(actor)
	if not first.is_empty():
		var weight:=absf(input.x)/(absf(input.x)+absf(input.y))
		CastPose.blend_from(actor,first,weight)
	actor.set_meta("creation_locomotion_clips",choices)
	actor.set_meta("creation_locomotion_axes",input)

## Keep the moving gait below the waist while retaining the active cast above it.
## Sample the existing locomotion system; never edit either source animation.
static func is_locomotion_bone(rig:Skeleton3D,index:int) -> bool:
	var name_:=rig.get_bone_name(index)
	if name_ in ["root","pelvis"]:return true
	while index>=0:
		if rig.get_bone_name(index).begins_with("thigh_"):return true
		index=rig.get_bone_parent(index)
	return false

static func moving_legs(actor:Node,input:Vector2,time:float,sprinting:bool,weight:float=1.0) -> void:
	if input.is_zero_approx() or weight<=0.0:return
	var cast:=CastPose.capture(actor)
	var cast_clip:String=actor.clip
	var model_rotation:Vector3=actor.model.rotation
	pose(actor,input,time,sprinting)
	var rig:Skeleton3D=actor.skeleton
	for index in rig.get_bone_count():
		var gait:=rig.get_bone_pose(index)
		rig.set_bone_pose(index,cast[index].interpolate_with(gait,clampf(weight,0.0,1.0)) if is_locomotion_bone(rig,index) else cast[index])
	actor.clip=cast_clip
	actor.model.rotation=model_rotation
	rig.force_update_all_bone_transforms()

## Animation-owned authority over locomotion; independent of movement speed/costs.
static func leg_takeover(profile:Dictionary) -> float:
	var value:=float(profile.get("leg_takeover",0.0))
	return clampf(value,0.0,1.0) if is_finite(value) else 0.0

static func cast_legs(actor:Node,profile:Dictionary,input:Vector2,time:float,sprinting:bool) -> void:
	moving_legs(actor,input,time,sprinting,1.0-leg_takeover(profile))
