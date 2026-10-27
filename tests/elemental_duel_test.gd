extends SceneTree
var field: Node3D
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	root.size = Vector2i(1152, 720)
	field = load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	print("TEST VIEWPORT ", field.get_viewport().get_visible_rect().size)
	var health_valid := true
	var bars_valid := true
	var floor_valid := true
	var lowest_root := 0.0
	var debug_misses := 0
	var visible := 0
	var samples := 0
	for i in 7200:
		await physics_frame
		for f in field.fighters:
			health_valid = health_valid and f.health >= 0 and f.health <= f.MAX_HEALTH
			bars_valid = bars_valid and absf(field.health_bars[f.team].value - f.health) < 0.01
			floor_valid = floor_valid and f.position.y > -0.04
			if f.position.y < lowest_root:
				lowest_root = f.position.y
				if lowest_root < -0.04:
					print("FLOOR SAMPLE ", field.elapsed, " ", f.team, " ", f.mode, " ", f.position, " grounded=", f.is_on_floor())
			if field.elapsed > 1.0 and field.round_active:
				samples += 1
				if field.camera.is_position_in_frustum(f.bone_point("Head")):
					visible += 1
				elif debug_misses < 10:
					debug_misses += 1
					print("CAMERA MISS ",field.elapsed," team=",f.team," head=",f.bone_point("Head")," camera=",field.camera.position)
	check(health_valid and bars_valid, "Health must stay bounded and match both HUD bars")
	check(floor_valid, "Fighters must not fall through the meadow")
	check(field.round_number >= 2 and field.wins[0] + field.wins[1] > 0, "Physical damage must produce a knockout and automatic round restart")
	check(field.minimum_spacing > 0.43, "Character-body collision must keep the fighters separated")
	check(field.max_radius < 13, "AI must keep action in the meadow camera area")
	check(field.peak_effects < 160, "Short-lived effects must remain bounded")
	var coverage := float(visible) / maxi(1, samples)
	print("CAMERA head visibility=", coverage)
	check(coverage > 0.95, "Camera must frame both fighters during aerial exchanges")
	for f in field.fighters:
		check(f.damage_dealt > 100 and f.hits_scored > 4, "Both elemental fighters must land damaging spells")
		check(f.max_height > 1.8 and f.air_casts > 2, "Both fighters must jump and cast while airborne")
		check(f.distance_run > 30, "Both fighters must run around the field")
		for action in ["run", "dash", "flip", "land", "air_dash_burst"]:
			check(f.actions.get(action, 0) > 0, "Missing dynamic action: " + action)
		for action in ["shield", "strafe", "retreat", "approach", "dodge_back", "roll_back"]:
			check(f.actions.get(action, 0) > 0, "Missing defensive footwork action: " + action)
		check(f.blocks > 0 and f.absorbed_damage > 0, "Both fighters must absorb real incoming spells in autonomous combat")
	check(field.vfx.peak <= field.vfx.LIMIT, "Texture effects must respect their hard particle limit")
	# Same spacing and animations, but no hurtbox collision: no proximity damage.
	field.clear_battle_effects()
	field.round_active = true
	field.warmup = 0
	field.intermission = 0
	for f in field.fighters:
		f.brain_enabled = false
		f.reset_fighter(Vector3(-2 if f.team == 0 else 2, 0.02, 0))
		f.mode_length = 999
		for item in f.targets:
			item[0].collision_layer = 0
	await frames(32)
	var attacker = field.fighters[0]
	var victim = field.fighters[1]
	for spec in field.SPELLS:
		if spec.effect == "heal":
			continue
		attacker.mode = "cast"
		attacker.mode_time = 0
		attacker.mode_length = 999
		attacker.current_spell = spec
		attacker.did_release = true
		field.cast_magic(attacker, spec, false)
		await frames(130)
	check(attacker.health == attacker.MAX_HEALTH and victim.health == victim.MAX_HEALTH, "No spell may damage a fighter with disabled hurtbox collisions")
	field.clear_battle_effects()
	var previous_clashes: int = field.clashes
	field.spawn_projectile(attacker, field.SPELLS[0], Vector3(-1, 1.2, 0))
	field.spawn_projectile(victim, field.SPELLS[0], Vector3(1, 1.2, 0))
	await frames(30)
	check(field.clashes == previous_clashes + 1 and field.shots.is_empty(), "Opposing projectiles must collide into a steam clash")
	check(attacker.health == attacker.MAX_HEALTH and victim.health == victim.MAX_HEALTH, "A projectile clash must not deal phantom damage")
	field.clear_battle_effects()
	for f in field.fighters:
		f.mode = "idle"
		f.mode_time = 0
		f.mode_length = 999
		for item in f.targets:
			item[0].collision_layer = 8 << f.team
	await frames(2)
	field.spawn_projectile(attacker, field.SPELLS[0], attacker.bone_point("hand_r"))
	victim.position.z += 8
	await frames(130)
	check(victim.health == victim.MAX_HEALTH, "A launched projectile must miss when the target leaves its predicted path")
	check(field.shots.is_empty() and field.pulses.is_empty() and field.channels.is_empty(), "Finished spell instances must clean up")
	field.write_report()
	if failures.is_empty():
		print("PASS: elemental AI, running/jumps/flips/air casts, health, KOs, camera framing, cleanup and collision-driven misses")
	quit(0 if failures.is_empty() else 1)
