extends Node
## Metadata only, loaded once in the background. Models load only for visible cards.
signal catalog_ready
const Pool = preload("res://scripts/clothing_pool.gd")
const MANIFESTS := [Pool.MANIFEST, Pool.LIBRARY_MANIFEST, "res://assets/characters/wardrobe/library/makehuman_catalog.json", "res://assets/characters/wardrobe/library/gcd_catalog.json"]
var loaded := false
var loading := false
var slots: Dictionary = {}
var total := 0
var missing := 0
var unwanted := 0
var stamp := ""
var worker: Thread
func metadata_stamp() -> String:
	var result := ""
	for path in MANIFESTS + [Pool.SAVE]: result += (str(FileAccess.get_modified_time(path)) if FileAccess.file_exists(path) else "0") + ":"
	return result
func request() -> void:
	if loading: return
	var current := metadata_stamp()
	if loaded and stamp == current: return
	stamp = current
	loaded = false
	loading = true
	worker = Thread.new()
	worker.start(_read_metadata)
func _process(_delta: float) -> void:
	if not loading or worker.is_alive(): return
	var result: Dictionary = worker.wait_to_finish()
	slots = result.slots; total = result.total; missing = result.missing; unwanted = result.unwanted
	# Publish shared lookup tables on the main thread. Equipping an item must not
	# synchronously parse the entire library again inside StoryCharacter.
	Pool.refresh()
	Pool.imported_cache.clear(); Pool.imported_cache.append_array(result.imported)
	Pool.value_index.clear()
	for item in result.imported: Pool.value_index[str(item.value)] = item
	Pool.catalog_cache.clear()
	loading = false; loaded = true
	catalog_ready.emit()
func for_slot(slot: String) -> Array: return slots.get(slot,[])
func _read_metadata() -> Dictionary:
	var imported: Array = []
	for path in MANIFESTS:
		if not FileAccess.file_exists(path): continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Array: continue
		for item in parsed:
			if not item is Dictionary or (item.has("triangles") and int(item.triangles) <= 4): continue
			imported.append(item)
	preload("res://scripts/clothing_names.gd").make_unique(imported)
	var decisions := Pool.decisions()
	var index := {}; var count := 0; var absent := 0; var rejected := 0
	for item in imported:
		if str(decisions.get_value("decisions",str(item.id),"pending")) == "unwanted": rejected += 1; continue
		var path := str(item.get("path",Pool.IMPORT_BASE + str(item.get("file",""))))
		if not FileAccess.file_exists(path): absent += 1; continue
		var slot := str(item.get("slot",""))
		if slot.is_empty(): continue
		if not index.has(slot): index[slot] = []
		index[slot].append(item); count += 1
	for entries in index.values(): entries.sort_custom(func(a: Dictionary,b: Dictionary): return str(a.name).naturalnocasecmp_to(str(b.name)) < 0)
	return {"slots":index,"total":count,"missing":absent,"unwanted":rejected,"imported":imported}
func _exit_tree() -> void:
	if worker != null and worker.is_started(): worker.wait_to_finish()
