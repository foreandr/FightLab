extends RefCounted
## BVH parser/retargeter. Original files remain untouched and are content-addressed.
const ALIASES={
	"pelvis":["hips","hip","pelvis"],"spine_01":["spine","lowerback","abdomen"],"spine_02":["spine1","chest2"],"spine_03":["chest","spine2","chest3","chest4"],"neck_01":["neck","neck1"],"Head":["head"],
	"clavicle_l":["shoulderl","leftshoulder","leftcollar"],"upperarm_l":["upperarml","leftarm","leftshoulder"],"lowerarm_l":["forearml","lowerarml","leftforearm","leftelbow"],"hand_l":["handl","lefthand","leftwrist"],
	"clavicle_r":["shoulderr","rightshoulder","rightcollar"],"upperarm_r":["upperarmr","rightarm","rightshoulder"],"lowerarm_r":["forearmr","lowerarmr","rightforearm","rightelbow"],"hand_r":["handr","righthand","rightwrist"],
	"thigh_l":["uplegl","upperlegl","leftupleg","lefthip","leftthigh"],"calf_l":["legl","lowerlegl","leftleg","leftknee"],"foot_l":["footl","leftfoot","leftankle"],"ball_l":["toel","lefttoebase","lefttoe"],
	"thigh_r":["uplegr","upperlegr","rightupleg","righthip","rightthigh"],"calf_r":["legr","lowerlegr","rightleg","rightknee"],"foot_r":["footr","rightfoot","rightankle"],"ball_r":["toer","righttoebase","righttoe"]}
const CHILDREN={"pelvis":"spine_01","spine_01":"spine_03","spine_02":"spine_03","spine_03":"neck_01","neck_01":"Head","clavicle_l":"upperarm_l","upperarm_l":"lowerarm_l","lowerarm_l":"hand_l","clavicle_r":"upperarm_r","upperarm_r":"lowerarm_r","lowerarm_r":"hand_r","thigh_l":"calf_l","calf_l":"foot_l","foot_l":"ball_l","thigh_r":"calf_r","calf_r":"foot_r","foot_r":"ball_r"}
const EXTRA_ALIASES={"pelvis":["root","hipcenter"],"spine_01":["lowerspine"],"spine_02":["middlespine","upperback"],"spine_03":["thorax"],"neck_01":["lowerneck","upperneck"],"clavicle_l":["lclavicle"],"upperarm_l":["lshoulder","lhumerus"],"lowerarm_l":["lforearm","lradius"],"hand_l":["lhand","lwrist"],"clavicle_r":["rclavicle"],"upperarm_r":["rshoulder","rhumerus"],"lowerarm_r":["rforearm","rradius"],"hand_r":["rhand","rwrist"],"thigh_l":["lthigh","lfemur"],"calf_l":["lshin","lcalf","ltibia"],"foot_l":["lfoot"],"ball_l":["ltoe","ltoes","toesl"],"thigh_r":["rthigh","rfemur"],"calf_r":["rshin","rcalf","rtibia"],"foot_r":["rfoot"],"ball_r":["rtoe","rtoes","toesr"]}

static func parse(path:String,include_frames:=true) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null:return {"error":"Cannot read BVH"}
	var nodes:Array[Dictionary]=[]
	var stack:Array[int]=[]
	var current:=-1
	var channels:=0
	var frame_count:=0
	var frame_time:=0.0
	while not file.eof_reached():
		var line:=file.get_line().strip_edges().replace("\t"," ")
		var words:=line.split(" ",false)
		if words.is_empty():continue
		if words[0] in ["ROOT","JOINT"] or line.begins_with("End Site"):
			current=nodes.size()
			nodes.append({"name":words[1] if words[0]!="End" else "End"+str(current),"parent":stack.back() if not stack.is_empty() else -1,"offset":Vector3.ZERO,"channels":[],"first":channels})
		elif line=="{":stack.append(current)
		elif line=="}":
			if not stack.is_empty():stack.pop_back()
			current=stack.back() if not stack.is_empty() else -1
		elif words[0]=="OFFSET" and current>=0:nodes[current].offset=Vector3(float(words[1]),float(words[2]),float(words[3]))
		elif words[0]=="CHANNELS" and current>=0:
			nodes[current].channels=words.slice(2)
			channels+=int(words[1])
		elif words[0]=="Frames:":frame_count=int(words[1])
		elif line.begins_with("Frame Time:"):
			frame_time=float(words[words.size()-1])
			break
	if frame_count<2 or frame_time<=0 or channels<6:return {"error":"Invalid BVH timing/hierarchy"}
	var frames:Array[PackedFloat64Array]=[]
	if include_frames:
		while not file.eof_reached() and frames.size()<frame_count:
			var line:=file.get_line().strip_edges().replace("\t"," ")
			if line.is_empty():continue
			var values:=line.split_floats(" ",false)
			if values.size()!=channels:return {"error":"BVH frame channel mismatch"}
			frames.append(values)
		if frames.size()!=frame_count:return {"error":"Truncated BVH"}
	return {"nodes":nodes,"frames":frames,"frame_count":frame_count,"frame_time":frame_time,"duration":(frame_count-1)*frame_time,"channels":channels}

