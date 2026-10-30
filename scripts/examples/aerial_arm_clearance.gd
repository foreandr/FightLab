extends RefCounted
const Solver=preload("res://scripts/pose_drag_solver.gd")

static func measure(actor:Node) -> Dictionary:
	var s:=Solver.point(actor,"upperarm_r")
	var e:=Solver.point(actor,"lowerarm_r")
	var h:=Solver.point(actor,"hand_r")
	var bodies:Array=[
		[Solver.point(actor,"spine_01"),Solver.point(actor,"neck_01"),0.172],
		[Solver.point(actor,"pelvis"),Solver.point(actor,"spine_01"),0.15]]
	var limbs:Array=[[s.lerp(e,0.48),e,0.055],[e,h,0.055],[h,h,0.065]]
	var total:=0.0
	var worst:=0.0
	for body in bodies:
		for limb in limbs:
			var nearest:=Geometry3D.get_closest_points_between_segments(body[0],body[1],limb[0],limb[1])
			var depth:=maxf(0.0,float(body[2])+float(limb[2])-nearest[0].distance_to(nearest[1]))
			total+=depth*depth
			worst=maxf(worst,depth)
	return {"sum":total,"worst":worst}

static func solve(actor:Node,previous:Array=[]) -> Dictionary:
	var rig:Skeleton3D=actor.skeleton
	var ids:Array=[actor.bones.upperarm_r,actor.bones.lowerarm_r]
	var original:Array=[rig.get_bone_pose_rotation(ids[0]),rig.get_bone_pose_rotation(ids[1])]
	var hand:=Solver.point(actor,"hand_r")
	var before:=measure(actor)
	var angles:Array=[Quaternion.IDENTITY,Quaternion.IDENTITY]
	if not previous.is_empty():
		angles=previous.duplicate()
		for j in 2:rig.set_bone_pose_rotation(ids[j],(angles[j]*original[j]).normalized())
		rig.force_update_all_bone_transforms()
	var best:=score(actor,original,ids,hand,previous)
	for size in [0.16,0.08,0.035,0.015]:
		for iteration in 16:
			var improvement:=false
			for j in 2:
				var current:Quaternion=rig.get_bone_pose_rotation(ids[j])
				var winner:=current
				for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
					for sign_ in [-1.0,1.0]:
						var candidate:Quaternion=Quaternion(axis,size*sign_)*current
						if original[j].angle_to(candidate)>deg_to_rad(70 if j==0 else 55):continue
						rig.set_bone_pose_rotation(ids[j],candidate.normalized())
						rig.force_update_all_bone_transforms()
						var cost:=score(actor,original,ids,hand,previous)
						if cost<best-0.0000001:
							best=cost
							winner=candidate
							improvement=true
				rig.set_bone_pose_rotation(ids[j],winner.normalized())
				rig.force_update_all_bone_transforms()
			if not improvement:break
	for j in 2:angles[j]=rig.get_bone_pose_rotation(ids[j])*(original[j] as Quaternion).inverse()
	return {"before":before.worst,"after":measure(actor).worst,"corrections":angles}

static func score(actor:Node,original:Array,ids:Array,hand:Vector3,previous:Array) -> float:
	var rig:Skeleton3D=actor.skeleton
	var result:float=measure(actor).sum*6000.0
	result+=Solver.point(actor,"hand_r").distance_squared_to(hand)*0.7
	for j in 2:
		var q:=rig.get_bone_pose_rotation(ids[j])
		result+=pow(original[j].angle_to(q),2)*0.025
		if not previous.is_empty():result+=pow((q*(original[j] as Quaternion).inverse()).angle_to(previous[j]),2)*0.08
	return result
