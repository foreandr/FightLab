shader_type spatial;
render_mode cull_disabled;
void fragment() {
	float crust=fract(sin(dot(floor(UV*85.0),vec2(12.9898,78.233)))*43758.5453);
	float seam=pow(max(0.0,sin(UV.x*37.0+sin(UV.y*21.0)*2.0)),12.0);
	ALBEDO=mix(vec3(0.47,0.72,0.83),vec3(0.91,0.98,1.0),0.55+crust*0.35);
	ALBEDO=mix(ALBEDO,vec3(0.27,0.55,0.7),seam*0.4);
	ROUGHNESS=0.92;
	EMISSION=vec3(0.015,0.035,0.045);
}
