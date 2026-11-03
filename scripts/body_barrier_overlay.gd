extends RefCounted
## Thin, body-conforming visual overlay shared by the loadout preview and story fights.

static func apply(skeleton: Skeleton3D) -> Array:
	var overlays: Array = []
	if not is_instance_valid(skeleton):return overlays
	if skeleton.has_meta("body_barrier_overlays"):return skeleton.get_meta("body_barrier_overlays")
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode blend_mix, cull_back, unshaded;
uniform float barrier_strength : hint_range(0.0, 1.0) = 0.0;
void vertex() {
	VERTEX += NORMAL * 0.012;
}
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.4);
	ALBEDO = vec3(0.60, 0.75, 0.81);
	EMISSION = vec3(0.20, 0.42, 0.52) * (0.20 + rim * 0.9);
	ALPHA = barrier_strength * (0.16 + rim * 0.30);
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
	skeleton.set_meta("body_barrier_overlays",overlays)
	return overlays

static func set_strength(overlays: Array, strength: float,source:String="combat") -> void:
	for overlay: ShaderMaterial in overlays:
		if not is_instance_valid(overlay):continue
		var sources:Dictionary=overlay.get_meta("barrier_strength_sources",{})
		sources[source]=clampf(strength,0.0,1.0)
		overlay.set_meta("barrier_strength_sources",sources)
		var combined:=0.0
		for value in sources.values():combined=maxf(combined,float(value))
		overlay.set_shader_parameter("barrier_strength",combined)
