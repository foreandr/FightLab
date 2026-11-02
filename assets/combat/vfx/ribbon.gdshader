shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D pattern: source_color, repeat_enable;
uniform bool water=false;
uniform vec4 fire_primary : source_color=vec4(1.0,0.408,0.11,1.0);
uniform vec4 fire_accent : source_color=vec4(1.0,0.91,0.537,1.0);
void fragment(){
 float edge=abs(UV.y-.5)*2.;
 float flow=texture(pattern,vec2(UV.x*2.2-TIME*3.,UV.y)).a;
 float core=pow(max(0.,1.-edge),2.);
 float filaments=pow(max(0.,sin(UV.x*38.-TIME*25.+UV.y*18.)),6.);
 vec3 hot=mix(fire_primary.rgb,fire_accent.rgb,core);
 vec3 wet=mix(vec3(.02,.32,.65),vec3(.76,.97,1.),clamp(core*.4+filaments*.6+pow(edge,5.),0.,1.));
 ALBEDO=water?wet:hot;
 EMISSION=ALBEDO*.35;
 ALPHA=(1.-smoothstep(.60,1.,edge))*(1.-UV.x)*clamp(.48+flow*.65+filaments*.25,0.,1.);
}
