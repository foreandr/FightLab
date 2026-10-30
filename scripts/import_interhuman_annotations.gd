extends SceneTree
## Convert the original public InterHuman text captions to a pair-ID lookup.
const ROOT:="res://assets/animations/community/raw/interhuman"
func _initialize():
	var folder:=ROOT+"/annots"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		push_error("Extract the public annots folder to "+folder)
		quit(1)
		return
	var pattern:=RegEx.new()
	pattern.compile("^(\\d+)(?: \\(\\d+\\))?$")
	var descriptions:Dictionary={}
	for filename in DirAccess.get_files_at(folder):
		if filename.get_extension().to_lower()!="txt":continue
		var match_=pattern.search(filename.get_basename())
		if match_==null:continue
		var pair_id:=match_.get_string(1)
		var content:=FileAccess.get_file_as_string(folder.path_join(filename)).strip_edges()
		if content.is_empty():continue
		var existing:=str(descriptions.get(pair_id,""))
		if existing.is_empty():descriptions[pair_id]=content
		elif not existing.contains(content):descriptions[pair_id]=existing+"\n"+content
	var output:=FileAccess.open(ROOT+"/annotations.json.tmp",FileAccess.WRITE)
	output.store_string(JSON.stringify(descriptions))
	output.close()
	var result:=DirAccess.rename_absolute(ProjectSettings.globalize_path(ROOT+"/annotations.json.tmp"),ProjectSettings.globalize_path(ROOT+"/annotations.json"))
	if result!=OK:push_error("Could not save annotation lookup: "+str(result));quit(1);return
	print("INTERHUMAN ANNOTATIONS: ",descriptions.size()," source IDs indexed")
	quit()
