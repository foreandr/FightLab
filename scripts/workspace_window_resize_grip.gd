extends Control
var window:Control
var edges:=Vector2.ZERO

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	tooltip_text="Drag to resize window"
	mouse_filter=Control.MOUSE_FILTER_STOP
	if edges.x!=0 and edges.y!=0:mouse_default_cursor_shape=Control.CURSOR_FDIAGSIZE if edges.x==edges.y else Control.CURSOR_BDIAGSIZE
	elif edges.x!=0:mouse_default_cursor_shape=Control.CURSOR_HSIZE
	else:mouse_default_cursor_shape=Control.CURSOR_VSIZE
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		window.begin_border_resize(edges)
		grab_focus()
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		var direction:Vector2={KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}[event.keycode]
		window.resize_window_by(direction*(24.0 if event.shift_pressed else 6.0))
		accept_event()

func _draw() -> void:
	if edges==Vector2.ONE:
		for offset in [4.0,8.0,12.0]:draw_line(Vector2(size.x-offset,size.y-2),Vector2(size.x-2,size.y-offset),Color("98703d"),1.5)
	elif get_global_rect().has_point(get_global_mouse_position()):draw_rect(Rect2(Vector2.ZERO,size),Color(0.69,0.54,0.30,0.45))
