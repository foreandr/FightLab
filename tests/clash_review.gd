extends SceneTree
## Isolated visual review of the same continuous projectile collision used in fights.
func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	var field := (load("res://scenes/duel_study.tscn") as PackedScene).instantiate()
	root.add_child(field)
	field.warmup = 0
	field.round_active = true
	for f in field.fighters:
		f.brain_enabled = false
		f.reset_fighter(Vector3(-2 if f.team == 0 else 2, 0.02, 0))
		f.mode_length = 999
	await frames(45)
	field.spawn_projectile(field.fighters[0], field.SPELLS[0], Vector3(-1, 1.2, 0))
	field.spawn_projectile(field.fighters[1], field.SPELLS[0], Vector3(1, 1.2, 0))
	await frames(14)
	if not field.capture_dir.is_empty():
		field.capture.call_deferred("steam_clash.png")
	await frames(65)
	field.write_report()
	if field.clashes != 1:
		push_error("The opposed spells must produce one clash")
	quit(0 if field.clashes == 1 else 1)
