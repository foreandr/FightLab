extends Node3D
## Automatic spell-motion study. The target is fixed; only real physics contacts hit it.
const Actor = preload("res://scripts/spell_actor.gd")
const SPELLS := [
	{"id":"palm_fireball", "name":"Palm Fireball", "description":"Draw back, turn the shoulder, extend the right palm.", "release":0.68, "hand":"hand_r", "effect":"orb"},
	{"id":"cleaving_flick", "name":"Severing Flick", "description":"A compact, finger-led slash across the body.", "release":0.64, "hand":"hand_r", "effect":"slash"},
	{"id":"overhead_cleave", "name":"Cinder Cleave", "description":"Raise both hands, then cut down like a sword stroke.", "release":0.92, "hand":"both", "effect":"cleave"},
	{"id":"self_mend", "name":"Verdant Mend", "description":"Gather in both palms and draw the light toward the chest.", "release":0.95, "hand":"both", "effect":"heal"},
	{"id":"twin_push", "name":"Twin-Palm Blast", "description":"Compress an ember between the hands and push it outward.", "release":1.00, "hand":"both", "effect":"heavy"},
	{"id":"offhand_spark", "name":"Offhand Spark", "description":"A quick left-hand cast with the opposite shoulder leading.", "release":0.68, "hand":"hand_l", "effect":"spark"},
	{"id":"sun_spear", "name":"Sun Spear", "description":"Draw above the shoulder and throw a lance of fire.", "release":0.84, "hand":"hand_r", "effect":"spear"},
	{"id":"ground_sigil", "name":"Ground Sigil", "description":"Sink through the knees and press the spell into the earth.", "release":0.85, "hand":"hand_r", "effect":"ground"},
	{"id":"solar_nova", "name":"Solar Nova", "description":"Cross the arms inward, then open them into a spreading pulse.", "release":0.96, "hand":"both", "effect":"nova"},
	{"id":"flame_channel", "name":"Flame Channel", "description":"Brace both palms forward and sustain a stream of fire.", "release":0.80, "hand":"both", "effect":"beam"},
]
const CYCLE_SECONDS := 3.6
const FIRE := Color(1.0, 0.27, 0.035)
const HEAL := Color(0.27, 1.0, 0.62)
var caster: CharacterBody3D
var target: CharacterBody3D
var spell_index := 0
var cycle_time := 0.0
var elapsed := 0.0
var released := false
var playing_cast := false
var shots: Array = []
var particles: Array = []
var pulse: Dictionary = {}
var beam: MeshInstance3D
var beam_time := 0.0
var beam_connected := false
var charge: MeshInstance3D
var hud: Label
var subtitle: Label
var progress: ProgressBar
var camera: Camera3D
var casts := {}
var hits := {}
var heals := 0
var events: Array = []
var duration := 0.0
var capture_dir := ""
var report_file := ""
var capture_count := 0
var captured_cast := false
var cycle_enabled := true
var status := "Preparing"
var rng := RandomNumberGenerator.new()

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

