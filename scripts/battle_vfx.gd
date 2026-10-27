extends "res://scripts/elemental_vfx.gd"
var chips: Array = []

func _ready() -> void:
	super._ready()
	water = ShaderMaterial.new()
	water.shader = load(ROOT + "ice.gdshader")
	ribbon_materials[1] = ShaderMaterial.new()
	ribbon_materials[1].shader = load(ROOT + "ice_beam.gdshader")
	var speed := ShaderMaterial.new()
	speed.shader = load(ROOT + "ice_beam.gdshader")
	speed.set_shader_parameter("tint", Color("ffdf62"))
	ribbon_materials.append(speed)

func tint(team: int) -> Color:
	return [Color("ff641b"), Color("8ee9ff"), Color("ffdb51")][clampi(team, 0, 2)]

func projectile(team: int, kind: String, radius: float) -> MeshInstance3D:
	var node := super.projectile(mini(team, 1), kind, radius)
	if team == 1:
		var mesh_ := SphereMesh.new()
		mesh_.radius = radius * 1.4
		mesh_.height = radius * 3.4
		mesh_.radial_segments = 8
		mesh_.rings = 4
		node.mesh = mesh_
		node.material_override = water
	elif team==2:
		node.mesh=null
		for child in node.get_children():
			if child is Sprite3D:
				child.modulate=tint(2)
				child.material_override.set_shader_parameter("color",tint(2))
	return node

func burst(point: Vector3, team: int, connected: bool) -> void:
	if team==2:
		puff(point,"light_02",2,Vector2.ONE*0.8,Vector3.ZERO,0.15,Color("fff1ad"),0.5)
		for i in 7:
			puff(point,"spark_05",2,Vector2(0.1,0.4),Vector3(rng.randf_range(-2,2),rng.randf_range(0.2,2),rng.randf_range(-2,2)),0.25,Color("ffe46c"),0.3)
		return
	if team != 1:
		super.burst(point, mini(team, 1), connected)
		return
	puff(point, "light_02", 1, Vector2.ONE * 1.1, Vector3.ZERO, 0.18, Color("ebfcff"), 0.5)
	puff(point, "smoke_04", 1, Vector2.ONE * 0.8, Vector3.UP * 0.4, 0.6, Color(0.7, 0.9, 1, 0.5), 1.2)
	for i in 10:
		if chips.size() >= 90:
			break
		var node := MeshInstance3D.new()
		var mesh_ := SphereMesh.new()
		mesh_.radius = 0.035
		mesh_.height = 0.17
		mesh_.radial_segments = 5
		mesh_.rings = 2
		node.mesh = mesh_
		node.material_override = water
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		node.position = point
		chips.append({"node":node,"age":0.0,"velocity":Vector3(rng.randf_range(-2,2),rng.randf_range(1,3),rng.randf_range(-2,2))})

func step(delta: float) -> void:
	super.step(delta)
	for i in range(chips.size()-1,-1,-1):
		var item: Dictionary = chips[i]
		item.age += delta
		item.velocity += Vector3.DOWN * 8 * delta
		item.node.position += item.velocity * delta
		item.node.rotate_x(delta*7)
		item.node.scale = Vector3.ONE * maxf(0,1-item.age/0.7)
		if item.age > 0.7:
			item.node.queue_free()
			chips.remove_at(i)

func clear() -> void:
	super.clear()
	for item in chips:
		item.node.queue_free()
	chips.clear()
