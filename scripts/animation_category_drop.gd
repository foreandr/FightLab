extends Button
var editor
var group:="Motion"
var category:="Idle"
func _get_drag_data(_point:Vector2) -> Variant:
	var preview:=Label.new()
	preview.text=category
	preview.add_theme_color_override("font_color",Color("382c1c"))
	preview.custom_minimum_size=Vector2(110,30)
	set_drag_preview(preview)
	return {"type":"fightlab_category_order","group":group,"category":category}

func _can_drop_data(_point:Vector2,data:Variant) -> bool:
	if data is Dictionary and str(data.get("type",""))=="fightlab_category_order":
		return str(data.get("group",""))==group and str(data.get("category",""))!=category
	return data is Dictionary and data.get("entry",{}) is Dictionary and (bool(data.get("store_origin",false)) or data.entry.has("store_asset_id"))

func _drop_data(_point:Vector2,data:Variant) -> void:
	if str(data.get("type",""))=="fightlab_category_order":
		editor.reorder_category(group,str(data.get("category","")),category)
		return
	editor.take_store_animation(data.entry,group,category)
