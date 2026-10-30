extends RefCounted
## Reflect rotations across the model's sagittal plane, calibrated to each
## destination bone's rest axes. Never use negative model scale or swap hitboxes.
static func opposite(name_:String) -> String:
	if name_.ends_with("_l"):return name_.trim_suffix("_l")+"_r"
	if name_.ends_with("_r"):return name_.trim_suffix("_r")+"_l"
	return name_

static func apply(actor:Node) -> void:
	var rig:Skeleton3D=actor.skeleton
	var axes:Basis=rig.global_basis.inverse()*actor.model.global_basis
	var reflection:Basis=axes*Basis.from_scale(Vector3(-1,1,1))*axes.inverse()
	var rotations:Array[Basis]=[]
	var positions:Array[Vector3]=[]
	for index in rig.get_bone_count():
		var source:=rig.find_bone(opposite(rig.get_bone_name(index)))
		if source<0:source=index
		var source_rest:Basis=rig.get_bone_global_rest(source).basis
		var target_rest:Basis=rig.get_bone_global_rest(index).basis
		rotations.append((reflection*rig.get_bone_global_pose(source).basis*source_rest.inverse()*reflection*target_rest).orthonormalized())
		var parent:=rig.get_bone_parent(index)
		var source_parent:=rig.get_bone_parent(source)
		var parent_rest:=rig.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY
		var source_parent_rest:=rig.get_bone_global_rest(source_parent).basis if source_parent>=0 else Basis.IDENTITY
		positions.append(rig.get_bone_rest(index).origin+parent_rest.inverse()*reflection*source_parent_rest*(rig.get_bone_pose_position(source)-rig.get_bone_rest(source).origin))
	for index in rig.get_bone_count():
		var parent:=rig.get_bone_parent(index)
		var local:Basis=rotations[parent].inverse()*rotations[index] if parent>=0 else rotations[index]
		rig.set_bone_pose_rotation(index,local.get_rotation_quaternion())
		rig.set_bone_pose_position(index,positions[index])
	rig.force_update_all_bone_transforms()
