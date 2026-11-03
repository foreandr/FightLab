extends RefCounted
## Lightweight browsing hints, not authored combat ownership declarations.
const CastType=preload("res://scripts/animation_cast_type.gd")
const LABELS=["All types","Arm","Leg","Head","Movement"]

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
