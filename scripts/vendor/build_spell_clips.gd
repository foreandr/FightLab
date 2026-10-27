extends "res://scripts/vendor/build_sparring_clips.gd"
## Original FightLab casting poses composed with the vendored MIT skeletal helpers.
## Uses the Quaternius CC0 rig and neutral pose; contains no extracted game motion.

func _initialize() -> void:
	var model := (load(MODEL) as PackedScene).instantiate()
	skeleton = model.find_child("Skeleton3D") as Skeleton3D
	ual1 = load(UAL1)
	guard = sample(ual1.get_animation("Idle"), 0.0)
	arm(guard, "l", Vector3(0.27, 1.09, 0.18))
	arm(guard, "r", Vector3(-0.27, 1.09, 0.18))
	# Open hands from the rig rest pose, rather than the boxing fist pose.
	for bone in skeleton.get_bone_count():
		var name_ := skeleton.get_bone_name(bone)
		if name_.begins_with("index_") or name_.begins_with("middle_") or name_.begins_with("ring_") or name_.begins_with("pinky_") or name_.begins_with("thumb_"):
			guard[bone][1] = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
	var lib := AnimationLibrary.new()
	var breathe := pose(-0.01, 0, 1)
	lib.add_animation("idle", bake([[0.0, guard], [1.5, breathe], [3.0, guard]], true))
	lib.add_animation("palm_fireball", palm(false))
	lib.add_animation("offhand_spark", palm(true))
	lib.add_animation("cleaving_flick", flick())
	lib.add_animation("overhead_cleave", chop())
	lib.add_animation("self_mend", heal())
	lib.add_animation("twin_push", push())
	lib.add_animation("sun_spear", spear())
	lib.add_animation("ground_sigil", sigil())
	lib.add_animation("solar_nova", nova())
	lib.add_animation("flame_channel", channel())
	ResourceSaver.save(lib, "res://assets/combat/animations/spells.res")
	model.free()
	quit()

func pose(sink := 0.0, turn := 0.0, lean_angle := 0.0) -> Dictionary:
	var out := duplicate_pose(guard)
	move_bone(out, "pelvis", Vector3(0, sink, 0.025 * absf(turn) / 25.0))
	hip_turn(out, turn)
	lean(out, lean_angle, 0)
	return out

func arm(out: Dictionary, side: String, target: Vector3) -> void:
	var sign_ := 1.0 if side == "l" else -1.0
	solve_ik(out, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, target, Vector3(sign_ * 0.65, -0.3, 0.05))

func palm(left: bool) -> Animation:
	var side := "l" if left else "r"
	var sign_ := 1.0 if left else -1.0
	var wind := pose(-0.025, -sign_ * 15, 3)
	arm(wind, side, Vector3(sign_ * 0.30, 1.30, 0.08))
	var cast := pose(-0.015, sign_ * 25, -5)
	arm(cast, side, Vector3(sign_ * 0.12, 1.38, 0.68))
	rotate_bone(cast, "hand_" + side, Vector3.RIGHT, -35)
	var settle := pose(-0.01, sign_ * 12, 0)
	arm(settle, side, Vector3(sign_ * 0.13, 1.29, 0.48))
	return bake([[0.0, guard], [0.35, wind], [0.68, cast], [0.90, settle], [1.65, guard]])

func flick() -> Animation:
	var wind := pose(-0.025, -20, 0)
	arm(wind, "r", Vector3(-0.47, 1.48, 0.15))
	var cut := pose(-0.015, 20, -3)
	arm(cut, "r", Vector3(-0.04, 1.48, 0.61))
	rotate_bone(cut, "hand_r", Vector3.UP, 35)
	var follow := pose(-0.01, 25, 0)
	arm(follow, "r", Vector3(0.40, 1.40, 0.30))
	return bake([[0.0, guard], [0.40, wind], [0.64, cut], [0.82, follow], [1.65, guard]])

func chop() -> Animation:
	var raised := pose(-0.025, -12, 6)
	arm(raised, "r", Vector3(-0.10, 1.97, 0.12))
	arm(raised, "l", Vector3(0.08, 1.94, 0.18))
	var strike := pose(-0.07, 18, -18)
	arm(strike, "r", Vector3(-0.06, 1.03, 0.64))
	arm(strike, "l", Vector3(0.07, 1.08, 0.60))
	var finish := pose(-0.09, 22, -12)
	arm(finish, "r", Vector3(0.0, 0.83, 0.46))
	arm(finish, "l", Vector3(0.13, 0.90, 0.40))
	return bake([[0.0, guard], [0.58, raised], [0.92, strike], [1.10, finish], [1.95, guard]])

