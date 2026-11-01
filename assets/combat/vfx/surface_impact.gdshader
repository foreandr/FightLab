shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float severity=1.0;
uniform float seed=0.0;
float hash(float p){return fract(sin(p*127.1+seed*19.3)*43758.5453);}
void fragment(){
 vec2 p=(UV-0.5)*2.0;
 float r=length(p);
 float angle=atan(p.y,p.x);
 float edge=0.84+0.055*sin(angle*7.0+seed)+0.045*sin(angle*13.0-seed);
 float bowl=(1.0-smoothstep(0.05,0.63,r))*0.38;
 float rim=0.49+sin(angle*5.0+seed)*0.04+sin(angle*9.0)*0.025;
 float lip=exp(-pow((r-rim)*20.0,2.0));
 float rays=0.0;
 for(int i=0;i<9;i++){
  float a=float(i)*6.2831853/9.0+(hash(float(i))-0.5)*0.45;
  vec2 axis=vec2(cos(a),sin(a));
  float along=dot(p,axis);
  float knot=along*7.0;
  float zig=mix(hash(floor(knot)+float(i)*17.0),hash(floor(knot)+float(i)*17.0+1.0),fract(knot));
  float side=abs(p.x*axis.y-p.y*axis.x+(zig-0.5)*0.07);
  float reach=0.53+hash(float(i)+20.0)*0.4;
  rays=max(rays,(1.0-smoothstep(0.006,0.022,side))*smoothstep(0.1,0.3,along)*(1.0-smoothstep(reach-0.12,reach,along)));
  vec2 branch=p-axis*0.43;
  vec2 fork=vec2(cos(a+0.6),sin(a+0.6));
  float branch_along=dot(branch,fork);
  float branch_side=abs(branch.x*fork.y-branch.y*fork.x);
  rays=max(rays,(1.0-smoothstep(0.003,0.012,branch_side))*smoothstep(0.0,0.04,branch_along)*(1.0-smoothstep(0.12,0.24,branch_along)));
 }
 float mask=1.0-smoothstep(edge-0.13,edge,r);
 ALBEDO=mix(vec3(0.10,0.075,0.05),vec3(0.64,0.57,0.45),lip*(1.0-rays));
 ALPHA=clamp(bowl+rays*0.78+lip*0.24,0.0,0.9)*mask*clamp(0.8+severity*0.08,0.8,1.0);
}
