extends SceneTree
## Controlled projectile impacts; no direct damage/pose injection.
var field: Node3D

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func picture(name_: String) -> void:
	if not field.capture_dir.is_empty():
		field.capture.call_deferred(name_ + ".png")

func run() -> void:
	field = load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera = true
	field.camera.position = Vector3(3.3, 2.2, 4.8)
	field.camera.look_at(Vector3(0, 0.95, 0))
	field.camera.fov = 36
	for team in 2:
		for spec in [["spine_03", true, "SIDE TORSO RIGHT"], ["spine_03", false, "SIDE TORSO LEFT"], ["Head", true, "HEAD"], ["calf_l", true, "LEFT LEG"], ["calf_r", false, "RIGHT LEG"]]:
			field.clear_battle_effects()
			field.round_active = true
			field.warmup = 0
			field.intermission = 0
			for f in field.fighters:
				f.brain_enabled = false
				f.reset_fighter(Vector3.ZERO if f.team == team else Vector3(0, 0, 5))
				f.mode = "review"
				f.mode_length = 999
				f.invulnerability = 0
				f.rotation.y = 0 if f.team == team else PI
				f.clip = ""
				f.play("fight/guard")
				for target in f.targets:
					target[0].collision_layer = 8 << f.team
			await frames(20)
			var victim = field.fighters[team]
			var attacker = field.fighters[1 - team]
			var area: Area3D
			for target in victim.targets:
				if target[1] == spec[0]:
					area = target[0]
			var point := area.global_position
			if spec[0] == "spine_03":
				point.z -= 0.285
				# Torso-only review isolates this region from guarded forearms.
				for target in victim.targets:
					if str(target[0].get_meta("zone")).begins_with("arm"):
						target[0].collision_layer = 0
			var source := point + Vector3.RIGHT * (3 if spec[1] else -3)
			field.status = spec[2]
			var impacts: int = victim.impact_physics.impacts
			picture("%d_%s_before" % [team, spec[2].replace(" ", "_")])
			field.spawn_projectile(attacker, field.SPELLS[0], source)
			field.shots[-1].velocity = (point - source).normalized() * 12.5
			for i in 60:
				await physics_frame
				if victim.impact_physics.impacts > impacts:
					break
			for frame in [6, 12, 24]:
				await frames(6 if frame == 6 else (6 if frame == 12 else 12))
				picture("%d_%s_%02d" % [team, spec[2].replace(" ", "_"), frame])
			await frames(90)
	field.write_report()
	quit()
