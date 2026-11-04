extends SceneTree
const Timing=preload("res://scripts/ragdoll_recovery_timing.gd")
var w
var a
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func tick(count:int):
 for i in count:await physics_frame;w.tick_combat(1.0/60)
func knockdown():
 w.clear_battle_effects();a.reset_fighter(Vector3(0,0.03,0));w.fighters[1].reset_fighter(Vector3(10,0,0));w.round_active=true
 await tick(8)
 a.player_controlled=true;a.stamina=20;a.mana=20;a.stamina_delay=0;a.mana_delay=0;a.guard_energy=0
 a.start_ragdoll(Vector3(200,0,0),a.bone_point("spine_03"))
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 w=current_scene;w.set_physics_process(false);a=w.fighters[0]
 await knockdown()
 assert(a.recovery_timing.offered() and a.recovery_timing.progress()==0.0)
 assert(a.try_quick_recovery()=="" and a.recovery_timing.waiting(),"Unaffordable recovery used the chance")
 await tick(10)
 assert(a.mode=="ragdoll" and is_equal_approx(a.stamina,20+34.0*10/60) and is_equal_approx(a.stamina,a.mana),"Ragdoll regeneration changed")
 for fraction in [0.0,0.5,1.0,2.0]:
  await knockdown();a.stamina=100;a.recovery_timing.age=Timing.WINDOW*fraction
  var cost:float=a.recovery_timing.stamina_cost()
  assert(is_equal_approx(cost,30.0*(1.0-clampf(fraction,0,1))))
  assert(a.try_quick_recovery()=="Recovered" and is_equal_approx(a.stamina,100-cost))
  assert(a.try_quick_recovery()=="Recovered" and is_equal_approx(a.stamina,100-cost))
  await tick(1);assert(a.mode=="getup" and is_equal_approx(a.mode_length,Timing.RECOVERY_GETUP_SECONDS))
  a.stamina=20;a.mana=20;a.stamina_delay=0;a.mana_delay=0
  await tick(3);assert(a.stamina>20 and is_equal_approx(a.stamina,a.mana))
 await knockdown()
 for i in 600:
  await tick(1)
  if a.mode=="getup":break
 assert(a.mode=="getup" and is_equal_approx(a.mode_length,Timing.NORMAL_GETUP_SECONDS),"Waiting did not recover naturally")
 await knockdown();a.health=0
 assert(a.try_quick_recovery()=="");await tick(120);assert(a.mode=="ragdoll")
 a.reset_fighter(Vector3.ZERO);assert(not a.recovery_timing.running)
 print("RECOVERY TIMING PASS: immediate voluntary recovery, continuous cost 30 to 0, retry when affordable, no duplicate payment, unchanged regeneration and dead exclusions")
 quit()
