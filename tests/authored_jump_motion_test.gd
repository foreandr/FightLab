extends SceneTree
const Jump=preload("res://scripts/animation_jump_motion.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);var a=w.fighters[0];var b=w.fighters[1]
 var items:Array[Dictionary]=[]
 for item in w.brains[0].loadout:
  if not Jump.settings(item.profile).is_empty():items.append(item)
 assert(items.size()==4)
 for item in items:
  w.clear_battle_effects();w.combat().discard_cast_attempt(a);w.events.clear()
  a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,8));w.round_active=true
  for i in 10:
   await physics_frame
   w.tick_combat(1.0/60.0)
  var minimum:=Jump.minimum(item.profile)
  assert(float(item.duration)>=minimum and float(item.spec.jump_stamina_cost)>=4)
  var bad:Dictionary=item.profile.duplicate(true);bad.duration=minimum*0.5
  assert(not a.start_authored_cast(item.spec,bad,b),"Too-fast airborne clip was allowed")
  var cheap:Dictionary=item.spec.duplicate(true);cheap.erase("jump_stamina_cost")
  assert(not a.start_authored_cast(cheap,item.profile,b),"Jump was allowed without its stamina cost")
  var before:float=a.stamina_spent
  a.parry_cast_haste.grant(10)
  assert(a.start_authored_cast(item.spec,item.profile,b))
  assert(a.cast_speed_multiplier()<=float(item.duration)/minimum+0.00001,"Haste bypassed jump minimum duration")
  var peak:=0.0;var took_off:=false;var landed:=false;var tail_on_floor:=false
  for i in 190:
   await physics_frame
   w.tick_combat(1.0/60.0)
   peak=maxf(peak,a.position.y-w.ground_height(a.position))
   if not a.is_on_floor():took_off=true
   if took_off and a.is_on_floor():
    landed=true
    if a.mode=="cast":tail_on_floor=true
   if landed and a.mode!="cast" and i>120:break
  assert(took_off and landed and peak>0.5 and tail_on_floor,"Missing actual launch, gravity landing or authored recovery tail: "+str(item.title))
  var launches:Array=w.events.filter(func(e):return e.event=="animation_jump")
  assert(launches.size()==1,"Double jump impulse")
  assert(is_equal_approx(a.stamina_spent-before,float(item.spec.stamina_cost)),"Jump/cast cost was not paid exactly once")
  print("AUTHORED JUMP ",item.title," min=",minimum," peak=",peak," jump stamina=",item.spec.jump_stamina_cost," total=",item.spec.stamina_cost)
 assert(Jump.settings({"clip":"fight/spin_sweep"}).is_empty() and Jump.settings({"clip":"fight/slide_kick"}).is_empty(),"Ground moves were turned into jumps")
 # An existing ordinary jump may carry this attack, without a second launch.
 w.combat().discard_cast_attempt(a);a.reset_fighter(Vector3.ZERO);w.round_active=true
 for i in 8:
  await physics_frame
  w.tick_combat(1.0/60.0)
 assert(a.start_motion_jump(0.5))
 while a.is_on_floor():
  await physics_frame
  w.tick_combat(1.0/60.0)
 w.events.clear()
 var velocity:float=a.velocity.y
 assert(a.start_authored_cast(items[0].spec,items[0].profile,b))
 for i in 25:
  await physics_frame
  w.tick_combat(1.0/60.0)
  assert(a.velocity.y<=velocity+0.001,"Air attack added a second jump impulse")
  velocity=a.velocity.y
 assert(w.events.filter(func(e):return e.event=="animation_jump").is_empty())
 print("AUTHORED JUMP PASS: four declared airborne moves, actual actor takeoff/gravity/landing, native recovery tail, minimum duration including haste, mandatory priced jump, one payment/launch; grounded sweeps/slides unchanged")
 quit()
