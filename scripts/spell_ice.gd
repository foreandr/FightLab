extends StaticBody3D
## One persistent, damageable column of frozen water.
var hit_points:=45.0
var maximum_hp:=45.0
var trapped:Array[CharacterBody3D]=[]
var visual:MeshInstance3D
var environment:Node3D
var cell:=Vector2i.ZERO
var broken:=false
var crack:MeshInstance3D

func build(point:Vector3,height:float,width:float,potency:float) -> void:
 set_meta("spell_ice",true)
 collision_layer=1
 collision_mask=0
 maximum_hp=45.0*maxf(0.5,potency)
 hit_points=maximum_hp
 position=Vector3(point.x,height*0.5,point.z)
 var box:=BoxShape3D.new()
 box.size=Vector3(width,height,width)
 var collision:=CollisionShape3D.new()
 collision.shape=box
 add_child(collision)
 visual=MeshInstance3D.new()
 var mesh:=BoxMesh.new()
 mesh.size=box.size
 visual.mesh=mesh
 var material:=StandardMaterial3D.new()
 material.albedo_color=Color("9bdded")
 material.roughness=0.2
 material.metallic=0.08
 visual.material_override=material
 add_child(visual)
 # Dark branching cracks become visible as the ice takes damage.
 crack=MeshInstance3D.new()
 var lines:=ImmediateMesh.new()
 var ink:=StandardMaterial3D.new()
 ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 ink.albedo_color=Color("24627e")
 lines.surface_begin(Mesh.PRIMITIVE_LINES,ink)
 for i in 7:
  var angle:float=float(i)*2.399
  var center:=Vector3(0,height*0.5+0.006,0)
  var end:=center+Vector3(cos(angle),0,sin(angle))*width*0.47
  var mid:Vector3=center.lerp(end,0.55)+Vector3(0.12,0,-0.08)
  for v in [center,mid,mid,end]:lines.surface_add_vertex(v)
 lines.surface_end()
 crack.mesh=lines
 crack.visible=false
 add_child(crack)

func take_damage(amount:float) -> void:
 if broken or amount<=0:return
 hit_points-=amount
 crack.visible=hit_points<maximum_hp*0.8
 visual.material_override.albedo_color=Color("9bdded").lerp(Color("e0faff"),1-maxf(0,hit_points)/maximum_hp)
 if hit_points<=0:shatter()

func shatter() -> void:
 if broken:return
 broken=true
 collision_layer=0
 for fighter in trapped:
  if is_instance_valid(fighter):
   fighter.ice_trapped=false
   remove_collision_exception_with(fighter)
 trapped.clear()
 if is_instance_valid(environment):
  environment.ice.erase(cell)
  for i in 7:
   environment.arena.vfx.puff(global_position+Vector3.UP*0.4,"spark_05",1,Vector2.ONE*0.25,Vector3(sin(i*2.4),1,cos(i*2.4))*2,0.4,Color("b4f5ff"),0.1)
 queue_free()
