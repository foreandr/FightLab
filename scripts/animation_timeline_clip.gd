extends Button

var editor
var clip_id := -1

func _make_custom_tooltip(text:String) -> Object:
	return preload("res://scripts/animation_info_tooltip.gd").build(text)
var _dragging := false
var _drag_offset := Vector2.ZERO
var _edge:=""
var _edge_origin:=0.0
var _edge_delta:=0.0
var _stretch:=false
var _edge_start_position:=Vector2.ZERO
var _edge_start_width:=0.0

func _ready() -> void:
	# Keep the transparent fill, but render the clip's outline so it reads as a
	# draggable block sitting on the track line (rather than text on the line).
	flat=false
	focus_mode=Control.FOCUS_ALL
	add_theme_stylebox_override("normal",_clip_style(Color("f0e8d5"),Color("382c1c")))
	add_theme_stylebox_override("hover",_clip_style(Color("e8d9b8"),Color("98703d")))
	add_theme_stylebox_override("pressed",_clip_style(Color("d8c7a4"),Color("7b572b")))
	add_theme_stylebox_override("focus",_clip_style(Color(1,1,1,0),Color("98703d")))
	add_theme_color_override("font_color",Color("382c1c"))
	add_theme_color_override("font_hover_color",Color("382c1c"))
	add_theme_font_size_override("font_size",12)
	alignment=HORIZONTAL_ALIGNMENT_LEFT
	clip_text=true
	process_priority=1

func _clip_style(fill:Color,border:Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=border
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left=4
	style.content_margin_right=4
	style.content_margin_top=0
	style.content_margin_bottom=0
	return style

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion and not _dragging:
		mouse_default_cursor_shape=Control.CURSOR_HSIZE if event.position.x<8.0 or event.position.x>size.x-8.0 else Control.CURSOR_MOVE
	if event is InputEventKey and event.pressed and editor!=null:
		editor.timeline_selected_id=clip_id
		if event.keycode==KEY_S:editor.split_selected_timeline_clip()
		elif event.keycode in [KEY_DELETE,KEY_BACKSPACE]:editor.remove_timeline_clip(clip_id)
		elif event.keycode in [KEY_LEFT,KEY_RIGHT] and (event.alt_pressed or event.shift_pressed):
			editor.edit_timeline_clip_edge(clip_id,"left" if event.ctrl_pressed else "right",(-1.0 if event.keycode==KEY_LEFT else 1.0)/30.0,event.shift_pressed)
		else:return
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		if event.shift_pressed and editor!=null and event.position.x>=8.0 and event.position.x<=size.x-8.0:
			editor.timeline_selected_id=clip_id
			editor.timeline_playhead=(position.x+event.position.x)/editor.TIMELINE_PIXELS_PER_SECOND
			editor.split_selected_timeline_clip()
			accept_event()
			return
		if event.position.x<8.0 or event.position.x>size.x-8.0:
			_edge="left" if event.position.x<size.x*0.5 else "right"
			_edge_origin=get_global_mouse_position().x
			_edge_delta=0.0
			_stretch=not (event.shift_pressed or event.alt_pressed)
			_edge_start_position=position
			_edge_start_width=size.x
			editor.timeline_selected_id=clip_id
			accept_event()
			return
		if editor!=null:
			editor.select_timeline_clip(clip_id)
			editor.begin_timeline_clip_drag(clip_id,str(get_parent().get("track_id")))
		_dragging=true
		modulate=Color("e3b84f")
		_drag_offset=event.position
		accept_event()

func _draw() -> void:
	for x in [5.0,size.x-5.0]:
		draw_line(Vector2(x,9.0),Vector2(x,size.y-9.0),Color("98703d"),1.0)

func _input(event:InputEvent) -> void:
	if not _edge.is_empty():
		if event is InputEventMouseMotion:
			_edge_delta=(get_global_mouse_position().x-_edge_origin)/editor.TIMELINE_PIXELS_PER_SECOND
			var pixels:float=_edge_delta*editor.TIMELINE_PIXELS_PER_SECOND
			if _edge=="left":
				pixels=minf(pixels,_edge_start_width-8.0)
				position.x=_edge_start_position.x+pixels
				size.x=maxf(8.0,_edge_start_width-pixels)
			else:size.x=maxf(8.0,_edge_start_width+pixels)
			modulate=Color("e3b84f")
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
			var edge:=_edge
			_edge=""
			editor.edit_timeline_clip_edge(clip_id,edge,_edge_delta,_stretch)
			get_viewport().set_input_as_handled()
		return
	if not _dragging:return
	if event is InputEventMouseMotion:
		global_position=get_global_mouse_position()-_drag_offset
		if editor!=null:
			for row in editor.timeline_tracks.get_children():
				if row.get_child_count()>1:row.get_child(1).queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging=false
		modulate=Color.WHITE
		if editor!=null:editor.finish_timeline_clip_drag(clip_id,get_global_mouse_position(),global_position)
		get_viewport().set_input_as_handled()
