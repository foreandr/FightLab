extends SceneTree
const BVH=preload("res://scripts/community_bvh.gd")
const ROOT:="res://assets/animations/community"
var entries:Array[Dictionary]=[]
var seen:Dictionary={}
var names:Dictionary={}
var errors:Array=[]
var descriptions:Dictionary={}
var sources:Dictionary={}
var source_descriptions:Dictionary={}
var interhuman_descriptions:Dictionary={}

func _initialize():call_deferred("run")
func run():
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/community_animation_sources.json"))
	for source in config.sources:sources[source.id]=source
	var cologne_path:=ROOT+"/raw/cologne/metadata.json"
	if FileAccess.file_exists(cologne_path):source_descriptions=JSON.parse_string(FileAccess.get_file_as_string(cologne_path))
	var interhuman_annotation_path:=ROOT+"/raw/interhuman/annotations.json"
	if FileAccess.file_exists(interhuman_annotation_path):interhuman_descriptions=JSON.parse_string(FileAccess.get_file_as_string(interhuman_annotation_path))
	var index_path:=ROOT+"/raw/cmu/cmu/cmu-mocap-master/cmu-mocap-index-text.txt"
	if FileAccess.file_exists(index_path):
		var pattern:=RegEx.new()
		pattern.compile("^(\\d+_\\d+)\\s+(.+)$")
		for line in FileAccess.get_file_as_string(index_path).split("\n"):
			var match_=pattern.search(line.strip_edges())
			if match_!=null:descriptions[match_.get_string(1)]=match_.get_string(2)
	var old=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"/catalog.json")) if FileAccess.file_exists(ROOT+"/catalog.json") else {}
	for entry in old.get("entries",[]):
		var annotation:=interhuman_description(entry) if str(entry.get("source_name",""))=="InterHuman original recorded interactions" else ""
		var classify_text:=str(entry.title)+" "+str(entry.bvh_source)+" "+annotation
		entry.merge(classify(classify_text),true)
		if not annotation.is_empty():
			entry.description=annotation
			entry.title=interaction_title(entry,annotation)
		for source in config.sources:
			if str(entry.source_name)==str(source.name):
				entry.tags.append(str(source.id))
				entry.tags.append("commercial" if bool(source.commercial) else "noncommercial")
		if entry.get("root_normalized",false):entry.tags.append("pose-only");entry.tags.append("in-place")
		if str(entry.source_name)=="GetBVH dance library":entry.tags.append("dance");entry.category="Dance";entry.group="Motion";entry.step="Imported Motion"
		if str(entry.source_name)=="InterHuman original recorded interactions":entry.tags.append("interaction");entry.tags.append("recorded");entry.category="Interaction";entry.body_parts=interaction_body_parts(annotation) if not annotation.is_empty() else ["Misc"]
		seen[str(entry.sha256)]=true;entries.append(entry);names[str(entry.title).to_lower()]=true
	if "--metadata-only" in OS.get_cmdline_user_args():
		write_catalog()
		quit()
		return
	for source in config.sources:
		var path:=ROOT+"/raw/"+str(source.id)
		if DirAccess.dir_exists_absolute(path):await scan(path,source)
	write_catalog()
	print("COMMUNITY CATALOG: ",entries.size()," distinct downloaded animations; ",errors.size()," rejected files")
	quit()

func scan(path:String,source:Dictionary) -> void:
	for directory in DirAccess.get_directories_at(path):await scan(path.path_join(directory),source)
	for name_ in DirAccess.get_files_at(path):
		if name_.get_extension().to_lower() not in ["bvh","npy"]:continue
		var file_path:=path.path_join(name_)
		var sha:=FileAccess.get_sha256(file_path)
		if seen.has(sha):continue
		var data:Dictionary
		if name_.get_extension().to_lower()=="npy":data=preload("res://scripts/community_joint_array.gd").parse(file_path,false)
		else:data=BVH.parse(file_path,false)
		if data.has("error") or BVH.mapping(data).size()<12:
			errors.append({"path":file_path,"error":data.get("error","Unsupported skeleton")});continue
		seen[sha]=true
		var title:=name_.get_basename().replace("_"," ").replace("-"," ").strip_edges()
		var camel:=RegEx.new()
		camel.compile("([a-z0-9])([A-Z])")
		title=camel.sub(title,"$1 $2",true)
		if str(source.id)=="cmu" and descriptions.has(name_.get_basename()):title=str(descriptions[name_.get_basename()])+" · CMU "+name_.get_basename()
		if str(source.id)=="cologne" and source_descriptions.has(name_):title=str(source_descriptions[name_])+" · "+name_.get_basename()
		if str(source.id)=="bandai":title=title.trim_prefix("dataset 1 ").trim_prefix("dataset 2 ")
		if str(source.id)=="interhuman":title="Interaction %05d · Actor %s"%[int(name_.get_basename()),file_path.get_base_dir().get_file().trim_prefix("person")]
		var annotation:=str(interhuman_descriptions.get(name_.get_basename(),"")) if str(source.id)=="interhuman" else ""
		if not annotation.is_empty():title="Interaction %05d · Actor %s · %s"%[int(name_.get_basename()),file_path.get_base_dir().get_file().trim_prefix("person"),short_interaction_description(annotation)]
		var base_title:=title
		var suffix:=1
		while names.has(title.to_lower()):title=base_title+" (%d)"%suffix;suffix+=1
		names[title.to_lower()]=true
		var entry:=classify(title+" "+file_path+" "+annotation)
		if str(source.id)=="getbvh":entry.tags.append("dance");entry.category="Dance";entry.group="Motion";entry.step="Imported Motion"
		if str(source.id)=="interhuman":entry.tags.append("interaction");entry.tags.append("recorded");entry.category="Interaction";entry.body_parts=interaction_body_parts(annotation) if not annotation.is_empty() else ["Misc"]
		entry.tags.append(str(source.id))
		entry.tags.append("commercial" if bool(source.commercial) else "noncommercial")
		if str(source.id)=="tuffles":entry.up_axis="Z"
		if source.has("up_axis"):entry.up_axis=source.up_axis
		if str(source.id)=="hdm05":entry.root_normalized=true;entry.tags.append("pose-only");entry.tags.append("in-place")
		entry.merge({"title":title,"description":annotation,"clip":"community/"+sha,"store_asset_id":"download:"+sha,"sha256":sha,"bvh_source":file_path,"animation_resource":"user://community_animations/"+sha+".res","duration":data.duration,"source_duration":data.duration,"store_raw":true,"source_timing":"native_v1","source_name":source.name,"source_url":source.url,"license":source.license,"commercial_use":source.commercial,"downloaded":true,"original_filename":name_,"frame_count":data.frame_count},true)
		var id_:="source:"+sha
		entry.provenance={"schema":1,"head":id_,"nodes":{id_:{"id":id_,"asset_type":"animation","operation":"downloaded original; BVH retargeted on demand","title":title,"author":source.author,"parents":[],"citations":[{"url":source.url,"license":source.license,"author":source.author,"original_filename":name_,"sha256":sha}]}}}
		entries.append(entry)
		if entries.size()%500==0:
			write_catalog()
			print("Indexed ",entries.size()," distinct animations")
			await process_frame

