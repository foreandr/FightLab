shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float phase=0.0;
uniform float strength : hint_range(0.0,1.0)=1.0;
uniform vec4 primary : source_color=vec4(1.0,0.24,0.025,1.0);
uniform vec4 accent : source_color=vec4(1.0,0.35,0.27,1.0);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex(){
 // Upright camera-facing cards: their bases stay planted at all camera pitches.
 vec3 right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.0,INV_VIEW_MATRIX[0].z));
 vec3 up=vec3(0.0,1.0,0.0);
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right*length(MODEL_MATRIX[0].xyz),0.0),vec4(up*length(MODEL_MATRIX[1].xyz),0.0),vec4(cross(right,up)*length(MODEL_MATRIX[2].xyz),0.0),MODEL_MATRIX[3]);
}
void fragment(){
 float t=TIME*1.65+phase;
 float h=1.0-UV.y;
 float flow=noise(vec2(UV.x*5.0,h*4.0-t*2.0));
 float detail=noise(vec2(UV.x*12.0+phase,h*9.0-t*3.7));
 float streak=noise(vec2(UV.x*19.0+phase,h*5.0-t*4.2));
 float bend=(noise(vec2(h*3.0-t,phase))-0.5)*h*0.6;
 float width=0.43*pow(max(0.0,1.0-h),0.75);
 float field=width-abs(UV.x-0.5+bend)+(flow-0.5)*0.3+(detail-0.5)*0.12+(streak-0.5)*0.08;
 field-=smoothstep(0.2,0.9,h)*detail*0.13;
 float alpha=smoothstep(-0.025,0.045,field)*smoothstep(0.0,0.07,h)*(1.0-smoothstep(0.72,1.0,h));
 alpha*=mix(0.3,1.0,smoothstep(0.15,0.65,flow+streak*0.25));
 float core=smoothstep(0.015,0.26,field)*pow(1.0-h,0.6)*(0.7+streak*0.5);
 vec3 color=mix(primary.rgb*0.65,primary.rgb,smoothstep(-0.02,0.08,field));
 color=mix(color,accent.rgb,clamp(core*1.45,0.0,1.0));
 ALBEDO=color;
 EMISSION=color*(0.08+core*0.15);
 ALPHA=alpha*strength*0.86;
}
