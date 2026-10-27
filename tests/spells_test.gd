extends SceneTree
var field: Node3D
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	field = load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	var caster_start: Vector3 = field.caster.position
	var target_start: Vector3 = field.target.position
	await frames(2165)
	check(field.SPELLS.size() == 10 and field.casts.size() == 10, "Automatically cycle through ten casting animations")
	for spec in field.SPELLS:
		check(field.casts.get(spec.id, 0) == 1, "Each gesture must appear in the first cycle: " + spec.id)
		var animation: Animation = field.caster.player.get_animation("spells/" + spec.id)
		check(animation != null and animation.length > spec.release, "Valid skeletal release timing: " + spec.id)
		if spec.effect != "heal":
			check(field.hits.get(spec.id, 0) == 1, "Offensive spell must physically hit once: " + spec.id)
	check(field.heals == 1, "Self-heal must activate once")
	check(field.target.spell_hits == 9, "Nine offensive spells; self-heal must not hit the target")
	check(field.target.position.distance_to(target_start) < 0.001, "Target must remain stationary")
	check(field.caster.position.distance_to(caster_start) < 0.001, "Caster must retain the demonstration spacing")
	check(field.shots.is_empty() and field.pulse.is_empty() and field.beam_time <= 0, "Spent spells must clean up")
	await frames(2160)
	for spec in field.SPELLS:
		check(field.casts.get(spec.id, 0) == 2, "Automatic loop must repeat each casting motion: " + spec.id)
	check(field.target.spell_hits == 18 and field.heals == 2, "Second cycle must repeat nine hits and one self-heal")
	check(field.target.position.distance_to(target_start) < 0.001, "Target remains fixed across repeated cycles")
	check(field.shots.is_empty() and field.particles.is_empty() and field.pulse.is_empty(), "Repeated cycles must not accumulate effects")
	field.cycle_enabled = false
	field.target.collision_layer = 0
	await frames(2)
	var before: int = field.target.spell_hits
	for spec in field.SPELLS:
		if spec.effect != "heal":
			field.release_spell(spec)
			await frames(130)
	check(field.target.spell_hits == before, "No projectile, pulse, or beam may hit with target collision disabled")
	field.target.collision_layer = 8
	field.target.position = target_start
	await frames(2)
	field.spawn_shot(field.caster.bone_point("hand_r"), field.SPELLS[0])
	field.target.position.z += 8
	await frames(130)
	check(field.target.spell_hits == before, "A fireball must miss when its target leaves the flight path")
	field.target.position = target_start
	field.write_report()
	if failures.is_empty():
		print("PASS: two full ten-cast cycles, physical impacts, self-heal, stationary target, cleanup and collision-disabled/moving-target misses")
	quit(0 if failures.is_empty() else 1)
