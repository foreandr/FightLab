extends RefCounted
const FINGERS=["thumb","index","middle","ring","pinky"]

static func blend(a:Dictionary,b:Dictionary,weight:float) -> Dictionary:
	var result:Dictionary={}
	for side in ["l","r"]:
		var hand:Dictionary={}
		for key in FINGERS+["straight","palm_up","absolute"]:
			hand[key]=lerpf(float(a.get(side,{}).get(key,0.0)),float(b.get(side,{}).get(key,0.0)),weight)
		for finger in FINGERS:
			hand["absolute_"+finger]=lerpf(absolute_strength(a.get(side,{}),finger),absolute_strength(b.get(side,{}),finger),weight)
		result[side]=hand
	return result

static func absolute_strength(hand:Dictionary,finger:String) -> float:
	return clampf(float(hand.get("absolute_"+finger,hand.get("absolute",0.0))),0,1)

static func palm_normal_local(actor:Node,side:String) -> Vector3:
	var rig:Skeleton3D=actor.skeleton
	var hand:Transform3D=rig.get_bone_global_rest(actor.bones["hand_"+side])
	var index:Vector3=rig.get_bone_global_rest(actor.bones["index_01_"+side]).origin-hand.origin
	var pinky:Vector3=rig.get_bone_global_rest(actor.bones["pinky_01_"+side]).origin-hand.origin
	return hand.basis.inverse()*index.cross(pinky).normalized()*(-1.0 if side=="l" else 1.0)

static func apply(actor:Node,hands:Dictionary) -> void:
	var rig:Skeleton3D=actor.skeleton
	for side in ["l","r"]:
		var data:Dictionary=hands.get(side,{})
		var index:int=actor.bones["hand_"+side]
		var source:Quaternion=rig.get_bone_pose_rotation(index)
		var rest:Quaternion=rig.get_bone_rest(index).basis.get_rotation_quaternion()
		var straight:float=clampf(float(data.get("straight",0.0)),0,1)
		var up:float=clampf(float(data.get("palm_up",0.0)),0,1)
		var desired:=source.slerp(rest,straight)
		if up>0:
			var parent:int=rig.get_bone_parent(index)
			var parent_world:Basis=rig.global_basis*rig.get_bone_global_pose(parent).basis
			var axis:Vector3=(rig.global_basis*(rig.get_bone_global_pose(index).origin-rig.get_bone_global_pose(parent).origin)).normalized()
			var normal:Vector3=parent_world*Basis(rest)*palm_normal_local(actor,side)
			var target:Vector3=Vector3.UP-axis*Vector3.UP.dot(axis)
			if target.length()>0.001:
				normal=(normal-axis*normal.dot(axis)).normalized()
				var angle:=normal.signed_angle_to(target.normalized(),axis)
				var palm_up:Quaternion=(parent_world.inverse()*Basis(Quaternion(axis,angle))*parent_world*Basis(rest)).orthonormalized().get_rotation_quaternion()
				desired=desired.slerp(palm_up,up)
		rig.set_bone_pose_rotation(index,desired)
		for finger in FINGERS:
			var curl:float=clampf(float(data.get(finger,0.0))/100.0,0,1)
			var absolute:=absolute_strength(data,finger)
			for segment in range(1,3 if finger=="thumb" else 4):
				var bone:String="%s_%02d_%s"%[finger,segment,side]
				if not actor.bones.has(bone):continue
				var bone_index:int=actor.bones[bone]
				var base:Quaternion=rig.get_bone_pose_rotation(bone_index)
				var bone_rest:Quaternion=rig.get_bone_rest(bone_index).basis.get_rotation_quaternion()
				var axis:=Vector3(0,0,1) if finger=="thumb" else Vector3.RIGHT
				var sign_:float=-1.0 if side=="l" and finger=="thumb" else 1.0
				var old_angle:float=[110.0,60.0,30.0][segment-1]
				var angle:float=([35.0,45.0][segment-1] if finger=="thumb" else [85.0,95.0,65.0][segment-1])
				var legacy:=base*Quaternion(axis,deg_to_rad(old_angle*curl*sign_))
				var posed:=bone_rest*Quaternion(axis,deg_to_rad(angle*curl*sign_))
				rig.set_bone_pose_rotation(bone_index,legacy.slerp(posed,absolute).normalized())