func classify(text:String) -> Dictionary:
	text=text.to_lower()
	var tags:Array=[]
	var patterns={"acrobatics":["acro","flip","cartwheel","handspring","somersault","tumble","aerial","parkour","vault","wushu"],"punch":["punch","boxing","jab","hook","uppercut","elbow","slap","lariat","chop"],"kick":["kick","sweep","knee","roundhouse"],"weapon":["sword","weapon","staff","spear","slash","knife","rifle","shoot","pistol","archer","archery"],"spell":["spell","magic","cast","summon","channel"],"jump":["jump","leap","hop","hurdle"],"idle":["idle","standing","stance"," id "],"run":["run","jog","sprint"," fr "," br "," sr "],"walk":["walk"," fw "," bw "," sw "],"dance":["dance","dancing","ballet","breakdance"],"dodge":["dodge","evade","duck","roll"],"block":["block","guard","parry","defend"],"fall":["fall","trip","stumble","die","death"],"crouch":["crouch","kneel","crawl"],"spin":["spin","twist","turn","rotate"],"left":["left"],"right":["right"],"style":["angry","happy","tired","active","child","robot","zombie","drunk","ninja"]}
	for tag in patterns:
		for word in patterns[tag]:
			if text.contains(word):tags.append(tag);break
	var attack:=false
	for tag in ["punch","kick","weapon","spell","block"]:
		if tag in tags:attack=true
	var category:="Misc"
	for tag in ["acrobatics","punch","kick","weapon","spell","jump","idle","run","walk","dance","dodge","block","fall","crouch","spin"]:
		if tag in tags:category=tag.capitalize();break
	var air:="Airborne" if "jump" in tags or "acrobatics" in tags else "Grounded"
	return {"group":"Attack" if attack else "Motion","category":category,"step":"Imported Attack" if attack else "Imported Motion","tags":tags,"air_state":air,"classification_confidence":"keyword inference; original source names retained"}

func interhuman_description(entry:Dictionary) -> String:
	var basename:=str(entry.get("original_filename","" )).get_basename()
	return str(interhuman_descriptions.get(basename,""))

func short_interaction_description(description:String) -> String:
	var first_line:=description.split("\n",false)[0].strip_edges() if not description.is_empty() else ""
	if first_line.length()>58:first_line=first_line.substr(0,55).strip_edges()+"..."
	return first_line

func interaction_title(entry:Dictionary,description:String) -> String:
	return "Interaction %05d · Actor %s · %s"%[int(str(entry.get("original_filename","0")).get_basename()),str(entry.get("bvh_source","/person1/")).get_base_dir().get_file().trim_prefix("person"),short_interaction_description(description)]

func interaction_body_parts(description:String) -> Array[String]:
	var text:=description.to_lower()
	var parts:Array[String]=[]
	if text.contains("head") or text.contains("face"):parts.append("Head")
	if text.contains("torso") or text.contains("chest") or text.contains("spine"):parts.append("Torso")
	if text.contains("arm") or text.contains("hand") or text.contains("elbow"):parts.append("Arms")
	if text.contains("leg") or text.contains("foot") or text.contains("knee"):parts.append("Legs")
	if parts.is_empty():parts.append("Misc")
	return parts

func write_catalog() -> void:
	var file:=FileAccess.open(ROOT+"/catalog.json.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":1,"entries":entries,"rejected":errors,"distinct_count":entries.size(),"updated_utc":Time.get_datetime_string_from_system(true)}))
	file.close()
	DirAccess.rename_absolute(ROOT+"/catalog.json.tmp",ROOT+"/catalog.json")
