extends RefCounted
## Rejects malformed clips and severe hand/foot penetration into the torso core.
const LIMB_JOINTS:={"hand_l":"left hand","hand_r":"right hand","foot_l":"left foot","foot_r":"right foot"}

static func inspect(animation:Animation,skeleton:Skeleton3D) -> Dictionary:
	if animation==null:return {"ok":false,"reason":"Animation resource is missing."}
	if skeleton==null:return {"ok":false,"reason":"Character rig is missing."}
	if animation.length<0.05 or animation.length>60.0:return {"ok":false,"reason":"Animation length is outside the supported range."}
	if animation.get_track_count()<13:return {"ok":false,"reason":"Animation is missing body-part tracks."}
	var tracks:Array[Dictionary]=[]
	for index in animation.get_track_count():
		var path:=str(animation.track_get_path(index))
		var colon:=path.rfind(":")
		if colon<0:return {"ok":false,"reason":"A track is not attached to a character bone."}
		var bone_name:=path.substr(colon+1)
		var bone:=skeleton.find_bone(bone_name)
		if bone<0:return {"ok":false,"reason":"This rig is missing the %s bone."%bone_name}
		if animation.track_get_type(index) not in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D]:continue
		for key in animation.track_get_key_count(index):
			var value=animation.track_get_key_value(index,key)
			if value is Quaternion and (not value.is_finite() or absf(value.length()-1.0)>0.01):return {"ok":false,"reason":"A bone rotation is invalid."}
			if value is Vector3 and not value.is_finite():return {"ok":false,"reason":"A bone position is invalid."}
		tracks.append({"index":index,"bone":bone,"type":animation.track_get_type(index)})
	var torso:=skeleton.find_bone("spine_03")
	if torso<0:torso=skeleton.find_bone("spine_02")
	if torso<0:return {"ok":false,"reason":"Character rig has no torso reference bone."}
	var limb_bones:Dictionary={}
	for bone_name in LIMB_JOINTS:
		var index:=skeleton.find_bone(bone_name)
		if index<0:return {"ok":false,"reason":"Character rig is missing the %s bone."%bone_name}
		limb_bones[bone_name]=index
	var saved_positions:Array[Vector3]=[]
	var saved_rotations:Array[Quaternion]=[]
	var saved_scales:Array[Vector3]=[]
	for bone in skeleton.get_bone_count():
		saved_positions.append(skeleton.get_bone_pose_position(bone))
		saved_rotations.append(skeleton.get_bone_pose_rotation(bone))
		saved_scales.append(skeleton.get_bone_pose_scale(bone))
	var samples:=clampi(ceili(animation.length*20.0),2,240)
	var penetrations:Dictionary={"hand_l":0,"hand_r":0,"foot_l":0,"foot_r":0}
	for sample in samples:
		skeleton.reset_bone_poses()
		var time:=animation.length*float(sample)/float(samples-1)
		for track in tracks:
			var track_index:int=track.index
			if track.type==Animation.TYPE_ROTATION_3D:skeleton.set_bone_pose_rotation(track.bone,animation.rotation_track_interpolate(track_index,time))
			elif track.type==Animation.TYPE_POSITION_3D:skeleton.set_bone_pose_position(track.bone,animation.position_track_interpolate(track_index,time))
		skeleton.force_update_all_bone_transforms()
		var torso_pose:=skeleton.get_bone_global_pose(torso)
		var torso_center:=torso_pose.origin
		var inverse_basis:=torso_pose.basis.orthonormalized().inverse()
		for limb in limb_bones:
			var point:=skeleton.get_bone_global_pose(int(limb_bones[limb])).origin
			var local:=inverse_basis*(point-torso_center)
			# Only flag deep penetration into the chest, not normal guard/contact poses.
			var normalized:=Vector3(local.x/0.18,local.y/0.24,local.z/0.14).length_squared()
			if normalized<0.30:penetrations[limb]=int(penetrations[limb])+1
	var restore_ok:=true
	for bone in skeleton.get_bone_count():
		skeleton.set_bone_pose_position(bone,saved_positions[bone])
		skeleton.set_bone_pose_rotation(bone,saved_rotations[bone])
		skeleton.set_bone_pose_scale(bone,saved_scales[bone])
	skeleton.force_update_all_bone_transforms()
	for limb in penetrations:
		if int(penetrations[limb])>=maxi(2,ceili(samples*0.08)):
			return {"ok":false,"reason":"The %s penetrates deeply into the torso for multiple frames."%LIMB_JOINTS[limb],"clipping_frames":penetrations}
	return {"ok":restore_ok,"reason":"","samples":samples,"clipping_frames":penetrations}
