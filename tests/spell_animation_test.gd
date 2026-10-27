extends SceneTree
const Registry = preload("res://scripts/spell_arena.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for gender in ["Male", "Female"]:
		var model := (load("res://assets/characters/base/Superhero_%s_FullBody.gltf" % gender) as PackedScene).instantiate()
		root.add_child(model)
		var skeleton := model.find_child("Skeleton3D") as Skeleton3D
		var player := AnimationPlayer.new()
		model.add_child(player)
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.add_animation_library("spells", load("res://assets/combat/animations/spells.res"))
		var signatures := {}
		var maximum_drift := 0.0
		for spec in Registry.SPELLS:
			player.play("spells/" + spec.id, 0)
			player.advance(0)
			var left := skeleton.find_bone("foot_l")
			var right := skeleton.find_bone("foot_r")
			var left_anchor := skeleton.get_bone_global_pose(left).origin
			var right_anchor := skeleton.get_bone_global_pose(right).origin
			for frame in int(ceil(player.current_animation_length * 60)) + 1:
				player.seek(minf(frame / 60.0, player.current_animation_length), true)
				maximum_drift = maxf(maximum_drift, skeleton.get_bone_global_pose(left).origin.distance_to(left_anchor))
				maximum_drift = maxf(maximum_drift, skeleton.get_bone_global_pose(right).origin.distance_to(right_anchor))
			player.seek(spec.release, true)
			var l := skeleton.get_bone_global_pose(skeleton.find_bone("hand_l")).origin.snapped(Vector3.ONE * 0.01)
			var r := skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).origin.snapped(Vector3.ONE * 0.01)
			signatures[str(l) + str(r)] = true
		print("SPELL POSES ", gender, " distinct_release_poses=", signatures.size(), " maximum_foot_drift_m=", maximum_drift)
		if signatures.size() != 10 or maximum_drift > 0.05:
			failed = true
			push_error("Spell clips must have distinct hand poses and keep both feet planted")
		model.free()
	if not failed:
		print("PASS: ten distinct casting poses on both rigs, with grounded feet")
	quit(1 if failed else 0)
