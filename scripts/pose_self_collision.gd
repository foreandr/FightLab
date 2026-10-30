extends RefCounted
## Small capsule proxies keep pose editing responsive without mesh collision.

static func penetrations(skeleton: Skeleton3D) -> Dictionary:
	var parts: Array[Dictionary]=[]
	_add(parts,skeleton,"torso","spine_01","neck_01",0.145)
	_add(parts,skeleton,"pelvis","pelvis","spine_01",0.135)
	_add(parts,skeleton,"head","Head","Head",0.115)
	for side in ["l","r"]:
		_add(parts,skeleton,"arm_"+side,"upperarm_"+side,"lowerarm_"+side,0.055,0.28)
		_add(parts,skeleton,"forearm_"+side,"lowerarm_"+side,"hand_"+side,0.048)
		_add(parts,skeleton,"hand_"+side,"hand_"+side,"hand_"+side,0.065)
		_add(parts,skeleton,"thigh_"+side,"thigh_"+side,"calf_"+side,0.075,0.15)
		_add(parts,skeleton,"calf_"+side,"calf_"+side,"foot_"+side,0.058)
		_add(parts,skeleton,"foot_"+side,"foot_"+side,"ball_"+side,0.055)
	var result: Dictionary={}
	for i in parts.size():
		for j in range(i+1,parts.size()):
			var a: Dictionary=parts[i]
			var b: Dictionary=parts[j]
			if _connected(a.id,b.id):continue
			var start_b:Vector3=b.a
			# The hip socket must be free to fold into a crouch. Keep checking
			# the distal thigh against the torso instead of the shared socket.
			if a.id=="torso" and str(b.id).begins_with("thigh_"):start_b=start_b.lerp(b.b,0.30)
			var points:=Geometry3D.get_closest_points_between_segments(a.a,a.b,start_b,b.b)
			result[a.id+":"+b.id]=maxf(0.0,float(a.radius)+float(b.radius)-points[0].distance_to(points[1]))
	return result

static func _add(parts:Array[Dictionary],skeleton:Skeleton3D,id:String,from:String,to:String,radius:float,trim:=0.0) -> void:
	var first:=skeleton.find_bone(from)
	var second:=skeleton.find_bone(to)
	if first<0 or second<0:return
	var a:Vector3=(skeleton.global_transform*skeleton.get_bone_global_pose(first)).origin
	var b:Vector3=(skeleton.global_transform*skeleton.get_bone_global_pose(second)).origin
	if id=="head":
		var actual:Transform3D=skeleton.global_transform*skeleton.get_bone_global_pose(first)
		var rest:Basis=skeleton.global_basis*skeleton.get_bone_global_rest(first).basis
		a=actual*(rest.inverse()*skeleton.global_basis*Vector3.UP*0.08)
		b=a
	parts.append({"id":id,"a":a.lerp(b,trim),"b":b,"radius":radius})

static func _connected(a:String,b:String) -> bool:
	if a=="torso" and b in ["pelvis","head"]:return true
	for side in ["l","r"]:
		if a=="pelvis" and b=="thigh_"+side:return true
		if a=="arm_"+side and b=="forearm_"+side:return true
		if a=="forearm_"+side and b=="hand_"+side:return true
		if a=="thigh_"+side and b=="calf_"+side:return true
		if a=="calf_"+side and b=="foot_"+side:return true
	return false
