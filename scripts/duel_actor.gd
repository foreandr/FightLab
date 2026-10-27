extends "res://scripts/spell_actor.gd"
## Autonomous elemental fighter. Root movement uses CharacterBody3D physics;
## sprint, tucked flight, casting and flips all deform the licensed skeleton.
const MAX_HEALTH := 160.0
const GRAVITY := 22.0
const CAST_SPEED := 1.65
const PLAN := ["cast", "run", "jump_cast", "dash", "cast", "flip", "run", "air_dash", "cast"]
var arena: Node3D
var rival: CharacterBody3D
var health := MAX_HEALTH
var brain_enabled := true
var mode := "idle"
var mode_time := 0.0
var mode_length := 0.3
var decision := 0
var spell_cursor := 0
var current_spell: Dictionary = {}
var cast_time := 0.0
var did_release := false
var air_momentum := Vector3.ZERO
var knockback := Vector3.ZERO
var jump_kind := "jump_cast"
var air_clock := 0.0
var air_dash_used := false
var dodge_cooldown := 0.0
var last_threat := -1
var invulnerability := 0.0
var healed_this_round := false
var actions := {}
var damage_dealt := 0.0
var damage_taken := 0.0
var distance_run := 0.0
var max_height := 0.0
var air_casts := 0
var hits_scored := 0
var ko_count := 0
var ground_spawn := Vector3.ZERO
var trail_clock := 0.0

func _ready() -> void:
	super._ready()
	player.add_animation_library("duel", load(BASE + "animations/duel.res"))
	collision_layer = 2 << team
	collision_mask = 1 | (2 << (1 - team))
	for item in targets:
		item[0].collision_layer = 8 << team
	decision = team * 3
	spell_cursor = team * 4
	mode_length = 0.25 + team * 0.4

func count_action(name_: String) -> void:
	actions[name_] = actions.get(name_, 0) + 1
	arena.events.append({"time":arena.elapsed, "event":"action", "team":team, "action":name_})

func reset_fighter(location: Vector3) -> void:
	position = location
	ground_spawn = location
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	air_momentum = Vector3.ZERO
	model.position = Vector3.ZERO
	health = MAX_HEALTH
	mode = "idle"
	mode_time = 0
	mode_length = 0.25 + team * 0.4
	current_spell = {}
	healed_this_round = false
	invulnerability = 0.4
	player.speed_scale = 1
	clip = ""
	play("spells/idle")
	player.advance(0)
	rotation.y = PI / 2 if team == 0 else -PI / 2

func choose_spell(air: bool) -> Dictionary:
	if not air and health < MAX_HEALTH * 0.38 and not healed_this_round:
		return arena.SPELLS[3]
	var index: int = spell_cursor % arena.SPELLS.size()
	spell_cursor += 1
	var spec: Dictionary = arena.SPELLS[index]
	if spec.effect == "heal":
		if healed_this_round or health > MAX_HEALTH * 0.75:
			spec = arena.SPELLS[4]
	if air and spec.effect in ["heal", "ground", "nova"]:
		var air_moves := [0, 1, 2, 4, 5, 6, 9]
		spec = arena.SPELLS[air_moves[spell_cursor % air_moves.size()]]
	return spec

func start_cast(air: bool) -> void:
	mode = "cast"
	mode_time = 0
	cast_time = 0
	did_release = false
	current_spell = choose_spell(air)
	var animation: String = "duel/air_" + current_spell.id if air else "spells/" + current_spell.id
	clip = ""
	play(animation, CAST_SPEED)
	mode_length = player.get_animation(animation).length / CAST_SPEED + 0.08
	count_action("air_cast" if air else "cast")
	if air:
		air_casts += 1

func start_jump(kind: String) -> void:
	mode = "takeoff"
	mode_time = 0
	mode_length = 0.14
	jump_kind = kind
	air_dash_used = false
	var away := flat_direction(rival.global_position, global_position)
	var side := Vector3(-away.z, 0, away.x) * (1 if team == 0 else -1)
	air_momentum = (away * 0.35 + side).normalized() * 4.2
	if kind == "flip":
		air_momentum = (away + side * 0.25).normalized() * 4.8
	if position.length() > 6.0:
		air_momentum = flat_direction(position, Vector3.ZERO) * 4.2
	clip = ""
	play("duel/takeoff", 1.35)
	count_action(kind)