static func mapping(data:Dictionary) -> Dictionary:
	var result:Dictionary={}
	var named:Dictionary={}
	for index in data.nodes.size():
		var original:=str(data.nodes[index].name)
		var name_:String=original.get_slice(":",original.get_slice_count(":")-1).to_lower().trim_suffix("_jnt").replace("_","").replace(" ","")
		if original.to_lower().ends_with("_jnt"):
			if name_.begins_with("l"):name_="left"+name_.trim_prefix("l")
			elif name_.begins_with("r"):name_="right"+name_.trim_prefix("r")
		if not named.has(name_):named[name_]=index
	for bone in ALIASES:
		for alias in ALIASES[bone]+EXTRA_ALIASES.get(bone,[]):
			if named.has(alias):result[bone]=named[alias];break
	# Some compact humanoid exports end at Neck and omit explicit clavicle joints.
	# Use their actual hierarchy endpoints, preserving the recorded anatomy.
	if not result.has("Head") and result.has("neck_01"):
		for index in data.nodes.size():
			if int(data.nodes[index].parent)==int(result.neck_01):result.Head=index;break
	if not result.has("spine_03"):
		for index in data.nodes.size():
			if str(data.nodes[index].name).to_lower()=="spine3":result.spine_03=index;break
	for side in ["l","r"]:
		var clavicle:String="clavicle_"+str(side)
		var arm:String="upperarm_"+str(side)
		if not result.has(clavicle) and result.has(arm):
			var parent:int=data.nodes[result[arm]].parent
			if parent>=0:result[clavicle]=parent
	return result

static func world_frame(data:Dictionary,frame:int) -> Array[Transform3D]:
	var result:Array[Transform3D]=[]
	var values=data.frames[clampi(frame,0,data.frames.size()-1)]
	for node in data.nodes:
		var position:Vector3=node.offset
		var rotation:=Quaternion.IDENTITY
		for channel in node.channels.size():
			var name_:String=node.channels[channel]
			var value:float=values[int(node.first)+channel]
			var axis:=Vector3.RIGHT if name_.begins_with("X") else (Vector3.UP if name_.begins_with("Y") else Vector3.BACK)
			if name_.ends_with("rotation"):rotation=rotation*Quaternion(axis,deg_to_rad(value))
			else:
				var dimension:=0 if name_.begins_with("X") else (1 if name_.begins_with("Y") else 2)
				position[dimension]=value
		var transform:=Transform3D(Basis(rotation),position)
		if int(node.parent)>=0:transform=result[int(node.parent)]*transform
		result.append(transform)
	if str(data.get("up_axis","Y"))=="Z":
		var conversion:=Transform3D(Basis(Vector3.RIGHT,-PI/2),Vector3.ZERO)
		for index in result.size():result[index]=conversion*result[index]
	return result

