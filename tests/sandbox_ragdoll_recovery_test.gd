extends SceneTree
const Timing=preload("res://scripts/ragdoll_recovery_timing.gd")
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var screen=current_scene;var b=screen.spell_builder
 while not screen.animation_browser.ready_catalog:await process_frame
 b.draft_path="user://logs/recovery_sandbox_draft.cfg";b.preview_preferences_path="user://logs/recovery_sandbox_preview.cfg"
 b.stop_preview_controls(true);b.set_process(false);b.set_physics_process(false);screen.field.set_physics_process(false)
 var actor=screen.actor;var cpu=screen.target
 assert(actor.player_controlled and not cpu.player_controlled,"Sandbox does not declare human/CPU ownership")
 actor.start_ragdoll(Vector3.BACK*200.0,actor.bone_point("spine_03"))
 await process_frame;await process_frame
 assert(actor.recovery_timing.offered(),"Recovery must be available immediately")
 actor.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.92
 await process_frame
 assert(is_instance_valid(actor.recovery_prompt) and actor.recovery_prompt.visible,"Sandbox recovery prompt is missing")
 var stamina:float=actor.stamina
 var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.pressed=true
 b._input(event)
 assert(actor.recovery_timing.result=="Recovered" and is_equal_approx(actor.stamina,stamina-Timing.MAX_STAMINA_COST*0.08),"Sandbox Space did not pay shared recovery cost")
 assert(not actor.motion_jump_held,"Recovery Space also charged a jump")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/sandbox_recovery_prompt.png")
 actor.reset_fighter(actor.position);await process_frame;await process_frame
 assert(not actor.recovery_prompt.visible)
 cpu.rng.seed=9147
 var counts:Dictionary={"Recovered":0,"":0};var attempts:Dictionary={}
 for trial in 40:
  cpu.reset_fighter(Vector3(0,0,3));cpu.stamina=100;cpu.mana=100;screen.field.round_active=true
  cpu.start_ragdoll(Vector3.BACK*200.0,cpu.bone_point("spine_03"))
  for i in 190:
   cpu.recovery_timing.step(0.01,cpu)
   if not cpu.recovery_timing.waiting():break
  var result:String=cpu.recovery_timing.result
  counts[result]+=1
  attempts[snappedf(cpu.recovery_timing.age,0.01)]=true
  assert(is_equal_approx(cpu.stamina,100.0-cpu.recovery_timing.stamina_cost() if result=="Recovered" else 100.0),"CPU bypassed shared recovery payment")
  var age:float=cpu.recovery_timing.age;cpu.recovery_timing.step(0.5,cpu)
  assert(cpu.recovery_timing.result==result and (cpu.recovery_timing.age==age if result=="Recovered" else cpu.recovery_timing.waiting()),"CPU rerolled recovery")
  await process_frame
 assert(counts.Recovered>0 and counts.Recovered<20 and counts[""]>20 and attempts.size()>3,"CPU recovery timing is not varied")
 cpu.reset_fighter(cpu.position);cpu.player_controlled=false
 cpu.start_ragdoll(Vector3.BACK*200.0,cpu.bone_point("spine_03"))
 cpu.recovery_timing.cpu_policy.target_progress=0.92
 for i in 180:
  cpu.tick(0.01)
  if not cpu.recovery_timing.waiting():break
 assert(cpu.recovery_timing.result=="Recovered","Shared actor tick never ran CPU recovery")
 cpu.reset_fighter(cpu.position);cpu.player_controlled=true
 cpu.start_ragdoll(Vector3.BACK*200.0,cpu.bone_point("spine_03"))
 cpu.recovery_timing.step(Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.95,cpu)
 assert(cpu.recovery_timing.result.is_empty(),"CPU recovery took over human input")
 cpu.health=0;cpu.recovery_timing.step(0.01,cpu)
 assert(cpu.recovery_timing.result.is_empty(),"Dead CPU tried recovery")
 print("SANDBOX RECOVERY PASS: visible Space prompt, cost paid via actual builder input, no jump, reset hides; CPU results ",counts," at ",attempts.size()," distinct timings; shared stamina/no retry/dead/human rules")
 while screen.animation_browser.thumbnails.busy or not screen.animation_browser.thumbnails.jobs.is_empty():await process_frame
 quit()
