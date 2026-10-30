extends RefCounted
## Decisions are shared by review and CPU generation; rejected files remain on disk.
const SAVE := "user://clothing_pavlov.cfg"
const Metadata = preload("res://scripts/clothing_metadata.gd")
const Names = preload("res://scripts/clothing_names.gd")
const IMPORT_BASE := "res://assets/characters/wardrobe/pavlov_imports/"
const MANIFEST := IMPORT_BASE + "catalog.json"
const LIBRARY_MANIFEST := "res://assets/characters/wardrobe/library/catalog.json"
static var imported_cache: Array[Dictionary] = []
static var value_index: Dictionary = {}
static var catalog_cache: Array[Dictionary] = []
static var manifest_stamp := ""

static func refresh() -> void:
	var stamp := ""
	for path in [MANIFEST,LIBRARY_MANIFEST,"res://assets/characters/wardrobe/library/makehuman_catalog.json","res://assets/characters/wardrobe/library/gcd_catalog.json"]:
		stamp += str(FileAccess.get_modified_time(path)) if FileAccess.file_exists(path) else "0"
	if stamp == manifest_stamp: return
	manifest_stamp = stamp
	imported_cache.clear()
	value_index.clear()
	catalog_cache.clear()

static func imported() -> Array[Dictionary]:
	refresh()
	if imported_cache.is_empty():
		for manifest in [MANIFEST,LIBRARY_MANIFEST,"res://assets/characters/wardrobe/library/makehuman_catalog.json","res://assets/characters/wardrobe/library/gcd_catalog.json"]:
			if not FileAccess.file_exists(manifest): continue
			var data = JSON.parse_string(FileAccess.get_file_as_string(manifest))
			if data is Array:
				for item in data:
					if item is Dictionary:
						# Flat billboard props are retained in the source library,
						# but cannot be presented as fitted clothing.
						if item.has("triangles") and int(item.triangles) <= 4: continue
						Metadata.annotate(item)
						imported_cache.append(item)
						value_index[str(item.value)] = item
		Names.make_unique(imported_cache)
	return imported_cache

static func item_for_value(value: String) -> Dictionary:
	if value_index.is_empty(): imported()
	return value_index.get(value,{})

static func catalog() -> Array[Dictionary]:
	refresh()
	if not catalog_cache.is_empty(): return catalog_cache
	var items: Array[Dictionary] = []
	for set_name in ["Peasant", "Traveler"]:
		for slot in ["shirt", "pants", "arms", "boots"]:
			items.append({"id":set_name.to_lower()+"_"+slot, "name":set_name+" "+slot, "slot":"wardrobe_"+slot, "value":set_name, "source":"Quaternius · Modular Character Outfits – Fantasy · CC0"})
	for entry in [["hood","Hood","hat"],["belt","Leather belt","belt"],["mask","Rogue mask","mask"],["cape","Cape","back"],["backpack","Backpack","back"]]:
		items.append({"id":entry[0],"name":entry[1],"slot":"wardrobe_"+entry[2],"value":entry[1],"source":"Downloaded wardrobe collection · Quaternius / Scott Marshall / Julien Savoie"})
	for set_name in ["Peasant", "Traveler"]:
		for slot in ["shirt", "pants", "arms", "boots"]:
			items.append({"id":set_name.to_lower()+"_field_"+slot,"name":set_name+" field style · "+slot,"slot":"wardrobe_"+slot,"value":set_name+":Field","source":"Quaternius · extra downloaded texture style · CC0"})
	items.append_array(imported())
	for item in items: Metadata.annotate(item)
	Names.make_unique(items)
	catalog_cache = items
	return catalog_cache

static func category(item: Dictionary) -> String:
	if item.has("category"): return str(item.category)
	var kind := str(item.get("kind",""))
	if kind == "hat" and "helmet" in str(item.name).to_lower(): return "helmet"
	if not kind.is_empty(): return kind
	if str(item.id) == "hood": return "hood"
	return str(item.slot).trim_prefix("wardrobe_")

static func body_part(item: Dictionary) -> String:
	Metadata.annotate(item)
	return str(item.get("body_part","misc"))

static func decisions() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SAVE)
	return config

static func status(id: String) -> String:
	return str(decisions().get_value("decisions", id, "pending"))

static func decide(id: String, vote: String) -> Error:
	var config := decisions()
	config.set_value("decisions", id, vote)
	return config.save(SAVE)

static func apply_to_cpu(profile: Dictionary, seed_value: int) -> Dictionary:
	var result := profile.duplicate(true)
	var slots := {}
	var config := decisions()
	for item in catalog():
		var slot: String = item.slot
		if not slots.has(slot): slots[slot] = []
		if config.get_value("decisions", item.id, "pending") == "accepted":
			slots[slot].append(item.value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for slot in slots:
		var pool: Array = slots[slot]
		result[slot] = pool[rng.randi_range(0, pool.size()-1)] if not pool.is_empty() else ("Underclothes" if slot in ["wardrobe_shirt", "wardrobe_pants"] else "None")
	if str(item_for_value(str(result.get("wardrobe_shirt",""))).get("kind","")) == "outfit":
		result["wardrobe_pants"] = "Underclothes"
		result["wardrobe_arms"] = "None"
	return result
