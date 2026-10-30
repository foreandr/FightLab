extends PanelContainer
## A single gear animation slot or the spell socket attached to that animation.

const GearIcon := preload("res://scripts/gear_inventory_icon.gd")

signal item_dropped(payload: Dictionary, socket_id: String)

var accepts_kind := ""
var socket_id := ""
var allow_spell_drop := false
var drag_payload: Dictionary = {}
var animation_icon: Control

func configure(kind: String, id: String, label_text: String, color: Color, minimum := Vector2(90, 34), accept_spell := false) -> void:
	accepts_kind = kind
	socket_id = id
	allow_spell_drop = accept_spell
	custom_minimum_size = minimum
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.14, 0.55)
	style.set_border_width_all(1)
	style.border_color = color
	style.set_corner_radius_all(5)
	add_theme_stylebox_override("panel", style)
	if kind == "animation" and not label_text.begins_with("＋"):
		var content := HBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(content)
		animation_icon = GearIcon.new()
		animation_icon.custom_minimum_size = Vector2(25, 25)
		animation_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(animation_icon)
		var animation_label := _make_label(label_text, color)
		animation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(animation_label)
	else:
		add_child(_make_label(label_text, color))
	mouse_filter = Control.MOUSE_FILTER_STOP

func _make_label(label_text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func configure_drag(payload: Dictionary) -> void:
	drag_payload = payload.duplicate(true)
	if is_instance_valid(animation_icon):
		animation_icon.configure("animation", Color("b8a1df"), Color("c5a8ff"), "", str(payload.get("animation", "")))

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:return false
	var payload_kind := str(data.get("kind", ""))
	return payload_kind == accepts_kind or (allow_spell_drop and payload_kind == "spell")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		item_dropped.emit(data, socket_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty():
		return null
	var ghost := Label.new()
	ghost.text = str(drag_payload.get("name", "Animation"))
	ghost.add_theme_color_override("font_color", Color("f1f3f4"))
	ghost.add_theme_font_size_override("font_size", 14)
	set_drag_preview(ghost)
	return drag_payload.duplicate(true)
