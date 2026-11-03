extends SceneTree
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Momentum=preload("res://scripts/physical_momentum.gd")
var w
var a
var b
var knee:Dictionary
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func reset(gap:float):
 w.clear_battle_effects();w.combat().discard_cast_attempt(a);w.events.clear()
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,gap));a.rotation.y=0;b.rotation.y=PI
 w.round_active=true
 for i in 10:
  await physics_frame
  w.tick_combat(1.0/60.0)
 b.guard_energy=0;b.damage_taken=0;a.damage_dealt=0
func launch(speed:float):
 a.mode="chase";a.drive_velocity=Vector3.BACK*speed;a.velocity=Vector3.BACK*speed
 preload("res://scripts/editor_rig_pose.gd").sample(a,"duel/run",0.27)
 var before:=Pose.capture(a)
 assert(a.start_authored_cast(knee.spec,knee.profile,b))
 assert(a.authored_entry_pose==before,"Entry discarded the actual running pose")
 a.advance_animation(0.0)
 for index in a.skeleton.get_bone_count():
  assert(a.skeleton.get_bone_pose(index).is_equal_approx(before[index]),"Frame-zero run -> knee snapped")
func impact(speed:float,gap:float)->Vector2:
 await reset(gap);launch(speed)
 for i in 85:
  await physics_frame
  w.tick_combat(1.0/60.0)
  if b.damage_taken>0:
   var movement:=Momentum.melee_movement(a)
   var hit:Dictionary={}
   for event in w.events:
    if event.event=="hit":hit=event
   assert(not hit.is_empty())
   var region:float=preload("res://scripts/combat_hit_regions.gd").physical_multiplier(str(hit.zone))
   var expected:float=w.damage_for(knee.spec)*Momentum.melee_multiplier(movement,Vector3.BACK,{"effect":"melee"})*region
   print("KNEE IMPACT speed=",speed," gap=",gap," actual=",b.damage_taken," expected=",expected," carry=",movement," region=",hit.zone)
   assert(is_equal_approx(b.damage_taken,expected),"Momentum was lost or applied more than once")
   return Vector2(b.damage_taken/region,Momentum.horizontal_speed(movement))
 assert(false,"Knee failed to connect at speed="+str(speed)+" gap="+str(gap))
 return Vector2.ZERO
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 w=current_scene;w.set_physics_process(false);a=w.fighters[0];b=w.fighters[1];knee=w.brains[0].loadout[10]
 await reset(10.0);launch(8.2)
 var last_speed:=8.2
 for i in 18:
  await physics_frame
  w.tick_combat(1.0/60.0)
  var speed:float=Vector2(a.velocity.x,a.velocity.z).length()
  assert(speed>0.1 and speed<=last_speed+0.001,"Run -> knee stopped abruptly or accelerated")
  assert(last_speed-speed<=0.57,"Braking contains a speed discontinuity")
  last_speed=speed
 assert(last_speed>1.5,"Sprint momentum vanished before contact")
 var still:=await impact(0.0,0.50)
 var walk:=await impact(3.0,0.85)
 var sprint:=await impact(8.2,1.3)
 assert(sprint.x>walk.x and walk.x>still.x,"Running knee does not smoothly inherit movement damage")
 # Old carry cannot buff a stationary later attack or an interrupted attack.
 a.mode="idle";a.velocity=Vector3.ZERO
 assert(Momentum.melee_movement(a).is_zero_approx())
 await reset(10.0);launch(8.2)
 for i in 75:
  await physics_frame
  w.tick_combat(1.0/60.0)
 assert(a.mode!="cast" and a.authored_entry_pose.is_empty(),"Exit blend did not finish")
 print("RUN ATTACK PASS: identical initial sprint pose, gradual braking, preserved leg cast, real static/walk/sprint knee damage (damage,impact speed): ",still," / ",walk," / ",sprint,"; no stale momentum, clean return")
 quit()
