extends Node3D
## Bounded surface patches and real rigid bodies, shared by all projectile elements.
var arena:Node3D
var patches:Array[Dictionary]=[]
var debris:Array[RigidBody3D]=[]
var water:Array[Dictionary]=[]
var water_volume:=0.0
var flood_depth:=0.0
var flood_radius:=0.0
var flood_electric:=0.0
var ice:Dictionary={}
var spark_mesh:MeshInstance3D
var spark_clock:=0.0
var spark_rng:=RandomNumberGenerator.new()
var earth_walls:Array[StaticBody3D]=[]
var flood:MeshInstance3D
const ARENA_RADIUS:=15.0

func _ready() -> void:
 spark_rng.seed=81537
 spark_mesh=MeshInstance3D.new()
 spark_mesh.name="WaterElectricSparks"
 add_child(spark_mesh)
 reset_environment()

func disc(point:Vector3,radius:float,color:Color) -> MeshInstance3D:
 var node:=MeshInstance3D.new()
 var mesh:=CylinderMesh.new()
 mesh.top_radius=radius
 mesh.bottom_radius=radius
 mesh.height=0.015
 mesh.radial_segments=24
 node.mesh=mesh
 var material:=StandardMaterial3D.new()
 material.albedo_color=color
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 node.material_override=material
 add_child(node)
 node.position=Vector3(point.x,0.035,point.z)
 return node

func reset_environment() -> void:
 for block in ice.values():block.shatter()
 ice.clear()
 if is_instance_valid(spark_mesh):spark_mesh.mesh=null
 water_volume=0
 flood_depth=0
 flood_radius=0
 flood_electric=0
 flood=null
 for wall in earth_walls:
  if is_instance_valid(wall):
   wall.collision_layer=0
   wall.queue_free()
 earth_walls.clear()
 if is_instance_valid(arena):
  for fighter in arena.fighters:
   fighter.water_depth=0
   fighter.ice_trapped=false
   fighter.air_remaining=8.0
 for p in patches:p.node.queue_free()
 patches.clear()
 for body in debris:
  if is_instance_valid(body):body.queue_free()
 debris.clear()
 for pool in water:pool.node.queue_free()
 water.clear()

func projectile_step(shot:Dictionary,from:Vector3,to:Vector3,hit:bool) -> void:
 var element:String=shot.spec.projectile_element
 var potency:float=float(shot.spec.get("potency",1.0))
 var radius:float=maxf(0.7,shot.radius*2)
 if element=="Wind":
  for other in arena.shots:
   if other.spec.get("projectile_element","")!="Fire" or other.get("wind_amplified",false):continue
   var nearest:Vector3=Geometry3D.get_closest_point_to_segment(other.node.position,from,to)
   if nearest.distance_to(other.node.position)<radius+other.radius:
    other["wind_amplified"]=true
    other.spec.damage=float(other.spec.get("damage",12.0))*1.5
    other.spec.potency=float(other.spec.get("potency",1.0))*1.5
  for patch in patches:
   if patch.element!="Fire" or patch.get("wind_amplified",false):continue
   if Geometry3D.get_closest_point_to_segment(patch.point+Vector3.UP*0.3,from,to).distance_to(patch.point+Vector3.UP*0.3)<radius+patch.radius:
    patch["wind_amplified"]=true
    patch.potency*=1.5
    patch.life+=2.0
  for body in debris:
   var closest:Vector3=Geometry3D.get_closest_point_to_segment(body.global_position,from,to)
   var distance:float=body.global_position.distance_to(closest)
   if distance<radius+1.3:
    var force:Vector3=(shot.velocity.normalized()*9+Vector3.UP*4)*potency*(1-distance/(radius+1.3))
    body.apply_central_impulse(force*get_physics_process_delta_time()*14)
 if not hit:return
 var point:Vector3=shot.get("impact_position",to)
 if element=="Fire":
  react_fire(point,radius,potency,float(shot.radius))
 if element=="Water":
  add_water(4.0/3.0*PI*pow(float(shot.radius),3),point)
  for p in patches:
   if p.element=="Fire" and p.point.distance_to(Vector3(point.x,0,point.z))<radius+p.radius:p.life=0.0
 if element=="Ice":
  for pool in water:
   if flat_distance(point,pool.point)<pool.radius+radius and point.y-radius<=pool.depth+0.2:
    freeze_water(point,radius,potency,pool.depth,pool.radius,pool.point)
 if element in ["Fire","Ice"] and not (element=="Fire" and water_height(point)>0):
  if patches.size()>=48:
   patches[0].node.queue_free()
   patches.pop_front()
  # Fire melts ice; ice extinguishes burning ground.
  for p in patches:
   if p.point.distance_to(Vector3(point.x,0,point.z))<radius+p.radius and p.element!=element:p.life=0.0
  patches.append({"point":Vector3(point.x,0,point.z),"radius":radius,"element":element,"life":8.0,"potency":potency,"source":shot.caster,"node":ground_fire(point,radius,shot.spec.get("appearance",{})) if element=="Fire" else disc(point,radius,Color(0.4,0.83,1,0.65))})
 if element=="Lightning":
  for pool in water:
   if flat_distance(point,pool.point)<pool.radius+radius and point.y-radius<pool.depth+0.1:
    pool.electric=maxf(pool.electric,6.0*potency)
    pool["stun"]=maxf(float(pool.get("stun",0.0)),0.7*potency)
  update_water_summary()

