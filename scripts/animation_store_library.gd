extends RefCounted
const Provenance=preload("res://scripts/asset_provenance.gd")
const ProjectAssets=preload("res://scripts/animation_project_assets.gd")
var path:="user://animation_store_library.cfg"
var taken:Dictionary={}
var blocked:Dictionary={}
var last_taken_entry:Dictionary={}

static func key(entry:Dictionary) -> String:
	if entry.has("store_asset_id"):return str(entry.store_asset_id)
	var clip:=str(entry.get("clip",""))
	if entry.has("source_animation"):clip="ual2/"+str(entry.source_animation)
	return (clip+"|"+str(entry.get("step",""))+"|"+str(entry.get("mirrored",false))+"|"+str(entry.get("path",""))).sha256_text()

func load_state() -> void:
	var cfg:=ConfigFile.new()
	if cfg.load(path)==OK:
		taken=cfg.get_value("store","taken",{}).duplicate(true)
		blocked=cfg.get_value("store","blocked",{}).duplicate(true)
	_load_project_entries()

func _load_project_entries() -> void:
	if not FileAccess.file_exists(ProjectAssets.MANIFEST):return
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(ProjectAssets.MANIFEST))
	if not manifest is Dictionary:return
	for entry in manifest.get("entries",[]):
		if not entry is Dictionary:continue
		var id:=str(entry.get("store_asset_id",""))
		var asset_path:=str(entry.get("project_asset_path",""))
		if id.is_empty() or not asset_path.begins_with(ProjectAssets.ROOT+"/") or not FileAccess.file_exists(asset_path):continue
		taken[id]=entry.duplicate(true)

func save() -> bool:
	var cfg:=ConfigFile.new()
	cfg.set_value("store","taken",taken)
	cfg.set_value("store","blocked",blocked)
	return cfg.save(path)==OK

func take(entry:Dictionary,group:String,category:String,existing_names:Array=[],animation:Animation=null) -> bool:
	var id:=key(entry)
	if taken.has(id):id=id+":"+Crypto.new().generate_random_bytes(6).hex_encode()
	var local:Dictionary=entry.duplicate(true)
	local.store_asset_id=id
	local["store_source_id"]=str(entry.get("store_source_id",key(entry)))
	local["original_title"]=entry.get("original_title",entry.get("title","Animation"))
	var names:Array=existing_names.duplicate()
	for owned in taken.values():names.append(str(owned.title))
	local.title=unique_name(str(entry.title),names)
	local.group=group
	local.category=category
	local["provenance"]=Provenance.derive([Provenance.source(entry)],"animation",str(local.title),Provenance.creator_name(),"added to personal library")
	if animation==null:animation=ProjectAssets.resolve(entry)
	var project_path:=ProjectAssets.save_animation(animation,id,str(local.title))
	if project_path.is_empty():return false
	local["project_asset_path"]=project_path
	local["animation_resource"]=project_path
	local.erase("bvh_source")
	local.erase("original_filename")
	var before:Dictionary=taken.duplicate(true)
	taken[id]=local
	if not save() or not _save_project_manifest():
		taken=before
		save()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(project_path))
		return false
	last_taken_entry=local.duplicate(true)
	return true

func ensure_project_copy(id:String,animation:Animation=null) -> bool:
	if not taken.has(id):return false
	if str(taken[id].get("project_asset_path","")).begins_with(ProjectAssets.ROOT+"/"):return true
	if animation==null:animation=ProjectAssets.resolve(taken[id])
	var project_path:=ProjectAssets.save_animation(animation,id,str(taken[id].get("title","Animation")))
	if project_path.is_empty():return false
	var before:Dictionary=taken.duplicate(true)
	taken[id]["project_asset_path"]=project_path
	taken[id]["animation_resource"]=project_path
	taken[id].erase("bvh_source")
	if not save() or not _save_project_manifest():
		taken=before
		save()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(project_path))
		return false
	return true