func launch() -> void:
	velocity.y = 10.8 if jump_kind != "air_dash" else 11.5
	air_clock = 0
	arena.movement_burst(self, false)
	if jump_kind == "flip":
		mode = "flip"
		mode_time = 0
		clip = ""
		play("duel/backflip")
	else:
		start_cast(true)

func select_action() -> void:
	var choice: String = PLAN[decision % PLAN.size()]
	decision += 1
	if health < MAX_HEALTH * 0.35 and not healed_this_round:
		choice = "cast"
	if choice in ["jump_cast", "flip", "air_dash"]:
		start_jump(choice)
	elif choice == "cast":
		start_cast(false)
	elif choice == "dash":
		mode = "dash"
		mode_time = 0
		mode_length = 0.24
		var away := flat_direction(rival.position, position)
		var side := Vector3(-away.z, 0, away.x) * (1 if decision % 2 == 0 else -1)
		air_momentum = (side + away * 0.2).normalized() * 10.5
		if position.length() > 6:
			air_momentum = flat_direction(position, Vector3.ZERO) * 10.5
		count_action("dash")
	else:
		mode = "run"
		mode_time = 0
		mode_length = rng.randf_range(0.7, 1.1)
		count_action("run")

func flat_direction(from: Vector3, to: Vector3) -> Vector3:
	var direction := to - from
	direction.y = 0
	return direction.normalized()