func _physics_process(delta:float) -> void:
 if not arena.round_active or not arena.is_physics_processing():return
 spark_clock-=delta
 if spark_clock<=0:
  spark_clock=0.065
  draw_sparks()
 for body in debris:
  if not is_instance_valid(body):continue
  var depth:float=water_height(body.position)-body.position.y
  if depth>0:
   body.apply_central_force(Vector3.UP*body.mass*clampf(depth*24,0,22)-body.linear_velocity*body.mass*2)
 for fighter in arena.fighters:
  var surface:float=water_height(fighter.position)
  fighter.water_depth=maxf(0,surface-fighter.position.y)
  var head:Vector3=fighter.bone_point("Head")
  var head_wet:bool=head.y<water_height(head)-0.05
  fighter.update_breath(delta,head_wet)
  if fighter.health<=0:continue
  if fighter.editor_pose_locked and (fighter.water_depth>0 or fighter.stun_time>0 or fighter.freeze_time>0):
   fighter.update_status(delta)
   fighter.stun_time=maxf(0,fighter.stun_time-delta)
   if fighter.water_depth>1.1 and not fighter.ice_trapped: fighter.tick_swimming(delta)
  if fighter.water_depth>0: fighter.burn_time=0
  fighter.surface_slippery=false
  var flat:=Vector3(fighter.position.x,0,fighter.position.z)
  for patch in patches:
   if patch.life<=0 or flat.distance_to(patch.point)>patch.radius or fighter.position.y>0.4:continue
   if patch.element=="Ice":fighter.surface_slippery=true
   elif patch.element=="Fire" and fighter.water_depth<0.15:
    fighter.burn_time=maxf(fighter.burn_time,0.6)
    fighter.burn_damage=1.5*patch.potency
    fighter.burn_source=patch.source
  for pool in water:
   if pool.electric>0 and flat.distance_to(pool.point)<pool.radius and fighter.position.y<pool.depth:
    fighter.stun_time=maxf(fighter.stun_time,minf(pool.electric,float(pool.get("stun",0.7))))
 for pool in water:
  pool.electric=maxf(0,pool.electric-delta)
  pool.node.material_override.albedo_color=Color(0.1,0.45,0.65,0.55)
 update_water_summary()
 for i in range(patches.size()-1,-1,-1):
  patches[i].life-=delta
  if patches[i].life<=0:
   patches[i].node.queue_free()
   patches.remove_at(i)

