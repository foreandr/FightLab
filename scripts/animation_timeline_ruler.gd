extends Control

var editor
var _scrubbing := false

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	tooltip_text="Left/Right: one frame · Shift: ten frames · Home/End: start/end"
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)

func _draw() -> void:
	var pixels:float = editor.TIMELINE_PIXELS_PER_SECOND if editor != null else 100.0
	var zoom:float=editor.panel_zoom_levels.get("Timeline",1.0) if editor!=null else 1.0
	var center_y := 21.0*zoom
	var line_color := Color("382c1c")
	var tick_color := Color("7e6b4d", 0.82)
	draw_line(Vector2(0, center_y), Vector2(size.x, center_y), line_color, 2.0)
	var last_quarter := floori(size.x / (pixels * 0.25))
	for quarter in range(last_quarter + 1):
		var x := float(quarter) * pixels * 0.25
		var is_second := quarter % 4 == 0
		var tick_height := 8.0 if is_second else 3.0
		draw_line(Vector2(x, center_y - tick_height), Vector2(x, center_y + tick_height), tick_color, 1.0)
		if is_second:
			var font := ThemeDB.fallback_font
			if font != null:
				draw_string(font, Vector2(x + 4.0, 11.0*zoom), "%d s" % int(quarter / 4), HORIZONTAL_ALIGNMENT_LEFT, -1.0, maxi(8,roundi(11.0*zoom)), Color("382c1c"))
	var last_tick_x := float(last_quarter) * pixels * 0.25
	if size.x - last_tick_x > 0.5:
		draw_line(Vector2(size.x, center_y - 3.0), Vector2(size.x, center_y + 3.0), tick_color, 1.0)
	if editor != null:
		var playhead_x := clampf(float(editor.timeline_playhead) * pixels, 0.0, size.x)
		draw_line(Vector2(playhead_x, 1.0), Vector2(playhead_x, size.y - 1.0), Color("b64234"), 2.0)
		draw_circle(Vector2(playhead_x, center_y), 7.0, Color("d8b24a"))
		draw_arc(Vector2(playhead_x, center_y), 7.0, 0.0, TAU, 20, Color("382c1c"), 1.5, true)

func _gui_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and editor!=null:
		var time:float=editor.timeline_playhead
		match event.keycode:
			KEY_LEFT:time-=10.0/30.0 if event.shift_pressed else 1.0/30.0
			KEY_RIGHT:time+=10.0/30.0 if event.shift_pressed else 1.0/30.0
			KEY_HOME:time=0
			KEY_END:time=editor.timeline_duration
			_:return
		editor.stop_timeline()
		editor._on_timeline_scrubbed(clampf(time,0,editor.timeline_duration))
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_scrubbing = true
			if editor != null:
				editor.stop_timeline()
				_seek_to_mouse(event.position.x)
			accept_event()
		else:
			_scrubbing = false
			accept_event()
	elif event is InputEventMouseMotion and _scrubbing:
		_seek_to_mouse(event.position.x)
		accept_event()

func _input(event:InputEvent) -> void:
	if not _scrubbing or editor == null:
		return
	if event is InputEventMouseMotion:
		_seek_to_mouse(get_global_mouse_position().x - global_position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_scrubbing = false

func _seek_to_mouse(mouse_x:float) -> void:
	if editor == null:
		return
	var pixels:float = editor.TIMELINE_PIXELS_PER_SECOND
	editor._on_timeline_scrubbed(clampf(mouse_x / pixels, 0.0, float(editor.timeline_duration)))
