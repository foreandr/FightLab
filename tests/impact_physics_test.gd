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

func prepare(team: int) -> void:
	field.clear_battle_effects()
	field.round_active = true
	field.warmup = 0
	field.intermission = 0
	for f in field.fighters:
		f.brain_enabled = false
		f.reset_fighter(Vector3.ZERO if f.team == team else Vector3(0, 0, 4))
		f.mode_length = 999
		f.invulnerability = 0
		f.rotation.y = 0 if f.team == team else PI
		for target in f.targets:
			target[0].collision_layer = 8 << f.team
	await frames(15)

func area_for(victim: Node3D, bone: String) -> Area3D:
	for target in victim.targets:
		if target[1] == bone:
			return target[0]
	return null

func shoot(victim: Node3D, bone: String, from_right: bool, speed := 12.5) -> Dictionary:
	var attacker = field.fighters[1 - victim.team]
	var area := area_for(victim, bone)
	var target := area.global_position
	if bone == "spine_03":
		target.z -= 0.285 # Clear the guarded arms and test an off-centre torso contact.
		# Isolate the torso for this joint-response test: guarded forearms may
		# physically intercept the path first, particularly on the female rig.
		for item in victim.targets:
			if str(item[0].get_meta("zone")).begins_with("arm"):
				item[0].collision_layer = 0
	var source := target + Vector3.RIGHT * (3 if from_right else -3)
	var before: int = victim.impact_physics.impacts
	field.spawn_projectile(attacker, field.SPELLS[0], source)
	field.shots[-1].velocity = (target - source).normalized() * speed
	for i in 60:
		await physics_frame
		if victim.impact_physics.impacts > before:
			break
	check(victim.impact_physics.impacts == before + 1, "Aimed test projectile must physically collide with " + bone)
	return victim.impact_physics.last_impact.duplicate(true)

func run() -> void:
	field = load("res://scenes/duel_study.tscn").instantiate()
	root.add_child(field)
	for team in 2:
		var victim = field.fighters[team]
		await prepare(team)
		var right := await shoot(victim, "spine_03", true)
		check(right.get("zone", "") == "chest", "Side torso projectile must preserve actual chest collider metadata")
		var right_torque: Vector3 = victim.impact_physics.frame_basis * right.get("torques", {}).get("spine_03", Vector3.ZERO)
		check(victim.knockback.x < 0 and absf(right_torque.y) > 0.1 and absf(right_torque.z) > 0.1, "Off-centre side impulse must shove, twist and tilt the torso")
		await frames(12)
		check(victim.impact_physics.joints.spine_03.angle.length() > 0.015, "Torso must deform through integrated joint motion")
		await prepare(team)
		var left := await shoot(victim, "spine_03", false)
		var left_torque: Vector3 = victim.impact_physics.frame_basis * left.get("torques", {}).get("spine_03", Vector3.ZERO)
		check(right_torque.y * left_torque.y < 0 and right_torque.z * left_torque.z < 0 and victim.knockback.x > 0, "Mirroring the side of impact must reverse angular and linear response")
		await prepare(team)
		var fast := await shoot(victim, "spine_03", true, 25.0)
		check(fast.impulse.length() > right.impulse.length() * 1.9 and victim.health == victim.MAX_HEALTH - 16, "Projectile speed must change momentum independently of health damage")
		await prepare(team)
		var head := await shoot(victim, "Head", true)
		check(head.get("zone", "") == "head" and head.get("bone", "") == "Head", "Head collider must generate a head-specific impulse")
		check(victim.impact_physics.joints.Head.omega.length() > victim.impact_physics.joints.calf_l.omega.length() + 0.1, "Head hit must preferentially drive head/neck, rather than a leg flinch")
		for side in ["l", "r"]:
			await prepare(team)
			var leg_area := area_for(victim, "calf_" + side)
			var hit := await shoot(victim, "calf_" + side, leg_area.global_position.x > 0)
			check(hit.get("zone", "") == "leg_" + side, "A lower-leg projectile must report the actual struck leg")
			check(victim.impact_physics.joints["calf_" + side].omega.length() > 0.1 and victim.impact_physics.support_loss > 0.2, "Leg impulse must move the struck joint and disrupt support")
			check(victim.stamina < victim.MAX_STAMINA, "Disrupted support must affect combat stamina")
			await frames(180)
			for joint in victim.impact_physics.joints.values():
				check(joint.angle.is_finite() and joint.omega.is_finite() and joint.angle.length() < 0.03, "Constrained physical response must remain finite and settle without accumulating pose drift")
		await prepare(team)
		victim.start_shield()
		await frames(15)
		var attacker = field.fighters[1 - team]
		var health: float = victim.health
		field.spawn_projectile(attacker, field.SPELLS[0], Vector3(0, 1.05, 2))
		field.shots[-1].velocity = Vector3(0, 0, -12.5)
		await frames(15)
		check(victim.health == health and victim.impact_physics.last_impact.get("zone", "") == "shield", "An absorbed spell must transmit reduced recoil through the guard without body damage")
		check(victim.knockback.length() > 0 and victim.knockback.length() < 1.0, "Blocked impact must transfer a smaller physical impulse")
	await prepare(0)
	field.fighters[1].position = Vector3(0, 0.02, 2)
	field.cast_magic(field.fighters[1], field.SPELLS[8], false)
	await frames(35)
	check(str(field.fighters[0].impact_physics.last_impact.get("zone", "")).begins_with("leg"), "Low water surge must physically contact the legs rather than synthesize a chest hit")
	# Integrator uses bounded substeps rather than frame-dependent interpolation.
	var a = load("res://scripts/impact_physics.gd").new()
	var b = load("res://scripts/impact_physics.gd").new()
	a.joints.Head.omega = Vector3(2, 1, 0)
	b.joints.Head.omega = Vector3(2, 1, 0)
	for i in 30:
		a.step(1.0 / 60)
	for i in 15:
		b.step(1.0 / 30)
	check(a.joints.Head.angle.distance_to(b.joints.Head.angle) < 0.002, "Joint dynamics must agree at 30 and 60 FPS")
	if failures.is_empty():
		print("PASS: bilateral actual head/torso/leg contacts, mirrored torque/shove, local joint response, support loss, guard transfer, settling and timestep stability")
	quit(0 if failures.is_empty() else 1)
