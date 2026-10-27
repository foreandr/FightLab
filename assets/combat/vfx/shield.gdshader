shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque;
uniform vec4 tint: source_color = vec4(.2,.7,1.,1.);
uniform float strength=1.0;
uniform float hit_age=2.0;
float hex(vec2 p){p=abs(p);return max(p.x*.866025+p.y*.5,p.y);}
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float radius=length(p);
 float mask=1.0-smoothstep(.91,1.0,radius);
 vec2 grid=UV*vec2(10.,7.);
 vec2 a=mod(grid,vec2(1.0,1.732))-.5*vec2(1.0,1.732);
 vec2 b=mod(grid+vec2(.5,.866),vec2(1.0,1.732))-.5*vec2(1.0,1.732);
 float cell=min(dot(a,a),dot(b,b));
 float lines=smoothstep(.20,.25,cell);
 float rim=exp(-abs(radius-.90)*55.0);
 float wave=exp(-abs(radius-hit_age*3.2)*28.0)*max(0.,1.-hit_age*1.5);
 float flow=pow(max(0.,sin(radius*50.-TIME*7.)),18.)*.16;
 ALBEDO=mix(tint.rgb,vec3(.85,.98,1.),clamp(wave+rim*.5,0.,1.));
 EMISSION=ALBEDO*(rim*.6+wave);
 ALPHA=mask*strength*clamp(.12+lines*.38+rim*.85+wave*.75+flow,.0,.95);
}
