extends SceneTree
var failed := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for gender in ["Male", "Female"]:
		var model := (load("res://assets/characters/base/Superhero_%s_FullBody.gltf" % gender) as PackedScene).instantiate()
		root.add_child(model)
		var sk := model.find_child("Skeleton3D") as Skeleton3D
		var player := AnimationPlayer.new()
		model.add_child(player)
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.add_animation_library("duel", load("res://assets/combat/animations/duel.res"))
		var foot := sk.find_bone("foot_l")
		player.play("duel/run", 0)
		player.advance(0)
		var minimum := INF
		var maximum := -INF
		for i in 80:
			player.seek(player.current_animation_length * i / 79.0, true)
			var z := sk.get_bone_global_pose(foot).origin.z
			minimum = minf(minimum, z)
			maximum = maxf(maximum, z)
		var stride := maximum - minimum
		player.play("duel/backflip", 0)
		player.advance(0)
		var inverted := false
		for i in 120:
			player.seek(player.current_animation_length * i / 119.0, true)
			inverted = inverted or sk.get_bone_global_pose(sk.find_bone("Head")).origin.y < sk.get_bone_global_pose(sk.find_bone("pelvis")).origin.y - 0.15
		player.play("duel/air_palm_fireball", 0)
		player.advance(0)
		player.seek(0.68, true)
		var tucked := sk.get_bone_global_pose(foot).origin.y > 0.30 and sk.get_bone_global_pose(sk.find_bone("foot_r")).origin.y > 0.30
		player.play("duel/strafe_left", 0)
		player.advance(0)
		var lateral_min := INF
		var lateral_max := -INF
		for i in 60:
			player.seek(i / 60.0, true)
			lateral_min = minf(lateral_min, sk.get_bone_global_pose(foot).origin.x)
			lateral_max = maxf(lateral_max, sk.get_bone_global_pose(foot).origin.x)
		player.play("duel/roll_back", 0)
		player.advance(0)
		var roll_inverts := false
		for i in 80:
			player.seek(player.current_animation_length * i / 79.0, true)
			roll_inverts = roll_inverts or sk.get_bone_global_pose(sk.find_bone("Head")).origin.y < sk.get_bone_global_pose(sk.find_bone("pelvis")).origin.y
		var shield_hands := []
		for style in ["palm", "brace"]:
			player.play("duel/shield_hold_" + style, 0)
			player.advance(0)
			shield_hands.append(sk.get_bone_global_pose(sk.find_bone("hand_l")).origin)
		if lateral_max - lateral_min < 0.35 or not roll_inverts or shield_hands[0].distance_to(shield_hands[1]) < 0.15:
			failed = true
			push_error("Both rigs need real lateral foot motion, a backward roll inversion, and distinct shield poses")
		print("DEFENSE ", gender, " lateral_stride_m=", lateral_max-lateral_min, " roll_inverts=", roll_inverts, " shield_pose_difference_m=", shield_hands[0].distance_to(shield_hands[1]))
		print("MOVEMENT ", gender, " sprint_stride_m=", stride, " skeletal_flip_inverts=", inverted, " air_cast_tucked=", tucked)
		if stride < 0.8 or not inverted or not tucked:
			failed = true
			push_error("Movement must animate real running strides, an inverted skeletal flip, and bent legs during air casting")
		model.free()
	if not failed:
		print("PASS: running, skeletal backflips and airborne casting on both humanoid rigs")
	quit(1 if failed else 0)
