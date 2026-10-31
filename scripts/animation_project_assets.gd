extends RefCounted
## Small, selected animations are stored in the project; the bulk shop stays local.
const ROOT:="res://assets/animations/attached"
const MANIFEST:=ROOT+"/library.json"

static func resolve(entry:Dictionary,player:AnimationPlayer=null) -> Animation:
	var resource_path:=str(entry.get("animation_resource",""))
	if not resource_path.is_empty() and ResourceLoader.exists(resource_path):
		var resource=load(resource_path)
		if resource is Animation:return resource
	var source_animation:=str(entry.get("source_animation",""))
	if not source_animation.is_empty():
		if player!=null and player.has_animation(source_animation):return player.get_animation(source_animation)
		var source_library:=load("res://assets/combat/animations/UAL2_Standard.glb") as AnimationLibrary
		if source_library!=null and source_library.has_animation(source_animation):return source_library.get_animation(source_animation)
	var clip:=str(entry.get("clip",""))
	if player!=null and player.has_animation(clip):return player.get_animation(clip)
	if not clip.is_empty() and ResourceLoader.exists("res://assets/combat/animations/"+clip.get_slice("/",0)+".res"):
		var library:=load("res://assets/combat/animations/"+clip.get_slice("/",0)+".res") as AnimationLibrary
		if library!=null and library.has_animation(clip.get_slice("/",1)):return library.get_animation(clip.get_slice("/",1))
	GameDiagnostics.log_event("animation_project_resolve_failed",{"title":entry.get("title",""),"asset_id":entry.get("store_asset_id",""),"clip":clip,"resource":resource_path,"resource_file_exists":FileAccess.file_exists(resource_path),"resource_loader_exists":ResourceLoader.exists(resource_path) if not resource_path.is_empty() else false,"source_animation":source_animation,"player_has_clip":player!=null and player.has_animation(clip)})
	return null

static func save_animation(animation:Animation,asset_id:String,title:String) -> String:
	if animation==null:
		GameDiagnostics.log_event("animation_project_save_failed",{"title":title,"asset_id":asset_id,"stage":"missing_animation"})
		return ""
	var directory_error:=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	if directory_error!=OK:
		GameDiagnostics.log_event("animation_project_save_failed",{"title":title,"asset_id":asset_id,"stage":"directory","error":error_string(directory_error)})
		return ""
	var slug:=title.to_lower().strip_edges().replace(" ","_").validate_filename().left(48)
	if slug.is_empty():slug="animation"
	var path:=ROOT+"/"+slug+"_"+asset_id.sha256_text().left(12)+".tres"
	var saved:=animation.duplicate(true) as Animation
	saved.resource_name=title
	var save_error:=ResourceSaver.save(saved,path,ResourceSaver.FLAG_COMPRESS)
	if save_error!=OK:
		GameDiagnostics.log_event("animation_project_save_failed",{"title":title,"asset_id":asset_id,"stage":"save","path":path,"error":error_string(save_error)})
		return ""
	GameDiagnostics.log_event("animation_project_saved",{"title":title,"asset_id":asset_id,"path":path,"tracks":saved.get_track_count(),"duration":saved.length})
	return path

static func save_manifest(entries:Array[Dictionary]) -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))!=OK:return false
	var temporary:=MANIFEST+".pending"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify({"version":1,"entries":entries},"\t"))
	file.close()
	var absolute:=ProjectSettings.globalize_path(MANIFEST)
	if FileAccess.file_exists(MANIFEST):DirAccess.remove_absolute(absolute)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),absolute)==OK
