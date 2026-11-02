extends PanelContainer
## Shared collapsible authoring section. Hidden content keeps its values and
## signals; changing numbers never forces the section back open.
signal collapsed_changed(value:bool)
const Icons=preload("res://scripts/animation_row_icons.gd")
var content:VBoxContainer
var header:Button
var collapsed:=false
var title:String
func setup(title_:String,book_theme:Theme) -> void:
 title=title_
 name="Section"+title.replace(" ","")
 theme=book_theme
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("f1e8d3")
 style.border_color=Color("c9b58f")
 style.set_border_width_all(1)
 style.set_corner_radius_all(5)
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,6)
 add_theme_stylebox_override("panel",style)
 var column:=VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 add_child(column)
 header=Button.new()
 header.name="Toggle"+name
 header.text=title.to_upper()
 header.flat=true
 header.toggle_mode=true
 header.alignment=HORIZONTAL_ALIGNMENT_LEFT
 header.icon_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 header.custom_minimum_size.y=28
 header.focus_mode=Control.FOCUS_ALL
 header.add_theme_font_size_override("font_size",14)
 header.add_theme_color_override("font_color",Color("775b34"))
 column.add_child(header)
 content=VBoxContainer.new()
 content.name="Content"
 content.add_theme_constant_override("separation",4)
 column.add_child(content)
 header.toggled.connect(func(value:bool):set_collapsed(value))
 set_collapsed(false,false)
func set_collapsed(value:bool,notify:=true) -> void:
 var changed:=collapsed!=value
 collapsed=value
 if is_instance_valid(content):content.visible=not collapsed
 if is_instance_valid(header):
  header.set_pressed_no_signal(collapsed)
  header.icon=Icons.get_icon("section_closed" if collapsed else "section_open")
  header.tooltip_text=("Expand " if collapsed else "Collapse ")+title
 if changed and notify:collapsed_changed.emit(collapsed)
