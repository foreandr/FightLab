extends RefCounted
const Library = preload("res://scripts/animation_catalog.gd")
var path := "user://animation_categories.cfg"
var custom_by_group: Dictionary = {}

func load_state() -> void:
	custom_by_group.clear()
	var config := ConfigFile.new()
	if config.load(path)!=OK:return
	for group in Library.GROUPS:
		var names: Array[String] = []
		var saved = config.get_value("categories",group,[])
		if not saved is Array:continue
		for value in saved:
			if not value is String:continue
			var name_value := str(value).strip_edges()
			if name_value.is_empty() or name_value.length()>48:continue
			var duplicate := false
			for existing in Library.GROUPS[group]+names:
				if str(existing).to_lower()==name_value.to_lower():duplicate=true
			if not duplicate:names.append(name_value)
		custom_by_group[group]=names

func names_for(group: String) -> Array[String]:
	var names: Array[String] = []
	names.assign(Library.GROUPS.get(group,[]))
	names.append_array(custom_by_group.get(group,[]))
	return names

func is_custom(group: String, name_value: String) -> bool:
	return name_value in custom_by_group.get(group,[])

func add(group: String, raw_name: String) -> Dictionary:
	var name_value := raw_name.strip_edges()
	if not Library.GROUPS.has(group):return {"ok":false,"error":"Choose Motion or Attack first."}
	if name_value.is_empty():return {"ok":false,"error":"Type a category name."}
	if name_value.length()>48:return {"ok":false,"error":"Use 48 characters or fewer."}
	for existing in names_for(group):
		if existing.to_lower()==name_value.to_lower():return {"ok":false,"error":"That category already exists."}
	var next := custom_by_group.duplicate(true)
	var names: Array = next.get(group,[])
	names.append(name_value)
	next[group]=names
	if not _save(next):return {"ok":false,"error":"Could not save the category."}
	custom_by_group=next
	return {"ok":true,"name":name_value}

func remove(group: String, name_value: String) -> bool:
	if not is_custom(group,name_value):return false
	var next := custom_by_group.duplicate(true)
	next[group].erase(name_value)
	if not _save(next):return false
	custom_by_group=next
	return true

func _save(data: Dictionary) -> bool:
	var config := ConfigFile.new()
	for group in Library.GROUPS:config.set_value("categories",group,data.get(group,[]))
	return config.save(path)==OK
