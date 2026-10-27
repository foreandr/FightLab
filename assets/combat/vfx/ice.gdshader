shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float rim=pow(1.-max(dot(normalize(NORMAL),normalize(VIEW)),0.),1.6);
 float fracture=pow(max(0.,sin(UV.x*43.+sin(UV.y*32.)*4.)),18.);
 ALBEDO=mix(vec3(.075,.35,.56),vec3(.74,.97,1.),clamp(rim*.8+fracture*.55,0.,1.));
 EMISSION=vec3(.04,.16,.22)+fracture*.16;
 ROUGHNESS=.18; METALLIC=.3;
}
