extends Window
## A movable, nonmodal inspector. Sliders remain usable while its numbers update.
var heading:Label
var explanation:RichTextLabel
var close_button:Button
var dragging:=false
const BODY_SIZE:=16
const LINE_GAP:=4

func _ready() -> void:
	title="Calculation"
	borderless=true
	transient=true
	exclusive=false
	unresizable=true
	set_meta("nonmodal_calculation",true)
	close_requested.connect(hide)
	var paper:=StyleBoxFlat.new()
	paper.bg_color=Color("f1e8d3")
	paper.border_color=Color("aa7b32")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(6)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:paper.set_content_margin(side,12)
	var panel:=PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel",paper)
	add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	var header:=HBoxContainer.new()
	header.mouse_filter=Control.MOUSE_FILTER_STOP
	header.mouse_default_cursor_shape=Control.CURSOR_MOVE
	header.gui_input.connect(header_input)
	column.add_child(header)
	heading=Label.new()
	heading.text="Calculation"
	heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.clip_text=true
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_theme_font_size_override("font_size",21)
	heading.add_theme_color_override("font_color",Color("382c1c"))
	header.add_child(heading)
	close_button=Button.new()
	close_button.text="Close"
	close_button.custom_minimum_size=Vector2(90,36)
	close_button.pressed.connect(hide)
	header.add_child(close_button)
	explanation=RichTextLabel.new()
	explanation.fit_content=false
	explanation.scroll_active=true
	explanation.selection_enabled=true
	explanation.bbcode_enabled=true
	explanation.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	explanation.size_flags_vertical=Control.SIZE_EXPAND_FILL
	explanation.add_theme_font_size_override("normal_font_size",BODY_SIZE)
	explanation.add_theme_font_size_override("bold_font_size",BODY_SIZE)
	explanation.add_theme_constant_override("line_separation",LINE_GAP)
	explanation.add_theme_color_override("default_color",Color("382c1c"))
	column.add_child(explanation)

func show_calculation(_title:String,calculation:String) -> void:
	explanation.text=readable_equations(calculation)
	explanation.scroll_to_line(0)
	var available:Vector2=get_parent().get_viewport_rect().size
	popup_centered(content_size(calculation,available))
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	grab_focus()
	close_button.grab_focus()

func update_calculation(_title_text:String,calculation:String) -> void:
	# Do not recenter, resize or reset reading position during a slider adjustment.
	var formatted:=readable_equations(calculation)
	if explanation.text==formatted:return
	var reading_position:=explanation.get_v_scroll_bar().value
	explanation.text=formatted
	explanation.get_v_scroll_bar().set_deferred("value",reading_position)

func content_size(calculation:String,available:Vector2) -> Vector2i:
	var font:=explanation.get_theme_font("normal_font")
	var longest:=0.0
	for line in calculation.split("\n"):
		longest=maxf(longest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,BODY_SIZE).x)
	var title_width:=heading.get_theme_font("font").get_string_size(heading.text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x
	var header_width:=title_width+close_button.get_combined_minimum_size().x+36.0
	var width:=minf(clampf(maxf(longest+44.0,header_width),340.0,560.0),available.x*0.9)
	var measured:=font.get_multiline_string_size(calculation,HORIZONTAL_ALIGNMENT_LEFT,width-44.0,BODY_SIZE)
	# Leave room for the header, margins and wrapped-line spacing. Long breakdowns scroll.
	var lines:=maxf(calculation.split("\n").size(),measured.y/font.get_height(BODY_SIZE))
	var height:=minf(measured.y+lines*LINE_GAP+80.0,minf(520.0,available.y*0.7))
	return Vector2i(ceili(width),ceili(height))

static func readable_equations(calculation:String) -> String:
	var rows:=PackedStringArray()
	for line in calculation.split("\n"):
		# Preserve every number and literal bracket; styling changes presentation only.
		# Escape brackets in one pass so BBCode's own escape tags stay intact.
		var escaped:=""
		for character in line:
			escaped+="[lb]" if character=="[" else ("[rb]" if character=="]" else character)
		var separator:=escaped.rfind(" = ")
		if separator>=0:
			escaped=escaped.left(separator+3)+"[b][color=#574016]"+escaped.substr(separator+3)+"[/color][/b]"
		elif ":" in escaped:
			var colon:=escaped.find(":")
			escaped="[b]"+escaped.left(colon+1)+"[/b]"+escaped.substr(colon+1)
		rows.append(escaped)
	return "\n".join(rows)

func _process(_delta:float) -> void:
	if visible and has_focus():Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if not visible:dragging=false

func header_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed
		get_viewport().set_input_as_handled()

func _input(event:InputEvent) -> void:
	if not dragging:return
	if event is InputEventMouseMotion:
		move_to(position+Vector2i(event.relative))
		set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		dragging=false
		set_input_as_handled()

func move_to(destination:Vector2i) -> void:
	var available:Vector2=get_parent().get_viewport_rect().size
	position=Vector2i(Vector2(destination).clamp(Vector2.ZERO,(available-Vector2(size)).max(Vector2.ZERO)))

func _unhandled_key_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or not event.alt_pressed:return
	var directions:Dictionary={KEY_LEFT:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_DOWN:Vector2i.DOWN}
	if directions.has(event.keycode):
		move_to(position+directions[event.keycode]*10)
		get_viewport().set_input_as_handled()
