extends RefCounted
## Editor-only inverse kinematics. Lengths come from the current rig; every small
## rotation is checked against the same body-volume guard used by the sliders.
const Collision=preload("res://scripts/pose_self_collision.gd")
const JOINTS=["upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","thigh_l","thigh_r","calf_l","calf_r","spine_03","foot_l","foot_r","spine_01","spine_02","neck_01","pelvis","Head"]
const HANDLES=[
	{"bone":"hand_l","label":"Left hand","chain":["lowerarm_l","upperarm_l"]},
	{"bone":"hand_r","label":"Right hand","chain":["lowerarm_r","upperarm_r"]},
	{"bone":"lowerarm_l","label":"Left elbow","chain":["upperarm_l"]},
	{"bone":"lowerarm_r","label":"Right elbow","chain":["upperarm_r"]},
	{"bone":"calf_l","label":"Left knee","chain":["thigh_l"]},
	{"bone":"calf_r","label":"Right knee","chain":["thigh_r"]},
	{"bone":"foot_l","label":"Left foot","chain":["calf_l","thigh_l"]},
	{"bone":"foot_r","label":"Right foot","chain":["calf_r","thigh_r"]},
	{"bone":"pelvis","label":"Hips — drag down to crouch","chain":[]},
	{"bone":"neck_01","label":"Chest","chain":["spine_03"]},
	{"bone":"Head","label":"Head — turn / tilt","chain":["Head"]}
]

static func point(actor:Node,bone:String) -> Vector3:
	var transform:Transform3D=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.bones[bone])
	if bone=="Head":
		# Offset from the joint to the forehead so dragging rotates the head
		# around its neck instead of trying to translate its own pivot.
		var rest:Basis=actor.skeleton.global_basis*actor.skeleton.get_bone_global_rest(actor.bones[bone]).basis
		var tip:Vector3=rest.inverse()*actor.model.global_basis*(Vector3(0,0.11,0.13))
		return transform*tip
	return transform.origin

static func _head_axes(actor:Node) -> Basis:
	var skeleton:Skeleton3D=actor.skeleton
	var parent:int=skeleton.get_bone_parent(actor.bones["Head"])
	var rest_world:Basis=(skeleton.global_basis*skeleton.get_bone_global_rest(parent).basis).orthonormalized()
	return (rest_world.inverse()*actor.model.global_basis.orthonormalized()).orthonormalized()

static func head_pose_angles(actor:Node,local:Quaternion) -> Vector3:
	var axes:=_head_axes(actor)
	var rest:Basis=actor.skeleton.get_bone_rest(actor.bones["Head"]).basis.orthonormalized()
	return (axes.inverse()*Basis(local)*rest.inverse()*axes).orthonormalized().get_euler()*180.0/PI

static func head_rotation_from_angles(actor:Node,angles:Vector3) -> Quaternion:
	var axes:=_head_axes(actor)
	var rest:Basis=actor.skeleton.get_bone_rest(actor.bones["Head"]).basis.orthonormalized()
	return (axes*Basis.from_euler(angles*PI/180.0)*axes.inverse()*rest).orthonormalized().get_rotation_quaternion()

static func limit_head_rotation(actor:Node,previous:Quaternion,desired:Quaternion) -> Quaternion:
	var before:=head_pose_angles(actor,previous)
	var angles:=head_pose_angles(actor,desired)
	var lower:=Vector3(-55,-75,-35).min(before)
	var upper:=Vector3(55,75,35).max(before)
	return head_rotation_from_angles(actor,angles.clamp(lower,upper))

