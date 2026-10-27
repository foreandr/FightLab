extends "res://scripts/vendor/build_duel_clips.gd"
func _initialize() -> void:
	var model := (load(MODEL) as PackedScene).instantiate()
	skeleton = model.find_child("Skeleton3D")
	var fight: AnimationLibrary = load("res://assets/combat/animations/fight_anims.res")
	var library := AnimationLibrary.new()
	for pair in [["uppercut", "uppercut", 0.95]]:
		var source := fight.get_animation(pair[1])
		var keys := []
		for frame in range(int(pair[2] * 60) + 1):
			var t := minf(frame / 60.0, pair[2])
			var pose := sample(source, minf(source.length, t / pair[2] * source.length))
			var p := global_origin(pose, "pelvis")
			move_bone(pose, "pelvis", Vector3(-p.x, 0, -p.z))
			var extension:=smoothstep(0.10,0.24,t)*(1.0-smoothstep(0.56,0.80,t))
			solve_ik(pose,"upperarm_r","lowerarm_r","hand_r",global_origin(pose,"hand_r")+Vector3.FORWARD*-0.24*extension,Vector3(-1,0.1,0.3))
			keys.append([t, pose])
		library.add_animation(pair[0], linear_animation(keys, false))
	guard=sample(fight.get_animation("guard"),0)
	var lifted:=duplicate_pose(guard)
	move_bone(lifted,"pelvis",Vector3(0,0.025,0.025))
	rotate_bone(lifted,"spine_02",Vector3.RIGHT,-8)
	solve_ik(lifted,"thigh_r","calf_r","foot_r",Vector3(-0.12,0.64,0.23),Vector3(-0.08,1.0,1.0))
	plant_foot(lifted,"l",global_origin(guard,"foot_l"))
	library.add_animation("knee",make_animation([[0.0,guard],[0.10,guard],[0.27,lifted],[0.39,lifted],[0.70,guard]],false))
	var duel: AnimationLibrary=load("res://assets/combat/animations/duel.res")
	var airborne:=sample(duel.get_animation("air"),0.35)
	for name_ in ["palm_fireball","cleaving_flick","twin_push","flame_channel","self_mend"]:
		var windup:=air_spell_pose(airborne,name_,false)
		var release:=air_spell_pose(airborne,name_,true)
		var release_at:=0.64 if name_=="cleaving_flick" else (0.8 if name_=="flame_channel" else (1.0 if name_=="twin_push" else (0.95 if name_=="self_mend" else 0.68)))
		library.add_animation("air_"+name_,make_animation([[0.0,airborne],[release_at*0.55,windup],[release_at*0.78,windup],[release_at,release],[release_at+0.18,release],[release_at+0.5,airborne]],false))
	ResourceSaver.save(library, "res://assets/combat/animations/battle.res")
	model.free()
	quit()

func air_spell_pose(base: Dictionary,name_: String,released: bool) -> Dictionary:
	var pose:=duplicate_pose(base)
	rotate_bone(pose,"spine_02",Vector3.UP,(24 if released else -28) if name_=="cleaving_flick" else (12 if released else -15))
	rotate_bone(pose,"spine_01",Vector3.RIGHT,12 if released else -14)
	var hands: Array
	match name_:
		"palm_fireball":
			hands=[Vector3(0.5,1.36,-0.12),Vector3(-0.10,1.43,0.78)] if released else [Vector3(0.5,1.22,0.18),Vector3(-0.5,1.82,-0.25)]
		"cleaving_flick":
			hands=[Vector3(0.48,1.1,-0.2),Vector3(0.5,1.2,0.54)] if released else [Vector3(0.25,1.05,0.2),Vector3(-0.65,1.76,-0.12)]
		"flame_channel":
			hands=[Vector3(0.22,1.4,0.72),Vector3(-0.22,1.4,0.72)] if released else [Vector3(0.5,1.92,-0.1),Vector3(-0.5,1.92,-0.1)]
		"twin_push":
			hands=[Vector3(-0.08,1.4,0.28),Vector3(0.08,1.4,0.36)] if released else [Vector3(0.65,1.7,0.05),Vector3(-0.65,1.7,0.05)]
		_:
			hands=[Vector3(0.7,1.5,0.1),Vector3(-0.7,1.5,0.1)] if released else [Vector3(0.12,1.22,0.35),Vector3(-0.12,1.22,0.35)]
	for side in ["l","r"]:
		var sign_:=1.0 if side=="l" else -1.0
		solve_ik(pose,"upperarm_"+side,"lowerarm_"+side,"hand_"+side,hands[0 if side=="l" else 1],Vector3(sign_,0.2,0.2))
	return pose
