extends Button
## Inventory tile that carries a typed payload while being dragged.

signal item_dropped(payload: Dictionary, target_id: String)

var drag_payload: Dictionary = {}
var accepted_drop_kind := ""
var drop_target_id := ""

func set_payload(payload: Dictionary) -> void:
	drag_payload = payload.duplicate(true)

func configure_drop_target(kind: String, target_id: String) -> void:
	accepted_drop_kind = kind
	drop_target_id = target_id

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not accepted_drop_kind.is_empty() and data is Dictionary and str(data.get("kind", "")) == accepted_drop_kind

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		item_dropped.emit(data, drop_target_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty():
		return null
	var ghost := Label.new()
	ghost.text = str(drag_payload.get("name", "Item"))
	ghost.add_theme_color_override("font_color", Color("f1f3f4"))
	ghost.add_theme_font_size_override("font_size", 14)
	set_drag_preview(ghost)
	return drag_payload.duplicate(true)
