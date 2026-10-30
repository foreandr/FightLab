extends RefCounted

static func build(text:String) -> Control:
	var card:=PanelContainer.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("f0e8d5")
	style.border_color=Color("98794d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,6)
	card.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	card.add_child(column)
	var lines:=text.split("\n")
	column.add_child(_label(lines[0]))
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",6)
	column.add_child(grid)
	for index in range(1,lines.size()):
		var cells:=lines[index].split("\t",true,1)
		grid.add_child(_label(cells[0]))
		var value:=_label(cells[1] if cells.size()>1 else "")
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(value)
	return card

static func _label(text:String) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color("382c1c"))
	label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	return label
