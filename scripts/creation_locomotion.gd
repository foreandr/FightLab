extends RefCounted
## Shared eight-way movement poses for Create and its playtest controller.
const Movement=preload("res://scripts/character_movement.gd")
const CastPose=preload("res://scripts/spell_cast_motion.gd")

static func axes(held:Dictionary) -> Vector2:
	return Vector2(float(held.get(KEY_D,false) or held.get(KEY_RIGHT,false))-float(held.get(KEY_A,false) or held.get(KEY_LEFT,false)),float(held.get(KEY_W,false) or held.get(KEY_UP,false))-float(held.get(KEY_S,false) or held.get(KEY_DOWN,false))).limit_length(1.0)

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

## Pose ownership is a declared animation type, never a manual blend percentage.
static func leg_takeover(profile:Dictionary) -> float:
	return 1.0 if preload("res://scripts/animation_cast_type.gd").owns_legs(profile) else 0.0

static func cast_legs(actor:Node,profile:Dictionary,input:Vector2,time:float,sprinting:bool) -> void:
	# An authored airborne move supplies its own leg pose; ground locomotion
	# must not replace the aerial kick/flip while gravity carries the actor.
	if not actor.is_on_floor() and not preload("res://scripts/animation_jump_motion.gd").settings(profile).is_empty():return
	var type_=preload("res://scripts/animation_cast_type.gd")
	if not type_.owns_legs(profile) and jump_pose(actor,true):return
	if not type_.applies(profile):
		# Non-Touch casts keep their full pose while still; moving uses the gait.
		moving_legs(actor,input,time,sprinting)
		return
	if type_.kind(profile)==type_.WHOLE_BODY:return
	var cast:=CastPose.capture(actor)
	var cast_clip:String=actor.clip
	# A leg contribution coasts instead of borrowing a running pose.
	if input.is_zero_approx() or type_.owns_legs(profile):preload("res://scripts/editor_rig_pose.gd").idle(actor,time)
	else:pose(actor,input,time,sprinting)
	var rig:Skeleton3D=actor.skeleton
	var kind:String=type_.kind(profile)
	for index in rig.get_bone_count():
		if type_.controls_bone(rig,index,kind):rig.set_bone_pose(index,cast[index])
	actor.clip=cast_clip
	rig.force_update_all_bone_transforms()

## Manual jump uses the same saved jump frames and actor clocks as gameplay.
## Regional casts can retain their upper body while jump supplies the legs.
static func jump_pose(actor:Node,legs_only:bool=false)->bool:
	if actor.jump_kind!="motion_jump" or (actor.is_on_floor() and actor.mode!="takeoff"):return false
	var baseline:Array[Transform3D]=[]
	if legs_only:baseline=CastPose.capture(actor)
	var cast_clip:String=actor.clip
	var taking_off:bool=actor.mode=="takeoff"
	var model_rotation:Vector3=actor.model.rotation
	var twist_age:float=actor.twist_age
	var time:float=actor.mode_time if taking_off else 0.14+actor.custom_jump_elapsed
	preload("res://scripts/editor_rig_pose.gd").sample(actor,"duel/takeoff" if taking_off else "duel/air",actor.mode_time if taking_off else actor.air_clock)
	if actor.custom_jump_frames.size()>=2:
		if actor.custom_jump_native:actor.apply_custom_jump_pose(time/maxf(0.001,actor.custom_jump_source_duration),actor.custom_jump_frames,true)
		else:actor.apply_custom_jump_pose(actor.custom_jump_elapsed/0.95)
	preload("res://scripts/jump_charge_pose.gd").apply(actor)
	if legs_only:
		for index in actor.skeleton.get_bone_count():
			if not is_locomotion_bone(actor.skeleton,index):actor.skeleton.set_bone_pose(index,baseline[index])
		actor.model.rotation=model_rotation
		actor.twist_age=twist_age
	actor.clip=cast_clip
	actor.skeleton.force_update_all_bone_transforms()
	return true

## Blend the cast recovery into the gait being requested now, not a frozen pose.
static func recover_from_cast(actor:Node,input:Vector2,time:float,sprinting:bool,weight:float) -> void:
	if weight<=0.0:return
	var cast:=CastPose.capture(actor)
	var cast_clip:String=actor.clip
	if input.is_zero_approx():preload("res://scripts/editor_rig_pose.gd").idle(actor,time)
	else:pose(actor,input,time,sprinting)
	CastPose.blend_from(actor,cast,weight)
	actor.clip=cast_clip
