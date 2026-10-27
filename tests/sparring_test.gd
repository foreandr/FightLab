extends SceneTree
## Integration checks exercise the actual skeleton and Godot physics world.
var arena: Node3D
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
	arena = load("res://scenes/sparring.tscn").instantiate()
	root.add_child(arena)
	await frames(10800)
	check(arena.punches > 0 and arena.kicks > 0, "NPCs must land punches and kicks")
	check(arena.fighters[0].landed > 0 and arena.fighters[1].landed > 0, "Both NPCs must land strikes")
	check(arena.knockdowns > 0, "Accumulated contact must cause a knockdown")
	check(arena.fighters[0].recoveries + arena.fighters[1].recoveries > 0, "Fallen fighters must recover and resume")
	check(arena.min_spacing > 0.55, "Character centers must stay separated")
	for move in arena.fighters[0].MOVES:
		var kind: String = move[0]
		check(arena.contact_types.get(kind, 0) > 0, "Missing contact type: " + kind)
	for f in arena.fighters:
		for limb in ["hand_l", "hand_r", "ball_l", "ball_r"]:
			check(f.attempted_by_limb.get(limb, 0) > 0, "Each NPC must attack with " + limb)
			check(f.landed_by_limb.get(limb, 0) > 0, "Each NPC must land with " + limb)
		check(f.skeleton.get_bone_count() == 65, "Expected shared 65-bone skeleton")
		check(f.clip != "ual1/A_TPose", "Fighters must never select T-pose")
		f.paused_ai = true
		f.down_time = 0
		f.reaction = 0
		f.move_index = -1
		f.knock_velocity = Vector3.ZERO
	# Same range and same animations, but hurtboxes removed: zero magical hits.
	for f in arena.fighters:
		for target in f.targets:
			target[0].collision_layer = 0
	arena.fighters[0].position = Vector3(-0.4, 0, 0)
	arena.fighters[1].position = Vector3(0.4, 0, 0)
	await frames(10)
	var before: int = arena.contacts
	for index in arena.fighters[0].MOVES.size():
		arena.fighters[0].start_move(index)
		await frames(100)
	check(arena.contacts == before, "Range alone must never cause a hit without collider contact")
	# Restoring colliders at long range must also produce whiffs for every move.
	for f in arena.fighters:
		for target in f.targets:
			target[0].collision_layer = 4
	arena.fighters[0].position.x = -2
	arena.fighters[1].position.x = 2
	await frames(10)
	for index in arena.fighters[0].MOVES.size():
		arena.fighters[0].start_move(index)
		await frames(100)
	check(arena.contacts == before, "Every strike must whiff at long range")
	arena.write_report()
	if failures.is_empty():
		print("PASS: both hands and legs per NPC, all eight strikes, recovery, separation and collider-disabled/distant whiffs")
	quit(0 if failures.is_empty() else 1)
