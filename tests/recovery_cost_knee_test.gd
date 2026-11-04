extends SceneTree
const Timing=preload("res://scripts/ragdoll_recovery_timing.gd")
var s
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 s=current_scene
 while not s.animation_browser.ready_catalog:await process_frame
 var b=s.spell_builder
 b.stop_preview_controls(true);b.set_process(false);b.set_physics_process(false);s.field.set_physics_process(false);s.target_behavior.set_physics_process(false)
 var a=s.actor;var cpu=s.target
 a.editor_pose_locked=false;cpu.editor_pose_locked=false
 for fraction in [0.0,0.25,0.5,1.0,2.0]:
  a.reset_fighter(Vector3(0,0,0));a.player_controlled=true;a.stamina=100
  a.start_ragdoll(Vector3.BACK*200,a.bone_point("spine_03"))
  a.recovery_timing.age=Timing.WINDOW*fraction
  var cost:float=a.recovery_timing.stamina_cost()
  assert(is_equal_approx(cost,30.0*(1.0-clampf(fraction,0.0,1.0))))
  assert(a.try_quick_recovery()=="Recovered" and is_equal_approx(a.stamina,100.0-cost))
  assert(a.try_quick_recovery()=="Recovered" and is_equal_approx(a.stamina,100.0-cost),"Duplicate recovery payment")
 a.reset_fighter(Vector3(0,3,0));a.player_controlled=true;a.stamina=5
 a.start_ragdoll(Vector3.BACK*200,a.bone_point("spine_03"))
 assert(a.try_quick_recovery()=="" and a.recovery_timing.waiting(),"Unaffordable recovery consumed attempt")
 a.recovery_timing.age=Timing.WINDOW
 assert(a.try_quick_recovery()=="Recovered")
 a.tick(0.01)
 assert(a.mode=="getup" and a.position.y>1.5,"Immediate air recovery snapped to floor or waited for landing")
 var height:float=a.position.y
 await physics_frame;a.tick(0.05)
 assert(a.mode=="getup" and a.position.y!=height,"Air recovery froze flight")
 a.reset_fighter(Vector3.ZERO);a.player_controlled=true;a.editor_pose_locked=false
 cpu.reset_fighter(Vector3(0,0,3));cpu.editor_pose_locked=false
 s.field.round_active=true;s.target_behavior.set_behavior("Perfect knee")
 var start:float=cpu.position.distance_to(a.position)
 var hit:=false
 for frame in 900:
  await physics_frame
  s.target_behavior.step(1.0/60.0);s.field.tick_combat(1.0/60.0)
  if is_instance_valid(a.ragdoll):hit=true;break
 assert(s.target_behavior.attacks_started>0,"Knee tester never attacked")
 assert(cpu.position.distance_to(a.position)<start,"Knee tester never approached")
 assert(hit and a.last_physical_impact_damage>=24.0,"Perfect knee did not land with shared 24-damage ragdoll")
 print("RECOVERY COST + KNEE PASS: continuous 30-to-0 cost, retry if unaffordable, one payment, immediate airborne recovery preserves flight; CPU walks up and lands perfect knee for ",a.last_physical_impact_damage)
 while s.animation_browser.thumbnails.busy or not s.animation_browser.thumbnails.jobs.is_empty():await process_frame
 quit()
