extends SceneTree
## Controlled visual review using the actual actor/cast/shield/physics paths.
var field: Node3D

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func reset_pair() -> void:
	field.clear_battle_effects()
	field.round_active = true
	field.warmup = 0
	field.intermission = 0
	for f in field.fighters:
		f.brain_enabled = false
		f.reset_fighter(Vector3(-2.2 if f.team == 0 else 2.2, 0.02, 0))
		f.mode_length = 999
		f.invulnerability = 0
	await frames(20)

func picture(name_: String) -> void:
	if not field.capture_dir.is_empty():
		field.capture.call_deferred(name_ + ".png")

func run() -> void:
	field = load("res://scenes/duel_study.tscn").instantiate()
	root.add_child(field)
	for team in 2:
		for style in 2:
			await reset_pair()
			var attacker = field.fighters[1 - team]
			var defender = field.fighters[team]
			attacker.spell_cursor = 0 if style == 0 else 6
			attacker.start_cast(false)
			await frames(12)
			defender.actions["shield"] = style + team
			defender.start_shield()
			await frames(19)
			picture("shield_%d_%d_before" % [team, style])
			await frames(13)
			picture("shield_%d_%d_impact" % [team, style])
			await frames(80)
	for action in ["strafe", "retreat", "dodge_back", "roll_back"]:
		await reset_pair()
		for f in field.fighters:
			f.start_footwork(action)
		await frames(17)
		picture(action)
		await frames(65)
	for team in 2:
		await reset_pair()
		var attacker = field.fighters[team]
		attacker.spell_cursor = 9
		attacker.start_cast(false)
		await frames(40)
		picture("channel_%d" % team)
		await frames(85)
	field.write_report()
	quit()
