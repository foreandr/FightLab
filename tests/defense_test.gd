extends SceneTree
var failures: Array[String] = []
var field: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func prepare() -> void:
	field.clear_battle_effects()
	field.round_active = true
	field.intermission = 0
	field.warmup = 0
	for f in field.fighters:
		f.brain_enabled = false
		f.reset_fighter(Vector3(-2.5 if f.team == 0 else 2.5, 0.02, 0))
		f.mode_length = 999
		f.invulnerability = 0
	await frames(3)

func run() -> void:
	field = load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	await prepare()
	var attacker = field.fighters[0]
	var victim = field.fighters[1]
	victim.start_shield()
	await frames(15)
	field.spawn_projectile(attacker, field.SPELLS[0], attacker.position + Vector3.UP * 1.05)
	await frames(28)
	check(victim.health == victim.MAX_HEALTH and victim.blocks == 1, "Front shield must intercept an actual projectile before body damage")
	check(absf(victim.guard_energy - 28) < 0.01 and victim.absorbed_damage == 16, "Absorption must spend guard energy, without healing or awarding a damaging hit")
	check(attacker.damage_dealt == 0, "Absorbed hits must not count as health damage")
	check(field.shots.is_empty(), "Blocked projectile must be consumed")
	check(field.guard_bars[1].value == victim.guard_energy, "Guard meter must match remaining energy")
	# Behind the shield is deliberately unprotected.
	victim.invulnerability = 0
	var health_before: float = victim.health
	field.apply_impact(attacker, victim, field.SPELLS[0], victim.position + Vector3.UP, victim.global_basis.z)
	check(victim.health == health_before - 16, "Rear hits must bypass a forward-facing shield")
	await prepare()
	victim.start_shield()
	await frames(15)
	victim.guard_energy = 10
	field.apply_impact(attacker, victim, field.SPELLS[4], victim.shield_center(), -victim.global_basis.z)
	check(victim.guard_energy == 0 and victim.health == victim.MAX_HEALTH - 14, "A breaking guard must absorb only its remaining energy and pass overflow to health")
	check(victim.guard_breaks == 1 and not victim.shield_active(), "Guard break must end protection and trigger recovery")
	await frames(150)
	check(victim.guard_energy > 0 and victim.guard_energy <= victim.MAX_GUARD, "Guard must recharge after its recovery delay")
	# Continuous plane/disk sweep: front covered, side and rear paths uncovered.
	await prepare()
	victim.start_shield()
	await frames(15)
	var center: Vector3 = victim.shield_center()
	var normal: Vector3 = victim.global_basis.z
	check(not victim.shield_intersection(center + normal * 2, center - normal * 2).is_empty(), "Fast front sweep must hit the shield")
	check(victim.shield_intersection(center - normal * 2, center + normal * 2).is_empty(), "Rear sweep must bypass shield")
	check(victim.shield_intersection(center + normal * 2 + Vector3.UP * 2, center - normal * 2 + Vector3.UP * 2).is_empty(), "Spells outside the shield disk must miss it")
	for action in ["strafe", "retreat", "approach", "dodge_back", "roll_back"]:
		await prepare()
		var begin: Vector3 = victim.position
		victim.start_footwork(action)
		var facing := 1.0
		for i in 20:
			await physics_frame
			facing = minf(facing, victim.global_basis.z.dot(victim.flat_direction(victim.position, attacker.position)))
		var movement: Vector3 = victim.position - begin
		check(facing > 0.94, "Footwork must keep facing the rival: " + action)
		check(movement.length() > 0.20, "Footwork must physically move the body: " + action)
		if action in ["retreat", "dodge_back", "roll_back"]:
			check(victim.position.distance_to(attacker.position) > begin.distance_to(attacker.position) + 0.2, "Retreat must increase separation: " + action)
		if action == "strafe":
			check(absf(movement.z) > absf(movement.x) * 2, "Strafe must move sideways relative to rival")
	await prepare()
	for i in 400:
		field.vfx.puff(Vector3.UP, "smoke_04", 0, Vector2.ONE, Vector3.ZERO, 0.25)
	check(field.vfx.motes.size() <= field.vfx.LIMIT, "Texture particles must have a hard limit")
	await frames(90)
	check(field.vfx.motes.is_empty(), "Texture particles must expire")
	if failures.is_empty():
		print("PASS: physical shield interception, energy, overflow, guard break/recharge, rear bypass, facing-preserving footwork and VFX cleanup")
	quit(0 if failures.is_empty() else 1)