static func solve(actor:Node,pose:Dictionary,handle:String,target:Vector3,anchors:Dictionary={}) -> Dictionary:
	var result:Dictionary={"pose":pose.duplicate(true),"blocked":false,"contact":Collision.penetrations(actor.skeleton),"bends":_joint_bends(actor),"base":{}}
	for bone in JOINTS:
		var angles:Vector3=pose.get(bone,Vector3.ZERO)
		var offset:=Quaternion.from_euler(angles*PI/180.0)
		result.base[bone]=(actor.skeleton.get_bone_pose_rotation(actor.bones[bone])*offset.inverse()).normalized()
	if handle=="pelvis":
		var feet:Dictionary=anchors if not anchors.is_empty() else {"l":point(actor,"foot_l"),"r":point(actor,"foot_r")}
		var delta:Vector3=(target-point(actor,"pelvis")).limit_length(0.075)
		var previous:Vector3=result.pose.get("pelvis_offset",Vector3.ZERO)
		var index:int=actor.bones["pelvis"]
		var parent:int=actor.skeleton.get_bone_parent(index)
		var parent_basis:Basis=actor.skeleton.global_basis*actor.skeleton.get_bone_global_pose(parent).basis if parent>=0 else actor.skeleton.global_basis
		var desired_world:Vector3=(parent_basis*previous+delta).clamp(Vector3(-0.35,-0.60,-0.35),Vector3(0.35,0.35,0.35))
		var desired:Vector3=parent_basis.inverse()*desired_world
		var original:Vector3=actor.skeleton.get_bone_pose_position(index)
		actor.skeleton.set_bone_pose_position(index,original+desired-previous)
		actor.skeleton.force_update_all_bone_transforms()
		if _accept(actor,result):
			result.pose["pelvis_offset"]=desired
			for side in ["l","r"]:
				_solve_chain(actor,result,"foot_"+side,["calf_"+side,"thigh_"+side],feet[side])
				if anchors.has("rotation_"+side):_plant_foot_rotation(actor,result,"foot_"+side,anchors["rotation_"+side])
			if point(actor,"foot_l").distance_to(feet.l)>0.045 or point(actor,"foot_r").distance_to(feet.r)>0.045:
				# A planted squat must not pull the feet underground or off their anchors.
				actor.skeleton.set_bone_pose_position(index,original)
				for bone in JOINTS:
					var angles:Vector3=pose.get(bone,Vector3.ZERO)
					actor.skeleton.set_bone_pose_rotation(actor.bones[bone],(result.base[bone] as Quaternion)*Quaternion.from_euler(angles*PI/180.0))
				actor.skeleton.force_update_all_bone_transforms()
				result.pose=pose.duplicate(true)
				result.blocked=true
				result["blocking_pair"]="feet cannot stay planted"
		else:
			actor.skeleton.set_bone_pose_position(index,original)
			actor.skeleton.force_update_all_bone_transforms()
	else:
		for definition in HANDLES:
			if definition.bone==handle:
				var goal:Vector3=point(actor,handle)+(target-point(actor,handle)).limit_length(0.12)
				_solve_chain(actor,result,handle,definition.chain,goal)
				break
	return result

static func _plant_foot_rotation(actor:Node,state:Dictionary,bone:String,world:Quaternion) -> void:
	var skeleton:Skeleton3D=actor.skeleton
	var index:int=actor.bones[bone]
	var parent:int=skeleton.get_bone_parent(index)
	var parent_basis:Basis=skeleton.global_basis*skeleton.get_bone_global_pose(parent).basis
	var desired:Quaternion=(parent_basis.inverse()*Basis(world)).orthonormalized().get_rotation_quaternion()
	var previous:Quaternion=skeleton.get_bone_pose_rotation(index)
	skeleton.set_bone_pose_rotation(index,desired)
	skeleton.force_update_all_bone_transforms()
	if _accept(actor,state):state.pose[bone]=((state.base[bone] as Quaternion).inverse()*desired).get_euler()*180.0/PI
	else:
		skeleton.set_bone_pose_rotation(index,previous)
		skeleton.force_update_all_bone_transforms()

static func _solve_chain(actor:Node,state:Dictionary,end:String,chain:Array,target:Vector3) -> void:
	for iteration in 10:
		if point(actor,end).distance_to(target)<0.008:break
		# Give a straight limb a bend direction; CCD alone cannot shorten it.
		if chain.size()==2:
			var root:Vector3=point(actor,chain[1])
			var middle:Vector3=point(actor,chain[0])
			var tip:Vector3=point(actor,end)
			var axis:Vector3=(target-root).normalized()
			var distance:=clampf(root.distance_to(target),0.025,root.distance_to(middle)+middle.distance_to(tip)-0.001)
			var first:=root.distance_to(middle)
			var second:=middle.distance_to(tip)
			var along:float=(first*first+distance*distance-second*second)/(2.0*distance)
			var height:=sqrt(maxf(0,first*first-along*along))
			var pole:Vector3=actor.global_basis.z if end.begins_with("foot") else middle-root-axis*(middle-root).dot(axis)
			pole-=axis*pole.dot(axis)
			if pole.length()<0.025:
				pole=actor.global_basis.z if end.begins_with("foot") else actor.global_basis.x*(-1 if end.ends_with("l") else 1)+Vector3.DOWN*0.4
				pole-=axis*pole.dot(axis)
			if pole.length()>0.001:_rotate_toward(actor,state,chain[1],chain[0],root+axis*along+pole.normalized()*height)
			_rotate_toward(actor,state,chain[0],end,target)
		else:
			for joint in chain:_rotate_toward(actor,state,joint,end,target)

