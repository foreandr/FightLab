extends Node3D
## Autonomous contact-driven sparring. See assets/combat/NOTICE.md.
const FighterScene = preload("res://scripts/sparring_fighter.gd")
var fighters: Array = []
var elapsed := 0.0
var contacts := 0
var punches := 0
var kicks := 0
var knockdowns := 0
var last_contact := "Closing distance"
var hud: Label
var camera: Camera3D
var capture_dir := ""
var duration := 0.0
var capture_count := 0
var next_capture := 1.0
var min_spacing := INF
var contact_types := {}

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
		if arg.begins_with("--duration="):
			duration = float(arg.trim_prefix("--duration="))
	build_arena()
	for i in 2:
		var f = FighterScene.new()
		f.team = i
		f.position = Vector3(-1.65 if i == 0 else 1.65, 0.02, 0)
		add_child(f)
		fighters.append(f)
		f.contact.connect(on_contact)
	fighters[0].opponent = fighters[1]
	fighters[1].opponent = fighters[0]

func _physics_process(delta: float) -> void:
	elapsed += delta
	for f in fighters:
		f.step(delta)
	for f in fighters:
		f.update_targets()
	for f in fighters:
		f.detect_contact(delta)
	var midpoint: Vector3 = (fighters[0].position + fighters[1].position) * 0.5
	var spacing: float = fighters[0].position.distance_to(fighters[1].position)
	min_spacing = minf(min_spacing, spacing)
	camera.position = camera.position.lerp(midpoint + Vector3(0.3, 2.5, 5.2 + maxf(0, spacing - 2.0) * 0.5), delta * 2)
	camera.look_at(midpoint + Vector3(0, 0.95, 0))
	hud.text = "FIGHTLAB   /   AUTONOMOUS SPARRING\n\nRED  %d     •     BLUE  %d\n%d punches   /   %d kicks   /   %d knockdowns\n%s\n\nR  restart     Space  slow motion     Esc  quit" % [fighters[0].landed, fighters[1].landed, punches, kicks, knockdowns, last_contact]
	if not capture_dir.is_empty() and elapsed >= next_capture and capture_count < 32:
		next_capture += 0.55
		capture_count += 1
		capture.call_deferred("frame_%03d.png" % capture_count)
	if duration > 0 and elapsed >= duration:
		write_report()
		get_tree().quit()

func on_contact(kind: String, attacker: int, zone: String, speed: float, fell: bool) -> void:
	contacts += 1
	contact_types[kind] = contact_types.get(kind, 0) + 1
	if "kick" in kind:
		kicks += 1
	else:
		punches += 1
	if fell:
		knockdowns += 1
	last_contact = "%s • %s → %s • %.1f m/s%s" % ["RED" if attacker == 0 else "BLUE", kind, zone, speed, " • DOWN" if fell else ""]
	print("CONTACT ", last_contact)
	if not capture_dir.is_empty() and contacts <= 12:
		capture.call_deferred("contact_%02d_%s.png" % [contacts, kind])

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(filename))

func write_report() -> void:
	var report := {"seconds": elapsed, "contacts": contacts, "punches": punches, "kicks": kicks, "knockdowns": knockdowns, "types": contact_types, "minimum_center_spacing": min_spacing, "fps": Engine.get_frames_per_second(), "renderer": RenderingServer.get_video_adapter_name()}
	print("REPORT ", JSON.stringify(report))
	if not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("report.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		if event.keycode == KEY_SPACE:
			Engine.time_scale = 0.35 if Engine.time_scale == 1 else 1.0

func box(size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	mesh.material_override = mat
	mesh.position = at
	add_child(mesh)

func build_arena() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("161d29")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce6fa")
	env.ambient_light_energy = 0.4
	world.environment = env
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -30, 0)
	key.light_energy = 0.85
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 145, 0)
	fill.light_color = Color("b9cfff")
	fill.light_energy = 0.3
	add_child(fill)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(24, 0.2, 24)
	collision.shape = shape
	collision.position.y = -0.1
	floor_body.add_child(collision)
	add_child(floor_body)
	box(Vector3(24, 0.2, 24), Vector3(0, -0.11, 0), Color("222c38"))
	box(Vector3(7, 0.03, 6), Vector3(0, -0.014, 0), Color("707e8a"))
	for x in [-3.4, 3.4]:
		box(Vector3(0.035, 0.005, 5.8), Vector3(x, 0.006, 0), Color("bac6cf"))
	for z in [-2.9, 2.9]:
		box(Vector3(6.8, 0.005, 0.035), Vector3(0, 0.006, z), Color("bac6cf"))
	for x in [-3.5, 3.5]:
		for z in [-3.0, 3.0]:
			box(Vector3(0.12, 1.4, 0.12), Vector3(x, 0.7, z), Color("293b4c"))
	for y in [0.5, 0.9, 1.3]:
		box(Vector3(7, 0.035, 0.035), Vector3(0, y, -3), Color("c3cbd2"))
	camera = Camera3D.new()
	camera.fov = 40
	camera.position = Vector3(0.3, 2.5, 6.0)
	add_child(camera)
	camera.current = true
	var overlay := CanvasLayer.new()
	add_child(overlay)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 17)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 1)
	overlay.add_child(hud)
