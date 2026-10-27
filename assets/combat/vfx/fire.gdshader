shader_type spatial;
render_mode unshaded, cull_disabled;
float noise(vec3 p){return sin(p.x*19.0+sin(p.y*12.0+TIME*9.0))*sin(p.z*17.0-p.y*9.0+TIME*13.0)*.5+.5;}
void vertex(){VERTEX += NORMAL * (sin(VERTEX.y*38.0+TIME*28.0+VERTEX.x*25.0)*.023);}
void fragment(){
 float f=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),.7);
 float n=noise(VERTEX*2.0);
 ALBEDO=mix(vec3(1.0,.83,.26),vec3(1.0,.075,.004),clamp(f*.9+n*.3,0.0,1.0));
 EMISSION=ALBEDO*.45;
 ROUGHNESS=1.0;
}
