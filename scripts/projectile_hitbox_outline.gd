extends MeshInstance3D
## Draw the same world-space sphere used by projectile collision queries.
func configure(radius:float) -> void:
	name="ProjectileHitbox"
	set_meta("collision_radius",radius)
	top_level=true
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lines:=ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for axis in 3:
		for step in 64:
			for angle in [TAU*step/64.0,TAU*(step+1)/64.0]:
				var a:=cos(angle)*radius
				var b:=sin(angle)*radius
				lines.surface_add_vertex(Vector3(0,a,b) if axis==0 else (Vector3(a,0,b) if axis==1 else Vector3(a,b,0)))
	lines.surface_end()
	mesh=lines
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color("00e5ff")
	material.no_depth_test=true
	material_override=material
