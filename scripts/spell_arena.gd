extends "res://scripts/legacy_arena_host.gd"
## Automatic spell-motion study. The target is fixed; only real physics contacts hit it.
const Actor = preload("res://scripts/spell_actor.gd")
const CYCLE_SECONDS := 3.6
var caster: CharacterBody3D
var target: CharacterBody3D
var spell_index := 0
var cycle_time := 0.0
var released := false
var playing_cast := false
var pulse: Dictionary = {}
var beam: MeshInstance3D
var beam_time := 0.0
var beam_connected := false
var charge: MeshInstance3D
var captured_cast := false
var cycle_enabled := true

func _ready() -> void:
	rng.seed = 59127
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):
			duration = float(arg.trim_prefix("--duration="))
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
		if arg.begins_with("--report-file="):
			report_file = arg.trim_prefix("--report-file=")
	build_grassland()
	caster = Actor.new()
	caster.team = 0
	caster.position = Vector3(-1.9, 0, 0)
	caster.rotation.y = PI / 2
	add_child(caster)
	target = Actor.new()
	target.team = 1
	target.is_target = true
	target.position = Vector3(1.9, 0, 0)
	target.rotation.y = -PI / 2
	add_child(target)
	charge = sphere(0.08, FIRE)
	add_core(charge, 0.08, false)
	charge.visible = false
	beam = MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.035
	tube.bottom_radius = 0.065
	tube.height = 1
	tube.radial_segments = 10
	beam.mesh = tube
	beam.material_override = glow(FIRE, 0.8)
	beam.visible = false
	add_child(beam)
	begin_cast(0)

func begin_cast(index: int) -> void:
	for shot in shots:
		shot.node.queue_free()
	shots.clear()
	for item in particles:
		item.node.queue_free()
	particles.clear()
	if not pulse.is_empty():
		pulse.node.queue_free()
		pulse = {}
	beam_time = 0
	beam.visible = false
	spell_index = posmod(index, SPELLS.size())
	cycle_time = 0
	released = false
	captured_cast = false
	playing_cast = true
	status = "Preparing"
	var spec: Dictionary = SPELLS[spell_index]
	caster.clip = ""
	caster.play("spells/" + spec.id)
	casts[spec.id] = casts.get(spec.id, 0) + 1
	charge.material_override = glow(HEAL if spec.effect == "heal" else FIRE, 0.60)
	charge.get_node("Core").material_override = glow(Color("c0ffe0") if spec.effect == "heal" else Color("ffe68a"))
	subtitle.text = "%02d / 10   %s\n%s" % [spell_index + 1, spec.name, spec.description]
	print("CAST t=%.3f " % elapsed, spec.id)

func hand_origin(hand: String) -> Vector3:
	if hand == "both":
		return (caster.bone_point("hand_l") + caster.bone_point("hand_r")) * 0.5
	return caster.bone_point(hand)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if cycle_enabled:
		cycle_time += delta
	var spec: Dictionary = SPELLS[spell_index]
	caster.advance_pose(delta)
	target.advance_pose(delta)
	if playing_cast and cycle_time > caster.player.get_animation("spells/" + spec.id).length + 0.1:
		playing_cast = false
		caster.play("spells/idle")
	charge.visible = cycle_enabled and not released and cycle_time > 0.20
	if charge.visible:
		charge.global_position = hand_origin(spec.hand)
		charge.scale = Vector3.ONE * (0.45 + 0.5 * clampf(cycle_time / spec.release, 0, 1))
	if cycle_enabled and not released and cycle_time >= spec.release:
		released = true
		charge.visible = false
		release_spell(spec)
	step_shots(delta)
	step_pulse(delta)
	step_beam(delta)
	step_particles(delta)
	progress.value = 100 * cycle_time / CYCLE_SECONDS
	hud.text = "FIGHTLAB   /   GRASSLAND SPELL STUDY\nStationary target • 3.8 m spacing     %s\nN next cast   •   Space slow motion   •   R restart   •   Esc quit" % status
	if cycle_enabled and cycle_time >= CYCLE_SECONDS:
		begin_cast(spell_index + 1)
	if not capture_dir.is_empty() and released and not captured_cast and cycle_time >= spec.release + 0.08:
		captured_cast = true
		capture_count += 1
		capture.call_deferred("spell_%02d_%s.png" % [capture_count, spec.id])
	if duration > 0 and elapsed >= duration:
		write_report()
		get_tree().quit()

func release_spell(spec: Dictionary) -> void:
	var origin := hand_origin(spec.hand)
	status = "Released"
	events.append({"time":elapsed, "event":"release", "spell":spec.id, "origin":[origin.x, origin.y, origin.z]})
	if spec.effect == "heal":
		heals += 1
		status = "Self heal"
		for i in 3:
			ring(caster.position + Vector3.UP * (0.12 + i * 0.48), 0.46, HEAL, 1.1)
		for i in 22:
			var point := caster.position + Vector3(rng.randf_range(-0.32, 0.32), rng.randf_range(0.15, 1.65), rng.randf_range(-0.32, 0.32))
			mote(point, HEAL, Vector3.UP * rng.randf_range(0.4, 0.8), 0.8, 0.026)
	elif spec.effect == "nova":
		var node := make_ring(FIRE)
		node.position = caster.position + Vector3.UP * 0.10
		pulse = {"node":node, "age":0.0, "hit":false, "spell":spec.id}
	elif spec.effect == "beam":
		beam_time = 0.9
		beam_connected = false
		beam.visible = true
	elif spec.effect == "ground":
		ring(caster.position + Vector3.UP * 0.04, 0.60, FIRE, 0.9)
		spawn_shot(caster.position + Vector3(0.45, 0.25, 0), spec)
	else:
		spawn_shot(origin, spec)

