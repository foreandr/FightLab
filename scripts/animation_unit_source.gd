extends Button
const CyberStyle=preload("res://scripts/ui_design.gd")

func _get_drag_data(_position:Vector2) -> Variant:
	var preview:=Label.new()
	preview.text=text
	preview.add_theme_color_override("font_color",CyberStyle.TEXT)
	set_drag_preview(preview)
	return {"type":"fightlab_editor_unit"}
