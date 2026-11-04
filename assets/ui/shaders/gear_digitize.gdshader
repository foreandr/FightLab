shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
uniform float amount : hint_range(0.0,1.0) = 0.0;
uniform bool vertex_tint = false;
uniform float surface_roughness = 0.85;
varying vec3 grid_position;
float hash_cell(vec3 p) { p=fract(p*0.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
void vertex() { grid_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec4 source = texture(albedo_tex,UV)*tint;
 if (vertex_tint) { source *= COLOR; }
 if (source.a < 0.3) { discard; }
 vec3 cell = floor(grid_position/0.032);
 float rank = hash_cell(cell);
 if (rank < amount || amount > 0.999) { discard; }
 float edge = (1.0-smoothstep(0.0,0.16,rank-amount))*smoothstep(0.0,0.07,amount);
 vec3 local = fract(grid_position/0.032);
 float outline = step(0.86,max(local.x,max(local.y,local.z)));
 ALBEDO = mix(source.rgb,vec3(0.16,0.8,0.95),edge*0.65);
 EMISSION = vec3(0.15,0.85,1.0)*edge*(1.2+outline*1.0);
 ROUGHNESS = surface_roughness;
}