func spawn_shot(origin: Vector3, spec: Dictionary) -> void:
	var aim := target.position + Vector3.UP * (0.35 if spec.effect == "ground" else 1.15)
	var node: MeshInstance3D
	if spec.effect == "slash" or spec.effect == "cleave":
		node = crescent()
	else:
		node = sphere(0.17 if spec.effect == "heavy" else 0.105, FIRE)
		add_core(node, 0.17 if spec.effect == "heavy" else 0.105, false)
	add_child_if_needed(node)
	node.global_position = origin
	var velocity_ := (aim - origin).normalized() * (8.5 if spec.effect == "spear" else 6.8)
	node.look_at(camera.global_position if spec.effect == "slash" or spec.effect == "cleave" else origin + velocity_)
	if spec.effect == "cleave":
		node.rotate_object_local(Vector3.FORWARD, PI / 2)
	if spec.effect == "spear":
		node.scale = Vector3(0.50, 0.50, 3.4)
	if spec.effect == "ground":
		node.scale.y = 0.6
	shots.append({"node":node, "velocity":velocity_, "age":0.0, "trail":0.0, "spell":spec.id})

func step_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var node: Node3D = shot.node
		var from := node.global_position
		var to: Vector3 = from + shot.velocity * delta
		var query := PhysicsRayQueryParameters3D.create(from, to, 8)
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		shot.age += delta
		shot.trail += delta
		if not result.is_empty():
			register_hit(shot.spell, result.position)
			node.queue_free()
			shots.remove_at(i)
		elif shot.age > 2.0:
			node.queue_free()
			shots.remove_at(i)
		else:
			node.global_position = to
			if shot.trail >= 0.02:
				shot.trail = 0
				var flame_drift: Vector3 = -shot.velocity * 0.035 + Vector3(rng.randf_range(-0.16, 0.16), 0.65, rng.randf_range(-0.16, 0.16))
				mote(to, Color("ffb23e"), flame_drift, 0.22, 0.055)
				mote(to + Vector3.UP * 0.04, FIRE, flame_drift * 1.4, 0.20, 0.045)

func step_pulse(delta: float) -> void:
	if pulse.is_empty():
		return
	pulse.age += delta
	var radius: float = 0.15 + pulse.age * 4.9
	pulse.node.scale = Vector3(radius, 1, radius)
	if not pulse.hit:
		var shape := SphereShape3D.new()
		shape.radius = radius
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, caster.position + Vector3.UP * 0.7)
		query.collision_mask = 8
		var result := get_world_3d().direct_space_state.intersect_shape(query, 1)
		if not result.is_empty():
			pulse.hit = true
			register_hit(pulse.spell, target.position + Vector3.UP * 0.8)
	if pulse.age > 1.05:
		pulse.node.queue_free()
		pulse = {}

func step_beam(delta: float) -> void:
	if beam_time <= 0:
		beam.visible = false
		return
	beam_time -= delta
	var from := hand_origin("both")
	var end := target.position + Vector3.UP * 1.13
	var query := PhysicsRayQueryParameters3D.create(from, end + (end - from).normalized(), 8)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		end = result.position
		if not beam_connected:
			beam_connected = true
			register_hit("flame_channel", end)
	var direction := end - from
	beam.position = (end + from) * 0.5
	beam.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	beam.scale = Vector3(1 + 0.15 * sin(elapsed * 33), direction.length(), 1)
	if Engine.get_physics_frames() % 4 == 0:
		mote(end, FIRE, Vector3(rng.randf_range(-0.4, 0.4), 0.5, rng.randf_range(-0.4, 0.4)), 0.25, 0.035)

func register_hit(spell: String, point: Vector3) -> void:
	target.spell_hit()
	hits[spell] = hits.get(spell, 0) + 1
	status = "Impact"
	events.append({"time":elapsed, "event":"hit", "spell":spell, "point":[point.x, point.y, point.z]})
	print("SPELL HIT t=%.3f " % elapsed, spell)
	for i in 11:
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.0, 1.2), rng.randf_range(-1, 1))
		mote(point, FIRE, direction * 1.4, 0.40, 0.025)
	ring(Vector3(point.x, 0.045, point.z), 0.36, FIRE, 0.35)

func write_report() -> void:
	var report := {"seconds":elapsed, "casts":casts, "hits":hits, "heals":heals, "events":events, "target_hits":target.spell_hits, "caster_position":[caster.position.x, caster.position.y, caster.position.z], "target_position":[target.position.x, target.position.y, target.position.z], "fps":Engine.get_frames_per_second(), "renderer":RenderingServer.get_video_adapter_name()}
	var summary := report.duplicate()
	summary.erase("events")
	print("REPORT ", JSON.stringify(summary))
	var destination := report_file if not report_file.is_empty() else capture_dir.path_join("report.json")
	if not report_file.is_empty() or not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var file := FileAccess.open(destination, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		if event.keycode == KEY_R:
			Engine.time_scale = 1
			get_tree().reload_current_scene()
		if event.keycode == KEY_SPACE:
			Engine.time_scale = 0.35 if Engine.time_scale == 1 else 1.0
		if event.keycode == KEY_N:
			begin_cast(spell_index + 1)
