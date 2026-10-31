extends Control
## UI adapter: the existing duration/release ranges remain the source of truth.
var builder:Node
var release_handle:Button
var duration_handle:Button
var view_span:=2.0
var dragging:=""

func setup(owner_builder:Node) -> void:
	builder=owner_builder
	name="SpellCastTimeline"
	custom_minimum_size=Vector2(0,100)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_STOP
	tooltip_text="Drag the right edge to stretch the animation. Drag Release to move the cast. Wheel zooms time. Arrow keys adjust the focused handle; Shift makes smaller adjustments."
	release_handle=make_handle("Release", "release")
	duration_handle=make_handle("↔", "duration")
	duration_handle.mouse_default_cursor_shape=Control.CURSOR_HSIZE
	release_handle.mouse_default_cursor_shape=Control.CURSOR_HSIZE
	resized.connect(refresh)
	refresh()

func make_handle(title:String,kind:String) -> Button:
	var button:=Button.new()
	button.text=title
	button.focus_mode=Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size",12)
	button.tooltip_text="Drag to change "+("animation length" if kind=="duration" else "spell release time")+" · Left/Right arrows adjust"
	add_child(button)
	button.gui_input.connect(func(event:InputEvent):handle_input(event,kind,button))
	return button

func duration_value() -> float:return float(builder.demo_duration_slider.value)
func release_value() -> float:return float(builder.release_slider.value)/100.0
func track_width() -> float:return maxf(1.0,size.x-28.0)
func time_x(time:float) -> float:return 8.0+time/view_span*track_width()

func refresh() -> void:
	if not is_instance_valid(builder) or not is_instance_valid(release_handle):return
	if dragging.is_empty() and (duration_value()>view_span*0.95 or duration_value()<view_span*0.25):
		view_span=clampf(pow(2.0,ceil(log(maxf(0.2,duration_value()*1.4))/log(2.0))),0.25,128.0)
	var end:=time_x(duration_value())
	var unit:float=size.y/100.0
	duration_handle.position=Vector2(end-7,35*unit)
	duration_handle.size=Vector2(18,39*unit)
	var release_x:=time_x(duration_value()*release_value())
	release_handle.position=Vector2(clampf(release_x-32,0,maxf(0,size.x-64)),40*unit)
	release_handle.size=Vector2(64,28*unit)
	release_handle.tooltip_text="Release at %.2f s · Drag or use Left/Right arrows"%(duration_value()*release_value())
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(builder):return
	var font:=get_theme_default_font()
	var ink:=Color("59472d")
	var end:=time_x(duration_value())
	var unit:float=size.y/100.0
	draw_rect(Rect2(8,35*unit,track_width(),39*unit),Color("d8cdb4"))
	draw_rect(Rect2(8,35*unit,maxf(1,end-8),39*unit),Color("dfc78d"))
	draw_rect(Rect2(8,35*unit,maxf(1,end-8),39*unit),ink,false,1)
	for i in 5:
		var time:float=view_span*i/4.0
		var x:=time_x(time)
		draw_line(Vector2(x,25*unit),Vector2(x,32*unit),ink)
		draw_string(font,Vector2(clampf(x-9,0,maxf(0,size.x-38)),19*unit),str(snappedf(time,0.01))+" s",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
	var marker:=time_x(duration_value()*release_value())
	draw_line(Vector2(marker,33*unit),Vector2(marker,78*unit),Color("b95430"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(marker-5,31*unit),Vector2(marker+5,31*unit),Vector2(marker,37*unit)]),Color("b95430"))

func set_at_position(kind:String,x:float) -> void:
	var time:=maxf(0.0,(x-8.0)/track_width()*view_span)
	if kind=="duration":builder.demo_duration_slider.value=snappedf(time,0.1)
	else:builder.release_slider.value=100.0*time/maxf(0.001,duration_value())
	refresh()

func handle_input(event:InputEvent,kind:String,button:Button) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:dragging=kind;button.grab_focus()
		else:dragging="";refresh()
		button.accept_event()
	elif event is InputEventMouseMotion and dragging==kind:
		set_at_position(kind,get_local_mouse_position().x)
		button.accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT]:
		var direction:float=-1 if event.keycode==KEY_LEFT else 1
		if kind=="duration":builder.demo_duration_slider.value+=direction*(0.1 if event.shift_pressed else 0.5)
		else:builder.release_slider.value+=direction*(1.0 if event.shift_pressed else 5.0)
		refresh()
		button.accept_event()

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		view_span=clampf(view_span*(0.8 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.25),maxf(0.25,duration_value()*1.05),128.0)
		queue_redraw()
		# Keep the chosen zoom until the next value change.
		var previous:=dragging
		dragging="zoom"
		refresh()
		dragging=previous
		accept_event()