func heal() -> Animation:
	var gather := pose(-0.035, 0, -3)
	arm(gather, "l", Vector3(0.15, 1.02, 0.28))
	arm(gather, "r", Vector3(-0.15, 1.02, 0.28))
	var heart := pose(-0.01, 0, 4)
	arm(heart, "l", Vector3(0.12, 1.40, 0.20))
	arm(heart, "r", Vector3(-0.12, 1.40, 0.20))
	var lift := pose(0, 0, 6)
	arm(lift, "l", Vector3(0.30, 1.55, 0.23))
	arm(lift, "r", Vector3(-0.30, 1.55, 0.23))
	return bake([[0.0, guard], [0.45, gather], [0.95, heart], [1.35, lift], [2.15, guard]])

func push() -> Animation:
	var charge := pose(-0.08, 0, 7)
	arm(charge, "l", Vector3(0.18, 1.23, 0.18))
	arm(charge, "r", Vector3(-0.18, 1.23, 0.18))
	var cast := pose(-0.025, 0, -10)
	arm(cast, "l", Vector3(0.17, 1.30, 0.65))
	arm(cast, "r", Vector3(-0.17, 1.30, 0.65))
	return bake([[0.0, guard], [0.65, charge], [1.00, cast], [1.20, cast], [2.05, guard]])

func spear() -> Animation:
	var draw := pose(-0.03, -25, 8)
	arm(draw, "r", Vector3(-0.27, 1.74, -0.20))
	arm(draw, "l", Vector3(0.22, 1.40, 0.44))
	var cast := pose(-0.02, 30, -9)
	arm(cast, "r", Vector3(-0.10, 1.70, 0.60))
	var follow := pose(-0.04, 35, -12)
	arm(follow, "r", Vector3(0.05, 1.05, 0.58))
	return bake([[0.0, guard], [0.55, draw], [0.84, cast], [1.08, follow], [1.95, guard]])

func sigil() -> Animation:
	var gather := pose(-0.12, -10, -12)
	arm(gather, "r", Vector3(-0.18, 1.16, 0.14))
	var press := pose(-0.30, 10, -27)
	arm(press, "r", Vector3(-0.12, 0.30, 0.46))
	arm(press, "l", Vector3(0.30, 0.98, 0.12))
	return bake([[0.0, guard], [0.40, gather], [0.85, press], [1.12, press], [2.00, guard]])

func nova() -> Animation:
	var coil := pose(-0.09, 0, -6)
	arm(coil, "l", Vector3(-0.08, 1.33, 0.26))
	arm(coil, "r", Vector3(0.08, 1.38, 0.30))
	var spread := pose(-0.01, 0, 10)
	arm(spread, "l", Vector3(0.70, 1.53, 0.02))
	arm(spread, "r", Vector3(-0.70, 1.53, 0.02))
	return bake([[0.0, guard], [0.55, coil], [0.96, spread], [1.30, spread], [2.10, guard]])

func channel() -> Animation:
	var focus := pose(-0.045, -10, 3)
	arm(focus, "l", Vector3(0.14, 1.27, 0.30))
	arm(focus, "r", Vector3(-0.14, 1.27, 0.30))
	var cast := pose(-0.025, 8, -5)
	arm(cast, "l", Vector3(0.14, 1.38, 0.60))
	arm(cast, "r", Vector3(-0.14, 1.38, 0.60))
	var pulse := duplicate_pose(cast)
	rotate_bone(pulse, "spine_02", Vector3.RIGHT, -3)
	return bake([[0.0, guard], [0.45, focus], [0.80, cast], [1.10, pulse], [1.40, cast], [1.68, pulse], [2.30, guard]])

func bake(keys: Array, loop := false) -> Animation:
	var dense := []
	var length: float = keys[-1][0]
	var feet := {"l": global_origin(guard, "foot_l"), "r": global_origin(guard, "foot_r")}
	var segment := 0
	for frame in range(int(ceil(length * 60)) + 1):
		var t := minf(frame / 60.0, length)
		while segment < keys.size() - 2 and t > keys[segment + 1][0]:
			segment += 1
		var f := clampf((t - keys[segment][0]) / (keys[segment + 1][0] - keys[segment][0]), 0, 1)
		f = smoothstep(0, 1, f)
		var current := {}
		for bone in skeleton.get_bone_count():
			var a: Array = keys[segment][1][bone]
			var b: Array = keys[segment + 1][1][bone]
			current[bone] = [(a[0] as Vector3).lerp(b[0], f), (a[1] as Quaternion).slerp(b[1], f)]
		plant_foot(current, "l", feet.l)
		plant_foot(current, "r", feet.r)
		dense.append([t, current])
	var anim := make_animation(dense, loop)
	for track in anim.get_track_count():
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	return anim
