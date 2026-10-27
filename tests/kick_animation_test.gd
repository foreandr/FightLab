extends SceneTree
## Sample the actual imported skins and baked clips, including the female proportions.
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
		player.add_animation_library("boxing", load("res://assets/combat/animations/boxing.res"))
		for side in ["r", "l"]:
			for kind in ["front_kick", "high_kick"]:
				var support := skeleton.find_bone("ball_" + ("l" if side == "r" else "r"))
				var foot := skeleton.find_bone("ball_" + side)
				player.play("boxing/" + kind + "_" + side, 0)
				player.advance(0)
				var anchor := skeleton.get_bone_global_pose(support).origin
				var drift := 0.0
				var height := 0.0
				for frame in int(ceil(player.current_animation_length * 120)) + 1:
					player.seek(minf(frame / 120.0, player.current_animation_length), true)
					drift = maxf(drift, skeleton.get_bone_global_pose(support).origin.distance_to(anchor))
					height = maxf(height, skeleton.get_bone_global_pose(foot).origin.y)
				print("KICK POSE ", gender, " ", kind, "_", side, " support_drift_m=", drift, " peak_foot_height_m=", height)
				if drift > 0.035 or height < 0.85:
					failed = true
					push_error("Kick loses support-foot contact or fails to lift the striking foot")
		model.free()
	if not failed:
		print("PASS: all four kicks on both rigs keep the support foot planted")
	quit(1 if failed else 0)
