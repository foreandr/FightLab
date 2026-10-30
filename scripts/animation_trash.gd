extends RefCounted
const CUSTOM_DIR := "user://custom_animations"
const DEFAULT_TRASH := CUSTOM_DIR+"/.trash"

static func is_custom_path(path:String) -> bool:
	var root:=ProjectSettings.globalize_path(CUSTOM_DIR).simplify_path().trim_suffix("/")+"/"
	var absolute:=ProjectSettings.globalize_path(path).simplify_path()
	return path.ends_with(".json") and absolute.to_lower().begins_with(root.to_lower())

static func archive(entry:Dictionary,trash_dir:=DEFAULT_TRASH) -> Dictionary:
	var path:String=str(entry.get("path",""))
	if not entry.has("frames") or not is_custom_path(path) or not FileAccess.file_exists(path):return {}
	var record:Dictionary={"version":1,"original_path":path,"title":entry.title,"group":entry.group,"category":entry.category,"deleted_at":Time.get_unix_time_from_system(),"content":FileAccess.get_file_as_string(path)}
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(trash_dir))!=OK:return {}
	var archive_path:=trash_dir+"/"+path.get_file().get_basename()+"_"+str(Time.get_ticks_usec())+"_"+str(randi())+".json"
	var file:=FileAccess.open(archive_path,FileAccess.WRITE)
	if file==null:return {}
	file.store_string(JSON.stringify(record,"\t"))
	file.close()
	if DirAccess.remove_absolute(ProjectSettings.globalize_path(path))!=OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
		return {}
	record["archive_path"]=archive_path
	return record

static func list_deleted(trash_dir:=DEFAULT_TRASH) -> Array[Dictionary]:
	var records:Array[Dictionary]=[]
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(trash_dir)):return records
	var directory:=DirAccess.open(trash_dir)
	if directory==null:return records
	for filename in directory.get_files():
		if not filename.ends_with(".json"):continue
		var path:=trash_dir+"/"+filename
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or parsed.get("version",0)!=1:continue
		if not is_custom_path(str(parsed.get("original_path",""))) or not parsed.get("content","") is String:continue
		parsed["archive_path"]=path
		records.append(parsed)
	records.sort_custom(func(a:Dictionary,b:Dictionary):return float(a.get("deleted_at",0))<float(b.get("deleted_at",0)))
	return records

static func restore(record:Dictionary) -> Dictionary:
	var path:String=str(record.get("original_path",""))
	if not is_custom_path(path):return {}
	var content:String=str(record.get("content",""))
	var parsed=JSON.parse_string(content)
	if not parsed is Dictionary:return {}
	var name_:String=str(parsed.get("name",record.get("title","Restored animation")))
	if FileAccess.file_exists(path):
		var stem:=name_+" Restored"
		name_=stem
		var suffix:=2
		path=CUSTOM_DIR+"/"+name_.to_lower().replace(" ","_").validate_filename()+".json"
		while FileAccess.file_exists(path):
			name_=stem+" "+str(suffix)
			suffix+=1
			path=CUSTOM_DIR+"/"+name_.to_lower().replace(" ","_").validate_filename()+".json"
		parsed["name"]=name_
		content=JSON.stringify(parsed,"\t")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return {}
	file.store_string(content)
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(record.archive_path))
	return {"path":path,"title":name_,"group":record.group,"category":record.category}
