shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D mask_texture : source_color, filter_linear_mipmap;
uniform vec4 primary : source_color=vec4(1.0,0.22,0.02,1.0);
uniform vec4 accent : source_color=vec4(1.0,0.35,0.27,1.0);
uniform float phase=0.0;
uniform float opacity=0.9;
uniform float glow=1.0;
uniform int flame_tongues=1;
uniform float flame_bend=0.0;
uniform float flame_turbulence=1.0;
uniform float flame_flow=1.0;
// Structure and atlas layout are cosmetic; gameplay radius stays independent.
uniform int flame_structure=0;
uniform int flame_sheet_columns=1;
uniform int flame_sheet_rows=1;
uniform int flame_sheet_frames=1;
uniform float flame_sheet_fps=24.0;
uniform float flame_preview_time=-1.0;
float flame_noise(vec2 p){return fract(sin(dot(floor(p),vec2(127.1,311.7)))*43758.5453);}
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 float clock=flame_preview_time>=0.0?flame_preview_time:TIME;
 float t=clock*2.8*flame_flow+phase;
 vec2 uv=UV;
 // Atlas animation retains each artist's actual frame-by-frame silhouette.
 bool atlas=flame_sheet_frames>1;
 if(flame_tongues>1){uv.x=fract(uv.x*float(flame_tongues));}
 uv.x+=flame_bend*(1.0-uv.y)*(1.0-uv.y);
 if(!atlas){
  uv.x+=sin(uv.y*12.0-t*2.0)*0.035*(1.0-uv.y)*flame_turbulence;
  uv.y+=sin(uv.x*9.0+t)*0.025*flame_turbulence;
 }
 if(flame_structure==3){
  vec2 p=uv-0.5;
  float angle=length(p)*5.5-t*0.45;
  uv=mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)))*p+0.5;
 }
 if(flame_structure==7){uv.x+=sin(uv.y*15.0-t*2.0)*0.16;}
 vec2 sheet=vec2(float(flame_sheet_columns),float(flame_sheet_rows));
 float frame=mod(floor(clock*flame_sheet_fps*flame_flow+phase),float(flame_sheet_frames));
 vec2 cell=vec2(mod(frame,sheet.x),floor(frame/sheet.x));
 // Half-texel inset prevents neighbouring atlas frames bleeding at the edges.
 vec2 frame_size=vec2(textureSize(mask_texture,0))/sheet;
 vec2 local_uv=clamp(uv,vec2(0.5)/frame_size,vec2(1.0)-vec2(0.5)/frame_size);
 vec2 sample_uv=(local_uv+cell)/sheet;
 vec4 sample_color=texture(mask_texture,sample_uv);
 float raw=sample_color.a;
 if(uv.x<0.0||uv.x>1.0||uv.y<0.0||uv.y>1.0){raw=0.0;}
 if(flame_structure==1){
  float interior=min(min(texture(mask_texture,sample_uv+vec2(0.04,0.0)/sheet).a,texture(mask_texture,sample_uv-vec2(0.04,0.0)/sheet).a),min(texture(mask_texture,sample_uv+vec2(0.0,0.04)/sheet).a,texture(mask_texture,sample_uv-vec2(0.0,0.04)/sheet).a));
  raw=max(0.0,raw-interior*0.95);
 }
 if(flame_structure==2){raw*=smoothstep(0.3,0.55,flame_noise(uv*vec2(17.0,22.0)+vec2(0.0,-floor(t*3.0))));}
 if(flame_structure==4){
  float ring=1.0-smoothstep(0.05,0.11,abs(length((UV-0.5)*vec2(1.0,1.15))-0.30));
  raw=ring*(0.55+raw*0.45)*(0.8+sin(atan(UV.y-0.5,UV.x-0.5)*9.0-t*3.0)*0.2);
 }
 if(flame_structure==5){raw*=smoothstep(0.025,0.07,abs(uv.x-0.5)+(uv.y-0.8)*0.18);}
 if(flame_structure==6){
  float flecks=smoothstep(0.65,0.9,flame_noise(uv*vec2(12.0,16.0)+vec2(0.0,-floor(t*2.0))));
  raw*=flecks;
 }
 if(flame_structure==7){raw*=0.45+0.55*smoothstep(-0.2,0.35,sin(uv.y*23.0-t*3.0));}
 float a=clamp(pow(raw,0.55)*2.1,0.0,1.0);
 float heat=atlas?dot(sample_color.rgb,vec3(0.299,0.587,0.114)):clamp(raw*0.6+uv.y*0.4,0.0,1.0);
 vec3 pigment=mix(primary.rgb,accent.rgb,heat);
 ALBEDO=pigment;
 EMISSION=pigment*(0.2+glow*0.25);
 ALPHA=pow(a,0.85)*opacity*(0.85+sin(t*2.3)*0.12);
}
