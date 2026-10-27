shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D mask_texture: source_color, filter_linear_mipmap;
uniform vec4 color: source_color=vec4(1.0);
uniform float spin=0.0;
void vertex(){
 float c=cos(spin); float s=sin(spin);
 VERTEX.xy=mat2(vec2(c,s),vec2(-s,c))*VERTEX.xy;
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 float mask=texture(mask_texture,UV).a;
 vec3 pigment=color.rgb;
 if(color.r>.9 && color.g<.7){pigment=mix(color.rgb,vec3(1.,.91,.40),mask*.85);}
 ALBEDO=pigment;
 EMISSION=pigment*.22;
 ALPHA=clamp(pow(mask,.65)*1.55,0.,1.)*color.a;
}
