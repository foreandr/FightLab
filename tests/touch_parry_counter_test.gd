extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var a=w.fighters[0];var b=w.fighters[1];var punch:Dictionary=w.brains[0].loadout[1]
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.7));a.rotation.y=0;b.rotation.y=PI
 for i in 10:
  await physics_frame
  w.tick_combat(1.0/60.0)
 a.guard_energy=0;b.guard_energy=0
 var shield:=Rules.author(Rules.self_barrier_base(),1.0,0.3,false);shield.shield_strength=40
 assert(w.combat().release(b,shield,b.position));b.self_barrier.age=0.05
 assert(a.start_authored_cast(punch.spec,punch.profile,b))
 # Resolve the first genuine jab contact while the perfect window is open.
 var parried:=false
 for i in 50:
  b.self_barrier.age=0.05
  await physics_frame
  w.tick_combat(1.0/60.0)
  if a.touch_parry_recovery>0:
   parried=true;break
 assert(parried and a.touch_parry_recovery>=0.18 and a.touch_parry_recovery<=0.43)
 var stamina:float=a.stamina;var mana:float=a.mana
 assert(not a.chain_touch_cast(punch.spec,punch.profile,b))
 assert(not w.combat().can_start_cast(a,punch.spec))
 assert(not w.combat().authorize_cast(a,punch.spec,punch.profile))
 assert(a.stamina==stamina and a.mana==mana,"Denied follow-up spent resources")
 b.self_barrier.clear()
 # Isolate the new recovery penalty from the existing defender haste reward.
 b.parry_cast_haste.clear()
 assert(b.start_authored_cast(punch.spec,punch.profile,a),"Parry defender couldn't immediately counter")
 assert(is_equal_approx(a.cast_speed_multiplier(),b.cast_speed_multiplier()))
 var old_clock:float=a.cast_time
 var first_hit:=-1
 for i in 50:
  await physics_frame
  w.tick_combat(1.0/60.0)
  # Attacker keeps trying an equally fast punch through the normal link API.
  if a.mode=="cast":a.chain_touch_cast(punch.spec,punch.profile,b)
  for event in w.events:
   if event.event=="hit":first_hit=int(event.team);break
  if first_hit>=0:break
 assert(first_hit==b.team,"Perfect-parry defender lost the equal-speed counter race")
 assert(a.cast_time>old_clock or a.combat_reaction_active(),"Parry froze the current animation")
 a.reset_fighter(a.position);assert(a.touch_parry_recovery==0)
 print("TOUCH COUNTER PASS: real perfect-parried jab, brief follow-up lock, current follow-through continues, no cost on denied action, defender wins actual equal-speed counter hit, reset clears status")
 quit()