func _save_project_manifest() -> bool:
	var portable:Array[Dictionary]=[]
	for entry in taken.values():
		var asset_path:=str(entry.get("project_asset_path",""))
		if asset_path.begins_with(ProjectAssets.ROOT+"/") and FileAccess.file_exists(asset_path):portable.append(entry.duplicate(true))
	return ProjectAssets.save_manifest(portable)

func is_taken(entry:Dictionary) -> bool:
	var id:=key(entry)
	for owned in taken.values():
		if str(owned.get("store_source_id",key(owned)))==id or key(owned)==id:return true
	return false

func move(id:String,group:String,category:String) -> bool:
	if not taken.has(id):return false
	var before:=taken.duplicate(true)
	taken[id].group=group
	taken[id].category=category
	if not save() or not _save_project_manifest():taken=before;save();return false
	return true

func remove(id:String) -> bool:
	if not taken.has(id):return false
	var before:=taken.duplicate(true)
	var asset_path:=str(taken[id].get("project_asset_path",""))
	taken.erase(id)
	if not save() or not _save_project_manifest():taken=before;save();return false
	if asset_path.begins_with(ProjectAssets.ROOT+"/") and FileAccess.file_exists(asset_path):DirAccess.remove_absolute(ProjectSettings.globalize_path(asset_path))
	return true

static func unique_name(requested:String,names:Array) -> String:
	var used:Dictionary={}
	for name_ in names:used[str(name_).strip_edges().to_lower()]=true
	var title:=requested.strip_edges().left(100)
	if title.is_empty():title="Animation"
	if not used.has(title.to_lower()):return title
	var index:=1
	while used.has((title+" (%d)"%index).to_lower()):index+=1
	return title+" (%d)"%index

func rename(id:String,requested:String) -> String:
	if not taken.has(id) or requested.strip_edges().is_empty():return ""
	var names:Array=[]
	for key_ in taken:
		if key_!=id:names.append(str(taken[key_].title))
	var before:=taken.duplicate(true)
	var name_:=unique_name(requested,names)
	taken[id].title=name_
	taken[id].provenance=Provenance.derive([Provenance.source(taken[id])],"animation",name_,Provenance.creator_name(),"renamed in personal library")
	var old_path:=str(taken[id].get("project_asset_path",""))
	if old_path.begins_with(ProjectAssets.ROOT+"/") and FileAccess.file_exists(old_path):
		var animation:=load(old_path) as Animation
		var new_path:=ProjectAssets.save_animation(animation,id,name_)
		if new_path.is_empty():taken=before;return ""
		taken[id]["project_asset_path"]=new_path
		taken[id]["animation_resource"]=new_path
	if not save() or not _save_project_manifest():taken=before;save();return ""
	if old_path.begins_with(ProjectAssets.ROOT+"/") and old_path!=str(taken[id].get("project_asset_path","")):DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
	return name_

func set_blocked(entry:Dictionary,value:bool) -> bool:
	var before:=blocked.duplicate(true)
	if value:blocked[key(entry)]={"title":entry.get("title",""),"provenance":Provenance.source(entry)}
	else:blocked.erase(key(entry))
	if not save():blocked=before;return false
	return true

func entries_for(group:String,category:String) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry in taken.values():
		if entry.group==group and entry.category==category:result.append(entry.duplicate(true))
	return result