func flat_distance(a:Vector3,b:Vector3) -> float:
 return Vector2(a.x-b.x,a.z-b.z).length()

func add_water(volume:float,impact:Vector3=Vector3.ZERO) -> void:
 if volume<=0:return
 var point:=Vector3(impact.x,0,impact.z)
 var total:float=volume
 var absorbed:Array[Dictionary]=[]
 var radius:float=sqrt(total/(PI*0.12))
 # Combine overlapping puddles, retaining their total volume and local footprint.
 var changed:=true
 while changed:
  changed=false
  for pool in water:
   if pool in absorbed:continue
   if flat_distance(point,pool.point)>radius+pool.radius:continue
   point=(point*total+pool.point*pool.volume)/(total+pool.volume)
   total+=pool.volume
   radius=sqrt(total/(PI*0.12))
   absorbed.append(pool)
   changed=true
 var electric:=0.0
 var stun:=0.7
 for pool in absorbed:
  electric=maxf(electric,pool.electric)
  stun=maxf(stun,float(pool.get("stun",0.7)))
  pool.node.queue_free()
  water.erase(pool)
 # Only use an arena-wide level once the footprint already covers the arena.
 if radius>=ARENA_RADIUS+Vector2(point.x,point.z).length():
  point=Vector3.ZERO
  radius=ARENA_RADIUS
 var depth:float=total/maxf(0.001,PI*radius*radius)
 var node:MeshInstance3D=disc(point,radius,Color(0.07,0.4,0.72,0.48))
 node.name="ImpactWaterVolume"
 node.mesh.height=maxf(0.01,depth)
 node.position.y=depth*0.5
 node.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
 node.material_override.roughness=0.12
 node.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
 water.append({"point":point,"radius":radius,"depth":depth,"volume":total,"node":node,"electric":electric,"stun":stun})
 for patch in patches:
  if patch.element=="Fire" and flat_distance(patch.point,point)<radius:patch.life=0.0
 update_water_summary()

func update_water_summary() -> void:
 water_volume=0
 flood_depth=0
 flood_radius=0
 flood_electric=0
 flood=null
 for pool in water:
  water_volume+=pool.volume
  flood_electric=maxf(flood_electric,pool.electric)
  if pool.depth>=flood_depth:
   flood_depth=pool.depth
   flood=pool.node
  flood_radius=maxf(flood_radius,pool.radius)

func water_height(point:Vector3) -> float:
 var height:=0.0
 for pool in water:
  if flat_distance(point,pool.point)<pool.radius:height=maxf(height,pool.depth)
 return height

func water_contact(from:Vector3,to:Vector3,radius:float) -> Dictionary:
 var nearest:Dictionary={}
 var nearest_distance:=INF
 for pool in water:
  if minf(from.y,to.y)-radius>pool.depth:continue
  var fraction:float=clampf((from.y-radius-pool.depth)/maxf(0.0001,from.y-to.y),0,1) if from.y-radius>pool.depth else 0.0
  var point:Vector3=from.lerp(to,fraction)
  if flat_distance(point,pool.point)>pool.radius:continue
  if from.distance_to(point)>=nearest_distance:continue
  nearest_distance=from.distance_to(point)
  var cell:=Vector2i(floori(point.x/2.0),floori(point.z/2.0))
  nearest={"position":point,"collider":ice[cell]} if ice.has(cell) else {"position":point}
 return nearest

