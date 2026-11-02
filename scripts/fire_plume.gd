extends RefCounted
## Shared inexpensive fire rendering. No damage, terrain or status ownership.
static func flame(width:float,height:float,phase:float,appearance:Dictionary={}) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var quad:=QuadMesh.new()
	quad.size=Vector2(width,height)
	node.mesh=quad
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/combat/vfx/fire_plume.gdshader")
	mat.set_shader_parameter("phase",phase)
	var palette:Dictionary=preload("res://scripts/fire_palette.gd").colors(appearance)
	mat.set_shader_parameter("primary",palette.color)
	mat.set_shader_parameter("accent",palette.accent)
	node.material_override=mat
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func particles(radius:float,smoke:bool=false) -> CPUParticles3D:
	var node:=CPUParticles3D.new()
	node.amount=4 if smoke else 10
	node.lifetime=1.8 if smoke else 1.2
	node.preprocess=0.4
	node.fixed_fps=24
	node.local_coords=false
	node.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
	node.emission_sphere_radius=radius
	node.direction=Vector3.UP
	node.spread=18.0
	node.initial_velocity_min=0.18 if smoke else 0.6
	node.initial_velocity_max=0.45 if smoke else 1.25
	node.gravity=Vector3(0.06,0.06 if smoke else -0.2,0.03)
	node.scale_amount_min=0.2 if smoke else 0.015
	node.scale_amount_max=0.4 if smoke else 0.035
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color(0.22,0.19,0.16,0.0),Color(0.27,0.24,0.2,0.12),Color(0.3,0.28,0.25,0.0)]) if smoke else PackedColorArray([Color("ffe889"),Color("ff681c"),Color(Color("ff681c"),0.0)])
	node.color_ramp=gradient
	gradient.offsets=PackedFloat32Array([0.0,0.3,1.0])
	var mesh:=QuadMesh.new()
	mesh.size=Vector2.ONE
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo=true
	mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if smoke:mat.albedo_texture=preload("res://assets/combat/vfx/smoke_04.png")
	mesh.material=mat
	node.mesh=mesh
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