static func enrich(entry:Dictionary,animation:Animation=null) -> Dictionary:
	var data:Dictionary=entry.duplicate(true)
	var words:="%s %s %s %s"%[data.get("title",""),data.get("clip",""),data.get("category",""),data.get("step","")]
	var tags:Array=[]
	for tag in data.get("tags",[]):
		if str(tag).to_lower() not in tags:tags.append(str(tag).to_lower())
	var regex:=RegEx.new()
	regex.compile("[a-z0-9]+")
	for match_ in regex.search_all(words.to_lower()):
		if match_.get_string() not in tags:tags.append(match_.get_string())
	var parts:Array=[]
	var bone:=str(data.get("attack_bone",""))
	var hints:=words.to_lower()+" "+bone
	for pair in [["Head",["head","neck","face","mouth"]],["Arms",["arm","hand","punch","jab","cross","hook","elbow","uppercut","palm","slash"]],["Legs",["leg","foot","ball_","kick","knee","sweep","stomp","run","walk","jump"]],["Torso",["torso","spine","chest","waist","pelvis"]]]:
		for hint in pair[1]:
			if hints.contains(hint):
				parts.append(pair[0]);break
	var animated_parts:Array=[]
	if animation!=null:
		for index in animation.get_track_count():
			var track:=str(animation.track_get_path(index)).to_lower()
			var part:="Head" if track.contains("head") or track.contains("neck") else ("Arms" if track.contains("arm") or track.contains("hand") or track.contains("clavicle") else ("Legs" if track.contains("thigh") or track.contains("calf") or track.contains("foot") else ("Torso" if track.contains("spine") or track.contains("pelvis") else "")))
			if not part.is_empty() and part not in animated_parts:animated_parts.append(part)
	if parts.is_empty():parts=animated_parts.duplicate()
	if parts.is_empty():parts.append("Misc")
	for part in parts:
		var tag:=str(part).to_lower()
		if tag not in tags:tags.append(tag)
	var state:=str(data.get("air_state",""))
	if state.is_empty():
		state="Grounded"
		for hint in ["air","jump","flip","fly","flying","fall","leap","aerial","hover"]:
			if hints.contains(hint):state="Airborne";break
	if state.to_lower() not in tags:tags.append(state.to_lower())
	data["tags"]=tags
	data["body_parts"]=data.get("body_parts",parts)
	data["animated_body_parts"]=animated_parts
	data["air_state"]=state
	data["classification_source"]="Source metadata, title keywords and animated bone tracks; inferred hints"
	data["provenance"]=Provenance.source(data)
	return data

static func matches(entry:Dictionary,query:String) -> bool:
	var regex:=RegEx.new()
	regex.compile('(?:[^\\s"]|"[^"]*")+')
	var metadata:Dictionary=entry.get("provenance",{})
	var all_text:="%s %s %s %s %s %s %s"%[entry.get("title",""),entry.get("clip",""),entry.get("tags",[]),entry.get("body_parts",[]),entry.get("air_state",""),entry.get("store_creator",""),entry.get("source_name","")]
	for match_ in regex.search_all(query.to_lower()):
		var term:=match_.get_string()
		var negative:=term.begins_with("-")
		if negative:term=term.substr(1)
		var value:=term.get_slice(":",1).replace('"','') if term.contains(":") else term.replace('"','')
		var haystack:=all_text.to_lower()
		if term.begins_with("tag:"):haystack=str(entry.get("tags",[])).to_lower()
		elif term.begins_with("body:"):haystack=str(entry.get("body_parts",[])).to_lower()
		elif term.begins_with("state:") or term.begins_with("air:"):haystack=str(entry.get("air_state","")).to_lower()
		elif term.begins_with("source:"):haystack=(str(entry.get("clip",""))+" "+str(entry.get("source_name",""))+" "+str(entry.get("source_url",""))+" "+JSON.stringify(metadata)).to_lower()
		elif term.begins_with("license:"):haystack=str(entry.get("license","")).to_lower()
		elif term.begins_with("commercial:"):haystack="yes true allowed" if bool(entry.get("commercial_use",false)) else "no false restricted"
		elif term.begins_with("author:"):
			haystack=""
			haystack=str(entry.get("store_creator","")).to_lower()
			for node in metadata.get("nodes",{}).values():haystack+=" "+str(node.get("author","")).to_lower()
		var found:=haystack.contains(value)
		if found==negative:return false
	return true
