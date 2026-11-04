extends RefCounted
## Lightweight browsing hints, not authored combat ownership declarations.
const CastType=preload("res://scripts/animation_cast_type.gd")
const LABELS=["All types","Arm","Leg","Head","Movement"]

static func action_words(entry:Dictionary)->Array[String]:
	var text:=""
	for field in ["title","category","step"]:text+=" "+str(entry.get(field,""))
	for tag in entry.get("tags",[]):text+=" "+str(tag)
	var camel:=RegEx.new();camel.compile("([a-z])([A-Z])")
	var words:=RegEx.new();words.compile("[a-z]+")
	var result:Array[String]=[]
	for found in words.search_all(camel.sub(text,"$1 $2",true).to_lower()):result.append(found.get_string())
	return result

static func is_airborne(entry:Dictionary)->bool:
	var jump=preload("res://scripts/animation_jump_motion.gd")
	if jump.requires_air(entry) or not jump.settings(entry).is_empty() or str(entry.get("air_state",""))=="Airborne":return true
	return _has(action_words(entry),["air","airborne","aerial","jump","jumping","flip","backflip","backflips","twist","fly","flying","leap","leaping","cartwheel","dive","diving"])

static func is_grab(entry:Dictionary)->bool:
	return _has(action_words(entry),["grab","grabs","grabbing","grapple","grappling","clinch","clinching","wrestle","wrestling","takedown","takedowns","armbar","choke","chokes","choking","headlock","suplex"])

static func is_idle(entry:Dictionary)->bool:
	# A browsing section, not a new combat pose-ownership type.
	var title:=str(entry.get("title",""))
	var camel:=RegEx.new();camel.compile("([a-z])([A-Z])")
	var regex:=RegEx.new();regex.compile("[a-z]+")
	var words:Array[String]=[]
	for found in regex.search_all(camel.sub(title,"$1 $2",true).to_lower()):words.append(found.get_string())
	# Idle-to-action transitions and shield-break reactions remain actions.
	if "idle" in words and _has(words,["to","from"]):return false
	if _has(words,["run","walk","sprint","jump","attack","punch","kick","hit","break","death","draw","sheathe","enter","exit","start","stop"]):return false
	return _has(words,["idle","idles","idling"]) or str(entry.get("category","")).nocasecmp_to("Idle")==0

static func kind(entry:Dictionary)->String:
	if CastType.declared(entry):return CastType.kind(entry)
	if str(entry.get("store_animation_type","")) in CastType.TYPES:return str(entry.store_animation_type)
	# Use readable labels only: source IDs and paths can contain unrelated words.
	var text:=" "
	for key in ["title","category","step"]:text+=str(entry.get(key,""))+" "
	for tag in entry.get("tags",[]):
		# Enrichment adds broad body labels for search; these are not action types.
		if str(tag).to_lower() not in ["head","arms","legs","torso","misc"]:text+=str(tag)+" "
	var regex:=RegEx.new();regex.compile("[a-z]+")
	var tokens:Array[String]=[]
	for found in regex.search_all(text.to_lower()):tokens.append(found.get_string())
	# Locomotion/acrobatic combinations own the whole action, even with arm gestures.
	if _has(tokens,["walk","walking","run","running","jog","jogging","sprint","jump","jumping","flip","backflip","cartwheel","acrobatic","acrobatics","dance","dancing","dive","diving","fall","falling","roll","rolling","crawl","crawling","swim","swimming","climb","climbing","locomotion","spin","spinning","dodge","vault","leap"]):return "Movement"
	if _has(tokens,["headbutt","head","nod","nodding","neck"]):return "Head"
	if _has(tokens,["kick","kicking","knee","knees","sweep","sweeps","stomp","stomping","leg","legs","foot","feet"]):return "Leg"
	if _has(tokens,["punch","punching","jab","cross","hook","uppercut","elbow","slash","backfist","haymaker","slap","swipe","chop","fist","fists","melee","block","blocking","parry","weapon","sword","shoot","shooting","aim","aiming","throw","throwing","wave","waving","clap","clapping","reach","reaching","grab","grabbing","arm","arms","hand","hands","gesture","gestures","point","pointing","boxing"]):return "Arm"
	var legacy:=CastType.kind(entry)
	return legacy

static func _has(tokens:Array[String],hints:Array)->bool:
	for hint in hints:
		if hint in tokens:return true
	return false
