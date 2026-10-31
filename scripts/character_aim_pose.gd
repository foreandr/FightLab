extends RefCounted
## Shared post-animation aim correction, extracted from Story's calibrated rig.
## Call after sampling the base pose, before ice constraints are restored.
const Aim=preload("res://scripts/combat_aim.gd")

static func apply_torso(actor:Node,yaw:float,pitch:float) -> void:
	# Let the arm absorb small aim corrections on its own. Bring the upper torso
	# in only after the target moves outside that natural reach, and involve the
	# hips/legs only for a genuinely far-off angle.
	var arm_yaw_deadzone:=deg_to_rad(18.0)
	var torso_yaw:=signf(yaw)*maxf(0.0,absf(yaw)-arm_yaw_deadzone)
	var hip_start:=deg_to_rad(58.0)
	var hip_yaw_magnitude:=clampf(absf(torso_yaw)-hip_start,0.0,deg_to_rad(42.0))
	var hip_yaw:=signf(torso_yaw)*hip_yaw_magnitude
	var upper_yaw:=clampf(torso_yaw-hip_yaw,-deg_to_rad(82.0),deg_to_rad(82.0))
	var arm_pitch_deadzone:=deg_to_rad(10.0)
	var torso_pitch:=signf(pitch)*maxf(0.0,absf(pitch)-arm_pitch_deadzone)
	rotate_bone(actor,"pelvis",Vector3.UP,hip_yaw)
	rotate_bone(actor,"spine_02",Vector3.UP,upper_yaw*0.5)
	rotate_bone(actor,"spine_03",Vector3.UP,upper_yaw*0.5)
	rotate_bone(actor,"spine_02",actor.global_basis.x,torso_pitch*0.5)
	rotate_bone(actor,"spine_03",actor.global_basis.x,torso_pitch*0.5)

static func rotate_bone(actor:Node,bone_name:String,world_axis:Vector3,angle:float) -> void:
	if not actor.bones.has(bone_name) or absf(angle)<0.001:return
	var index:int=int(actor.bones[bone_name])
	var parent:int=actor.skeleton.get_bone_parent(index)
	var axis_in_skeleton:Vector3=actor.skeleton.global_basis.inverse()*world_axis
	var axis_in_parent:Vector3=axis_in_skeleton if parent<0 else actor.skeleton.get_bone_global_pose(parent).basis.inverse()*axis_in_skeleton
	if axis_in_parent.is_zero_approx():return
	var current:Quaternion=actor.skeleton.get_bone_pose_rotation(index)
	actor.skeleton.set_bone_pose_rotation(index,Quaternion(axis_in_parent.normalized(),angle)*current)

static func endpoint_angles(actor:Node,emitter:String,target:Vector3) -> Dictionary:
	var torso_pivot:Vector3=actor.bone_point("spine_03")
	var fist:Vector3=actor.bone_point(emitter)
	var current_offset:=fist-torso_pivot
	var target_offset:=target-torso_pivot
	var current_flat:=Vector3(current_offset.x,0.0,current_offset.z)
	var target_flat:=Vector3(target_offset.x,0.0,target_offset.z)
	if current_flat.length_squared()<0.0001 or target_flat.length_squared()<0.0001:return {}
	var yaw:=clampf(current_flat.signed_angle_to(target_flat,Vector3.UP),-deg_to_rad(120.0),deg_to_rad(120.0))
	var current_pitch:=atan2(current_offset.y,maxf(0.001,current_flat.length()))
	var target_pitch:=atan2(target_offset.y,maxf(0.001,target_flat.length()))
	var pitch:=clampf(current_pitch-target_pitch,-deg_to_rad(80.0),deg_to_rad(80.0))
	var off_center:=clampf(Vector2(yaw/deg_to_rad(89.0),pitch/deg_to_rad(80.0)).length(),0.0,1.0)
	return {"yaw":yaw,"pitch":pitch,"recovery_duration":lerpf(0.12,0.26,off_center)}

static func align_forearm(actor:Node,side:String,target:Vector3,weight:float=1.0) -> void:
	var elbow:Vector3=actor.bone_point("lowerarm_%s"%side)
	var fist:Vector3=actor.bone_point("hand_%s"%side)
	var current_direction:=fist-elbow
	var desired_direction:=target-elbow
	if current_direction.length_squared()<0.0001 or desired_direction.length_squared()<0.0001:return
	var world_delta:=Quaternion(current_direction.normalized(),desired_direction.normalized())
	var bone_index:=int(actor.bones.get("lowerarm_%s"%side,-1))
	if bone_index<0:return
	var parent:int=actor.skeleton.get_bone_parent(bone_index)
	var parent_world_basis:Basis=actor.skeleton.global_transform.basis
	if parent>=0:parent_world_basis=actor.skeleton.global_transform.basis*actor.skeleton.get_bone_global_pose(parent).basis
	var parent_world_rotation:Quaternion=parent_world_basis.get_rotation_quaternion()
	var local_delta:=parent_world_rotation.inverse()*world_delta*parent_world_rotation
	var current:Quaternion=actor.skeleton.get_bone_pose_rotation(bone_index)
	actor.skeleton.set_bone_pose_rotation(bone_index,current.slerp(local_delta*current,clampf(weight,0.0,1.0)))
	actor.skeleton.force_update_all_bone_transforms()

static func aim_leg(actor:Node,side:String,direction:Vector3,weight:float=1.0) -> void:
	if direction.is_zero_approx():return
	var local:Vector3=actor.global_basis.inverse()*direction.normalized()
	var yaw:=clampf(atan2(local.x,local.z),-0.8,0.8)*weight
	rotate_bone(actor,"thigh_%s"%side,Vector3.UP,yaw*0.78)
	rotate_bone(actor,"calf_%s"%side,Vector3.UP,yaw*0.18)

static func apply(actor:Node,target:Vector3,emitter:String,weight:float) -> void:
	weight=clampf(weight,0.0,1.0)
	if weight<=0.0:return
	if emitter in ["hand_l","hand_r"]:
		var correction:=endpoint_angles(actor,emitter,target)
		if not correction.is_empty():apply_torso(actor,float(correction.yaw)*weight,float(correction.pitch)*weight)
		actor.skeleton.force_update_all_bone_transforms()
		align_forearm(actor,emitter.right(1),target,weight)
	elif emitter.begins_with("thigh_") or emitter.begins_with("calf_") or emitter.begins_with("foot_") or emitter.begins_with("ball_"):
		var correction:=Aim.angles(actor,target-actor.bone_point("spine_03"))
		apply_torso(actor,float(correction.yaw)*weight,-float(correction.pitch)*weight)
		aim_leg(actor,emitter.right(1),target-actor.bone_point(emitter),weight)
	actor.skeleton.force_update_all_bone_transforms()
