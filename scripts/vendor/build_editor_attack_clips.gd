extends "res://scripts/vendor/build_duel_clips.gd"
func _initialize() -> void:
	var model:Node=(load(MODEL) as PackedScene).instantiate()
	skeleton=model.find_child("Skeleton3D")
	var fight:AnimationLibrary=load("res://assets/combat/animations/fight_anims.res")
	var base:=sample(fight.get_animation("guard"),0)
	var chamber:=duplicate_pose(base)
	rotate_bone(chamber,"spine_02",Vector3.UP,-24)
	solve_ik(chamber,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.18,1.52,-0.06),Vector3(-1,0.35,-0.2))
	var strike:=duplicate_pose(base)
	rotate_bone(strike,"spine_02",Vector3.UP,32)
	solve_ik(strike,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.10,1.48,0.08),Vector3(-0.2,0.15,1))
	var library:=AnimationLibrary.new()
	library.add_animation("elbow",make_animation([[0.0,base],[0.16,chamber],[0.29,strike],[0.36,strike],[0.65,base]],false))
	guard=base
	library.add_animation("sky_palm",build_sky_palm(base))
	library.add_animation("stomp",build_stomp(base))
	library.add_animation("ground_punch",build_ground_punch(base))
	library.add_animation("body_slash",build_body_slash(base))
	library.add_animation("default_spell_cast",build_default_spell_cast(base))
	ResourceSaver.save(library,"res://assets/combat/animations/editor_attacks.res")
	model.free()
	quit()

func body_pose(base:Dictionary,drop:float,lean_forward:float,turn:float) -> Dictionary:
	var pose:=duplicate_pose(base)
	move_bone(pose,"pelvis",Vector3(0,-drop,0))
	rotate_bone(pose,"pelvis",Vector3.UP,turn*0.35)
	rotate_bone(pose,"spine_01",Vector3.RIGHT,lean_forward*0.55)
	rotate_bone(pose,"spine_02",Vector3.RIGHT,lean_forward*0.45)
	rotate_bone(pose,"spine_02",Vector3.UP,turn*0.65)
	return pose

func build_default_spell_cast(base:Dictionary) -> Animation:
	var load:=body_pose(base,0.05,2,-20)
	solve_ik(load,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.30,1.28,0.10),Vector3(-1,0,0.2))
	var hit:=body_pose(base,0.04,8,20)
	solve_ik(hit,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.13,1.39,0.79),Vector3(-1,0.1,0.2))
	solve_ik(hit,"upperarm_l","lowerarm_l","hand_l",Vector3(0.35,1.17,0.12),Vector3(1,0,0.2))
	for pose in [load,hit]:
		set_digits(pose,"r",false)
		var hand:=global_transform(pose,skeleton.find_bone("hand_r"))
		var a:=global_origin(pose,"index_01_r")-hand.origin
		var b:=global_origin(pose,"pinky_01_r")-hand.origin
		_apply_global_rotation(pose,skeleton.find_bone("hand_r"),Quaternion(a.cross(b).normalized(),Vector3.BACK))
	return bake_planted([[0.0,base],[0.14,load],[0.30,hit],[0.38,hit],[0.70,base]],["l","r"])

func set_digits(pose:Dictionary,side:String,closed:bool) -> void:
	for finger in ["thumb","index","middle","ring","pinky"]:
		for segment in range(1,3 if finger=="thumb" else 4):
			var index:=skeleton.find_bone("%s_%02d_%s"%[finger,segment,side])
			var rest:=skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			var angle:float=([35.0,45.0][segment-1] if finger=="thumb" else [85.0,95.0,65.0][segment-1]) if closed else 0.0
			pose[index][1]=rest*Quaternion(Vector3(0,0,1) if finger=="thumb" else Vector3.RIGHT,deg_to_rad(angle*(-1 if side=="l" and finger=="thumb" else 1)))

func palm_up(pose:Dictionary,side:String) -> void:
	var hand:=global_transform(pose,skeleton.find_bone("hand_"+side))
	var a:=global_origin(pose,"index_01_"+side)-hand.origin
	var b:=global_origin(pose,"pinky_01_"+side)-hand.origin
	var normal:=a.cross(b).normalized()*(-1 if side=="l" else 1)
	_apply_global_rotation(pose,skeleton.find_bone("hand_"+side),Quaternion(normal,Vector3.UP))

func bake_planted(keys:Array,sides:Array,stomp:=false) -> Animation:
	var source:=make_animation(keys,false)
	var dense:Array=[]
	var left:=global_origin(guard,"foot_l")
	var right:=global_origin(guard,"foot_r")
	for frame in range(ceili(source.length*30)+1):
		var time:=minf(float(frame)/30,source.length)
		var pose:=sample(source,time)
		for side in sides:plant_foot(pose,side,left if side=="l" else right)
		if stomp and (time<0.12 or time>=0.48):plant_foot(pose,"r",right)
		if stomp and global_origin(pose,"foot_r").y<right.y:plant_foot(pose,"r",right)
		dense.append([time,pose])
	return linear_animation(dense,false)

