shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D mask_texture : source_color, filter_linear_mipmap;
uniform vec4 primary : source_color=vec4(1.0,0.22,0.02,1.0);
uniform vec4 accent : source_color=vec4(1.0,0.9,0.3,1.0);
uniform float phase=0.0;
uniform float opacity=0.9;
uniform float glow=1.0;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 vec2 uv=UV;
 float t=TIME*2.8+phase;
 uv.x+=sin(uv.y*12.0-t*2.0)*0.035*(1.0-uv.y);
 uv.y+=sin(uv.x*9.0+t)*0.025;
 float raw=texture(mask_texture,uv).a;
 float a=clamp(pow(raw,0.55)*2.1,0.0,1.0);
 float heat=clamp(raw*0.6+uv.y*0.4,0.0,1.0);
 vec3 pigment=mix(primary.rgb,accent.rgb,heat);
 ALBEDO=pigment;
 EMISSION=pigment*(0.2+glow*0.25);
 ALPHA=pow(a,0.85)*opacity*(0.85+sin(t*2.3)*0.12);
}
