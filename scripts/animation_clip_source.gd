extends Button
const CyberStyle=preload("res://scripts/ui_design.gd")

var entry: Dictionary = {}
var editor
var store_origin:=false

func _make_custom_tooltip(text:String) -> Object:
	return preload("res://scripts/animation_info_tooltip.gd").build(text)

func _get_drag_data(_at_position:Vector2) -> Variant:
	if editor!=null and not store_origin and not entry.has("store_asset_id") and not editor.can_add_unit_animation():
		editor.show_unit_selection_warning()
		return null
	if entry.is_empty():return null
	var preview:=Label.new()
	preview.text=str(entry.get("title","Animation"))
	preview.add_theme_color_override("font_color",CyberStyle.TEXT)
	preview.add_theme_stylebox_override("normal",_preview_style())
	preview.custom_minimum_size=Vector2(150,34)
	set_drag_preview(preview)
	return {"type":"fightlab_animation_clip","entry":entry.duplicate(true),"store_origin":store_origin,"source_order":not store_origin}

func _can_drop_data(_at_position:Vector2,data:Variant) -> bool:
	if store_origin:return false
	if not data is Dictionary or str(data.get("type",""))!="fightlab_animation_clip":return false
	if not bool(data.get("source_order",false)):return false
	var source:Dictionary=data.get("entry",{})
	return str(source.get("group",""))==str(entry.get("group","")) and str(source.get("category",""))==str(entry.get("category","")) and editor!=null

func _drop_data(_at_position:Vector2,data:Variant) -> void:
	if editor!=null:editor.reorder_animation_entries(data.get("entry",{}),entry)

func _preview_style() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=CyberStyle.PANEL
	style.border_color=CyberStyle.CYAN
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
