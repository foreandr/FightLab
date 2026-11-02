extends SceneTree
const Fire=preload("res://scripts/spell_ground_fire.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var world=preload("res://scripts/combat_world.gd").new()
 root.add_child(world);world.set_physics_process(false);world.round_active=true
 var pit=preload("res://scenes/maps/gladiatorial_pit.tscn").instantiate();world.add_child(pit)
 var caster=world.spawn_combatant(0,Vector3(-8,0,0));caster.brain_enabled=false
 await physics_frame;await physics_frame
 # Actual shared projectile collision against the pit floor, at four hitbox sizes.
 for radius in [0.03,0.2,0.8,2.0]:
  var before:int=world.spell_environment.patches.size()
  world.spawn_projectile(caster,{"id":"floor_size","effect":"orb","projectile_element":"Fire","potency":1.0,"damage":0.0,"projectile_radius":radius,"projectile_velocity":10.0,"unrestricted_preview":true,"aim_direction":Vector3.DOWN},Vector3(4,5,0))
  for i in 100:
   world.step_shots(1.0/60.0)
   if world.shots.is_empty():break
  assert(world.spell_environment.patches.size()==before+1,"Floor cast did not create its fire patch")
  var patch:Dictionary=world.spell_environment.patches.back()
  assert(is_equal_approx(float(patch.radius),radius),"Floor burn radius is inflated")
  assert(patch.node.get_child(0).mesh.size.is_equal_approx(Vector2.ONE*radius*2.0))
 # Tiny flames have no fixed minimum, large flames have no fixed height cap.
 # Check the projected footprint on ground, wall and sloping surfaces.
 for normal in [Vector3.UP,Vector3.FORWARD,Vector3(0,1,1).normalized()]:
  for radius in [0.03,0.2,0.8,2.0]:
   var fire:=Fire.new();root.add_child(fire);fire.setup(radius,{},normal)
   for i in fire.flames.size():
    var flame:MeshInstance3D=fire.flames[i]
    var height:float=flame.mesh.size.y
    assert(is_equal_approx(height/radius,0.9*(0.7+float(i%4)*0.17)),"Flame dimensions do not scale with hitbox")
    var tangent:Vector3=flame.position-normal*flame.position.dot(normal)
    var up:Vector3=Vector3.UP-normal*normal.dot(Vector3.UP)
    var extent:float=flame.mesh.size.x*0.5+height*0.5*up.length()
    assert(tangent.length()+extent<=radius+0.00001,"Flame footprint exceeds hitbox on surface")
   assert(is_equal_approx(fire.embers.initial_velocity_max,1.25*radius/0.8))
   assert(is_equal_approx(fire.smoke.scale_amount_max,0.4*radius/0.8))
   fire.free()
 print("SURFACE FIRE SIZE PASS: actual floor impacts use exact projectile hitbox radius; tiny/large flames, scorch, embers and smoke scale; ground/wall/slope footprints remain bounded")
 quit()
