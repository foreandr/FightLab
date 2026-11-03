extends RefCounted
## Read-only animation recipes; no timeline, pose editor or UI dependencies.
const CUSTOM_DIR:="user://custom_animations"
const MIN_CUSTOM_FRAMES:=2
const CUSTOM_LOOP_DURATION:=3.0
const HAND_FINGERS:=["thumb","index","middle","ring","pinky"]
const Library=preload("res://scripts/animation_catalog.gd")
const DragSolver=preload("res://scripts/pose_drag_solver.gd")
const AssetProvenance=preload("res://scripts/asset_provenance.gd")

static func load_custom_motion(category:String, wanted_titles:Array=[]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CUSTOM_DIR)):return result
	var dir:=DirAccess.open(CUSTOM_DIR)
	if dir==null:return result
	dir.list_dir_begin()
	var filename:=dir.get_next()
	while not filename.is_empty():
		if filename.ends_with(".json"):
			var file:=FileAccess.open(CUSTOM_DIR+"/"+filename,FileAccess.READ)
			if file!=null:
				var parsed=JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and (wanted_titles.is_empty() or wanted_titles.any(func(title):return str(title).nocasecmp_to(str(parsed.get("name","")))==0)) and (category.is_empty() or Library.category_for(str(parsed.get("category","Jump")))==category) and parsed.get("frames",[]).size()>=MIN_CUSTOM_FRAMES:
					var actual_category:String=Library.category_for(str(parsed.get("category","Jump")))
					var decoded_frames: Array[Dictionary]=[]
					for source_pose in parsed.frames:
						var decoded: Dictionary={}
						for bone in DragSolver.JOINTS:
							var raw: Array=source_pose.get(bone,[0.0,0.0,0.0])
							decoded[bone]=Vector3(float(raw[0]),float(raw[1]),float(raw[2]))
						decoded["hands"]=_normalize_hand_pose(source_pose.get("hands",_default_hand_pose()))
						var pelvic:Array=source_pose.get("pelvis_offset",[0,0,0])
						decoded["pelvis_offset"]=Vector3(float(pelvic[0]),float(pelvic[1]),float(pelvic[2]))
						decoded_frames.append(decoded)
					var source:Dictionary={}
					for candidate in Library.entries():
						if (candidate.group=="Motion" or candidate.group=="Attack" and actual_category in ["Punch","Kick","Knee","Elbow","Uppercut","Sweep","Slash","Block","Dodges"]) and candidate.category==actual_category:
							if source.is_empty():source=candidate
							if candidate.step==str(parsed.get("step",actual_category)) and candidate.clip==str(parsed.get("clip",candidate.clip)) and bool(candidate.get("mirrored",false))==bool(parsed.get("mirrored",false)):
								source=candidate
								break
					if source.is_empty() and not str(parsed.get("clip","")).is_empty():
						source=Library.item(str(parsed.get("group","Motion")),actual_category,str(parsed.get("name",filename.get_basename())),str(parsed.get("step","Idle")),str(parsed.clip))
					if not source.is_empty():
						var based_on:Dictionary=parsed.get("based_on",{})
						result.append({"group":source.group,"category":actual_category,"title":str(parsed.get("name",filename.get_basename())),"step":str(parsed.get("step",source.step)),"clip":str(parsed.get("clip",source.clip)),"source_title":str(parsed.get("source_title",source.title)),"mirrored":bool(parsed.get("mirrored",false)),"attack_bone":str(parsed.get("attack_bone",source.get("attack_bone",""))),"source_timing":str(parsed.get("source_timing","legacy")),"source_duration":clampf(float(parsed.get("source_duration",parsed.get("duration",CUSTOM_LOOP_DURATION))),0.1,60.0),"parent_name":str(based_on.get("name","")),"parent_path":str(based_on.get("path","")),"kind":"custom_"+actual_category.to_lower(),"duration":clampf(float(parsed.get("duration",CUSTOM_LOOP_DURATION)),0.2,60.0),"frames":decoded_frames,"frame_count":decoded_frames.size(),"path":CUSTOM_DIR+"/"+filename})
						var loaded_entry:Dictionary=result.back()
						loaded_entry["provenance"]=AssetProvenance.source(parsed)
						loaded_entry["animation_type"]=preload("res://scripts/animation_cast_type.gd").legacy_type(parsed)
						loaded_entry["animation_components"]=parsed.get("animation_components",[]).duplicate(true)
						if not str(parsed.get("animation_resource","")).is_empty():loaded_entry["animation_resource"]=str(parsed.animation_resource)
						if not str(parsed.get("source_animation","")).is_empty():loaded_entry["source_animation"]=str(parsed.source_animation)
		filename=dir.get_next()
	dir.list_dir_end()
	return result


static func _normalize_hand_pose(source:Dictionary) -> Dictionary:
	var result:=_default_hand_pose()
	for side in ["l","r"]:
		var source_fingers: Dictionary=source.get(side,{})
		for finger in HAND_FINGERS:
			result[side][finger]=clampf(float(source_fingers.get(finger,0.0)),0.0,100.0)
		for key in ["absolute","straight","palm_up"]:result[side][key]=clampf(float(source_fingers.get(key,0.0)),0,1)
		for finger in HAND_FINGERS:
			if source_fingers.has("absolute_"+finger):result[side]["absolute_"+finger]=clampf(float(source_fingers["absolute_"+finger]),0,1)
	return result


static func _default_hand_pose() -> Dictionary:
	var hand: Dictionary={}
	for side in ["l","r"]:
		var fingers: Dictionary={}
		for finger in HAND_FINGERS:fingers[finger]=0.0
		hand[side]=fingers
	return hand

