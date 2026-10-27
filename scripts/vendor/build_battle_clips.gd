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
	ResourceSaver.save(library, "res://assets/combat/animations/battle.res")
	model.free()
	quit()
