extends SceneTree
## Repeatable rendered review: both legs on both characters, with actual contacts.
## Run with --write-movie review.avi --fixed-fps 30 -s res://tests/kick_review.gd
## The review is a diagnostic only; normal play remains fully autonomous.
var arena: Node3D
var failed := false

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func reset_pair(attacker: int, distance: float) -> void:
	for i in 2:
		var f = arena.fighters[i]
		f.paused_ai = true
		f.down_time = 0
		f.reaction = 0
		f.move_index = -1
		f.balance = -100
		f.knock_velocity = Vector3.ZERO
		f.velocity = Vector3.ZERO
		f.position = Vector3((-0.5 if i == 0 else 0.5) * distance, 0.02, 0)
		f.rotation.y = PI * (0.5 if i == 0 else -0.5)
		f.player.speed_scale = 1
		f.play("fight/guard")
		f.player.advance(0)
	arena.last_contact = "KICK REVIEW • %s" % ("RED" if attacker == 0 else "BLUE")

func run() -> void:
	arena = load("res://scenes/sparring.tscn").instantiate()
	root.add_child(arena)
	for f in arena.fighters:
		f.paused_ai = true
	await frames(30)
	for attacker in 2:
		for move in [2, 6, 7, 4]:
			var f = arena.fighters[attacker]
			reset_pair(attacker, f.MOVES[move][5])
			await frames(20)
			print("REVIEW ", arena.elapsed, " ", attacker, " ", f.MOVES[move][0])
			f.start_move(move)
			var before: int = arena.contacts
			await frames(120)
			var expected_zone := "head" if "high_kick" in f.MOVES[move][0] else "body"
			if arena.contacts != before + 1 or arena.contact_events[-1].zone != expected_zone:
				failed = true
				push_error("Kick must connect once with the intended target: " + f.MOVES[move][0])
	arena.write_report()
	if not failed:
		print("PASS: left/right front kicks to body and high kicks to head on both fighters")
	quit(1 if failed else 0)