static func _rotate_toward(actor:Node,state:Dictionary,bone:String,end:String,target:Vector3) -> void:
	var pivot:Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.bones[bone]).origin
	var from:Vector3=point(actor,end)-pivot
	var to:=target-pivot
	if from.length()<0.001 or to.length()<0.001:return
	var turn:=Quaternion(from.normalized(),to.normalized())
	var angle:=turn.get_angle()
	if angle<0.0001:return
	turn=Quaternion.IDENTITY.slerp(turn,minf(1.0,deg_to_rad(5.0)/angle))
	var skeleton:Skeleton3D=actor.skeleton
	var index:int=actor.bones[bone]
	var parent:int=skeleton.get_bone_parent(index)
	var parent_basis:Basis=skeleton.global_basis*skeleton.get_bone_global_pose(parent).basis if parent>=0 else skeleton.global_basis
	var world_basis:Basis=Basis(turn)*skeleton.global_basis*skeleton.get_bone_global_pose(index).basis
	var local:Quaternion=(parent_basis.inverse()*world_basis).orthonormalized().get_rotation_quaternion()
	if bone=="Head":local=limit_head_rotation(actor,skeleton.get_bone_pose_rotation(index),local)
	var offset:Quaternion=(state.base[bone] as Quaternion).inverse()*local
	var angles:=offset.get_euler()*180.0/PI if bone=="Head" else _limit_angles(bone,offset.get_euler()*180.0/PI)
	var previous:Quaternion=skeleton.get_bone_pose_rotation(index)
	skeleton.set_bone_pose_rotation(index,((state.base[bone] as Quaternion)*Quaternion.from_euler(angles*PI/180.0)).normalized())
	skeleton.force_update_all_bone_transforms()
	if _accept(actor,state):state.pose[bone]=angles
	else:
		skeleton.set_bone_pose_rotation(index,previous)
		skeleton.force_update_all_bone_transforms()

static func _limit_angles(bone:String,angles:Vector3) -> Vector3:
	if bone.begins_with("upperarm"):return angles.clamp(Vector3(-120,-100,-145),Vector3(120,100,145))
	if bone.begins_with("lowerarm"):return angles.clamp(Vector3(-160,-110,-110),Vector3(160,110,110))
	if bone.begins_with("thigh"):return angles.clamp(Vector3(-100,-45,-60),Vector3(110,45,60))
	if bone.begins_with("calf"):return angles.clamp(Vector3(-160,-110,-110),Vector3(160,110,110))
	return angles.clamp(Vector3(-45,-60,-35),Vector3(45,60,35))

static func _joint_bends(actor:Node) -> Dictionary:
	var result:Dictionary={}
	for side in ["l","r"]:
		for chain in [["upperarm_","lowerarm_","hand_"],["thigh_","calf_","foot_"]]:
			var first:Vector3=point(actor,chain[1]+side)-point(actor,chain[0]+side)
			var second:Vector3=point(actor,chain[2]+side)-point(actor,chain[1]+side)
			result[chain[0]+side]=first.angle_to(second)
	return result

static func _accept(actor:Node,state:Dictionary) -> bool:
	var bends:=_joint_bends(actor)
	for joint in bends:
		if float(bends[joint])>maxf(deg_to_rad(155),float(state.bends.get(joint,0))+0.00001):
			state.blocked=true
			state["blocking_pair"]="joint limit"
			return false
	var contact:=Collision.penetrations(actor.skeleton)
	for pair in contact:
		if float(contact[pair])>maxf(0.005,float(state.contact.get(pair,0))+0.00001):
			state.blocked=true
			state["blocking_pair"]=pair
			return false
	state.contact=contact
	state.bends=bends
	return true
