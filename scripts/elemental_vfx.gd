extends Node3D
## Layered CC0 textured effects. All particles are bounded, camera-facing quads.
const ROOT := "res://assets/combat/vfx/"
const LIMIT := 240
var camera: Camera3D
var motes: Array = []
var textures := {}
var rng := RandomNumberGenerator.new()
var fire: ShaderMaterial
var water: ShaderMaterial
var shield_shader: Shader
var ribbon_materials: Array = []
var peak := 0
var particle_shader: Shader

func _ready() -> void:
	rng.seed = 48271
	particle_shader = load(ROOT + "particle.gdshader")
	for name_ in ["flame_01", "flame_04", "smoke_04", "spark_05", "slash_02", "light_02", "circle_03", "twirl_02", "magic_01", "trace_02"]:
		textures[name_] = load(ROOT + name_ + ".png")
	fire = ShaderMaterial.new()
	fire.shader = load(ROOT + "fire.gdshader")
	water = ShaderMaterial.new()
	water.shader = load(ROOT + "water.gdshader")
	shield_shader = load(ROOT + "shield.gdshader")
	for team in 2:
		var mat := ShaderMaterial.new()
		mat.shader = load(ROOT + "ribbon.gdshader")
		mat.set_shader_parameter("water", team == 1)
		mat.set_shader_parameter("pattern", textures["flame_01" if team == 0 else "twirl_02"])
		ribbon_materials.append(mat)

func tint(team: int) -> Color:
	return Color(1.0, 0.34, 0.045) if team == 0 else Color(0.18, 0.75, 1.0)

func sprite(texture: String, size_: Vector2, color: Color) -> Sprite3D:
	var node := Sprite3D.new()
	node.texture = textures[texture]
	node.pixel_size = 1.0 / 512.0
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = false
	node.shaded = false
	node.modulate = color
	var material := ShaderMaterial.new()
	material.shader = particle_shader
	material.set_shader_parameter("mask_texture", textures[texture])
	material.set_shader_parameter("color", color)
	node.material_override = material
	node.scale = Vector3(size_.x, size_.y, 1)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Soft alpha edges work in the Compatibility renderer without bloom.
	return node

func puff(point: Vector3, texture: String, team: int, size_: Vector2, velocity_: Vector3, life: float, color: Color = Color(-1, 0, 0), grow := 0.8, spin := 0.0) -> void:
	if motes.size() >= LIMIT:
		return
	var node := sprite(texture, size_, tint(team) if color.r < 0 else color)
	add_child(node)
	node.position = point
	var angle := rng.randf_range(-PI, PI)
	motes.append({"node":node, "age":0.0, "life":life, "size":node.scale, "velocity":velocity_, "color":node.modulate, "grow":grow, "angle":angle, "spin":spin, "gravity":Vector3.UP * 0.55 if team == 0 else Vector3.DOWN * 2.5})
	peak = maxi(peak, motes.size())

func step(delta: float) -> void:
	for i in range(motes.size() - 1, -1, -1):
		var m: Dictionary = motes[i]
		m.age += delta
		if m.age >= m.life:
			m.node.queue_free()
			motes.remove_at(i)
			continue
		var t: float = m.age / m.life
		m.velocity += m.gravity * delta
		m.node.position += m.velocity * delta
		m.node.scale = m.size * lerpf(0.65, 1.0 + m.grow, t)
		m.node.modulate = Color(m.color, m.color.a * pow(1.0 - t, 1.25) * minf(1, t * 14))
		m.node.rotation.z = m.angle + m.spin * m.age
		m.node.material_override.set_shader_parameter("color", m.node.modulate)
		m.node.material_override.set_shader_parameter("spin", m.angle + m.spin * m.age)

func clear() -> void:
	for m in motes:
		m.node.queue_free()
	motes.clear()