static func retarget(data:Dictionary,actor:Node) -> Animation:
	var map:=mapping(data)
	if not map.has("pelvis") or not map.has("Head") or map.size()<12:return null
	var rig:Skeleton3D=actor.skeleton
	var root_node:Node=actor.player.get_node(actor.player.root_node)
	var rig_path:=str(root_node.get_path_to(rig))
	var animation:=Animation.new()
	animation.length=float(data.duration)
	var rotations:Dictionary={}
	for bone in map:
		if not actor.bones.has(bone):continue
		var track:=animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track,NodePath(rig_path+":"+bone))
		rotations[bone]=track
	var position_track:=animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(position_track,NodePath(rig_path+":pelvis"))
	var first:=world_frame(data,0)
	var source_height:float=first[map.Head].origin.y-first[map.pelvis].origin.y
	var rest_hip:=rig.get_bone_global_rest(actor.bones.pelvis)
	var target_height:float=(rig.global_basis*(rig.get_bone_global_rest(actor.bones.Head).origin-rest_hip.origin)).length()
	var scale_:float=target_height/maxf(0.1,absf(source_height))
	if map.has("thigh_r") and map.has("calf_r") and map.has("foot_r"):
		var source_leg:float=first[map.thigh_r].origin.distance_to(first[map.calf_r].origin)+first[map.calf_r].origin.distance_to(first[map.foot_r].origin)
		var target_leg:float=rig.get_bone_global_rest(actor.bones.thigh_r).origin.distance_to(rig.get_bone_global_rest(actor.bones.calf_r).origin)+rig.get_bone_global_rest(actor.bones.calf_r).origin.distance_to(rig.get_bone_global_rest(actor.bones.foot_r).origin)
		scale_=target_leg/maxf(0.1,source_leg)
	var pelvis_start:Vector3=first[map.pelvis].origin
	var frames:=ceili(animation.length*30.0)+1
	for frame in frames:
		var time:=minf(animation.length,float(frame)/30.0)
		var source:=world_frame(data,roundi(time/float(data.frame_time)))
		var desired:Dictionary={}
		for bone in rotations:
			var index:int=actor.bones[bone]
			var rest_basis:Basis=rig.global_basis*rig.get_bone_global_rest(index).basis
			var child:String=CHILDREN.get(bone,"")
			var basis:=rest_basis
			var parent_index:=rig.get_bone_parent(index)
			var parent_name:=rig.get_bone_name(parent_index) if parent_index>=0 else ""
			if desired.has(parent_name):basis=(desired[parent_name] as Basis)*(rig.global_basis*rig.get_bone_global_rest(parent_index).basis).inverse()*rest_basis
			if map.has(child) and actor.bones.has(child):
				var from:Vector3=rig.global_basis*(rig.get_bone_global_rest(actor.bones[child]).origin-rig.get_bone_global_rest(index).origin)
				var to:Vector3=source[map[child]].origin-source[map[bone]].origin
				if from.length()>0.001 and to.length()>0.001:basis=Basis(Quaternion(from.normalized(),to.normalized()))*rest_basis
			desired[bone]=basis
		# Use the shoulder line to retain torso twist, facing and full-body flips.
		if map.has("upperarm_l") and map.has("upperarm_r") and map.has("spine_01"):
			var up:Vector3=(source[map.Head].origin-source[map.pelvis].origin).normalized()
			var right:Vector3=(source[map.upperarm_r].origin-source[map.upperarm_l].origin).normalized()
			var forward:Vector3=right.cross(up).normalized()
			if forward.length()>0.5:
				var source_body:=Basis(up.cross(forward).normalized(),up,forward)
				var rest_up:Vector3=(rig.global_basis*(rig.get_bone_global_rest(actor.bones.Head).origin-rest_hip.origin)).normalized()
				var rest_right:Vector3=(rig.global_basis*(rig.get_bone_global_rest(actor.bones.upperarm_r).origin-rig.get_bone_global_rest(actor.bones.upperarm_l).origin)).normalized()
				var rest_forward:Vector3=rest_right.cross(rest_up).normalized()
				var rest_body:=Basis(rest_up.cross(rest_forward).normalized(),rest_up,rest_forward)
				for bone in ["pelvis","spine_01","spine_02","spine_03","neck_01","Head"]:
					if desired.has(bone):desired[bone]=source_body*rest_body.inverse()*rig.global_basis*rig.get_bone_global_rest(actor.bones[bone]).basis
		for bone in rotations:
			var index:int=actor.bones[bone]
			var parent:=rig.get_bone_parent(index)
			var parent_name:=rig.get_bone_name(parent) if parent>=0 else ""
			var parent_basis:Basis=desired.get(parent_name,rig.global_basis*rig.get_bone_global_rest(parent).basis if parent>=0 else rig.global_basis)
			var local:Quaternion=(parent_basis.inverse()*(desired[bone] as Basis)).orthonormalized().get_rotation_quaternion()
			animation.rotation_track_insert_key(rotations[bone],time,local)
		var delta:Vector3=(source[map.pelvis].origin-pelvis_start)*scale_
		# Keep horizontal locomotion in-place; preserve real aerial height.
		delta.x=0;delta.z=0
		var parent:=rig.get_bone_parent(actor.bones.pelvis)
		var parent_basis:Basis=rig.global_basis*rig.get_bone_global_rest(parent).basis if parent>=0 else rig.global_basis
		animation.position_track_insert_key(position_track,time,rig.get_bone_rest(actor.bones.pelvis).origin+parent_basis.inverse()*delta)
	return animation
