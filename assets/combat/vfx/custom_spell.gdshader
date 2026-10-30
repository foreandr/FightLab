shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform vec4 primary : source_color = vec4(1.0,0.3,0.05,1.0);
uniform vec4 accent : source_color = vec4(1.0,0.95,0.65,1.0);
uniform float glow = 1.0;
uniform float opacity = 0.9;
uniform float pulse = 0.15;
uniform float flow = 1.5;
uniform int element_kind = 0;
uniform sampler2D detail_texture : source_color, filter_linear_mipmap;
uniform bool use_detail=false;
float hash(vec3 p){p=fract(p*0.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise3(vec3 p){
 vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void fragment(){
 vec3 q=vec3(UV*vec2(7.0,5.0),TIME*flow*0.35);
 float cloud=noise3(q)*0.7+noise3(q*2.2+3.0)*0.3;
 float edge=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.0);
 float hot=smoothstep(0.4,0.8,cloud);
 float alpha=opacity;
 vec3 color=mix(primary.rgb,accent.rgb,hot*0.7+edge*0.3);
 if(element_kind==0){hot=smoothstep(0.3,0.8,cloud);color=mix(primary.rgb*0.55,accent.rgb,hot);alpha*=0.6+cloud*0.4;}
 if(element_kind==1){float facets=0.6+0.4*abs(dot(normalize(NORMAL),normalize(vec3(0.4,0.7,0.6))));color*=facets;hot=max(hot*0.4,edge);}
 if(element_kind==2){float vein=1.0-smoothstep(0.015,0.06,abs(cloud-0.52));hot=vein+edge*0.3;color=mix(primary.rgb*0.4,accent.rgb,hot);}
 if(element_kind==3){float ribbon=sin(UV.y*20.0+cloud*6.0-TIME*flow)*0.5+0.5;alpha*=0.2+ribbon*0.8;hot=ribbon*0.6+edge;}
 if(element_kind==4){float ripple=sin(UV.x*28.0+cloud*10.0+TIME*flow)*0.5+0.5;hot=ripple*0.35+edge*0.7;color=mix(primary.rgb,accent.rgb,hot);alpha*=0.65+edge*0.35;}
 if(element_kind==5){float facets=0.4+0.6*max(0.0,dot(normalize(NORMAL),normalize(vec3(0.4,0.8,0.5))));color=primary.rgb*facets*(0.7+cloud*0.5);hot=cloud*0.1;}
 float beat=1.0+pulse*0.2*sin(TIME*6.0);
 ALBEDO=color*beat;
 EMISSION=color*glow*(0.12+hot*0.5)*beat;
 ALPHA=clamp(alpha,0.0,1.0)*(use_detail ? texture(detail_texture,UV).a : 1.0);
}
