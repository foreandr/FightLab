extends RefCounted
const Source=preload("res://scripts/animation_source_pose.gd")
const Mirror=preload("res://scripts/animation_mirror.gd")
const AimPose=preload("res://scripts/character_aim_pose.gd")

static func pose(actor:Node,profile:Dictionary,progress:float,aim:Dictionary={}) -> void:
	actor.capture_ice_pose()
	actor.skeleton.reset_bone_poses()
	actor.model.rotation=Vector3.ZERO
	actor.twist_age=-1
	if bool(profile.get("store_raw",false)):
		var clip:=str(profile.get("clip",""))
		if not actor.player.has_animation(clip):
			actor.restore_ice_pose()
			return
		actor.clip=clip
		actor.player.pause()
		preload("res://scripts/editor_rig_pose.gd").sample(actor,clip,actor.player.get_animation(clip).length*clampf(progress,0.0,0.9999))
	else:
		var duration:float=float(profile.get("source_duration",Source.duration(actor,profile.step,profile.clip)))
		var recipe:=Source.clip_at(actor,profile.step,profile.clip,progress,duration)
		actor.clip=recipe.name
		actor.player.speed_scale=1.0
		actor.player.play(recipe.name,0,1)
		actor.player.seek(actor.player.get_animation(recipe.name).length*float(recipe.blend),true)
		actor.player.advance(0)
		actor.player.pause()
		preload("res://scripts/editor_rig_pose.gd").sample(actor,recipe.name,actor.player.get_animation(recipe.name).length*float(recipe.blend))
	if profile.get("mirrored",false):Mirror.apply(actor)
	if profile.get("frames",[]).size()>=2:actor.apply_custom_jump_pose(progress,profile.frames,true)
	if profile.has("demo_palm"):_apply_demo_hand(actor,str(profile.demo_palm),progress)
	if not aim.is_empty():AimPose.apply(actor,aim.target,str(aim.get("emitter","hand_r")),float(aim.get("weight",1.0)))
	actor.restore_ice_pose()
	actor.skeleton.force_update_all_bone_transforms()

static func _apply_demo_hand(actor:Node,orientation:String,progress:float) -> void:
	var hand_pose=preload("res://scripts/hand_pose.gd")
	var closed:=orientation=="straight"
	var curl:=100.0 if closed else 0.0
	_apply_demo_reach(actor,orientation,progress)
	hand_pose.apply(actor,{"r":{"straight":1.0,"absolute":1.0,"thumb":70.0 if closed else 0.0,"index":curl,"middle":curl,"ring":curl,"pinky":curl}})
	if closed:return
	var rig:Skeleton3D=actor.skeleton
	rig.force_update_all_bone_transforms()
	var hand:int=actor.bones.hand_r
	var parent:=rig.get_bone_parent(hand)
	var parent_world:Basis=rig.global_basis*rig.get_bone_global_pose(parent).basis
	var hand_world:Basis=rig.global_basis*rig.get_bone_global_pose(hand).basis
	var axis:Vector3=(rig.global_basis*(rig.get_bone_global_pose(hand).origin-rig.get_bone_global_pose(parent).origin)).normalized()
	var normal:Vector3=hand_world*hand_pose.palm_normal_local(actor,"r")
	var target:=Vector3.UP if orientation=="up" else Vector3.DOWN
	target-=axis*target.dot(axis)
	if target.length()<0.001:return
	normal=(normal-axis*normal.dot(axis)).normalized()
	var angle:=normal.signed_angle_to(target.normalized(),axis)
	var source:=rig.get_bone_pose_rotation(hand)
	var desired:Quaternion=(parent_world.inverse()*Basis(Quaternion(axis,angle))*parent_world*Basis(source)).orthonormalized().get_rotation_quaternion()
	var weight:=smoothstep(0.0,0.2,progress)*(1.0-smoothstep(0.8,1.0,progress))
	rig.set_bone_pose_rotation(hand,source.slerp(desired,weight))

static func _apply_demo_reach(actor:Node,orientation:String,progress:float) -> void:
	# Explicit two-bone reaches make the choices visible at the wide spell camera:
	# a straight fist, a lower open palm-up cast, and a level palm-down cast.
	var rig:Skeleton3D=actor.skeleton
	rig.force_update_all_bone_transforms()
	var upper:int=actor.bones.upperarm_r
	var lower:int=actor.bones.lowerarm_r
	var hand:int=actor.bones.hand_r
	var shoulder:Vector3=rig.global_transform*rig.get_bone_global_pose(upper).origin
	var elbow:Vector3=rig.global_transform*rig.get_bone_global_pose(lower).origin
	var wrist:Vector3=rig.global_transform*rig.get_bone_global_pose(hand).origin
	var upper_length:=shoulder.distance_to(elbow)
	var lower_length:=elbow.distance_to(wrist)
	var vertical:float=-0.33 if orientation=="up" else (0.07 if orientation=="down" else 0.0)
	var forward:Vector3=(actor.global_basis.z+Vector3.UP*vertical).normalized()
	var extension:=smoothstep(0.03,0.32,progress)*(1.0-smoothstep(0.68,0.96,progress))
	var target:=wrist.lerp(shoulder+forward*(upper_length+lower_length)*0.96,extension)
	var toward:=target-shoulder
	var distance:=clampf(toward.length(),absf(upper_length-lower_length)+0.001,upper_length+lower_length-0.001)
	var axis:=toward.normalized()
	var bend:Vector3=actor.global_basis.x*0.35-Vector3.UP
	bend=(bend-axis*bend.dot(axis)).normalized()
	var along:float=(upper_length*upper_length-lower_length*lower_length+distance*distance)/(2.0*distance)
	var height:=sqrt(maxf(0.0,upper_length*upper_length-along*along))
	var elbow_target:=shoulder+axis*along+bend*height
	_rotate_demo_bone(rig,upper,elbow-shoulder,elbow_target-shoulder)
	rig.force_update_all_bone_transforms()
	elbow=rig.global_transform*rig.get_bone_global_pose(lower).origin
	wrist=rig.global_transform*rig.get_bone_global_pose(hand).origin
	_rotate_demo_bone(rig,lower,wrist-elbow,target-elbow)
	rig.force_update_all_bone_transforms()

static func _rotate_demo_bone(rig:Skeleton3D,bone:int,from:Vector3,to:Vector3) -> void:
	if from.length_squared()<0.000001 or to.length_squared()<0.000001:return
	var parent:=rig.get_bone_parent(bone)
	var parent_world:Basis=rig.global_basis*rig.get_bone_global_pose(parent).basis if parent>=0 else rig.global_basis
	var current_world:Basis=rig.global_basis*rig.get_bone_global_pose(bone).basis
	var desired_world:=Basis(Quaternion(from.normalized(),to.normalized()))*current_world
	rig.set_bone_pose_rotation(bone,(parent_world.inverse()*desired_world).orthonormalized().get_rotation_quaternion())
