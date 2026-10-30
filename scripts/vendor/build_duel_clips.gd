extends "res://scripts/vendor/build_sparring_clips.gd"
## Reuses CC0 Quaternius locomotion and CC BY upstream flip choreography.
## Creates in-place movement clips and airborne variants of the casting library.

func _initialize() -> void:
	var model := (load(MODEL) as PackedScene).instantiate()
	skeleton = model.find_child("Skeleton3D") as Skeleton3D
	ual1 = load(UAL1)
	var ual2: AnimationLibrary = load("res://assets/combat/animations/UAL2_Standard.glb")
	var fight: AnimationLibrary = load("res://assets/combat/animations/fight_anims.res")
	var spells: AnimationLibrary = load("res://assets/combat/animations/spells.res")
	var lib := AnimationLibrary.new()
	guard = sample(spells.get_animation("idle"), 0)
	add_defense_clips(lib, fight, ual2)
	lib.add_animation("run", extract_clip(ual1.get_animation("Sprint"), 0, 0.6666667, 0.6666667, true))
	var dash_keys := []
	for frame in 41:
		var t := frame / 60.0
		var pose := sample(ual1.get_animation("Sprint"), t)
		var pelvis := skeleton.find_bone("pelvis")
		var position := global_origin(pose, "pelvis")
		move_bone(pose, "pelvis", Vector3(0, 0, -position.z))
		for side in ["l", "r"]:
			var sign_ := 1.0 if side == "l" else -1.0
			var shoulder := global_origin(pose, "upperarm_" + side)
			solve_ik(pose, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, shoulder + Vector3(sign_ * 0.12, -0.28, -0.48), Vector3(sign_, -0.2, -0.4))
		dash_keys.append([t, pose])
	lib.add_animation("dash", linear_animation(dash_keys, true))
	lib.add_animation("takeoff", extract_clip(ual1.get_animation("Jump_Start"), 0, 0.26, 0.24))
	lib.add_animation("air", extract_clip(ual2.get_animation("NinjaJump_Idle"), 0, 2.0, 2.0, true))
	lib.add_animation("land", extract_clip(ual1.get_animation("Jump_Land"), 0.13, 0.85, 0.32))
	lib.add_animation("backflip", extract_clip(fight.get_animation("flip_kick"), 0, 0.66, 0.98))
	var air_pose := sample(ual2.get_animation("NinjaJump_Idle"), 0.4)
	for name_ in spells.get_animation_list():
		if name_ == "idle":
			continue
		var source := spells.get_animation(name_)
		var keys := []
		for frame in range(int(ceil(source.length * 60)) + 1):
			var t := minf(frame / 60.0, source.length)
			var current := sample(source, t)
			var spine := skeleton.find_bone("spine_01")
			var upper_basis := global_transform(current, spine).basis
			for bone in skeleton.get_bone_count():
				var bone_name := skeleton.get_bone_name(bone)
				if bone_name.begins_with("thigh_") or bone_name.begins_with("calf_") or bone_name.begins_with("foot_") or bone_name.begins_with("ball_"):
					current[bone] = air_pose[bone].duplicate()
			var pelvis := skeleton.find_bone("pelvis")
			move_bone(current, "pelvis", Vector3(0, 0.9, 0) - global_origin(current, "pelvis"))
			current[pelvis][1] = air_pose[pelvis][1]
			var parent_basis := global_transform(current, skeleton.get_bone_parent(spine)).basis
			current[spine][1] = (parent_basis.inverse() * upper_basis).get_rotation_quaternion()
			keys.append([t, current])
		lib.add_animation("air_" + name_, linear_animation(keys, false))
	ResourceSaver.save(lib, "res://assets/combat/animations/duel.res")
	model.free()
	quit()

func add_defense_clips(lib: AnimationLibrary, fight: AnimationLibrary, ual2: AnimationLibrary) -> void:
	var walk := fight.get_animation("walk_guard")
	lib.add_animation("walk_forward", extract_clip(walk, 0, walk.length, walk.length, true))
	lib.add_animation("walk_back", extract_clip(walk, walk.length, 0, walk.length, true))
	var roll := ual1.get_animation("Roll")
	lib.add_animation("roll_back", extract_clip(roll, roll.length, 0, 0.72))
	for sign_ in [-1, 1]:
		var keys := []
		for frame in 61:
			var t := frame / 60.0
			var pose := duplicate_pose(guard)
			move_bone(pose, "pelvis", Vector3(0, -0.055 + absf(sin(t * TAU)) * 0.025, 0))
			for side in ["l", "r"]:
				var phase := fposmod(t + (0.5 if side == "r" else 0.0), 1.0)
				var foot := global_origin(guard, "foot_" + side)
				foot.x += sign_ * (lerpf(-0.24, 0.24, phase * 2) if phase < 0.5 else lerpf(0.24, -0.24, (phase - 0.5) * 2))
				foot.y += maxf(0, sin(phase * TAU)) * 0.11
				plant_foot(pose, side, foot)
			keys.append([t, pose])
		lib.add_animation("strafe_left" if sign_ > 0 else "strafe_right", linear_animation(keys, true))
	for style in ["palm", "brace"]:
		var held := duplicate_pose(guard)
		move_bone(held, "pelvis", Vector3(0, -0.07, -0.03))
		for side in ["l", "r"]:
			var sign_ := 1.0 if side == "l" else -1.0
			var target := Vector3(-sign_ * 0.16, 1.30 if side == "l" else 1.47, 0.48)
			if style == "palm":
				target = Vector3(-0.10, 1.40, 0.63) if side == "r" else Vector3(0.27, 1.08, 0.17)
			solve_ik(held, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, target, Vector3(sign_, -0.2, 0.3))
			plant_foot(held, side, global_origin(guard, "foot_" + side))
		var recoil := duplicate_pose(held)
		move_bone(recoil, "pelvis", Vector3(0, -0.045, -0.07))
		rotate_bone(recoil, "spine_02", Vector3.RIGHT, -9)
		lib.add_animation("shield_raise_" + style, make_animation([[0.0, guard], [0.22, held]], false))
		lib.add_animation("shield_hold_" + style, make_animation([[0.0, held], [0.8, held]], true))
		lib.add_animation("shield_hit_" + style, make_animation([[0.0, held], [0.08, recoil], [0.28, held]], false))
		lib.add_animation("shield_lower_" + style, make_animation([[0.0, held], [0.24, guard]], false))
	var dodge := duplicate_pose(guard)
	move_bone(dodge, "pelvis", Vector3(0, -0.18, -0.05))
	rotate_bone(dodge, "spine_02", Vector3.RIGHT, -15)
	for side in ["l", "r"]:
		plant_foot(dodge, side, global_origin(guard, "foot_" + side))
	lib.add_animation("dodge_back", make_animation([[0.0, guard], [0.10, dodge], [0.26, dodge], [0.42, guard]], false))

func extract_clip(source: Animation, from: float, to: float, length: float, loop := false) -> Animation:
	var keys := []
	var pelvis := skeleton.find_bone("pelvis")
	for frame in range(int(ceil(length * 60)) + 1):
		var t := minf(frame / 60.0, length)
		var current := sample(source, lerpf(from, to, t / length))
		var position := global_origin(current, "pelvis")
		move_bone(current, "pelvis", Vector3(0, 0, -position.z))
		keys.append([t, current])
	return linear_animation(keys, loop)

func linear_animation(keys: Array, loop: bool) -> Animation:
	var animation := make_animation(keys, loop)
	for track in animation.get_track_count():
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	return animation
