extends HBoxContainer

var dragging:=false
var drag_offset:=Vector2.ZERO

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	mouse_default_cursor_shape=Control.CURSOR_MOVE
	tooltip_text="Drag title to move · Drag window edges to resize · Arrows move; Ctrl+arrows resize"

func _window() -> Control:
	return get_parent().get_parent() as Control

func _detach_anchors() -> void:
	var window:=_window()
	var previous_position:=window.global_position
	var previous_size:=window.size
	window.set_anchors_preset(Control.PRESET_TOP_LEFT,true)
	window.global_position=previous_position
	window.size=previous_size

func _move_window(point:Vector2) -> void:
	var window:=_window()
	var viewport_size:=get_viewport_rect().size
	window.global_position=Vector2(clampf(point.x,0.0,maxf(0.0,viewport_size.x-window.size.x)),clampf(point.y,0.0,maxf(0.0,viewport_size.y-size.y)))

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		_detach_anchors()
		dragging=true
		drag_offset=get_global_mouse_position()-_window().global_position
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		_detach_anchors()
		var movement:Vector2={KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}[event.keycode]
		if event.ctrl_pressed and _window().has_method("resize_window_by"):_window().call("resize_window_by",movement*(24.0 if event.shift_pressed else 6.0))
		else:_move_window(_window().global_position+movement*(24.0 if event.shift_pressed else 6.0))
		accept_event()

func _input(event:InputEvent) -> void:
	if not dragging:return
	if event is InputEventMouseMotion:
		_move_window(event.position-drag_offset)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		dragging=false
		get_viewport().set_input_as_handled()
