extends RefCounted
## Thin, body-conforming visual overlay shared by the loadout preview and story fights.

static func apply(skeleton: Skeleton3D) -> Array:
	var overlays: Array = []
	if not is_instance_valid(skeleton):return overlays
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode blend_mix, cull_front, unshaded;
uniform float barrier_strength : hint_range(0.0, 1.0) = 0.0;
void vertex() {
	VERTEX += NORMAL * 0.012;
}
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.4);
	ALBEDO = vec3(0.30, 0.82, 1.0);
	EMISSION = vec3(0.12, 0.62, 1.0) * (0.35 + rim * 1.8);
	ALPHA = barrier_strength * (0.035 + rim * 0.34);
}
"""
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:continue
		for surface in mesh.mesh.get_surface_count():
			var original:=mesh.get_active_material(surface)
			var base: Material=original.duplicate() if original != null else StandardMaterial3D.new()
			var overlay:=ShaderMaterial.new()
			overlay.shader=shader
			overlay.set_shader_parameter("barrier_strength", 0.0)
			# Preserve any pass already attached to the asset material.
			overlay.next_pass=base.next_pass
			base.next_pass=overlay
			mesh.set_surface_override_material(surface, base)
			overlays.append(overlay)
	return overlays

static func set_strength(overlays: Array, strength: float) -> void:
	for overlay: ShaderMaterial in overlays:
		if is_instance_valid(overlay):overlay.set_shader_parameter("barrier_strength", clampf(strength, 0.0, 1.0))
