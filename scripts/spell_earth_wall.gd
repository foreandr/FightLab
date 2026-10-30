extends StaticBody3D
## Summoned solid earth. Only destruction produces movable debris.
var environment:Node3D
var hit_points:=70.0
var maximum_hp:=70.0
var broken:=false
var visual:MeshInstance3D

func build(point:Vector3,direction:Vector3,radius:float,potency:float) -> void:
 set_meta("spell_earth",true)
 collision_layer=1
 collision_mask=0
 var forward:=Vector3(direction.x,0,direction.z).normalized()
 if forward.length_squared()<0.1:forward=Vector3.FORWARD
 rotation.y=atan2(forward.x,forward.z)
 var size:=Vector3(maxf(1.5,radius*2),maxf(1.8,radius*2.2),maxf(0.45,radius*0.4))
 position=Vector3(point.x,size.y/2,point.z)+forward*(size.z/2+0.5)
 maximum_hp=70*potency
 hit_points=maximum_hp
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=size
 collision.shape=shape
 add_child(collision)
 visual=MeshInstance3D.new()
 var mesh:=BoxMesh.new()
 mesh.size=size
 visual.mesh=mesh
 var material:=StandardMaterial3D.new()
 material.albedo_color=Color("9c8059")
 material.roughness=0.98
 visual.material_override=material
 add_child(visual)
 # Layer seams make the raised wall read as compacted earth.
 for i in 4:
  var seam:=MeshInstance3D.new()
  var strip:=BoxMesh.new()
  strip.size=Vector3(size.x+0.01,0.035,size.z+0.01)
  seam.mesh=strip
  var dark:=StandardMaterial3D.new()
  dark.albedo_color=Color("665036")
  seam.material_override=dark
  seam.position.y=(float(i)/4.0-0.4)*size.y
  add_child(seam)

func take_damage(amount:float) -> void:
 if broken or amount<=0:return
 hit_points-=amount
 visual.material_override.albedo_color=Color("9c8059").lerp(Color("5b4937"),1-maxf(0,hit_points)/maximum_hp)
 if hit_points<=0:shatter()

func shatter() -> void:
 if broken:return
 broken=true
 collision_layer=0
 if is_instance_valid(environment):
  environment.spawn_earth_debris(self)
  environment.earth_walls.erase(self)
 queue_free()
