extends RefCounted
const SHAPES=["Element style","Orb","Lance","Shard","Ring","Wisp","Bolt","Flame","Drawn"]
static func defaults(element:String) -> Dictionary:
 var colors:Dictionary=load("res://scripts/basic_projectile.gd").COLORS
 return {"shape":{"Fire":"Flame","Ice":"Shard","Lightning":"Lance","Wind":"Ring","Water":"Orb","Earth":"Shard"}.get(element,"Orb"),"color":colors.get(element,Color.WHITE),"accent":Color("fff0a0") if element=="Fire" else colors.get(element,Color.WHITE).lerp(Color.WHITE,0.8),"glow":{"Fire":1.8,"Ice":0.8,"Lightning":2.3,"Wind":0.8,"Water":0.6,"Earth":0.15}.get(element,1.0),"trail_texture":"Element style","texture":"Element style","drawn_outline":PackedVector2Array(),"drawn_trail":PackedVector2Array(),"orbits":element=="Wind","opacity":0.75 if element=="Water" else 0.95,"trail_style":"Element style","trail":0.6,"pulse":0.15,"spin":1.4}
static func settings(element:String,custom:Dictionary) -> Dictionary:
 var out:Dictionary=defaults(element)
 out.merge(custom,true)
 if out.shape=="Element style":out.shape=defaults(element).shape
 return out
static func visual(element:String,radius:float,custom:Dictionary={}) -> MeshInstance3D:
 var look:Dictionary=settings(element,custom)
 var body:=MeshInstance3D.new()
 var mesh:=SphereMesh.new()
 mesh.radius=radius
 mesh.height=radius*2
 mesh.radial_segments=24
 mesh.rings=16
 body.mesh=mesh
 var material:=ShaderMaterial.new()
 material.shader=preload("res://assets/combat/vfx/custom_spell.gdshader")
 material.set_shader_parameter("element_kind",["Fire","Ice","Lightning","Wind","Water","Earth"].find(element))
 material.set_shader_parameter("primary",look.color)
 material.set_shader_parameter("accent",look.accent)
 material.set_shader_parameter("glow",look.glow)
 material.set_shader_parameter("pulse",look.pulse)
 material.set_shader_parameter("opacity",look.opacity)
 material.set_shader_parameter("flow",look.spin)
 var selected_texture:String=str(look.texture)
 if selected_texture!="Element style":
  var texture:Texture2D=preload("res://scripts/spell_textures.gd").texture(selected_texture)
  if texture!=null:
   material.set_shader_parameter("detail_texture",texture)
   material.set_shader_parameter("use_detail",true)
 body.material_override=material
 body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var base:=Vector3.ONE
 match str(look.shape):
  "Drawn":
   var custom_mesh=preload("res://scripts/spell_draw_mesh.gd").mesh(look.drawn_outline,radius)
   if custom_mesh!=null:body.mesh=custom_mesh
  "Flame":
   var quad:=QuadMesh.new()
   quad.size=Vector2(radius*2,radius*2.5)
   body.mesh=quad
   var flame_material:=ShaderMaterial.new()
   flame_material.shader=preload("res://assets/combat/vfx/flame_sprite.gdshader")
   var texture:Texture2D=preload("res://scripts/spell_textures.gd").texture("flame_04" if selected_texture=="Element style" else selected_texture)
   if texture==null:texture=load("res://assets/combat/vfx/flame_04.png")
   flame_material.set_shader_parameter("mask_texture",texture)
   flame_material.set_shader_parameter("primary",look.color)
   flame_material.set_shader_parameter("accent",look.accent)
   flame_material.set_shader_parameter("opacity",look.opacity)
   flame_material.set_shader_parameter("glow",look.glow)
   body.material_override=flame_material
  "Lance":base=Vector3(0.35,0.35,1.8)
  "Bolt":
   var core:=SphereMesh.new()
   core.radius=radius*0.06
   core.height=radius*0.12
   core.radial_segments=8
   core.rings=4
   body.mesh=core
  "Wisp":base=Vector3(0.65,0.65,1.3)
  "Shard":
   body.mesh=crystal_mesh(radius)
   body.rotation.x=PI/2
  "Ring":
   var ring:=TorusMesh.new()
   ring.inner_radius=radius*0.65
   ring.outer_radius=radius
   ring.rings=24
   ring.ring_segments=10
   body.mesh=ring
   body.rotation.x=PI/2
 if look.shape=="Bolt":
  for i in 7:
   var segment:=MeshInstance3D.new()
   var beam:=CylinderMesh.new()
   beam.top_radius=radius*0.028
   beam.bottom_radius=radius*0.028
   var a:=Vector3(sin(i*2.8)*radius*0.12,cos(i*3.7)*radius*0.12,(float(i)/7-0.5)*radius*3.0)
   var b:=Vector3(sin((i+1)*2.8)*radius*0.12,cos((i+1)*3.7)*radius*0.12,(float(i+1)/7-0.5)*radius*3.0)
   beam.height=a.distance_to(b)
   beam.radial_segments=5
   segment.mesh=beam
   var spark:=StandardMaterial3D.new()
   spark.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
   spark.albedo_color=look.accent
   segment.material_override=spark
   segment.position=(a+b)*0.5
   segment.basis=Basis(Quaternion(Vector3.UP,(b-a).normalized()))
   body.add_child(segment)
 body.scale=base
 body.set_meta("visual_base",base)
 body.set_meta("look",look)
 for i in 2 if bool(look.orbits) else 0:
  var band:=MeshInstance3D.new()
  var ring:=TorusMesh.new()
  ring.inner_radius=radius*(0.94+float(i)*0.15)
  ring.outer_radius=ring.inner_radius+radius*0.025
  ring.rings=24
  ring.ring_segments=6
  band.mesh=ring
  band.set_meta("orbit",true)
  band.rotation=Vector3(0.6+i*1.4,i*0.9,0.4)
  var shine:=StandardMaterial3D.new()
  shine.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  shine.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  shine.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
  shine.albedo_color=Color(look.accent,0.25+float(look.glow)*0.1)
  band.material_override=shine
  body.add_child(band)
 return body
static func step(body:MeshInstance3D,age:float,delta:float) -> void:
 if not body.has_meta("look"):return
 var look:Dictionary=body.get_meta("look")
 body.scale=body.get_meta("visual_base")*(1.0+float(look.pulse)*0.1*sin(age*6))
 for child in body.get_children():
  if child is MeshInstance3D and child.has_meta("orbit"):child.rotate_z(delta*float(look.spin))

static func crystal_mesh(radius:float) -> ArrayMesh:
 var vertices:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var uvs:=PackedVector2Array()
 for side in 2:
  var tip:=Vector3(0,radius*(1.5 if side==0 else -1.0),0)
  for i in 6:
   var a:=Vector3(cos(i*TAU/6)*radius*0.65,0,sin(i*TAU/6)*radius*0.65)
   var b:=Vector3(cos((i+1)*TAU/6)*radius*0.65,0,sin((i+1)*TAU/6)*radius*0.65)
   var face:Array=[tip,a,b] if side==0 else [tip,b,a]
   var normal:Vector3=(face[1]-face[0]).cross(face[2]-face[0]).normalized()
   for j in 3:
    vertices.append(face[j])
    normals.append(normal)
    uvs.append(Vector2(float(i)/6+float(j)*0.08,float(side)+float(j)*0.3))
 var arrays:Array=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_NORMAL]=normals
 arrays[Mesh.ARRAY_TEX_UV]=uvs
 var mesh:=ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return mesh
