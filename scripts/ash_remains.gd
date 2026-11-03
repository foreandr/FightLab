extends RefCounted
## Shared lightweight ash: powder, low broken heaps and scattered charcoal flakes.
static func create(seed_:int)->Node3D:
 var root:=Node3D.new();root.name="AshRemains"
 var rng:=RandomNumberGenerator.new();rng.seed=seed_
 var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var colors:=PackedColorArray()
 for heap in 5:
  var center:=Vector3(rng.randf_range(-0.32,0.32),0,rng.randf_range(-0.22,0.22))
  var radius:=rng.randf_range(0.15,0.28)
  var peak:=center+Vector3(rng.randf_range(-0.04,0.04),rng.randf_range(0.035,0.065),0)
  var rim:Array[Vector3]=[]
  for i in 15:
   var angle:=float(i)*TAU/15.0
   rim.append(center+Vector3(cos(angle),0,sin(angle)*0.75)*radius*rng.randf_range(0.65,1.2))
  for i in 15:triangle(vertices,normals,colors,peak,rim[(i+1)%15],rim[i],shade(rng))
 # Separate, angular chips break up the silhouette instead of forming a smooth oval.
 for i in 95:
  var angle:=rng.randf()*TAU;var radius:=sqrt(rng.randf())*0.80
  var center:=Vector3(cos(angle)*radius,rng.randf_range(0.002,0.012),sin(angle)*radius*0.7)
  var size:=rng.randf_range(0.014,0.050)*(1.0-radius*0.55)
  var a:=center+Vector3(-size,0,-size*0.4)
  var b:=center+Vector3(size*0.8,rng.randf_range(0.0,0.012),-size*0.6)
  var c:=center+Vector3(rng.randf_range(-size,size),0,size)
  triangle(vertices,normals,colors,a,c,b,shade(rng))
 var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors
 var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=1.0
 material.metallic_specular=0.0;material.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh.surface_set_material(0,material)
 var chips:=MeshInstance3D.new();chips.name="CharcoalAndAsh";chips.mesh=mesh;root.add_child(chips)
 var powder:=MeshInstance3D.new();powder.name="LoosePowder"
 var plane:=PlaneMesh.new();plane.size=Vector2(1.9,1.5);powder.mesh=plane
 var shader:=Shader.new()
 shader.code="""shader_type spatial;
render_mode blend_mix,cull_disabled,depth_draw_never;
varying vec2 point;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){point=VERTEX.xz;}
void fragment(){float n=noise(point*13.0);float d=length(point/vec2(0.83,0.60));float edge=1.0-smoothstep(0.30,1.0,d+(n-0.5)*0.40);ALBEDO=mix(vec3(0.17,0.15,0.13),vec3(0.30,0.28,0.25),n);ROUGHNESS=1.0;SPECULAR=0.0;ALPHA=edge*(0.16+noise(point*41.0)*0.30);}
"""
 var powder_material:=ShaderMaterial.new();powder_material.shader=shader;powder.material_override=powder_material
 powder.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(powder)
 return root
static func shade(rng:RandomNumberGenerator)->Color:
 return Color("35322e").lerp(Color("827b70"),pow(rng.randf(),1.5))
static func triangle(vertices:PackedVector3Array,normals:PackedVector3Array,colors:PackedColorArray,a:Vector3,b:Vector3,c:Vector3,color:Color)->void:
 var normal:Vector3=(b-a).cross(c-a).normalized()
 if normal.y<0:normal=-normal
 vertices.append_array(PackedVector3Array([a,b,c]))
 for i in 3:normals.append(normal);colors.append(color)
