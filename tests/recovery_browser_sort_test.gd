extends SceneTree
const Recovery=preload("res://scripts/recovery_animation.gd")
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.spell_builder;var browser=s.animation_browser
 while not browser.ready_catalog:await process_frame
 browser.preferences_path="user://logs/recovery_sort_test.cfg"
 b.preview_preferences_path="user://logs/recovery_browser_prefs.cfg";b.draft_path="user://logs/recovery_browser_draft.cfg"
 s.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 b.stop_preview_controls(true)
 assert(browser.type_buttons.has("Recovery") and browser.sort_choice.item_count==3)
 browser.set_type("Recovery")
 assert(browser.matches_.size()>=2,"Recovery category omitted the new default or existing get-ups")
 var chosen:Dictionary={}
 for entry in browser.matches_:
  assert(entry._recovery)
  if entry.clip==Recovery.CLIP:chosen=entry
 assert(not chosen.is_empty() and browser.select_animation(chosen))
 b.stop_preview_controls(true)
 assert(is_equal_approx(b.playback_animation().source_duration,Recovery.ANIMATION.length/1.32))
 assert(Recovery.ANIMATION.length>0.9 and Recovery.ANIMATION.length<1.1 and Recovery.ANIMATION.get_meta("playback_speed")==2.0)
 var credited:=false
 for node in Recovery.ANIMATION.get_meta("provenance").nodes.values():
  if node.author=="Haley Tuffles":credited=true
 assert(credited,"Arms Lariat source credit missing")
 browser.set_type("Arm");browser.search.text="";browser.sort_descending=false
 var detail_reads:int=browser.detail_loads
 var measured:=Time.get_ticks_usec()
 for mode in 3:
  browser.sort_descending=false;browser.set_sort(mode)
  for i in range(1,browser.matches_.size()):
   var a:Dictionary=browser.matches_[i-1];var c:Dictionary=browser.matches_[i]
   if mode==0:assert(str(a.title).naturalnocasecmp_to(str(c.title))<=0)
   else:
    var key:="_duration_min" if mode==1 else "_duration_max"
    assert(float(a[key])<=float(c[key])+0.00001)
  browser.toggle_sort_direction()
  for i in range(1,browser.matches_.size()):
   var a:Dictionary=browser.matches_[i-1];var c:Dictionary=browser.matches_[i]
   if mode==0:assert(str(a.title).naturalnocasecmp_to(str(c.title))>=0)
   else:
    var key:="_duration_min" if mode==1 else "_duration_max"
    assert(float(a[key])+0.00001>=float(c[key]))
 assert(browser.detail_loads==detail_reads,"Sorting loaded animation detail records")
 var reloaded=load("res://scripts/sandbox_animation_browser.gd").new();reloaded.preferences_path=browser.preferences_path;reloaded.load_preferences()
 assert(reloaded.sort_mode==2 and reloaded.sort_descending);reloaded.free()
 print("SORT PASS: alphabetical/min/max both directions, persisted preference, metadata-only sorting; total ms ",(Time.get_ticks_usec()-measured)/1000.0)
 browser.sort_descending=false;browser.set_sort(0);browser.set_type("Recovery")
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/recovery_category_sort.png")
 var actor=s.actor
 actor.start_ragdoll(Vector3.BACK*100,actor.bone_point("spine_03"));actor.recovery_timing.age=actor.recovery_timing.OPPORTUNITY_DELAY+actor.recovery_timing.WINDOW*0.95
 assert(actor.try_quick_recovery()=="Recovered")
 actor.finish_ragdoll()
 assert(actor.mode=="getup" and actor.clip==Recovery.CLIP and is_equal_approx(actor.mode_length,0.65/1.32))
 assert(actor.recovery_target.size()==actor.skeleton.get_bone_count(),"Recovery does not own the full skeleton")
 var position:Vector3=actor.position
 actor.tick(0.12)
 assert(actor.player.current_animation_position>0.0,"Recovery arm swing is still waiting through the old gather pause")
 actor.tick(actor.mode_length*0.75-0.12)
 var pose:=preload("res://scripts/spell_cast_motion.gd").capture(actor)
 b.held_practice_shortcut.begin(b,"knee_r");b.play_demo_preview();b.move_caster(0.05,Vector2(0,1),true);b.process_demo_preview(0.02)
 assert(actor.mode=="getup" and actor.clip==Recovery.CLIP and not b.held_cast.active ,"A cast/run overwrote the full-body recovery")
 for i in pose.size():assert(pose[i].is_equal_approx(actor.skeleton.get_bone_pose(i)),"Editor pose overwrote recovery joint")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/lariat_recovery_pose.png")
 actor.tick(actor.mode_length*0.3);assert(actor.mode=="idle")
 var cpu=s.target
 for result in ["Recovered","Miss"]:
  cpu.reset_fighter(Vector3(0,0,3));cpu.start_ragdoll(Vector3.BACK*100,cpu.bone_point("spine_03"));cpu.recovery_timing.result=result
  cpu.finish_ragdoll()
  assert(cpu.clip==Recovery.CLIP and is_equal_approx(cpu.mode_length,0.65/1.32 if result=="Recovered" else Recovery.NORMAL_SECONDS))
 print("RECOVERY ANIMATION PASS: exact Arms Lariat derived at 2x with credit, shared player/CPU default, all joints override cast/run, 32% faster voluntary/normal recovery")
 quit()
