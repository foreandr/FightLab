extends SceneTree
var service:Node
var pid:=0
var root_path:=""
func _initialize():call_deferred("run")
func require(ok:bool,message:String)->bool:
 if ok:return true
 push_error("SELF PLAY DASHBOARD FAILED: "+message)
 if is_instance_valid(service) and service.running():service.request_stop()
 quit(1);return false
func wait_phase(phases:Array,seconds:float=90.0)->bool:
 var deadline:=Time.get_ticks_msec()+int(seconds*1000)
 while Time.get_ticks_msec()<deadline:
  await create_timer(0.1,true,false,true).timeout
  service.poll()
  if str(service.state.get("phase","")) in phases:return true
  if service.state.get("phase","")=="error":push_error(str(service.state));return false
 return false
func run():
 var original_hash:=FileAccess.get_sha256("user://ai/self_play.json") if FileAccess.file_exists("user://ai/self_play.json") else ""
 service=root.get_node("SelfPlayTraining")
 root_path="user://logs/dashboard_test_"+str(Time.get_unix_time_from_system()*1000000)
 service.session_file=root_path+"_session.json";service.preferences_file=root_path+"_prefs.cfg";service.session={};service.state={}
 change_scene_to_file("res://scenes/home.tscn");await process_frame;await process_frame
 current_scene.show_page("Dev")
 if not require(current_scene.navigation_buttons.has("Self Play"),"Missing Dev entry"):return
 current_scene.navigation_buttons["Self Play"].pressed.emit()
 for i in 600:
  await process_frame
  if current_scene!=null and current_scene.name=="SelfPlayDashboard":break
 var ui=current_scene
 if not require(ui.start_button.focus_mode==Control.FOCUS_ALL and ui.start_button.name=="StartSelfPlay","Controls lack keyboard route"):return
 var options:Dictionary={"matches":4,"speed":16,"pose_mode":"collision","eval_every":0,"eval_pairs":1,"timeout":10,"profile":root_path+"_model.json"}
 service.save_preferences(options)
 if not require(service.start_job(options),"Start failed: "+service.error):return
 pid=service.session.pid
 if not require(not service.start_job(options) and service.session.pid==pid,"Duplicate worker was allowed"):return
 service.error=""
 if not require(service.control(true,false),"Pause control failed"):return
 if not require(await wait_phase(["paused"]),"Trainer never paused"):return
 var count:=int(service.state.completed);var active:float=service.state.active_seconds
 await create_timer(0.6,true,false,true).timeout;service.poll()
 if not require(int(service.state.completed)==count and absf(float(service.state.active_seconds)-active)<0.1,"Paused training advanced"):return
 var monitor=preload("res://scripts/ai/self_play_training.gd").new();monitor.session_file=service.session_file;monitor.preferences_file=service.preferences_file;root.add_child(monitor);monitor.poll()
 if not require(monitor.running() and int(monitor.session.pid)==pid,"Reopen did not attach to existing worker"):return
 monitor.queue_free()
 service.toggle_pause()
 if not require(await wait_phase(["training"]),"Resume did not restart training"):return
 await create_timer(0.8,true,false,true).timeout;service.poll();ui.refresh()
 if not require(ui.start_button.disabled and not ui.stop_button.disabled and float(service.state.round_seconds)>0,"Live progress or control state missing"):return
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://work/self_play_dashboard_running.png")
 service.request_stop()
 if not require(await wait_phase(["stopped"]),"Safe stop did not complete"):return
 if not require(int(service.state.completed)>=1 and int(service.state.completed)<4,"Stop lost current match or ran entire target"):return
 var saved:Dictionary=service.read_json(options.profile)
 if not require(int(saved.get("matches",0))==int(service.state.completed) and int(saved.get("updates",0))>0,"Completed match/model updates were not persisted"):return
 var completed_profile:="user://logs/dashboard_complete_"+str(Time.get_unix_time_from_system()*1000000)+".json"
 options.profile=completed_profile;options.matches=1
 if not require(service.start_job(options),"Second run could not start"):return
 if not require(await wait_phase(["completed"]),"One-match job did not complete"):return
 ui.refresh()
 if not require(ui.progress_bar.value==1 and not ui.start_button.disabled and ui.pause_button.disabled,"Completion UI incorrect"):return
 var result:Dictionary=service.read_json(completed_profile)
 if not require(int(result.get("matches",0))==1 and service.preferences().matches==4,"Completion or setup persistence failed"):return
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://work/self_play_dashboard_complete.png")
 options.eval_every=1;options.eval_pairs=1
 if not require(service.start_job(options),"Evaluated job could not start"):return
 if not require(await wait_phase(["evaluating"]),"Evaluation phase was not reported"):return
 if not require(await wait_phase(["completed"]),"Evaluation did not complete"):return
 result=service.read_json(completed_profile)
 if not require(int(service.state.completed)==1 and int(service.state.evaluations_completed)==2 and int(result.matches)==2,"Frozen evaluations were counted as training matches"):return
 var invalid_profile:=root_path+"_invalid.json"
 var file:=FileAccess.open(invalid_profile,FileAccess.WRITE);file.store_string("{invalid}");file.close()
 options.profile=invalid_profile
 if not require(service.start_job(options),"Error-case worker could not start"):return
 if not require(await wait_phase(["error"]),"Initialization failure was not reported"):return
 if not require(FileAccess.get_file_as_string(invalid_profile)=="{invalid}","Invalid source model was overwritten"):return
 var final_hash:=FileAccess.get_sha256("user://ai/self_play.json") if FileAccess.file_exists("user://ai/self_play.json") else ""
 if not require(final_hash==original_hash,"Test changed the real learner"):return
 print("SELF PLAY DASHBOARD PASS: Dev entry, isolated real worker, live progress, single-job guard, pause/resume, reattach, safe stop saves learning, completion, keyboard controls, preferences, frozen evaluation counts, error handling and real-model preservation")
 quit()
