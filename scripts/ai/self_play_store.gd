extends RefCounted
## Local learning data is separate from game content and character saves.
const FORMAT:=1
const RULESET:="cpu_duel_touch_v1"
var path:="user://ai/self_play.json"
var error:=""
var last_save_error:=""
var revision:=""
var recovered_backup:=false
var data:Dictionary={}
var snapshot_error:=""
const SNAPSHOT_EVERY:=10
func fresh()->Dictionary:
 return {"format":FORMAT,"ruleset":RULESET,"matches":0,"updates":0,"learner":{},"champion":{},"generation":0,"evaluations":[],"history":[],"league":[]}
func load_data()->bool:
 data=fresh();error="";recovered_backup=false;revision=""
 if not FileAccess.file_exists(path):return true
 revision=FileAccess.get_file_as_string(path).sha256_text()
 var parsed:Variant=read_profile(path)
 if not valid(parsed):
  var backup:Variant=read_profile(path+".bak") if FileAccess.file_exists(path+".bak") else null
  if not valid(backup):error="AI profile is unreadable or uses different combat rules; existing file preserved";return false
  parsed=backup;recovered_backup=true
 data=parsed
 return true
func read_profile(file_path:String)->Variant:
 var parser:=JSON.new()
 return parser.data if parser.parse(FileAccess.get_file_as_string(file_path))==OK else null
func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 if value.get("format",0)!=FORMAT or value.get("ruleset","")!=RULESET:return false
 for field in ["matches","updates","generation"]:
  if not value.get(field) is float and not value.get(field) is int:return false
  if not is_finite(float(value[field])) or float(value[field])<0:return false
 for field in ["history","evaluations"]:
  if not value.get(field) is Array:return false
 for field in ["learner","champion"]:
  if not value.get(field) is Dictionary:return false
  for state in value[field].values():
   if not state is Dictionary:return false
   for entry in state.values():
    if not entry is Dictionary or not is_finite(float(entry.get("q",NAN))) or not is_finite(float(entry.get("n",NAN))) or float(entry.get("n",-1))<0:return false
 return true
func save()->bool:
 last_save_error=""
 if not error.is_empty():return false
 var disk_revision:=FileAccess.get_file_as_string(path).sha256_text() if FileAccess.file_exists(path) else ""
 if disk_revision!=revision:
  last_save_error="AI profile changed in another process; stop the other writer and reload before training"
  return false
 var absolute:=ProjectSettings.globalize_path(path)
 if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK:return false
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null:return false
 file.store_string(JSON.stringify(data,"",true,true));file.flush();file.close()
 if FileAccess.file_exists(path) and not recovered_backup:
  var backup:=FileAccess.open(path+".bak",FileAccess.WRITE)
  if backup==null:return false
  backup.store_string(FileAccess.get_file_as_string(path));backup.close()
 if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),absolute)!=OK:return false
 revision=FileAccess.get_file_as_string(path).sha256_text();recovered_backup=false
 return true
func completed(updates:int,winner:int,seconds:float)->bool:
 data.matches=int(data.matches)+1;data.updates=int(data.updates)+updates
 data.history.append({"match":data.matches,"winner":winner,"seconds":seconds})
 if data.history.size()>100:data.history.pop_front()
 if not save():return false
 if int(data.matches)%SNAPSHOT_EVERY==0 or not has_snapshots():
  save_snapshot("Automatic")
 return true
func evaluate(candidate:Dictionary,points:float,games:int,incumbent_points:float=0.0,incumbent_games:int=0)->bool:
 # Frozen candidate vs incumbent, equal games on each side; never promote on training reward.
 var promoted:=games>=20 and incumbent_games>=10 and points/float(games)>=0.70 and incumbent_points/float(incumbent_games)>=0.60
 data.evaluations.append({"match":data.matches,"points":points,"games":games,"incumbent_points":incumbent_points,"incumbent_games":incumbent_games,"promoted":promoted})
 if data.evaluations.size()>50:data.evaluations.pop_front()
 if promoted:
  if not data.has("league"):data.league=[]
  data.league.append(data.champion.duplicate(true))
  if data.league.size()>5:data.league.pop_front()
  data.champion=candidate.duplicate(true);data.generation=int(data.generation)+1
 return save()

func best_model()->Dictionary:
 return (data.champion if not data.champion.is_empty() else data.learner).duplicate(true)

func snapshot_directory()->String:return path.get_basename()+"_models"
func has_snapshots()->bool:
 var folder:=DirAccess.open(snapshot_directory())
 if folder!=null:
  for file in folder.get_files():
   if file.ends_with(".json"):return true
 return false
func save_snapshot(caption:String="Manual")->Dictionary:
 snapshot_error=""
 if not error.is_empty():snapshot_error=error;return {}
 var folder:=snapshot_directory()
 if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))!=OK:
  snapshot_error="Could not create model folder";return {}
 var snapshot:=fresh()
 for key in ["matches","updates","generation"]:snapshot[key]=data[key]
 # Normalize JSON numbers before hashing, so saving/reloading preserves the hash.
 snapshot.learner=JSON.parse_string(JSON.stringify(data.learner,"",true,true))
 snapshot["snapshot_format"]=1;snapshot["created_at"]=Time.get_datetime_string_from_system(true)
 snapshot["caption"]=caption;snapshot["engine"]=Engine.get_version_info().string
 snapshot["model_hash"]=JSON.stringify(snapshot.learner,"",true,true).sha256_text()
 var stem:="model_%06d_%d"%[int(data.matches),Time.get_unix_time_from_system()*1000000]
 var file_path:=folder.path_join(stem+".json");var suffix:=1
 while FileAccess.file_exists(file_path):
  file_path=folder.path_join(stem+"_"+str(suffix)+".json");suffix+=1
 var file:=FileAccess.open(file_path+".tmp",FileAccess.WRITE)
 if file==null:snapshot_error="Could not write model snapshot";return {}
 file.store_string(JSON.stringify(snapshot,"",true,true));file.flush();file.close()
 if DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path+".tmp"),ProjectSettings.globalize_path(file_path))!=OK:
  snapshot_error="Could not finish model snapshot";return {}
 return snapshot_summary(snapshot,file_path)
func snapshot_summary(snapshot:Dictionary,file_path:String)->Dictionary:
 return {"path":file_path,"matches":int(snapshot.matches),"updates":int(snapshot.updates),"created_at":str(snapshot.created_at),"caption":str(snapshot.caption)}
func snapshots()->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 var folder:=DirAccess.open(snapshot_directory())
 if folder==null:return result
 for file in folder.get_files():
  if not file.ends_with(".json"):continue
  var file_path:=snapshot_directory().path_join(file)
  var snapshot:Variant=read_profile(file_path)
  if valid_snapshot(snapshot):result.append(snapshot_summary(snapshot,file_path))
 result.sort_custom(func(a:Dictionary,b:Dictionary):return a.created_at>b.created_at if a.created_at!=b.created_at else a.path>b.path)
 return result
func valid_snapshot(snapshot:Variant)->bool:
 return valid(snapshot) and snapshot.get("snapshot_format",0)==1 and snapshot.get("created_at") is String and snapshot.get("caption") is String and snapshot.get("model_hash","")==JSON.stringify(snapshot.learner,"",true,true).sha256_text()
func load_snapshot(file_path:String)->Dictionary:
 snapshot_error=""
 var snapshot:Variant=read_profile(file_path) if FileAccess.file_exists(file_path) else null
 if not valid_snapshot(snapshot):
  snapshot_error="Model is missing, damaged, or uses different combat rules";return {}
 return snapshot
