extends Control

var editor
var kind:="browser"
var dragging:=false

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	mouse_default_cursor_shape=Control.CURSOR_VSIZE if kind=="timeline" else Control.CURSOR_HSIZE
	tooltip_text="Drag to resize · Arrow keys resize when focused · Double-click to reset"
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	if dragging or has_focus() or get_rect().has_point(get_parent().get_local_mouse_position()):
		draw_rect(Rect2(Vector2.ZERO,size),Color("b18b4c"))

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		if event.double_click:
			var coordinate:float=164.0 if kind=="categories" else (490.0 if kind=="browser" else editor.base_ui.size.y-350.0)
			editor.resize_workspace(kind,coordinate)
			editor.save_workspace_layout()
		else:dragging=true
		queue_redraw()
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		var coordinate:float=position.y+3.0 if kind=="timeline" else position.x+3.0
		coordinate+=(-1.0 if event.keycode in [KEY_LEFT,KEY_UP] else 1.0)*(24.0 if event.shift_pressed else 6.0)
		editor.resize_workspace(kind,coordinate)
		editor.save_workspace_layout()
		accept_event()

func _input(event:InputEvent) -> void:
	if not dragging:return
	if event is InputEventMouseMotion:
		var point:Vector2=get_parent().get_local_mouse_position()
		editor.resize_workspace(kind,point.y if kind=="timeline" else point.x)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		dragging=false
		editor.save_workspace_layout()
		queue_redraw()
		get_viewport().set_input_as_handled()
