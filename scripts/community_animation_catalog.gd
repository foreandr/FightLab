extends RefCounted
const ROOT:="res://assets/animations/community"
const MANIFEST:=ROOT+"/catalog.json"
const IMPORT_VERSION:=3

static func entries() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not FileAccess.file_exists(MANIFEST):return result
	var data=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary:return result
	for entry in data.get("entries",[]):
		if entry is Dictionary and FileAccess.file_exists(str(entry.get("bvh_source",""))):result.append(entry)
	return result

static func ensure(entry:Dictionary,actor:Node) -> bool:
	var started:=Time.get_ticks_usec()
	var path:=str(entry.get("animation_resource",""))
	var context:Dictionary={"title":entry.get("title",""),"asset_id":entry.get("store_asset_id",""),"source":entry.get("bvh_source",""),"resource":path}
	if path.is_empty():
		GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"resource_path","reason":"No output resource path"}))
		return false
	if FileAccess.file_exists(path):
		var cached:=load(path) as Animation
		if cached!=null and int(cached.get_meta("community_import_version",0))==IMPORT_VERSION:return true
	var source:=str(entry.get("bvh_source",""))
	if source.is_empty():
		GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"source_path","reason":"No source path"}))
		return false
	var data:Dictionary
	if source.get_extension().to_lower()=="npy":data=preload("res://scripts/community_joint_array.gd").parse(source)
	else:data=preload("res://scripts/community_bvh.gd").parse(source)
	if data.has("error"):
		GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"parse","reason":data.error,"source_exists":FileAccess.file_exists(source)}))
		return false
	data.up_axis=str(entry.get("up_axis","Y"))
	var animation:=preload("res://scripts/community_bvh.gd").retarget(data,actor)
	if animation==null:
		GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"retarget","mapped_joints":preload("res://scripts/community_bvh.gd").mapping(data).keys()}))
		return false
	animation.set_meta("community_import_version",IMPORT_VERSION)
	var directory_error:=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if directory_error!=OK:
		GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"create_directory","error":error_string(directory_error)}))
		return false
	var temporary:=path.get_basename()+".pending-%d.res"%OS.get_process_id()
	var save_error:=ResourceSaver.save(animation,temporary,ResourceSaver.FLAG_COMPRESS)
	if save_error!=OK:
		GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"save","temporary":temporary,"error":error_string(save_error)}))
		return false
	# ResourceSaver uses Godot URIs, but rename_absolute only accepts native
	# filesystem paths. Passing user:// through directly silently failed, which
	# left Store previews and Download without an importable Animation resource.
	var temporary_absolute:=ProjectSettings.globalize_path(temporary)
	var destination_absolute:=ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var remove_error:=DirAccess.remove_absolute(destination_absolute)
		if remove_error!=OK:
			GameDiagnostics.log_event("animation_import_failed",context.merged({"stage":"replace_cache","error":error_string(remove_error)}))
			return false
	var rename_error:=DirAccess.rename_absolute(temporary_absolute,destination_absolute)
	GameDiagnostics.log_event("animation_import_ready" if rename_error==OK else "animation_import_failed",context.merged({"stage":"rename","error":error_string(rename_error),"tracks":animation.get_track_count(),"duration":animation.length,"elapsed_ms":float(Time.get_ticks_usec()-started)/1000.0}))
	return rename_error==OK
