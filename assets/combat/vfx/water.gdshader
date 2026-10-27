shader_type spatial;
render_mode blend_mix, cull_disabled;
void vertex(){VERTEX += NORMAL * sin(VERTEX.x*29.0+VERTEX.y*23.0+TIME*15.0)*.012;}
void fragment(){
 float edge=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),1.8);
 float stream=pow(max(0.0,sin(UV.y*55.0+sin(UV.x*24.0+TIME*7.0)*2.0-TIME*22.0)),8.0);
 ALBEDO=mix(vec3(.015,.21,.42),vec3(.65,.96,1.0),clamp(edge+stream*.7,0.0,1.0));
 EMISSION=vec3(.02,.12,.17)+stream*.12;
 ROUGHNESS=.1; METALLIC=.25; ALPHA=.82+edge*.16;
}
