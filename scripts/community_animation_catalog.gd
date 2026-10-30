extends RefCounted
const ROOT:="res://assets/animations/community"
const MANIFEST:=ROOT+"/catalog.json"
const IMPORT_VERSION:=2

static func entries() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not FileAccess.file_exists(MANIFEST):return result
	var data=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary:return result
	for entry in data.get("entries",[]):
		if entry is Dictionary and FileAccess.file_exists(str(entry.get("bvh_source",""))):result.append(entry)
	return result

static func ensure(entry:Dictionary,actor:Node) -> bool:
	var path:=str(entry.get("animation_resource",""))
	if FileAccess.file_exists(path):
		var cached:=load(path) as Animation
		if cached!=null and int(cached.get_meta("community_import_version",0))==IMPORT_VERSION:return true
	var source:=str(entry.get("bvh_source",""))
	if source.is_empty():return false
	var data:Dictionary
	if source.get_extension().to_lower()=="npy":data=preload("res://scripts/community_joint_array.gd").parse(source)
	else:data=preload("res://scripts/community_bvh.gd").parse(source)
	if data.has("error"):return false
	data.up_axis=str(entry.get("up_axis","Y"))
	var animation:=preload("res://scripts/community_bvh.gd").retarget(data,actor)
	if animation==null:return false
	animation.set_meta("community_import_version",IMPORT_VERSION)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var temporary:=path.get_basename()+".pending-%d.res"%OS.get_process_id()
	if ResourceSaver.save(animation,temporary,ResourceSaver.FLAG_COMPRESS)!=OK:return false
	return DirAccess.rename_absolute(temporary,path)==OK
