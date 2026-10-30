extends RefCounted
## Shared icon provenance fields for saved gear, spell, and animation records.

static func normalize(item: Dictionary) -> Dictionary:
	var icon_path := str(item.get("icon_asset_path", "")).strip_edges()
	var icon_exists := false
	if not icon_path.is_empty():
		icon_exists = ResourceLoader.exists(icon_path) or FileAccess.file_exists(icon_path)
	item["icon_asset_path"] = icon_path
	item["has_actual_icon"] = icon_exists
	if icon_exists:
		item["icon_status"] = "custom_asset"
	elif icon_path.is_empty():
		item["icon_status"] = "placeholder"
	else:
		item["icon_status"] = "missing_asset"
	return item