func tick(delta: float) -> void:
	var pending_release := false
	mode_time += delta
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	invulnerability = maxf(0, invulnerability - delta)
	player.speed_scale = 1
	var before := global_position
	var desired := Vector3.ZERO
	var can_decide: bool = brain_enabled and arena.round_active
	if health <= 0:
		mode = "ko"
	elif not arena.round_active:
		mode = "idle"
		play("spells/idle")
	if can_decide and mode in ["idle", "run"] and dodge_cooldown <= 0:
		var threat: int = arena.incoming_threat(self)
		if threat >= 0 and threat != last_threat:
			last_threat = threat
			if rng.randf() < 0.35:
				dodge_cooldown = 2.7
				start_jump("flip")
	if mode == "ko":
		if clip != "ual1/Death01":
			play("ual1/Death01", 1.3)
	elif mode == "takeoff":
		if mode_time >= mode_length:
			launch()
	elif mode == "cast":
		cast_time += delta * CAST_SPEED
		face_rival(delta)
		if not did_release and cast_time >= current_spell.release:
			did_release = true
			pending_release = true
		if mode_time >= mode_length:
			mode = "idle" if is_on_floor() else "air"
			mode_time = 0
			mode_length = 0.12
	elif mode == "hit":
		if mode_time >= mode_length:
			mode = "idle" if is_on_floor() else "air"
			mode_time = 0
			mode_length = 0.10
	elif mode == "land":
		if mode_time >= mode_length:
			mode = "idle"
			mode_time = 0
			mode_length = 0.08
	elif mode == "flip":
		face_rival(delta)
	elif mode == "air":
		play("duel/air")
		face_rival(delta)
	elif mode == "dash":
		desired = air_momentum
		if mode_time >= mode_length:
			mode = "idle"
			mode_time = 0
			mode_length = 0.08
	elif mode == "run":
		var away := flat_direction(rival.position, position)
		var distance := Vector2(position.x - rival.position.x, position.z - rival.position.z).length()
		var side := Vector3(-away.z, 0, away.x) * (1 if team == 0 else -1)
		desired = (side * 0.95 + away * (4.8 - distance) * 0.7).normalized() * 4.8
		if position.length() > 6:
			desired = flat_direction(position, Vector3.ZERO) * 4.8
		if mode_time >= mode_length:
			mode = "idle"
			mode_time = 0
			mode_length = 0.06
	elif mode == "idle":
		play("spells/idle")
		face_rival(delta)
		if can_decide and mode_time >= mode_length:
			select_action()
	if not is_on_floor() and mode != "takeoff":
		air_clock += delta
		desired = air_momentum
		if jump_kind == "air_dash" and not air_dash_used and air_clock > 0.25 and mode == "cast":
			air_dash_used = true
			air_momentum = flat_direction(position, rival.position) * 8.5
			count_action("air_dash_burst")
		if air_dash_used and air_clock > 0.46:
			air_momentum = air_momentum.move_toward(Vector3.ZERO, delta * 12)
	if desired.length() > 0.2 and mode in ["run", "dash"]:
		rotation.y = lerp_angle(rotation.y, atan2(desired.x, desired.z), minf(1, delta * 14))
		play("duel/dash" if mode == "dash" else "duel/run", clampf(desired.length() / 3.1, 0.7, 3.5))
	var acceleration := 45.0 if mode == "dash" or not is_on_floor() else 24.0
	velocity.x = move_toward(velocity.x, desired.x + knockback.x, delta * acceleration)
	velocity.z = move_toward(velocity.z, desired.z + knockback.z, delta * acceleration)
	knockback = knockback.move_toward(Vector3.ZERO, delta * 7)
	if is_on_floor() and velocity.y <= 0 and mode != "takeoff":
		velocity.y = -0.1
	else:
		velocity.y -= GRAVITY * delta
	var was_air := not is_on_floor()
	move_and_slide()
	# Stabilize tiny solver penetration at the known flat meadow surface.
	if position.y < 0 and position.y > -0.12 and velocity.y <= 0:
		position.y = 0
		apply_floor_snap()
		position.y = maxf(0, position.y)
	if is_on_floor() and was_air and mode in ["flip", "air", "cast", "hit"]:
		if mode != "cast" or did_release:
			mode = "land"
			mode_time = 0
			mode_length = 0.24
			clip = ""
			play("duel/land", 1.3)
			count_action("land")
			arena.movement_burst(self, true)
	distance_run += Vector2(position.x - before.x, position.z - before.z).length()
	max_height = maxf(max_height, position.y)
	player.advance(delta)
	if mode == "cast" and player.is_playing() and not current_spell.effect in ["heal", "ground", "nova"]:
		# Add a bounded chest aim layer to the existing cast, rather than rotating
		# the whole character when firing up at a jumper or down from the air.
		var toward: Vector3 = rival.bone_point("spine_03") - bone_point("spine_03")
		var pitch := clampf(atan2(toward.y, maxf(0.4, Vector2(toward.x, toward.z).length())), -0.42, 0.42)
		var spine := skeleton.find_bone("spine_02")
		var parent := skeleton.get_bone_parent(spine)
		var parent_basis := skeleton.get_bone_global_pose(parent).basis
		var basis_ := skeleton.get_bone_global_pose(spine).basis
		var aimed := Basis(Quaternion(Vector3.RIGHT, -pitch * 0.85)) * basis_
		skeleton.set_bone_pose_rotation(spine, (parent_basis.inverse() * aimed).get_rotation_quaternion())
	var lowest := INF
	for bone in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		var i: int = bones[bone]
		lowest = minf(lowest, skeleton.get_bone_global_pose(i).origin.y - skeleton.get_bone_global_rest(i).origin.y - 0.01)
	model.position.y = maxf(0, -lowest) if is_on_floor() else 0.0
	if pending_release:
		# Emit after movement, the cast pose and the chest aim layer are evaluated.
		arena.cast_magic(self, current_spell, not is_on_floor())
	trail_clock += delta
	if trail_clock > 0.065 and (mode in ["dash", "flip"] or (not is_on_floor() and velocity.length() > 7)):
		trail_clock = 0
		arena.speed_trail(self)

func face_rival(delta: float) -> void:
	if rival == null:
		return
	var direction := flat_direction(position, rival.position)
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1, delta * 18))

func receive_magic(amount: float, direction: Vector3, attacker: CharacterBody3D) -> bool:
	if health <= 0 or invulnerability > 0 or not arena.round_active:
		return false
	var applied := minf(health, amount)
	health = maxf(0, health - applied)
	damage_taken += applied
	attacker.damage_dealt += applied
	attacker.hits_scored += 1
	invulnerability = 0.16
	knockback = Vector3(direction.x, 0, direction.z).normalized() * 2.5
	if health <= 0:
		mode = "ko"
		ko_count += 1
		clip = ""
		play("ual1/Death01", 1.3)
		arena.finish_round(attacker.team)
	else:
		mode = "hit"
		mode_time = 0
		mode_length = 0.22
		clip = ""
		play("ual1/Hit_Chest", 1.5)
	return true
