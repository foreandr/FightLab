extends RefCounted
## Body-conforming block shell shared by authoring previews and combat.

static func apply(skeleton: Skeleton3D) -> Array:
	var overlays: Array = []
	if not is_instance_valid(skeleton):return overlays
	if skeleton.has_meta("body_barrier_overlays"):return skeleton.get_meta("body_barrier_overlays")
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode blend_mix, cull_back, unshaded;
uniform float barrier_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shield_strength = 0.0;
uniform float charge_strength = 0.0;
uniform vec4 charge_color : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform float shell_offset = 0.085;
uniform float block_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 block_flash_color : source_color = vec4(0.25, 1.0, 0.48, 1.0);
void vertex() {
	VERTEX += NORMAL * shell_offset;
}
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.4);
	float charge_mix = charge_strength / max(0.001, shield_strength + charge_strength);
	vec3 tint = mix(vec3(0.82, 0.93, 1.0), charge_color.rgb, charge_mix);
	ALBEDO = mix(tint, block_flash_color.rgb, block_flash);
	EMISSION = mix(tint * (0.08 + rim * 0.35 + charge_strength * 0.4), block_flash_color.rgb, block_flash);
	float shield_alpha = shield_strength * (0.025 + rim * 0.24);
	float charge_alpha = charge_strength * (0.07 + rim * 0.38);
	ALPHA = max(max(shield_alpha, charge_alpha), block_flash * (0.25 + rim * 0.4));
}
"""
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or mesh.get_meta("presentation_overlay",false):continue
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
		overlay.set_shader_parameter("charge_strength",float(sources.get("cast_charge",0.0)))
		var shield:=0.0
		for key in sources:
			if key!="cast_charge":shield=maxf(shield,float(sources[key]))
		overlay.set_shader_parameter("shield_strength",shield)

static func set_block_flash(overlays:Array,value:float,color:Color=Color("60e88a"))->void:
	for overlay:ShaderMaterial in overlays:
		if is_instance_valid(overlay):
			overlay.set_shader_parameter("block_flash",clampf(value,0.0,1.0))
			overlay.set_shader_parameter("block_flash_color",color)

static func set_charge_color(overlays:Array,color:Color)->void:
	for overlay:ShaderMaterial in overlays:
		if is_instance_valid(overlay):overlay.set_shader_parameter("charge_color",color)
