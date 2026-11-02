shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
varying vec3 local_point;
void vertex(){ local_point=VERTEX; }
float grain(vec3 p){return fract(sin(dot(floor(p*35.0),vec3(12.9898,78.233,37.719)))*43758.5453);}
void fragment(){
 float noise=grain(local_point);
 if(progress>noise) discard;
 vec3 original=base_color.rgb*(use_texture?texture(base_texture,UV).rgb:vec3(1.0));
 float charred=smoothstep(0.0,0.25,progress);
 ALBEDO=mix(original,vec3(0.12,0.105,0.09),charred);
 float rim=1.0-smoothstep(0.0,0.08,noise-progress);
 EMISSION=vec3(0.8,0.16,0.02)*rim*0.4;
 ROUGHNESS=1.0;
}
