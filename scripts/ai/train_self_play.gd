extends SceneTree
## Headless real-combat training. No surrogate damage or resource simulation.
var progress=preload("res://scripts/ai/training_progress.gd").new()
var cancelled:=false
var demo:Node
var speed:=4.0
var limit:=180.0
var base_seed:=731091
var report:Dictionary={"training":[],"evaluations":[]}
func argument(key:String,fallback:String)->String:
 for value in OS.get_cmdline_user_args():
  if value.begins_with("--"+key+"="):return value.trim_prefix("--"+key+"=")
 return fallback
func _initialize():call_deferred("run")
func match_game(seed_:int,models:Array,train:bool,train_sides:Array=[])->int:
 demo.learning_updates=train;demo.policy_overrides=models
 demo.policy_training_flags=train_sides
 demo.exploration=maxf(0.04,0.18/(1.0+float(demo.learning_store.data.matches)*0.002)) if train else 0.0
 demo.rematch(seed_)
 if not train:progress.state.evaluation_game=int(progress.state.get("evaluation_game",0))+1
 var match_start:=Time.get_ticks_msec()
 while demo.match_winner==-2:
  await physics_frame
  progress.match_tick(demo,train)
  if demo.elapsed>limit:
   demo.events.append({"time":demo.elapsed,"event":"training_timeout"})
   demo.finish_round(-1)
 if train and not demo.learning_save_ok:return -3
 progress.match_complete(demo,train,(Time.get_ticks_msec()-match_start)/1000.0)
 return int(demo.match_winner)
func evaluate_checkpoint(pairs:int,iteration:int)->bool:
 progress.state.evaluation_target=pairs*2;progress.state.evaluation_game=0
 var candidate:Dictionary=demo.learning_store.data.learner.duplicate(true)
 var champion:Dictionary=demo.learning_store.data.champion.duplicate(true)
 var points:=0.0;var incumbent_points:=0.0;var incumbent_games:=0
 for pair in pairs:
  var opponent:Dictionary=champion
  var incumbent:=pair<ceili(pairs*0.5)
  if not incumbent:
   var league:Array=demo.learning_store.data.get("league",[])
   opponent={} if pair%2==0 or league.is_empty() else league[pair%league.size()]
  # Both orientations use the same held-out seed and frozen policies.
  for side in 2:
   if not await progress.wait_between(demo):cancelled=true;return true
   var models:Array=[candidate,opponent] if side==0 else [opponent,candidate]
   var winner:int=await match_game(base_seed+100000000+iteration*1000+pair,models,false)
   var score:=0.5 if winner<0 else (1.0 if winner==side else 0.0)
   points+=score
   if incumbent:incumbent_points+=score;incumbent_games+=1
 var saved:bool=demo.learning_store.evaluate(candidate,points,pairs*2,incumbent_points,incumbent_games)
 report.evaluations.append({"training_iteration":iteration,"points":points,"games":pairs*2,"incumbent_points":incumbent_points,"incumbent_games":incumbent_games,"saved":saved})
 print("SELF PLAY EVALUATION points=",points,"/",pairs*2," incumbent=",incumbent_points,"/",incumbent_games," champion_generation=",demo.learning_store.data.generation)
 return saved
func run()->void:
 var matches:=clampi(int(argument("matches","1000")),1,1000000)
 var every:=maxi(0,int(argument("eval-every","100")))
 var pairs:=clampi(int(argument("eval-pairs","10")),1,100)
 var history_every:=maxi(0,int(argument("history-every","3")))
 speed=clampf(float(argument("speed","4")),1.0,16.0)
 limit=clampf(float(argument("timeout","180")),10.0,1800.0)
 base_seed=int(argument("seed","731091"))
 var profile:=argument("profile","user://ai/self_play.json")
 set_meta("cpu_training_view",true);set_meta("ai_learning_path",profile)
 var pose_mode:=argument("pose-mode","full")
 if pose_mode not in ["full","collision"]:push_error("pose-mode must be full or collision");quit(1);return
 set_meta("collision_pose_cache",pose_mode=="collision")
 progress.setup(argument("status",""),matches,speed,profile,pose_mode)
 Engine.physics_ticks_per_second=int(60*speed);Engine.time_scale=speed;Engine.max_fps=0
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 demo=current_scene
 if not demo.get("ready_for_match") or not demo.learning_enabled:
  progress.phase("error","Could not initialize learning profile");push_error("Could not initialize learning profile");quit(1);return
 progress.ready()
 var start:=Time.get_ticks_msec()
 print("SELF PLAY START matches=",matches," profile=",ProjectSettings.globalize_path(profile)," physics_delta=1/60 speed=",speed)
 for iteration in matches:
  if not await progress.wait_between(demo):cancelled=true;break
  progress.phase("training","Training match %d of %d"%[iteration+1,matches])
  var opponents:Array=[];var train_sides:Array=[]
  if history_every>0 and (iteration+1)%history_every==0:
   var league:Array=demo.learning_store.data.get("league",[])
   var historical:Dictionary=demo.learning_store.data.champion if league.is_empty() else league[iteration%league.size()]
   var learner:Dictionary=demo.learning_store.data.learner
   opponents=[learner,historical.duplicate(true)] if iteration%2==0 else [historical.duplicate(true),learner]
   train_sides=[true,false] if iteration%2==0 else [false,true]
  var winner:int=await match_game(base_seed+iteration*104729,opponents,true,train_sides)
  if winner==-3:
   progress.phase("error",demo.learning_store.last_save_error if not demo.learning_store.last_save_error.is_empty() else "AI profile could not be saved")
   push_error("AI profile could not be saved");quit(1);return
  report.training.append({"iteration":iteration+1,"seed":base_seed+iteration*104729,"winner":winner,"seconds":demo.finished_at,"updates":demo.learning_store.data.updates})
  print("SELF PLAY MATCH ",iteration+1,"/",matches," winner=",winner," seconds=",snappedf(demo.finished_at,0.1)," total_matches=",demo.learning_store.data.matches," updates=",demo.learning_store.data.updates)
  if every>0 and (iteration+1)%every==0:
   progress.phase("evaluating","Testing frozen model against earlier opponents")
   if not await evaluate_checkpoint(pairs,iteration+1):progress.phase("error","Could not save evaluated checkpoint");push_error("Could not save evaluated checkpoint");quit(1);return
   if cancelled:break
 report["wall_seconds"]=(Time.get_ticks_msec()-start)/1000.0
 report["pose_mode"]=pose_mode
 report["pose_cache_build_seconds"]=preload("res://scripts/ai/collision_pose_cache.gd").build_usec/1000000.0
 report["profile"]=profile;report["total_matches"]=demo.learning_store.data.matches
 var output:=FileAccess.open(profile.get_basename()+"_report.json",FileAccess.WRITE)
 if output:output.store_string(JSON.stringify(report,"  "));output.close()
 var saved:bool=demo.learning_store.save()
 progress.state.report=profile.get_basename()+"_report.json"
 progress.phase(("stopped" if cancelled else "completed") if saved else "error","Stopped safely · completed matches saved" if cancelled and saved else ("Training complete · models saved" if saved else "Could not save model"))
 print("SELF PLAY COMPLETE additional_matches=",progress.state.get("completed",matches)," wall_seconds=",report.wall_seconds," profile_saved=",saved)
 quit(0 if saved else 1)
