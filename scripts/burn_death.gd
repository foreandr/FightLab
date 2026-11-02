extends Node3D
## Shared terminal burn presentation; owns corpse motion even after round end.
const WRITHE_SECONDS:=1.15
const ASH_SECONDS:=1.25
var actor:CharacterBody3D
var age:=0.0
var pulse:=0.0
var materials:Array[ShaderMaterial]=[]
var originals:Array[Dictionary]=[]
var hit_areas:Dictionary={}
var ash:Node3D
var dust:CPUParticles3D
var finished:=false
func setup(owner_actor:CharacterBody3D)->void:
 actor=owner_actor
 name="BurnDeath"
 actor.player.pause()
 for pair in actor.targets+actor.limb_targets:hit_areas[pair[0]]=pair[0].collision_layer
 if is_instance_valid(actor.practice_dummy_visual):
  for area in actor.practice_dummy_visual.hurtboxes:hit_areas[area]=area.collision_layer
 for root_node in [actor.model,actor.practice_dummy_visual]:
  if not is_instance_valid(root_node):continue
  var meshes:Array=root_node.find_children("*","MeshInstance3D",true,false)
  if root_node is MeshInstance3D:meshes.append(root_node)
  for mesh:MeshInstance3D in meshes:
   if mesh.mesh==null:continue
   var record:Dictionary={"node":mesh,"visible":mesh.visible,"override":mesh.material_override,"surfaces":[]}
   for surface in mesh.mesh.get_surface_count():
    record.surfaces.append(mesh.get_surface_override_material(surface))
    var source:Material=mesh.get_active_material(surface)
    var material:=ShaderMaterial.new()
    material.shader=preload("res://assets/combat/vfx/burn_to_ash.gdshader")
    material.set_shader_parameter("progress",0.0)
    if source is BaseMaterial3D:
     material.set_shader_parameter("base_color",source.albedo_color)
     material.set_shader_parameter("use_texture",source.albedo_texture!=null)
     if source.albedo_texture!=null:material.set_shader_parameter("base_texture",source.albedo_texture)
    mesh.set_surface_override_material(surface,material)
    materials.append(material)
   mesh.material_override=null
   originals.append(record)
func is_burning()->bool:return not finished
func _physics_process(delta:float)->void:
 if not is_instance_valid(actor):queue_free();return
 if finished:return
 age+=delta
 if is_instance_valid(actor.ragdoll):
  actor.ragdoll.step(delta)
  pulse-=delta
  if age<WRITHE_SECONDS and pulse<=0.0:
   pulse=0.16
   var fade:=1.0-age/WRITHE_SECONDS
   for key in ["chest","arm_l","arm_r","thigh_l","thigh_r"]:
    if not actor.ragdoll.bodies.has(key):continue
    var body:RigidBody3D=actor.ragdoll.bodies[key]
    if body.freeze:continue
    var sign_:float=-1.0 if key.ends_with("l") else 1.0
    body.apply_torque_impulse(Vector3(sin(age*19.0)*0.32,0.08*sign_,cos(age*15.0)*0.22)*fade)
    body.angular_velocity=body.angular_velocity.limit_length(3.0)
 var progress:=clampf((age-WRITHE_SECONDS)/ASH_SECONDS,0.0,1.0)
 for material in materials:material.set_shader_parameter("progress",progress)
 if progress>0.0 and not is_instance_valid(ash):make_ash()
 if is_instance_valid(ash):ash.scale=Vector3.ONE*maxf(0.01,progress)
 if is_instance_valid(dust):dust.emitting=progress>0.0 and progress<0.95
 if progress>=1.0:
  finished=true
  actor.mode="ko"
  actor.velocity=Vector3.ZERO
  for area in hit_areas:
   if is_instance_valid(area):area.collision_layer=0
  for record in originals:
   if is_instance_valid(record.node):record.node.hide()
  if is_instance_valid(actor.ragdoll):
   actor.ragdoll.queue_free();actor.ragdoll=null
  if is_instance_valid(actor.burn_visual):actor.burn_visual._process(0.0)
func make_ash()->void:
 var origin:Vector3=actor.ragdoll.location() if is_instance_valid(actor.ragdoll) else actor.global_position
 var ground:Dictionary=actor.arena.ground_contact(origin)
 ash=Node3D.new();ash.name="AshRemains";add_child(ash)
 ash.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,ground.normal)),ground.position+ground.normal*0.015)
 var mound:=MeshInstance3D.new()
 var mesh:=SphereMesh.new();mesh.radius=0.5;mesh.height=1.0;mesh.radial_segments=16;mesh.rings=8
 mound.mesh=mesh;mound.scale=Vector3(1.0,0.10,0.65)
 var material:=StandardMaterial3D.new();material.albedo_color=Color("38332e");material.roughness=1.0
 mound.material_override=material;ash.add_child(mound)
 dust=CPUParticles3D.new();dust.amount=55;dust.lifetime=1.1;dust.local_coords=false
 dust.emission_shape=CPUParticles3D.EMISSION_SHAPE_POINTS
 var points:=PackedVector3Array()
 for bone in ["Head","spine_03","pelvis","hand_l","hand_r","foot_l","foot_r"]:points.append(to_local(actor.bone_point(bone)))
 dust.emission_points=points;dust.direction=Vector3.UP;dust.spread=65;dust.gravity=Vector3(0.2,-0.12,0.06)
 dust.initial_velocity_min=0.2;dust.initial_velocity_max=0.6
 dust.scale_amount_min=0.015;dust.scale_amount_max=0.045
 var flake:=QuadMesh.new();flake.size=Vector2.ONE
 var dust_material:=StandardMaterial3D.new();dust_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 dust_material.vertex_color_use_as_albedo=true;dust_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 dust_material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
 dust_material.billboard_keep_scale=true
 flake.material=dust_material;dust.mesh=flake
 var gradient:=Gradient.new();gradient.colors=PackedColorArray([Color(0.2,0.17,0.14,0.8),Color(0.3,0.28,0.25,0.0)])
 dust.color_ramp=gradient;add_child(dust)
func restore()->void:
 set_physics_process(false)
 for area in hit_areas:
  if is_instance_valid(area):area.collision_layer=hit_areas[area]
 hit_areas.clear()
 for record in originals:
  if not is_instance_valid(record.node):continue
  record.node.material_override=record.override
  record.node.visible=record.visible
  for surface in record.surfaces.size():record.node.set_surface_override_material(surface,record.surfaces[surface])
 originals.clear()
 queue_free()