func projectile(team: int, kind: String, radius: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh_ := SphereMesh.new()
	mesh_.radius = radius * (1.5 if team == 1 else 1.3)
	mesh_.height = mesh_.radius * 2
	mesh_.radial_segments = 20
	mesh_.rings = 10
	node.mesh = mesh_
	node.material_override = water if team == 1 else fire
	if team == 0:
		# The fire head is a soft flame silhouette, rather than an opaque red marble.
		node.mesh = null
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var corona := sprite("twirl_02" if team == 1 else "flame_04", Vector2.ONE * radius * 8.5, tint(team).lightened(0.15))
	corona.name = "Corona"
	node.add_child(corona)
	var core := sprite("light_02", Vector2.ONE * radius * 3.5, Color("d3f9ff") if team == 1 else Color("fff1ab"))
	node.add_child(core)
	if team == 0:
		var tongue := sprite("flame_01", Vector2(radius * 7.0, radius * 9.5), Color(1, 0.62, 0.12, 0.85))
		tongue.name = "Tongue"
		node.add_child(tongue)
	var ribbon := MeshInstance3D.new()
	ribbon.name = "Ribbon"
	ribbon.material_override = ribbon_materials[team]
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(ribbon)
	ribbon.top_level = true
	node.set_meta("path", [])
	if kind in ["slash", "cleave"]:
		node.mesh = null
		corona.texture = textures["slash_02"]
		corona.material_override.set_shader_parameter("mask_texture", textures["slash_02"])
		corona.scale = Vector3(1.5, 1.5, 1)
		core.visible = false
	return node

func flight(node: MeshInstance3D, velocity_: Vector3, team: int, kind: String, age: float) -> void:
	var path: Array = node.get_meta("path")
	path.push_front(node.global_position)
	if path.size() > 11:
		path.pop_back()
	var ribbon := node.get_node("Ribbon") as MeshInstance3D
	ribbon.global_transform = Transform3D.IDENTITY
	update_ribbon(ribbon, path, 0.32 if team == 0 else 0.24)
	var corona := node.get_node_or_null("Corona") as Sprite3D
	if corona:
		corona.rotation.z = age * (6.5 if team == 1 else 3.0) + (PI / 2 if kind == "cleave" else 0)
		corona.modulate.a = 0.7 + sin(age * 38) * 0.15
		corona.material_override.set_shader_parameter("color", corona.modulate)
		corona.material_override.set_shader_parameter("spin", corona.rotation.z)
	var tongue := node.get_node_or_null("Tongue") as Sprite3D
	if tongue:
		tongue.material_override.set_shader_parameter("spin", -age * 4)
	var speed := velocity_.normalized()
	var point := node.position - speed * 0.13
	if kind in ["slash", "cleave"]:
		puff(point, "slash_02", team, Vector2(0.9, 0.9), -speed * 0.8, 0.22, Color(tint(team), 0.65), 0.1)
	elif team == 0:
		puff(point, "flame_01" if rng.randf() < 0.5 else "flame_04", team, Vector2(0.6, 0.85), -velocity_ * 0.12 + Vector3.UP * 0.4, 0.32, Color(1, 0.63, 0.16, 0.95), 0.6, 2)
		puff(point - speed * 0.2, "smoke_04", team, Vector2.ONE * 0.38, -velocity_ * 0.08 + Vector3.UP * 0.5, 0.52, Color(0.24, 0.16, 0.15, 0.35), 1.5)
	else:
		puff(point, "smoke_04", team, Vector2(0.42, 0.54), -velocity_ * 0.08, 0.28, Color(0.36, 0.82, 1.0, 0.65), 0.5, 5)
		puff(point, "spark_05", team, Vector2(0.16, 0.3), Vector3(rng.randf_range(-0.8, 0.8), 0.2, rng.randf_range(-0.8, 0.8)), 0.36, Color("dbfaff"), 0.0)

func update_ribbon(node: MeshInstance3D, path: Array, width: float) -> void:
	if path.size() < 2:
		return
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in path.size():
		var p: Vector3 = path[i]
		var direction: Vector3 = path[maxi(0, i - 1)] - path[mini(path.size() - 1, i + 1)]
		if direction.length_squared() < 0.00001:
			direction = Vector3.UP
		var side := direction.normalized().cross((camera.global_position - p).normalized()).normalized()
		var t := float(i) / (path.size() - 1)
		var w := width * (1.0 - t * 0.90)
		vertices.append(p - side * w)
		vertices.append(p + side * w)
		uvs.append(Vector2(t, 0))
		uvs.append(Vector2(t, 1))
		if i < path.size() - 1:
			var a := i * 2
			indices.append_array(PackedInt32Array([a, a+1, a+2, a+1, a+3, a+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh_ := ArrayMesh.new()
	mesh_.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	node.mesh = mesh_

func burst(point: Vector3, team: int, connected: bool) -> void:
	var color := tint(team)
	puff(point, "light_02", team, Vector2.ONE * (1.3 if connected else 0.7), Vector3.ZERO, 0.18, Color("fff1c3") if team == 0 else Color("e3fcff"), 0.8)
	puff(point, "circle_03", team, Vector2.ONE * 0.55, Vector3.ZERO, 0.38, Color(color, 0.8), 3.5)
	for i in (9 if connected else 5):
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1.5), rng.randf_range(-1, 1)).normalized()
		puff(point, "flame_04" if team == 0 else "smoke_04", team, Vector2.ONE * rng.randf_range(0.28, 0.55), dir * rng.randf_range(1.1, 3.0), rng.randf_range(0.25, 0.5), Color(color.lightened(0.15), 0.85), 0.8, rng.randf_range(-5, 5))
		puff(point, "spark_05", team, Vector2(0.06, 0.27), dir * rng.randf_range(2, 4), 0.42, Color("ffe6a1") if team == 0 else Color("d9faff"), 0.0)
	for i in 3:
		puff(point, "smoke_04", team, Vector2.ONE * 0.55, Vector3(rng.randf_range(-0.4, 0.4), 0.8, rng.randf_range(-0.4, 0.4)), 0.7, Color(0.22, 0.16, 0.13, 0.3) if team == 0 else Color(0.7, 0.9, 1.0, 0.28), 1.5)

func shield(team: int) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in 18:
		for x in 18:
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				var uv: Vector2 = (Vector2(x, y) + corner) / 18.0
				var p: Vector2 = (uv - Vector2.ONE * 0.5) * 2
				surface.set_uv(uv)
				surface.set_normal(Vector3(0, 0, 1))
				surface.add_vertex(Vector3(p.x * 0.9, p.y * 0.9, 0.18 * (1 - p.length_squared())))
	node.mesh = surface.commit()
	var mat := ShaderMaterial.new()
	mat.shader = shield_shader
	mat.set_shader_parameter("tint", tint(team))
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
