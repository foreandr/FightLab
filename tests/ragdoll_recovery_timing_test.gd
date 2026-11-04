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
 a.stamina=20;a.mana=20;a.stamina_delay=0;a.mana_delay=0;a.guard_energy=0
 a.start_ragdoll(Vector3(200,0,0),a.bone_point("spine_03"))
func getup()->float:
 for i in 360:
  await tick(1)
  if a.mode=="getup":return a.mode_length
 assert(false,"Ragdoll never reached recovery")
 return -1
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 w=current_scene;w.set_physics_process(false);a=w.fighters[0]
 await knockdown()
 assert(a.recovery_timing.offered() and a.recovery_timing.progress()==0.0,"Recovery must be offered immediately on knockdown")
 await tick(10)
 assert(a.mode=="ragdoll" and a.stamina>25 and a.mana>25,"Ragdoll stopped resource recovery")
 assert(is_equal_approx(a.stamina,20+34.0*10/60) and is_equal_approx(a.stamina,a.mana),"Ragdoll recovery not exactly once at shared rate")
 a.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.90
 var stamina:float=a.stamina
 assert(a.try_quick_recovery()=="Perfect" and a.stamina==stamina)
 assert(a.try_quick_recovery()=="Perfect" and a.stamina==stamina,"Repeat attempt charged or changed result")
 var fast:float=await getup();assert(is_equal_approx(fast,0.65/1.32))
 a.stamina=20;a.mana=20;a.stamina_delay=0;a.mana_delay=0
 await tick(3);assert(a.stamina>20 and is_equal_approx(a.stamina,a.mana),"Getting up stopped regeneration")
 await knockdown();a.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.75
 stamina=a.stamina
 assert(a.try_quick_recovery()=="Good" and is_equal_approx(stamina-a.stamina,10))
 var medium:float=await getup();assert(is_equal_approx(medium,1.10/1.32) and medium>fast)
 await knockdown();a.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.2
 stamina=a.stamina;assert(a.try_quick_recovery()=="Miss" and a.stamina==stamina)
 var slow:float=await getup();assert(slow>medium)
 await knockdown();a.stamina=5;a.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.75
 assert(a.try_quick_recovery()=="Miss" and a.stamina==5,"Yellow succeeds without stamina")
 a.reset_fighter(Vector3.ZERO);assert(not a.recovery_timing.running)
 await knockdown();a.health=0
 assert(a.try_quick_recovery()=="");await tick(120);assert(a.mode=="ragdoll","Dead fighter got up")
 print("RAGDOLL TIMING PASS: living ragdoll/get-up regen once at 34/s; perfect free 0.49s; yellow costs10 and 0.83s; miss normal ",slow,"s; no retries, insufficient stamina, reset and dead exclusions")
 quit()
