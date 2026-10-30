extends Button

func _get_drag_data(_position:Vector2) -> Variant:
	var preview:=Label.new()
	preview.text=text
	preview.add_theme_color_override("font_color",Color("fff4d8"))
	set_drag_preview(preview)
	return {"type":"fightlab_editor_unit"}
