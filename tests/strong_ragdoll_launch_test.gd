extends SceneTree
const Rules=preload("res://scripts/combat_defense_rules.gd")
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=60;Engine.time_scale=4.0
 assert(Rules.ragdoll_launch_velocity(Vector3.ZERO,Vector3.ZERO,75.0)==Vector3.ZERO,"Burn/no-impact death acquired a launch")
 var slam:=Rules.ragdoll_launch_velocity(Vector3.ZERO,Vector3(100,-300,0),75.0)
 assert(slam.y<0.0,"Downward slam turned upward")
 var world=load("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;floor_body.collision_mask=0
 var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(60,0.2,60);collision.shape=box;floor_body.add_child(collision);world.add_child(floor_body);floor_body.position.y=-0.1
 var attacker=world.spawn_combatant(0,Vector3.ZERO)
 var victim=world.spawn_combatant(1,Vector3(0,0,3))
 for i in 3:await physics_frame
 for lethal in [false,true]:
  victim.reset_fighter(Vector3(0,0,3));victim.guard_energy=0;victim.invulnerability=0;victim.velocity=Vector3.ZERO
  victim.health=10.0 if lethal else 100.0;world.round_active=true
  await physics_frame;await physics_frame
  var chest:Area3D
  for pair in victim.targets:
   if str(pair[0].get_meta("zone",""))=="chest":chest=pair[0];break
  var damage:=12.0 if lethal else 30.0
  assert(world.apply_impact(attacker,victim,{"id":"right_knee_finisher","effect":"touch","delivery_type":"Touch","hand":"calf_r","touch_contacts":["calf_r"],"damage":damage},chest.global_position,Vector3.BACK,chest,Vector3.BACK*80.0))
  assert(is_instance_valid(victim.ragdoll))
  var rag=victim.ragdoll
  var minimum:=7.5 if lethal else 6.0
  assert(rag.initial_velocity.y>=minimum and Vector2(rag.initial_velocity.x,rag.initial_velocity.z).length()>=minimum)
  var start:Vector3=rag.location();var peak:=0.0;var distance:=0.0
  rag.step(1.0/60.0);rag.step(1.0/60.0)
  for i in 48:
   await physics_frame
   rag.step(1.0/60.0)
   peak=maxf(peak,rag.location().y-start.y)
   distance=maxf(distance,Vector2(rag.location().x-start.x,rag.location().z-start.z).length())
   for body in rag.bodies.values():assert(body.linear_velocity.is_finite() and body.global_position.is_finite())
  assert(peak>0.55 and distance>1.5,"Ragdoll failed to travel up/back under real physics: "+str([lethal,peak,distance]))
  print("STRONG RAGDOLL ","finishing knee" if lethal else "30 physical hit"," rise=",peak," distance=",distance)
 world.queue_free();await process_frame
 Engine.time_scale=1.0
 print("STRONG RAGDOLL PASS: physical threshold launch, lethal low-damage knee launches up/back, bounded physics, no-impact death and slams preserved")
 quit()
