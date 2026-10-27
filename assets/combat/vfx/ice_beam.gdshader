shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 tint:source_color=vec4(.4,.85,1.,1.);
void fragment(){
 float edge=abs(UV.y-.5)*2.;
 float jag=sin(UV.x*65.-TIME*28.)*.10+sin(UV.x*103.+TIME*37.)*.04;
 float core=pow(max(0.,1.-edge),3.);
 float frost=pow(max(0.,sin(UV.x*90.-TIME*36.+UV.y*15.)),7.);
 ALBEDO=mix(tint.rgb,vec3(.95,1.,1.),core*.8+frost*.2);
 EMISSION=ALBEDO*.35;
 ALPHA=(1.-smoothstep(.65+jag,1.+jag,edge))*.9;
}
