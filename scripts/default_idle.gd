extends RefCounted
## Shared default pool for creation previews and story fighters.
const SOURCES={"ual1":"res://assets/combat/animations/UAL1_Standard.glb","ual2":"res://assets/combat/animations/UAL2_Standard.glb"}
static var pool:Array[Dictionary]=[]

static func choices() -> Array[Dictionary]:
	if not pool.is_empty():return pool
	var config:=ConfigFile.new()
	if config.load("user://animation_store_library.cfg")==OK:
		for entry in config.get_value("store","taken",{}).values():
			var title:=str(entry.get("title","")).to_lower().replace(" ","").replace("_","")
			if title in ["idlecannon","idlefoldarms","idlefoldarm","idleno","idleshield"]:pool.append(entry.duplicate(true))
	if pool.is_empty():
		for pair in [["Idle cannon","ual1/Idle"],["Idle FoldArms","ual2/Idle_FoldArms"],["Idle No","ual2/Idle_No"],["Idle Shield","ual2/Idle_Shield"]]:
			pool.append({"title":pair[0],"clip":pair[1]})
	return pool

static func resolve(owner_:Node,player:AnimationPlayer,override:Variant=null) -> String:
	var entry:Dictionary={}
	if override is Dictionary and not override.is_empty():entry=override
	elif override is String and not override.is_empty():
		for candidate in choices():
			if str(candidate.title).nocasecmp_to(override)==0:entry=candidate;break
	if entry.is_empty():
		if not owner_.has_meta("default_idle_choice"):
			var preferred:Dictionary={"title":"Idle cannon","clip":"ual1/Idle"}
			for candidate in choices():
				if str(candidate.title).to_lower().replace(" ","")=="idlecannon":preferred=candidate;break
			owner_.set_meta("default_idle_choice",preferred.duplicate(true))
		entry=owner_.get_meta("default_idle_choice")
	var source_clip:=str(entry.get("clip","ual1/Idle"))
	var source_name:=str(entry.get("source_animation",source_clip.get_slice("/",1)))
	var namespace_:="ual2" if entry.has("source_animation") else source_clip.get_slice("/",0)
	var clip:="default_idle/"+(namespace_+"_"+source_name).validate_node_name()
	if player.has_animation(clip):return clip
	var library:=load(str(SOURCES.get(namespace_,SOURCES.ual1))) as AnimationLibrary
	if library==null or not library.has_animation(source_name):return "ual1/Idle"
	var animation:=library.get_animation(source_name).duplicate(true) as Animation
	animation.loop_mode=Animation.LOOP_LINEAR
	if not player.has_animation_library("default_idle"):player.add_animation_library("default_idle",AnimationLibrary.new())
	player.get_animation_library("default_idle").add_animation(clip.get_slice("/",1),animation)
	return clip
