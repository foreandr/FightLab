extends RefCounted
## One review library for every instance; locking prevents stale windows replacing votes.
var directory := OS.get_data_dir().path_join("FightLabShared/animation_pavlov")
var records: Dictionary = {}
var history: Array = []
var migrated: Dictionary = {}
var revision := ""

func _read() -> void:
 var config := ConfigFile.new()
 if config.load(directory+"/reviews.cfg") == OK:
  records=config.get_value("reviews","records",{})
  history=config.get_value("reviews","history",[])
  migrated=config.get_value("reviews","migrated",{})
 revision=FileAccess.get_sha256(directory+"/reviews.cfg") if FileAccess.file_exists(directory+"/reviews.cfg") else ""

func _lock() -> Error:
 var error := DirAccess.make_dir_recursive_absolute(directory)
 if error!=OK:return error
 var lock_path := directory+"/write.lock"
 for attempt in range(25):
  if DirAccess.make_dir_absolute(lock_path)==OK:
   var owner := FileAccess.open(lock_path+"/owner",FileAccess.WRITE)
   if owner==null:
    DirAccess.remove_absolute(lock_path)
    return ERR_CANT_CREATE
   owner.store_string(str(OS.get_process_id()))
   owner.close()
   return OK
  var owner := FileAccess.get_file_as_string(lock_path+"/owner") if FileAccess.file_exists(lock_path+"/owner") else ""
  if owner.is_valid_int() and not OS.is_process_running(int(owner)):
   DirAccess.remove_absolute(lock_path+"/owner")
   DirAccess.remove_absolute(lock_path)
  OS.delay_msec(10)
 return ERR_BUSY

func _unlock() -> void:
 DirAccess.remove_absolute(directory+"/write.lock/owner")
 DirAccess.remove_absolute(directory+"/write.lock")

func load_reviews() -> void:
 _read()
 if directory!=OS.get_data_dir().path_join("FightLabShared/animation_pavlov"):return
 if _lock()!=OK:return
 _read()
 var changed := false
 var root := OS.get_data_dir().path_join("Godot/app_userdata")
 for name in DirAccess.get_directories_at(root):
  if name!="FightLab" and not name.begins_with("FightLab Instance "):continue
  var legacy := root.path_join(name).path_join("animation_pavlov")
  if not FileAccess.file_exists(legacy+"/reviews.cfg"):continue
  var fingerprint := FileAccess.get_sha256(legacy+"/reviews.cfg")
  if str(migrated.get(legacy,""))==fingerprint:continue
  var config := ConfigFile.new()
  if config.load(legacy+"/reviews.cfg")!=OK:continue
  DirAccess.make_dir_recursive_absolute(directory+"/clips")
  var imported: Dictionary=config.get_value("reviews","records",{})
  var copied := true
  for clip in DirAccess.get_files_at(legacy+"/clips"):
   if clip.get_extension()!="tres":continue
   if not FileAccess.file_exists(directory+"/clips/"+clip):
    if DirAccess.copy_absolute(legacy+"/clips/"+clip,directory+"/clips/"+clip)!=OK:copied=false
  if not copied:continue
  for id in imported:
   var record: Dictionary=imported[id].duplicate(true)
   record["resource"]=directory+"/clips/"+str(record.resource).get_file()
   if not records.has(id) or str(record.get("reviewed_at",""))>str(records[id].get("reviewed_at","")):
    records[id]=record
  for event in config.get_value("reviews","history",[]):
   var restored: Dictionary=event.duplicate(true)
   if not restored.get("previous",{}).is_empty():
    restored.previous["resource"]=directory+"/clips/"+str(restored.previous.resource).get_file()
   if not history.has(restored):history.append(restored)
  migrated[legacy]=fingerprint
  changed=true
 if changed:
  history.sort_custom(func(a,b):return str(a.get("time",""))<str(b.get("time","")))
  save_reviews()
 _unlock()

func save_reviews() -> Error:
 var config := ConfigFile.new()
 config.set_value("reviews","records",records)
 config.set_value("reviews","history",history)
 config.set_value("reviews","migrated",migrated)
 var temporary := directory+"/reviews-"+str(OS.get_process_id())+".tmp"
 var error := config.save(temporary)
 if error!=OK:return error
 error=DirAccess.rename_absolute(temporary,directory+"/reviews.cfg")
 if error==OK:revision=FileAccess.get_sha256(directory+"/reviews.cfg")
 return error

func vote(candidate: Dictionary, verdict: String) -> Error:
 if verdict not in ["good","bad"]:return ERR_INVALID_PARAMETER
 var error := _lock()
 if error!=OK:return error
 _read()
 var record: Dictionary=candidate.duplicate(true)
 record["verdict"]=verdict
 record["reviewed_at"]=Time.get_datetime_string_from_system(true)
 history.append({"id":candidate.id,"previous":records.get(candidate.id,{}).duplicate(true),"verdict":verdict,"time":record.reviewed_at})
 records[candidate.id]=record
 error=save_reviews()
 if error!=OK:_read()
 _unlock()
 return error

func undo() -> Error:
 var error := _lock()
 if error!=OK:return error
 _read()
 if history.is_empty():
  _unlock()
  return ERR_DOES_NOT_EXIST
 var event: Dictionary=history.pop_back()
 if event.previous.is_empty():records.erase(event.id)
 else:records[event.id]=event.previous
 error=save_reviews()
 if error!=OK:_read()
 _unlock()
 return error
