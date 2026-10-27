shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
uniform float strength = 1.0;
void vertex() {
	float wave = sin(UV.x * 50.2655 + clock * 9.0 + UV.y * 11.0);
	VERTEX.xz *= 1.0 + wave * 0.18;
	VERTEX.y += sin(UV.x * 37.699 + clock * 7.0) * 0.28 * sin(UV.y * 3.14159);
}
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 1.65);
	float flame = pow(max(0.0, sin(UV.x * 56.5487 + sin(UV.y * 15.0 - clock * 8.0) * 1.1)), 5.0);
	float fade = pow(max(0.0, sin(UV.y * 3.14159)), 0.6);
	ALBEDO = mix(vec3(1.0, 0.29, 0.025), vec3(1.0, 0.85, 0.22), rim);
	ALPHA = (rim * 0.16 + flame * 0.12) * fade * strength;
}
