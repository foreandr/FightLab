extends RefCounted
## Optional trainer telemetry/control. Never changes combat or policy decisions.
var path:=""
var control_path:=""
var started_msec:=0
var last_write:=-1000
var paused_at_msec:=-1
var ready_msec:=-1
var last_sample_msec:=-1000
var state:Dictionary={}
func setup(output:String,matches:int,speed:float,profile:String,mode_:String)->void:
 path=output;control_path=output.get_basename()+"_control.json" if not output.is_empty() else ""
 started_msec=Time.get_ticks_msec()
 state={"schema":1,"pid":OS.get_process_id(),"phase":"starting","target":matches,"completed":0,"evaluations_completed":0,"requested_speed":speed,"profile":profile,"pose_mode":mode_,"elapsed_seconds":0.0,"simulated_seconds":0.0,"updates":0,"model_matches":0,"generation":0,"red_wins":0,"blue_wins":0,"draws":0,"recent":[],"samples":[],"message":"Preparing fighters"}
 publish(true)
func ready()->void:
 ready_msec=Time.get_ticks_msec();state.startup_seconds=(ready_msec-started_msec)/1000.0
 state.samples=[{"seconds":0.0,"completed":0,"simulated":0.0}]
 publish(true)
func controls()->Dictionary:
 if control_path.is_empty() or not FileAccess.file_exists(control_path):return {}
 var value=JSON.parse_string(FileAccess.get_file_as_string(control_path))
 return value if value is Dictionary else {}
func stopping()->bool:return bool(controls().get("stop",false))
func publish(force_:bool=false)->void:
 if path.is_empty() or (not force_ and Time.get_ticks_msec()-last_write<250):return
 last_write=Time.get_ticks_msec();state.elapsed_seconds=(last_write-started_msec)/1000.0
 state.active_seconds=maxf(0.0,(last_write-ready_msec)/1000.0-float(state.get("paused_seconds",0.0))-((last_write-paused_at_msec)/1000.0 if paused_at_msec>=0 else 0.0)) if ready_msec>=0 else 0.0
 if str(state.phase) in ["training","evaluating"] and last_write-last_sample_msec>=1000:
  last_sample_msec=last_write
  sample_speed(float(state.get("active_seconds",0)),float(state.simulated_seconds)+float(state.get("round_seconds",0)))
 state.updated_unix=Time.get_unix_time_from_system()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null:return
 file.store_string(JSON.stringify(state));file.close()
 DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
func phase(value:String,message:String)->void:
 state.phase=value;state.message=message;publish(true)
func match_tick(demo:Node,training:bool)->void:
 if path.is_empty() or Time.get_ticks_msec()-last_write<250:return
 state.phase="training" if training else "evaluating"
 state.round_seconds=demo.elapsed;state.round_limit=demo.match_duration
 state.model_matches=demo.learning_store.data.matches;state.updates=demo.learning_store.data.updates;state.generation=demo.learning_store.data.generation
 publish()
func match_complete(demo:Node,training:bool,wall_seconds:float)->void:
 state.simulated_seconds+=float(demo.finished_at)
 if training:
  state.completed+=1
  if demo.match_winner==0:state.red_wins+=1
  elif demo.match_winner==1:state.blue_wins+=1
  else:state.draws+=1
  state.recent.append({"match":state.completed,"winner":demo.match_winner,"sim_seconds":demo.finished_at,"wall_seconds":wall_seconds})
  if state.recent.size()>8:state.recent.pop_front()
 else:state.evaluations_completed+=1
 sample_speed(maxf(0.0,(Time.get_ticks_msec()-ready_msec)/1000.0-float(state.get("paused_seconds",0))),float(state.simulated_seconds))
 state.round_seconds=0.0;state.model_matches=demo.learning_store.data.matches;state.updates=demo.learning_store.data.updates;state.generation=demo.learning_store.data.generation
 publish(true)
func sample_speed(seconds:float,simulated:float)->void:
 var value:={"seconds":seconds,"completed":state.completed,"simulated":simulated}
 if not state.samples.is_empty() and seconds-float(state.samples.back().seconds)<0.1:state.samples[state.samples.size()-1]=value
 else:state.samples.append(value)
 if state.samples.size()>60:state.samples.pop_front()
func wait_between(demo:Node)->bool:
 if path.is_empty():return true
 if stopping():return false
 if not bool(controls().get("pause",false)):return true
 demo.set_physics_process(false)
 var previous_cap:=Engine.max_fps;Engine.max_fps=15
 var pause_start:=Time.get_ticks_msec();paused_at_msec=pause_start
 phase("paused","Paused · completed matches are saved")
 while bool(controls().get("pause",false)) and not stopping():
  await demo.get_tree().create_timer(0.25,true,false,true).timeout
  publish(true)
 var paused_seconds:float=(Time.get_ticks_msec()-pause_start)/1000.0
 state.paused_seconds=float(state.get("paused_seconds",0.0))+paused_seconds
 paused_at_msec=-1
 Engine.max_fps=previous_cap;demo.set_physics_process(true)
 return not stopping()
