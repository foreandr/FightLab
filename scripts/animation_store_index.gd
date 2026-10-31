extends RefCounted
## Local, compact search index for the community animation catalog.
## Full source records are stored as individual detail records and opened only for the visible page.

const Community = preload("res://scripts/community_animation_catalog.gd")
const CACHE_VERSION := 4
const STATIC_FILTER := "res://data/static_animation_filter.json"
const BODY_HINTS := {
	"Head": ["head", "neck", "face", "mouth"],
	"Arms": ["arm", "hand", "punch", "jab", "cross", "hook", "elbow", "uppercut", "palm", "slash"],
	"Legs": ["leg", "foot", "ball_", "kick", "knee", "sweep", "stomp", "run", "walk", "jump"],
	"Torso": ["torso", "spine", "chest", "waist", "pelvis"]
}
const TOP_HINTS := {"acrobatics":100,"spin":70,"jump":55,"weapon":50,"punch":40,"kick":40,"dodge":30,"block":20,"dance":10}

static func cache_path() -> String:
	return "user://animation_store_index_v2.bin"

static func details_path(index_path: String) -> String:
	return index_path.get_basename() + "_pages.bin"

static func load_cache(index_path: String) -> Dictionary:
	var file := FileAccess.open(index_path, FileAccess.READ)
	if file == null: return {}
	var data: Variant = bytes_to_var(file.get_buffer(file.get_length()))
	if not data is Dictionary or int(data.get("version", 0)) != CACHE_VERSION: return {}
	if data.get("source_stamp",{}) != _source_stamp(): return {}
	data["details_path"] = details_path(index_path)
	if not FileAccess.file_exists(data.details_path): return {}
	return data

static func _source_stamp() -> Dictionary:
	return {"manifest_modified":FileAccess.get_modified_time(Community.MANIFEST),"static_filter":FileAccess.get_file_as_string(STATIC_FILTER).sha256_text() if FileAccess.file_exists(STATIC_FILTER) else ""}

static func build_cache(index_path: String) -> Dictionary:
	var json_path := ProjectSettings.globalize_path(Community.MANIFEST)
	if not FileAccess.file_exists(json_path): return {}
	var raw_file := FileAccess.open(json_path, FileAccess.READ)
	if raw_file == null: return {}
	var parsed: Variant = JSON.parse_string(raw_file.get_as_text())
	if not parsed is Dictionary: return {}
	var raw: Array = parsed.get("entries", [])
	var suppressed_ids:Dictionary={}
	var filter_path:=ProjectSettings.globalize_path(STATIC_FILTER)
	if FileAccess.file_exists(filter_path):
		var filter_data=JSON.parse_string(FileAccess.get_file_as_string(filter_path))
		if filter_data is Dictionary:
			for item in filter_data.get("static",[])+filter_data.get("invalid",[]):
				if item is Dictionary:
					var suppressed_id:=str(item.get("store_asset_id",""))
					if not suppressed_id.is_empty():suppressed_ids[suppressed_id]=true
	var valid: Array[Dictionary] = []
	for value in raw:
		if value is Dictionary and FileAccess.file_exists(str(value.get("bvh_source", ""))) and not suppressed_ids.has(str(value.get("store_asset_id",""))): valid.append(value)
	var details_file := FileAccess.open(details_path(index_path), FileAccess.WRITE)
	if details_file == null: return {}
	var compact: Array[Dictionary] = []
	for entry_value in valid:
		var entry: Dictionary = entry_value
		var bytes := var_to_bytes(entry)
		var detail_offset := details_file.get_position()
		details_file.store_buffer(bytes)
		var record := _compact_record(entry)
		record["_detail_offset"] = detail_offset
		record["_detail_size"] = bytes.size()
		compact.append(record)
	details_file.close()
	var index_data := {"version": CACHE_VERSION, "records": compact, "total": compact.size(),"suppressed":suppressed_ids.size(),"source_stamp":_source_stamp()}
	var index_file := FileAccess.open(index_path, FileAccess.WRITE)
	if index_file == null: return {}
	index_file.store_buffer(var_to_bytes(index_data))
	index_file.close()
	index_data["details_path"] = details_path(index_path)
	return index_data

static func load_entry(details_file_path: String, offset: int, size: int) -> Dictionary:
	# The page loader already passes the details filename, not the index filename.
	var file := FileAccess.open(details_file_path, FileAccess.READ)
	if file == null: return {}
	if offset < 0 or size <= 0 or offset + size > file.get_length(): return {}
	file.seek(offset)
	var entry: Variant = bytes_to_var(file.get_buffer(size))
	return entry if entry is Dictionary else {}

static func _compact_record(entry: Dictionary) -> Dictionary:
	var title := str(entry.get("title", "Animation"))
	var clip := str(entry.get("clip", ""))
	var category := str(entry.get("category", ""))
	var step := str(entry.get("step", ""))
	var words := (title + " " + clip + " " + category + " " + step + " " + str(entry.get("attack_bone", ""))).to_lower()
	var tags: Array[String] = []
	for tag in entry.get("tags", []):
		var normalized := str(tag).to_lower()
		if not normalized.is_empty() and normalized not in tags: tags.append(normalized)
	var regex := RegEx.new()
	regex.compile("[a-z0-9]+")
	for found in regex.search_all(words):
		var token := found.get_string()
		if token not in tags: tags.append(token)
	var parts: Array[String] = []
	for part in BODY_HINTS:
		for hint in BODY_HINTS[part]:
			if words.contains(hint): parts.append(part); break
	if parts.is_empty(): parts.append("Misc")
	for part in parts:
		if part.to_lower() not in tags: tags.append(part.to_lower())
	var air := str(entry.get("air_state", ""))
	if air.is_empty():
		air = "Grounded"
		for hint in ["air", "jump", "flip", "fly", "flying", "fall", "leap", "aerial", "hover"]:
			if words.contains(hint): air = "Airborne"; break
	if air.to_lower() not in tags: tags.append(air.to_lower())
	var creator := str(entry.get("author", entry.get("creator_name", entry.get("source_name", "")))).strip_edges()
	var provenance: Dictionary = entry.get("provenance", {})
	for node in provenance.get("nodes", {}).values():
		var author := str(node.get("author", "")).strip_edges()
		if not author.is_empty(): creator = author; break
	if creator.is_empty(): creator = "FightLab"
	var score := 0
	for hint in TOP_HINTS:
		if hint in tags: score += TOP_HINTS[hint]
	var id := str(entry.get("store_asset_id", ""))
	if id.is_empty():
		var key_clip := "ual2/" + str(entry.get("source_animation", "")) if entry.has("source_animation") else clip
		id = (key_clip + "|" + step + "|" + str(entry.get("mirrored", false)) + "|" + str(entry.get("path", ""))).sha256_text()
	return {
		"title": title, "clip": clip, "category": category, "step": step,
		"group": str(entry.get("group", "Motion")), "store_asset_id": id,
		"mirrored": bool(entry.get("mirrored", false)),
		"store_creator": creator, "store_top_score": score,
		"tags": tags, "body_parts": entry.get("body_parts", parts), "air_state": air,
		"source_name": str(entry.get("source_name", "")), "source_url": str(entry.get("source_url", "")),
		"license": str(entry.get("license", "Unspecified")),
		"commercial_use": bool(entry.get("commercial_use", false)),
		"duration": float(entry.get("duration", entry.get("source_length", 1.0))),
		"source_length": float(entry.get("source_length", entry.get("duration", 1.0)))
	}
