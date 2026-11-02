extends SceneTree
const Appearance=preload("res://scripts/spell_appearance.gd")
const Catalog=preload("res://scripts/fire_style_catalog.gd")
func _initialize() -> void:call_deferred("run")
func verify(node:Node3D,transform:Transform3D,radius:float,label:String) -> void:
 var local:Transform3D=transform*node.transform
 if node is MeshInstance3D:
  for surface in node.mesh.get_surface_count():
   var arrays:Array=node.mesh.surface_get_arrays(surface)
   for vertex in arrays[Mesh.ARRAY_VERTEX]:
    assert((local*vertex).length()<=radius+maxf(0.000001,radius*0.00001),"Visual outside hitbox: "+label)
 for child in node.get_children():
  if child is Node3D:verify(child,local,radius,label)
func exercise(element:String,radius:float,look:Dictionary,label:String) -> void:
 var body:=Appearance.visual(element,radius,look)
 for age in [0.0,PI/12.0,PI/4.0,1.5]:
  Appearance.step(body,age,0.9)
  verify(body,Transform3D.IDENTITY,radius,label)
 body.free()
func run() -> void:
 for element in ["Fire","Ice","Lightning","Wind","Water","Earth"]:
  for shape in Appearance.SHAPES:
   for radius in [0.03,0.4,2.5]:
    for orbits in [false,true]:
     exercise(element,radius,{"shape":shape,"orbits":orbits,"pulse":3.0,"drawn_outline":PackedVector2Array([Vector2(0,0),Vector2(1,0.1),Vector2(0.8,1),Vector2(0.1,0.6)])},element+"/"+shape)
 for entry in Catalog.entries():
  exercise("Fire",0.4,Catalog.look(entry.id),entry.id)
 # Actual shared spawn/orientation must preserve the fit for old effect names too.
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world)
 world.set_physics_process(false);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO);actor.brain_enabled=false
 for effect in ["orb","spear","slash","cleave"]:
  world.spawn_projectile(actor,{"id":"fit_"+effect,"effect":effect,"charge":1.0,"projectile_element":"Fire","projectile_radius":0.4,"projectile_velocity":10.0,"aim_direction":Vector3.FORWARD,"appearance":{"shape":"Lance","orbits":true}},Vector3(0,1,0))
  var shot:Dictionary=world.shots.back()
  var body:MeshInstance3D=shot.node
  var position:=body.position;body.position=Vector3.ZERO
  verify(body,Transform3D.IDENTITY,shot.radius,"spawn/"+effect)
  Appearance.step(body,PI/12.0,0.9)
  verify(body,Transform3D.IDENTITY,shot.radius,"pulse/"+effect)
  body.position=position
 print("SPELL HITBOX FIT PASS: every shape and element, tiny/large casts, drawn meshes, orbit rotations and maximum pulse; actual orb/spear/slash/cleave spawn respects fit")
 quit()

