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

func prepare(distance := 4.0) -> void:
	field.clear_battle_effects()
	field.round_active = true
	field.warmup = 0
	field.intermission = 0
	for f in field.fighters:
		f.brain_enabled = false
		f.reset_fighter(Vector3(-distance * 0.5 if f.team == 0 else distance * 0.5, 0.02, 0))
		f.mode_length = 999
		f.invulnerability = 0
		for target in f.targets:
			target[0].collision_layer = 8 << f.team
	await frames(3)

func run() -> void:
	field = load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	await prepare()
	var a = field.fighters[0]
	var b = field.fighters[1]
	a.mana = 13
	var cast_count: int = field.casts.get("FIRE/palm_fireball", 0)
	field.cast_magic(a, field.SPELLS[0], false)
	check(field.shots.is_empty() and field.casts.get("FIRE/palm_fireball", 0) == cast_count and a.mana == 13, "Unaffordable release must not emit a free spell or spend partial mana")
	a.mana = 14
	field.cast_magic(a, field.SPELLS[0], false)
	check(a.mana == 0 and field.shots.size() == 1, "Exact-cost release must spend mana exactly once")
	field.clear_battle_effects()
	await frames(60)
	check(a.mana == 0, "Mana must not regenerate during post-spell delay")
	await frames(120)
	check(a.mana > 0 and a.mana < a.MAX_MANA, "Mana must recover gradually after delay")
	await prepare()
	a.mana = 2
	a.start_shield()
	check(a.mode != "shield" and a.mana == 2, "A fighter cannot raise a free shield without mana")
	a.stamina = 3
	var attempts: int = a.melee_attempts
	a.start_punch()
	check(a.mode == "recover" and a.melee_attempts == attempts and a.stamina == 3, "Exhaustion must prevent a free punch and enter recovery")
	a.start_jump("air_dash")
	check(a.mode != "takeoff" and a.stamina == 3, "Exhaustion must prevent a free jump")
	a.start_footwork("roll_back")
	check(a.mode != "roll_back" and a.stamina == 3, "Exhaustion must prevent a free roll")
	await frames(120)
	check(a.stamina > 20, "Recovery must restore stamina")
	await prepare()
	a.mana = 5
	a.select_action()
	check(a.close_combat and a.mode == "chase", "Low mana at range must choose to close distance")
	var initial_distance: float = a.flat_distance()
	await frames(22)
	check(a.flat_distance() < initial_distance - 0.5 and a.mana < 24, "Low-mana pursuit must physically close the gap")
	a.mana = 65
	a.select_action()
	check(not a.close_combat and a.mode == "retreat", "Recovered mana must switch back to magic and make space")
	# A real animated fist must contact an actual hurtbox; range alone is insufficient.
	for team in 2:
		await prepare(0.88)
		var attacker = field.fighters[team]
		var victim = field.fighters[1 - team]
		attacker.melee_sequence = 0
		var before: int = attacker.melee_hits
		attacker.start_punch()
		check(attacker.stamina == 92, "Jab must spend stamina at commitment")
		await frames(55)
		check(attacker.melee_hits == before + 1 and victim.health == victim.MAX_HEALTH - 8, "Animated jab must land exactly once on the opposing hurtbox")
		await prepare(0.88)
		attacker.melee_sequence = 0
		for target in victim.targets:
			target[0].collision_layer = 0
		attacker.start_punch()
		await frames(55)
		check(victim.health == victim.MAX_HEALTH, "Disabling hurtboxes must prevent melee proximity damage")
		await prepare(4)
		attacker.melee_sequence = 0
		attacker.start_punch()
		await frames(55)
		check(victim.health == victim.MAX_HEALTH, "Out-of-range punches must miss")
	await prepare(0.88)
	a.melee_sequence = 0
	a.start_punch()
	await frames(3)
	b.position.z += 3
	await frames(55)
	check(b.health == b.MAX_HEALTH, "Leaving the animated fist path must evade a punch")
	await prepare()
	a.mana = 1
	a.stamina = 1
	a.reset_fighter(Vector3(-2, 0.02, 0))
	check(a.mana == a.MAX_MANA and a.stamina == a.MAX_STAMINA and not a.close_combat, "New round must reset resource pools and tactical state")
	if failures.is_empty():
		print("PASS: mana costs/delay/recovery, stamina gating/recovery, resource-driven distance choices, bilateral fist contacts/misses and round reset")
	quit(0 if failures.is_empty() else 1)