func glow(color: Color, alpha := 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color, alpha)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func sphere(radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.material_override = glow(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func add_core(node: MeshInstance3D, radius: float, healing: bool) -> void:
	node.material_override = glow(HEAL if healing else FIRE, 0.60)
	var core := MeshInstance3D.new()
	core.name = "Core"
	var mesh := SphereMesh.new()
	mesh.radius = radius * 0.76
	mesh.height = radius * 1.52
	mesh.radial_segments = 12
	mesh.rings = 6
	core.mesh = mesh
	core.material_override = glow(Color("c0ffe0") if healing else Color("ffe68a"))
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(core)

func add_child_if_needed(node: Node) -> void:
	if node.get_parent() == null:
		add_child(node)

func make_ring(color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.95
	mesh.outer_radius = 1.0
	mesh.rings = 32
	mesh.ring_segments = 6
	node.mesh = mesh
	node.material_override = glow(color, 0.75)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func ring(point: Vector3, radius: float, color: Color, life: float) -> void:
	var node := make_ring(color)
	node.position = point
	node.scale = Vector3(radius, 0.6, radius)
	particles.append({"node":node, "velocity":Vector3.UP * 0.08, "age":0.0, "life":life, "scale":node.scale})

func mote(point: Vector3, color: Color, velocity_: Vector3, life: float, radius: float) -> void:
	var node := sphere(radius, color)
	node.position = point
	if color.r > 0.8 and color.g < 0.8:
		node.scale = Vector3(0.7, 1.7, 0.7)
	particles.append({"node":node, "velocity":velocity_, "age":0.0, "life":life, "scale":node.scale})

func step_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var item: Dictionary = particles[i]
		item.age += delta
		if item.age >= item.life:
			item.node.queue_free()
			particles.remove_at(i)
		else:
			item.node.position += item.velocity * delta
			item.node.scale = item.scale * maxf(0.02, 1 - item.age / item.life)

func crescent() -> MeshInstance3D:
	var vertices := PackedVector3Array()
	for i in 22:
		var a := float(i) / 22
		var b := float(i + 1) / 22
		var points: Array[Vector3] = []
		for t in [a, b]:
			var angle := lerpf(-1.25, 1.25, t)
			var width := 0.055 * sin(t * PI)
			var point := Vector3(sin(angle) * 0.7, cos(angle) * 0.23, 0)
			points.append(point + Vector3(0, width, 0))
			points.append(point - Vector3(0, width, 0))
		vertices.append_array(PackedVector3Array([points[0], points[1], points[2], points[2], points[1], points[3]]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var mat := glow(Color(1, 0.67, 0.25))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	return node

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(filename))

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

func build_grassland() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("5387b6")
	sky_mat.sky_horizon_color = Color("c5d6db")
	sky_mat.ground_horizon_color = Color("a7b697")
	sky_mat.ground_bottom_color = Color("637148")
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e1ebec")
	env.ambient_light_energy = 0.48
	env.fog_enabled = true
	env.fog_light_color = Color("bbcebc")
	env.fog_density = 0.006
	env.fog_sky_affect = 0.18
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -35, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	ground.mesh = plane
	var shader := Shader.new()
	shader.code = "shader_type spatial; varying vec3 p; void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float n=sin(p.x*1.3+sin(p.z*.7))*sin(p.z*.9+p.x*.3)*.5+.5; float m=sin(p.x*.19)*sin(p.z*.14)*.5+.5; ALBEDO=mix(vec3(.20,.28,.10),vec3(.36,.43,.19),n*.45+m*.55); ROUGHNESS=1.0;}"
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = shader
	ground.material_override = ground_mat
	ground.position.y = -0.025
	add_child(ground)
	var floor_body := StaticBody3D.new()
	floor_body.name = "MeadowFloor"
	var shape := BoxShape3D.new()
	shape.size = Vector3(180, 0.2, 180)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = -0.1
	floor_body.add_child(collision)
	add_child(floor_body)
	build_grass()
	for i in 18:
		var hill := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radial_segments = 24
		mesh.rings = 12
		hill.mesh = mesh
		hill.position = Vector3(-55 + i * 6.5, -2.0, -26 - rng.randf_range(0, 20))
		hill.scale = Vector3(rng.randf_range(8, 16), rng.randf_range(5, 9), rng.randf_range(10, 16))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("607d3e").darkened(rng.randf_range(0, 0.12))
		mat.roughness = 1
		hill.material_override = mat
		add_child(hill)
	camera = Camera3D.new()
	camera.position = Vector3(0.2, 2.2, 6.5)
	camera.fov = 39
	add_child(camera)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24, 18)
	hud.add_theme_font_size_override("font_size", 15)
	hud.add_theme_color_override("font_shadow_color", Color("172319"))
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(hud)
	subtitle = Label.new()
	subtitle.position = Vector2(24, 94)
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_shadow_color", Color("172319"))
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(subtitle)
	progress = ProgressBar.new()
	progress.position = Vector2(24, 150)
	progress.size = Vector2(340, 5)
	progress.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.07, 0.12, 0.08, 0.5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e9b465")
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)
	layer.add_child(progress)

func build_grass() -> void:
	var verts := PackedVector3Array()
	for angle in [0.0, 1.05, 2.10]:
		var side := Vector3(cos(angle), 0, sin(angle)) * 0.018
		var bend := Vector3(sin(angle), 0, cos(angle)) * 0.025
		var middle := bend + Vector3.UP * 0.12
		var tip: Vector3 = bend * 2.5 + Vector3.UP * (0.21 + angle * 0.015)
		verts.append_array(PackedVector3Array([-side, side, middle - side * 0.55, side, middle + side * 0.55, middle - side * 0.55, middle - side * 0.55, middle + side * 0.55, tip]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = 6500
	for i in mm.instance_count:
		var at := Vector3(rng.randf_range(-24, 24), 0, rng.randf_range(-22, 16))
		if absf(at.x) < 3 and absf(at.z) < 0.6:
			at.z += 1.2
		var basis_ := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.6, 1.4))
		mm.set_instance_transform(i, Transform3D(basis_, at))
		mm.set_instance_color(i, Color("708d3e").darkened(rng.randf_range(0, 0.35)))
	var grass := MultiMeshInstance3D.new()
	grass.multimesh = mm
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)