func freeze_water(point:Vector3,radius:float,potency:float,depth_override:float=-1.0,bounds_override:float=-1.0,bounds_center:Vector3=Vector3.ZERO) -> void:
 var depth:float=flood_depth if depth_override<0 else depth_override
 var bounds:float=flood_radius if bounds_override<0 else bounds_override
 var width:=2.0
 var reach:float=maxf(radius,1.5)
 for x in range(floori((point.x-reach)/width),ceili((point.x+reach)/width)+1):
  for z in range(floori((point.z-reach)/width),ceili((point.z+reach)/width)+1):
   var cell:=Vector2i(x,z)
   var center:=Vector3((x+0.5)*width,0,(z+0.5)*width)
   if Vector2(center.x-point.x,center.z-point.z).length()>reach or flat_distance(center,bounds_center)>bounds:continue
   if ice.has(cell):continue
   var block=preload("res://scripts/spell_ice.gd").new()
   block.environment=self
   block.cell=cell
   add_child(block)
   block.build(center,maxf(0.18,depth),width,potency)
   ice[cell]=block
   for fighter in arena.fighters:
    if absf(fighter.position.x-center.x)<=width*0.5 and absf(fighter.position.z-center.z)<=width*0.5 and fighter.position.y<depth-0.3 and fighter.health>0:
     block.trapped.append(fighter)
     block.add_collision_exception_with(fighter)
     fighter.ice_trapped=true
     fighter.velocity=Vector3.ZERO

func damage_ice_near(point:Vector3,damage:float,radius:float) -> bool:
 var hit:=false
 for block in ice.values()+earth_walls:
  if not is_instance_valid(block) or block.broken:continue
  var extent:Vector3=block.get_child(0).shape.size*0.5
  var offset:Vector3=block.to_local(point).abs()-extent
  if Vector3(maxf(0,offset.x),maxf(0,offset.y),maxf(0,offset.z)).length()<=radius:
   block.take_damage(damage)
   hit=true
 return hit

func draw_sparks() -> void:
 if not is_instance_valid(spark_mesh):return
 var mesh:=ImmediateMesh.new()
 var material:=StandardMaterial3D.new()
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color=Color("fff34b")
 material.emission_enabled=true
 material.emission=Color("ffdf16")
 material.emission_energy_multiplier=2.0
 var regions:Array[Dictionary]=[]
 for pool in water:
  if pool.electric>0:regions.append({"point":pool.point,"radius":pool.radius,"depth":pool.depth})
 if regions.is_empty():
  spark_mesh.mesh=null
  return
 mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
 for region in regions:
  for i in 90 if region.radius>5 else 18:
   var angle:float=spark_rng.randf()*TAU
   var r:float=sqrt(spark_rng.randf())*region.radius
   var point:Vector3=region.point+Vector3(cos(angle)*r,region.depth+0.06 if i%2==0 else spark_rng.randf_range(0.05,maxf(0.06,region.depth)),sin(angle)*r)
   for segment in 4:
    var next:Vector3=point+Vector3(spark_rng.randf_range(-0.22,0.22),spark_rng.randf_range(-0.12,0.12),spark_rng.randf_range(-0.22,0.22))
    mesh.surface_add_vertex(point)
    mesh.surface_add_vertex(next)
    point=next
 mesh.surface_end()
 spark_mesh.mesh=mesh

func support_height(point:Vector3) -> float:
 var height:=0.0
 for block in ice.values()+earth_walls:
  if not is_instance_valid(block) or block.broken:continue
  var half:Vector3=block.get_child(0).shape.size*0.5
  var relative:Vector3=block.to_local(point)
  var top:float=block.position.y+half.y
  if absf(relative.x)<=half.x and absf(relative.z)<=half.z and point.y>=top-0.4:height=maxf(height,top)
 return height

func summon_earth_wall(point:Vector3,direction:Vector3,radius:float,potency:float,centered:bool=false) -> StaticBody3D:
 var wall=preload("res://scripts/spell_earth_wall.gd").new()
 wall.environment=self
 add_child(wall)
 wall.build(point,direction,radius,potency)
 if centered:
  wall.position.x=point.x
  wall.position.z=point.z
 earth_walls.append(wall)
 return wall

