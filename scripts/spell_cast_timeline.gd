extends Control
## UI adapter: the existing duration/release ranges remain the source of truth.
var builder:Node
var release_handle:Button
var duration_handle:Button
var view_span:=2.0
var dragging:=""
var toolbar:HBoxContainer
var drag_value:=0.0

func _get_minimum_size() -> Vector2:
	return Vector2(0,(toolbar.get_combined_minimum_size().y if is_instance_valid(toolbar) else 26.0)+72.0)

func setup(owner_builder:Node) -> void:
	builder=owner_builder
	name="SpellCastTimeline"
	custom_minimum_size=Vector2(0,116)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_STOP
	tooltip_text="Drag the right edge to stretch the animation. Drag Release to move the cast. Wheel zooms time. Arrow keys adjust the focused handle; Shift makes smaller adjustments."
	toolbar=HBoxContainer.new()
	toolbar.add_theme_constant_override("separation",6)
	add_child(toolbar)
	for title in ["Fit","−","+"]:
		var button:=Button.new()
		button.text=title
		button.add_theme_font_size_override("font_size",12)
		button.custom_minimum_size=Vector2(46 if title=="Fit" else 28,26)
		toolbar.add_child(button)
		button.pressed.connect(fit_time if title=="Fit" else func():zoom_time(1.25 if title=="−" else 0.8))
	toolbar.tooltip_text="Time zoom · Fit keeps the whole animation visible"
	release_handle=make_handle("", "release")
	duration_handle=make_handle("", "duration")
	duration_handle.mouse_default_cursor_shape=Control.CURSOR_HSIZE
	release_handle.mouse_default_cursor_shape=Control.CURSOR_HSIZE
	resized.connect(refresh)
	refresh()

func make_handle(title:String,kind:String) -> Button:
	var button:=Button.new()
	button.text=title
	button.focus_mode=Control.FOCUS_ALL
	for state in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size",12)
	button.tooltip_text="Drag to change "+("animation length" if kind=="duration" else "spell release time")+" · Left/Right arrows adjust"
	add_child(button)
	button.gui_input.connect(func(event:InputEvent):handle_input(event,kind,button))
	return button

func duration_value() -> float:return float(builder.demo_duration_slider.value)
func release_value() -> float:return float(builder.release_slider.value)/100.0
func track_width() -> float:return maxf(1.0,size.x-28.0)
func time_x(time:float) -> float:return 8.0+time/view_span*track_width()
func ruler_y() -> float:return toolbar.size.y+25.0
func lane_y() -> float:return ruler_y()+14.0

func fit_time() -> void:
	view_span=maxf(0.2,duration_value()*1.25)
	refresh()

func zoom_time(factor:float) -> void:
	view_span=clampf(view_span*factor,maxf(0.2,duration_value()*1.12),128.0)
	refresh()

func _process(delta:float) -> void:
	if dragging=="duration" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_local_mouse_position().x>=size.x-20:
		drag_value=clampf(drag_value+maxf(0.5,view_span*0.7)*delta,0.1,60.0)
		builder.demo_duration_slider.value=drag_value
		refresh()

func refresh() -> void:
	if not is_instance_valid(builder) or not is_instance_valid(release_handle):return
	# Grow the scale during a drag, not only when the mouse is released.
	view_span=maxf(view_span,maxf(0.2,duration_value()*1.12))
	toolbar.size.x=size.x
	var end:=time_x(duration_value())
	duration_handle.position=Vector2(end-8,lane_y())
	duration_handle.size=Vector2(16,28)
	var release_x:=time_x(duration_value()*release_value())
	release_handle.position=Vector2(release_x-6,lane_y())
	release_handle.size=Vector2(12,28)
	release_handle.tooltip_text="Release at %.2f s · Drag or use Left/Right arrows"%(duration_value()*release_value())
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(builder):return
	var font:=get_theme_default_font()
	var ink:=Color("59472d")
	var end:=time_x(duration_value())
	var right:=time_x(view_span)
	var ruler:=ruler_y()
	var lane:=lane_y()
	draw_rect(Rect2(end,ruler-12,maxf(0,right-end),lane+40-ruler),Color("bdb49e"))
	draw_line(Vector2(8,ruler),Vector2(right,ruler),ink,2)
	var step_:float=pow(10.0,floor(log(view_span/3.0)/log(10.0)))
	if view_span/step_>8:step_*=5
	elif view_span/step_>4:step_*=2
	for i in range(int(view_span/step_)+1):
		var time:float=i*step_
		var x:=time_x(time)
		draw_line(Vector2(x,ruler-5),Vector2(x,ruler+5),ink)
		draw_string(font,Vector2(clampf(x-4,0,maxf(0,size.x-38)),ruler-9),str(snappedf(time,0.01))+" s",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
		for minor in range(1,4):
			var tick:=time_x(time+step_*minor/4.0)
			if tick<right:draw_line(Vector2(tick,ruler-2),Vector2(tick,ruler+2),ink)
	draw_rect(Rect2(8,lane,maxf(1,end-8),28),Color("f1e8d3"))
	draw_rect(Rect2(8,lane,maxf(1,end-8),28),ink,false,2)
	for offset in [4,7]:draw_line(Vector2(end-offset,lane+5),Vector2(end-offset,lane+23),ink)
	var marker:=time_x(duration_value()*release_value())
	var label_x:float=14.0 if marker-17>end-marker-24 else marker+10
	var available:float=marker-17 if label_x==14.0 else end-label_x-12
	if available>=font.get_string_size("Animation",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x:
		draw_string(font,Vector2(label_x,lane+19),"Animation",HORIZONTAL_ALIGNMENT_LEFT,available,12,ink)
	# Release is a small grip inside the animation, not a separate playhead row.
	draw_rect(Rect2(marker-3,lane+3,6,22),Color("b5a27f"))
	draw_rect(Rect2(marker-3,lane+3,6,22),ink,false,1)

func set_at_position(kind:String,x:float) -> void:
	var time:=maxf(0.0,(x-8.0)/track_width()*view_span)
	if kind=="duration":builder.demo_duration_slider.value=snappedf(time,0.1)
	else:builder.release_slider.value=100.0*time/maxf(0.001,duration_value())
	refresh()

func handle_input(event:InputEvent,kind:String,button:Button) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging=kind
			drag_value=duration_value() if kind=="duration" else builder.release_slider.value
			button.grab_focus()
		else:dragging="";refresh()
		button.accept_event()
	elif event is InputEventMouseMotion and dragging==kind:
		if kind=="duration":
			drag_value=clampf(drag_value+event.relative.x/track_width()*view_span,0.1,60.0)
			builder.demo_duration_slider.value=drag_value
		else:
			drag_value=clampf(drag_value+100.0*event.relative.x/track_width()*view_span/maxf(0.001,duration_value()),builder.release_slider.min_value,builder.release_slider.max_value)
			builder.release_slider.value=drag_value
		refresh()
		button.accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT]:
		var direction:float=-1 if event.keycode==KEY_LEFT else 1
		if kind=="duration":builder.demo_duration_slider.value+=direction*(0.1 if event.shift_pressed else 0.5)
		else:builder.release_slider.value+=direction*(1.0 if event.shift_pressed else 5.0)
		refresh()
		button.accept_event()

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		zoom_time(0.8 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.25)
		accept_event()
