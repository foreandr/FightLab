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
