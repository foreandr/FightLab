extends PopupPanel
## A scrollable snapshot: reading a calculation never depends on keeping the mouse still.
var heading:Label
var explanation:RichTextLabel
var close_button:Button
var scroll:ScrollContainer

func _ready() -> void:
	var paper:=StyleBoxFlat.new()
	paper.bg_color=Color("f1e8d3")
	paper.border_color=Color("aa7b32")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(6)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:paper.set_content_margin(side,12)
	add_theme_stylebox_override("panel",paper)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	add_child(column)
	var header:=HBoxContainer.new()
	column.add_child(header)
	heading=Label.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size",20)
	heading.add_theme_color_override("font_color",Color("382c1c"))
	header.add_child(heading)
	close_button=Button.new()
	close_button.text="Close"
	close_button.custom_minimum_size=Vector2(90,36)
	close_button.pressed.connect(hide)
	header.add_child(close_button)
	scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	explanation=RichTextLabel.new()
	explanation.fit_content=true
	explanation.scroll_active=false
	explanation.selection_enabled=true
	explanation.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	explanation.add_theme_font_size_override("normal_font_size",16)
	explanation.add_theme_color_override("default_color",Color("382c1c"))
	scroll.add_child(explanation)

func show_calculation(title:String,calculation:String) -> void:
	heading.text=title
	explanation.text=calculation
	scroll.scroll_vertical=0
	var available:Vector2=get_parent().get_viewport_rect().size
	popup_centered(Vector2i(Vector2(780,680).min(available*0.85)))
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	close_button.grab_focus()

func _process(_delta:float) -> void:
	if visible:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
