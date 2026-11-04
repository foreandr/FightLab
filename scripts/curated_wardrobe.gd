extends RefCounted
## The reviewed creator selection. The raw Pavlov archive remains untouched.
const MANIFEST := "res://assets/characters/wardrobe/curated/catalog.json"
static var entries: Dictionary = {}
static var stamp := -1
static func items() -> Dictionary:
	var current := FileAccess.get_modified_time(MANIFEST)
	if stamp == current: return entries
	stamp = current
	entries.clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if parsed is Array:
		for item in parsed:
			if item is Dictionary: entries[str(item.value)] = item
	return entries
static func item(value: String) -> Dictionary:
	return items().get(value,{})
