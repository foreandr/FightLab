extends Node
## Persistent launcher/monitor for the existing standalone training process.
signal changed
const TERMINAL:=["completed","stopped","error"]
var session_file:="user://ai/training_session.json"
var preferences_file:="user://ai/training_dashboard.cfg"
var session:Dictionary={}
var state:Dictionary={}
var error:=""
var poll_left:=0.0
var pause_requested:=false
var stop_requested:=false
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 load_session();poll()
func read_json(path:String)->Dictionary:
 if not FileAccess.file_exists(path):return {}
 var value=JSON.parse_string(FileAccess.get_file_as_string(path))
 return value if value is Dictionary else {}
func write_json(path:String,value:Dictionary)->bool:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null:return false
 file.store_string(JSON.stringify(value));file.close()
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
func load_session()->void:session=read_json(session_file)
func running()->bool:
 return not session.is_empty() and int(session.get("pid",0))>0 and OS.is_process_running(int(session.pid)) and str(state.get("phase","starting")) not in TERMINAL
func start_job(options:Dictionary)->bool:
 poll()
 if running():error="Training is already running";changed.emit();return false
 error="";pause_requested=false;stop_requested=false
 var stamp:="%d_%d"%[Time.get_unix_time_from_system()*1000000,OS.get_process_id()]
 var folder:=session_file.get_base_dir().path_join("training_jobs")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 var status_path:=folder.path_join(stamp+".json")
 var log_path:=folder.path_join(stamp+".log")
 var settings:Dictionary={"matches":clampi(int(options.get("matches",1000)),1,1000000),"speed":clampf(float(options.get("speed",8)),1.0,16.0),"eval_every":maxi(0,int(options.get("eval_every",100))),"eval_pairs":clampi(int(options.get("eval_pairs",10)),1,100),"pose_mode":str(options.get("pose_mode","full")),"profile":str(options.get("profile","user://ai/self_play.json")),"timeout":clampf(float(options.get("timeout",180)),10.0,1800.0)}
 if settings.pose_mode not in ["full","collision"]:error="Choose a valid training mode";changed.emit();return false
 var args:=PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://scripts/ai/train_self_play.gd","--log-file",ProjectSettings.globalize_path(log_path),"--","--matches="+str(settings.matches),"--speed="+str(settings.speed),"--eval-every="+str(settings.eval_every),"--eval-pairs="+str(settings.eval_pairs),"--pose-mode="+settings.pose_mode,"--timeout="+str(settings.timeout),"--profile="+settings.profile,"--status="+status_path])
 var pid:=OS.create_process(OS.get_executable_path(),args,false)
 if pid<0:error="Could not start the trainer";changed.emit();return false
 session={"pid":pid,"status":status_path,"log":log_path,"control":status_path.get_basename()+"_control.json","profile":settings.profile,"options":settings,"started_unix":Time.get_unix_time_from_system()}
 if not write_json(session_file,session):
  error="Trainer started, but the session link could not be saved"
 state={"phase":"starting","target":settings.matches,"completed":0,"requested_speed":settings.speed,"message":"Starting background trainer","elapsed_seconds":0.0}
 changed.emit();return true
func control(pause_:bool,stop_:bool)->bool:
 if session.is_empty() or not running():return false
 if not write_json(str(session.control),{"pause":pause_,"stop":stop_}):error="Could not send training control";changed.emit();return false
 pause_requested=pause_;stop_requested=stop_;changed.emit();return true
func toggle_pause()->void:control(not pause_requested,false)
func request_stop()->void:control(false,true)
func poll()->void:
 if session.is_empty():return
 var previous:=JSON.stringify(state)
 var latest:=read_json(str(session.get("status","")))
 if not latest.is_empty():state=latest
 var flags:=read_json(str(session.get("control","")))
 pause_requested=bool(flags.get("pause",false));stop_requested=bool(flags.get("stop",false))
 if not OS.is_process_running(int(session.get("pid",0))) and str(state.get("phase","")) not in TERMINAL:
  state.phase="error";state.message="Trainer exited unexpectedly. Completed matches are still saved; open the log for details."
 if previous!=JSON.stringify(state):changed.emit()
func _process(delta:float)->void:
 poll_left-=delta
 if poll_left<=0:poll_left=0.25;poll()
func preferences()->Dictionary:
 var file:=ConfigFile.new()
 if file.load(preferences_file)!=OK:return {}
 var value=file.get_value("training","options",{})
 return value if value is Dictionary else {}
func save_preferences(options:Dictionary)->void:
 var file:=ConfigFile.new();file.set_value("training","options",options)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(preferences_file).get_base_dir());file.save(preferences_file)
func open_log()->void:
 if not session.is_empty():OS.shell_open(ProjectSettings.globalize_path(str(session.log)))
func open_models()->void:
 var path:=str(session.get("profile","user://ai/self_play.json")).get_basename()+"_models"
 if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):path=path.get_base_dir()
 OS.shell_open(ProjectSettings.globalize_path(path))
func log_tail()->String:
 if session.is_empty():return ""
 var file:=FileAccess.open(str(session.get("log","")),FileAccess.READ)
 if file==null:return ""
 file.seek(maxi(0,file.get_length()-6000));var text:=file.get_buffer(file.get_length()-file.get_position()).get_string_from_utf8();file.close()
 var lines:=text.split("\n");var start:=maxi(0,lines.size()-12)
 return "\n".join(lines.slice(start))