func build_sky_palm(base:Dictionary) -> Animation:
	var load:=body_pose(base,0.16,12,-18)
	solve_ik(load,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.25,1.02,0.22),Vector3(-1,0,0.3))
	var rise:=body_pose(base,0.04,-10,12)
	solve_ik(rise,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.25,1.73,0.30),Vector3(-1,0.2,0))
	var sky:=body_pose(base,0.0,-12,20)
	rotate_bone(sky,"neck_01",Vector3.RIGHT,-8)
	rotate_bone(sky,"Head",Vector3.RIGHT,-43)
	solve_ik(sky,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.25,2.10,0.12),Vector3(-1,0,0.2))
	solve_ik(sky,"upperarm_l","lowerarm_l","hand_l",Vector3(0.35,1.04,0.06),Vector3(1,0,0.2))
	for pose in [load,rise,sky]:
		set_digits(pose,"r",false)
		palm_up(pose,"r")
	return bake_planted([[0.0,base],[0.24,load],[0.38,rise],[0.52,sky],[0.72,sky],[1.10,base]],["l","r"])

func build_stomp(base:Dictionary) -> Animation:
	var load:=body_pose(base,0.08,8,-12)
	move_bone(load,"pelvis",Vector3(0.08,0,0))
	var lift:=body_pose(base,0.02,-6,-18)
	move_bone(lift,"pelvis",Vector3(0.10,0,0))
	solve_ik(lift,"thigh_r","calf_r","foot_r",Vector3(-0.18,0.66,0.20),Vector3(-0.2,0.4,1))
	point_foot(lift,"r",Vector3(0,-0.25,1))
	solve_ik(lift,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.38,1.53,0.05),Vector3(-1,0,0.3))
	var hit:=body_pose(base,0.20,18,14)
	rotate_bone(hit,"Head",Vector3.RIGHT,16)
	solve_ik(hit,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.38,0.91,0.38),Vector3(-1,0,0.1))
	return bake_planted([[0.0,base],[0.16,load],[0.34,lift],[0.40,lift],[0.48,hit],[0.58,hit],[0.98,base]],["l"],true)

func build_ground_punch(base:Dictionary) -> Animation:
	var load:=body_pose(base,0.22,15,-32)
	solve_ik(load,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.45,1.34,-0.12),Vector3(-1,0.2,-0.4))
	var drive:=body_pose(base,0.48,39,12)
	solve_ik(drive,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.17,0.43,0.51),Vector3(-1,-0.2,0.3))
	var hit:=body_pose(base,0.66,60,28)
	rotate_bone(hit,"Head",Vector3.RIGHT,10)
	solve_ik(hit,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.12,0.10,0.50),Vector3(-0.6,-0.3,0.3))
	solve_ik(hit,"upperarm_l","lowerarm_l","hand_l",Vector3(0.44,0.82,0.15),Vector3(1,0,0.2))
	for pose in [load,drive,hit]:set_digits(pose,"r",true)
	return bake_planted([[0.0,base],[0.26,load],[0.42,drive],[0.53,hit],[0.68,hit],[0.91,load],[1.22,base]],["l","r"])

func build_body_slash(base:Dictionary) -> Animation:
	var load:=body_pose(base,0.12,5,-48)
	move_bone(load,"pelvis",Vector3(-0.06,0,-0.04))
	solve_ik(load,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.62,1.60,-0.10),Vector3(-1,0.2,-0.2))
	solve_ik(load,"upperarm_l","lowerarm_l","hand_l",Vector3(0.22,1.31,0.28),Vector3(1,0,0.3))
	var cut:=body_pose(base,0.08,12,10)
	solve_ik(cut,"upperarm_r","lowerarm_r","hand_r",Vector3(-0.18,1.40,0.68),Vector3(-1,0,0.1))
	var follow:=body_pose(base,0.10,8,46)
	move_bone(follow,"pelvis",Vector3(0.05,0,0.07))
	solve_ik(follow,"upperarm_r","lowerarm_r","hand_r",Vector3(0.57,1.06,0.43),Vector3(0.4,-0.2,1))
	solve_ik(follow,"upperarm_l","lowerarm_l","hand_l",Vector3(0.40,1.26,-0.06),Vector3(1,0,0.1))
	rotate_bone(follow,"neck_01",Vector3.UP,-18)
	for pose in [load,cut,follow]:set_digits(pose,"r",false)
	return bake_planted([[0.0,base],[0.28,load],[0.43,cut],[0.55,follow],[0.68,follow],[1.05,base]],["l","r"])