func spawn_earth_debris(wall:StaticBody3D) -> void:
 var size:Vector3=wall.get_child(0).shape.size
 for x in 4:
  for y in 3:
   while debris.size()>=96:
    var old:RigidBody3D=debris.pop_front()
    if is_instance_valid(old):old.queue_free()
   var body:=RigidBody3D.new()
   var dimensions:Vector3=Vector3(size.x/4,size.y/3,size.z)*0.85
   body.mass=maxf(0.4,dimensions.x*dimensions.y*dimensions.z*5)
   body.collision_layer=1024
   body.collision_mask=1|1024
   var collider:=CollisionShape3D.new()
   var shape:=BoxShape3D.new()
   shape.size=dimensions
   collider.shape=shape
   body.add_child(collider)
   var visual:=MeshInstance3D.new()
   var mesh:=BoxMesh.new()
   mesh.size=dimensions
   visual.mesh=mesh
   var material:=StandardMaterial3D.new()
   material.albedo_color=Color("8f7451")
   material.roughness=0.95
   visual.material_override=material
   body.add_child(visual)
   add_child(body)
   body.global_transform=wall.global_transform*Transform3D(Basis.IDENTITY,Vector3((x+0.5)*size.x/4-size.x/2,(y+0.5)*size.y/3-size.y/2,0))
   body.apply_central_impulse(Vector3(spark_rng.randf_range(-0.4,0.4),0.3,spark_rng.randf_range(-0.4,0.4))*body.mass)
   debris.append(body)

func steam(point:Vector3,radius:float) -> void:
 for i in 10:
  var offset:=Vector3(spark_rng.randf_range(-radius,radius),0.2,spark_rng.randf_range(-radius,radius))
  arena.vfx.puff(point+offset,"smoke_04",0,Vector2.ONE*spark_rng.randf_range(0.6,1.1),Vector3.UP*spark_rng.randf_range(0.8,1.8),1.4,Color(0.87,0.94,0.98,0.55),0.5)

func react_fire(point:Vector3,radius:float,potency:float,projectile_radius:float) -> void:
 var evaporate:float=maxf(0.02,4.0/3.0*PI*pow(projectile_radius,3)*potency*0.6)
 var wet:=false
 for pool in water.duplicate():
  if flat_distance(point,pool.point)>radius+pool.radius or point.y-radius>pool.depth+0.3:continue
  wet=true
  var removed:float=minf(pool.volume,evaporate)
  pool.volume-=removed
  evaporate-=removed
  steam(Vector3(point.x,pool.depth,point.z),minf(radius,1.5))
  if pool.volume<=0.0001:
   pool.node.queue_free()
   water.erase(pool)
  else:
   # Deep water lowers; shallow puddles shrink around their actual location.
   if pool.depth>0.1201:pool.depth=pool.volume/(PI*pool.radius*pool.radius)
   else:pool.radius=sqrt(pool.volume/(PI*pool.depth))
   pool.node.mesh.top_radius=pool.radius
   pool.node.mesh.bottom_radius=pool.radius
   pool.node.mesh.height=maxf(0.01,pool.depth)
   pool.node.position.y=pool.depth*0.5
  if evaporate<=0:break
 for fighter in arena.fighters:
  if fighter.freeze_time<=0 or flat_distance(point,fighter.position)>radius:continue
  fighter.freeze_time=maxf(0,fighter.freeze_time-2.0*potency)
  if fighter.freeze_time<=0:
   fighter.frost=0
   add_water(0.12,fighter.position)
   steam(fighter.position,0.4)
 for block in ice.values():
  var half:Vector3=block.get_child(0).shape.size*0.5
  var d:Vector3=block.to_local(point).abs()-half
  if Vector3(maxf(0,d.x),maxf(0,d.y),maxf(0,d.z)).length()<=radius:
   block.take_damage(50.0*potency)
   steam(Vector3(point.x,block.position.y+half.y,point.z),0.6)
 update_water_summary()

func ground_fire(point:Vector3,radius:float,appearance:Dictionary) -> Node3D:
 var fire=preload("res://scripts/spell_ground_fire.gd").new()
 add_child(fire)
 fire.position=Vector3(point.x,0,point.z)
 fire.setup(radius,appearance)
 return fire
