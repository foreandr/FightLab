extends "res://scripts/combat_world.gd"
## Presentation and capture utilities for the original grassland studies.
## The visual-only spell study is a sibling, never a combat arena superclass.
const HEAL := Color(0.27,1.0,0.62)
const FIRE := Color(1.0,0.27,0.035)
var particles: Array = []
var hud: Label
var subtitle: Label
var progress: ProgressBar
var rng := RandomNumberGenerator.new()
var duration := 0.0
var capture_dir := ""
var report_file := ""
var capture_count := 0

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

const SPELLS=preload("res://scripts/legacy_spell_catalog.gd").SPELLS
