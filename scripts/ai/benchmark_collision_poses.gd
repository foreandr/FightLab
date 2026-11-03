extends SceneTree
## Reproducible headless comparison; reads no model and writes only work reports.
const Cache=preload("res://scripts/ai/collision_pose_cache.gd")
const Motion=preload("res://scripts/spell_cast_motion.gd")
var mode_:="full"
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mode="):mode_=arg.trim_prefix("--mode=")
 call_deferred("run")
func run():
 if mode_ not in ["full","collision"]:push_error("mode must be full or collision");quit(1);return
 if DisplayServer.get_name()!="headless":push_error("Run this benchmark with --headless");quit(1);return
 Engine.time_scale=16;Engine.physics_ticks_per_second=960;Engine.max_physics_steps_per_frame=128;Engine.max_fps=0
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false)
 var a=w.fighters[0];var loadout:Array=w.brains[0].loadout
 var report:Dictionary={"mode":mode_,"micro":[],"matches":[]}
 # Bake every source variant once, outside timed warm measurements.
 set_meta("collision_pose_cache",true)
 for item in loadout:
  for progress in [0.0,0.5,0.9999]:Motion.pose(a,item.profile,progress)
 report.bake_seconds=Cache.build_usec/1000000.0
 report.collision_bones=Cache.rig_info(a).indices.size();report.full_bones=a.skeleton.get_bone_count()
 for variant in ["full","collision","collision","full"]:
  set_meta("collision_pose_cache",variant=="collision")
  var start:=Time.get_ticks_usec()
  for i in 630:
   var item:Dictionary=loadout[i%loadout.size()]
   Motion.pose(a,item.profile,float((i*37)%997)/997.0)
  report.micro.append({"mode":variant,"poses":630,"seconds":(Time.get_ticks_usec()-start)/1000000.0})
 print("POSE MICRO ",JSON.stringify(report.micro))
 set_meta("collision_pose_cache",mode_=="collision")
 for seed_ in [173,917,321]:
  w.rematch(seed_);w.set_physics_process(true)
  var start:=Time.get_ticks_usec();var start_frame:=Engine.get_physics_frames()
  while w.match_winner==-2:await physics_frame
  w.set_physics_process(false)
  var events:Dictionary={}
  for event in w.events:events[event.event]=int(events.get(event.event,0))+1
  var item:Dictionary={"seed":seed_,"wall_seconds":(Time.get_ticks_usec()-start)/1000000.0,"sim_seconds":w.finished_at,"winner":w.match_winner,"hp":[w.fighters[0].health,w.fighters[1].health],"events":events,"ticks":Engine.get_physics_frames()-start_frame}
  report.matches.append(item)
  print("POSE MATCH ",mode_," ",JSON.stringify(item))
 report.cache_hits=Cache.hits;report.bake_seconds=Cache.build_usec/1000000.0
 var output:=FileAccess.open("res://work/pose_benchmark_"+mode_+".json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"  "));output.close()
 print("POSE BENCHMARK DONE ",mode_)
 quit()
