extends PanelContainer

var resizing:=false
var resize_edges:=Vector2.ZERO
var resize_origin:=Rect2()
var resize_grips:Array[Control]=[]
var minimum_window_size:=Vector2(320,220)
var ignore_content_minimum:=false

func _ready() -> void:
	set_process_input(true)
	set_process(true)

func begin_border_resize(edges:Vector2) -> void:
	_detach_anchors()
	resizing=true
	resize_edges=edges
	resize_origin=get_global_rect()

func _ensure_resize_grips() -> void:
	if not resize_grips.is_empty():return
	for edges in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		var grip:=Control.new()
		grip.set_script(preload("res://scripts/workspace_window_resize_grip.gd"))
		grip.set("window",self)
		grip.set("edges",edges)
		get_parent().add_child(grip)
		resize_grips.append(grip)

func _update_resize_grips() -> void:
	_ensure_resize_grips()
	var rect:=get_global_rect()
	for grip in resize_grips:
		grip.visible=is_visible_in_tree()
		if not grip.visible:continue
		var edges:Vector2=grip.get("edges")
		grip.size=Vector2(16.0 if edges.x!=0 else maxf(16.0,size.x-16.0),16.0 if edges.y!=0 else maxf(16.0,size.y-16.0))
		grip.global_position=rect.position+Vector2(-8 if edges.x<0 else (size.x-8 if edges.x>0 else 8),-8 if edges.y<0 else (size.y-8 if edges.y>0 else 8))
		if get_index()>grip.get_index():get_parent().move_child(grip,get_parent().get_child_count()-1)

func _edges_at(point:Vector2) -> Vector2:
	var rect:=get_global_rect()
	if not rect.grow(10.0).has_point(point):return Vector2.ZERO
	var local:=point-rect.position
	return Vector2(-1 if local.x<8 else (1 if local.x>size.x-8 else 0),-1 if local.y<8 else (1 if local.y>size.y-8 else 0))

func _process(_delta:float) -> void:
	_update_resize_grips()
	if not is_visible_in_tree():return
	var edges:=resize_edges if resizing else _edges_at(get_global_mouse_position())
	if edges.x!=0 and edges.y!=0:mouse_default_cursor_shape=Control.CURSOR_FDIAGSIZE if edges.x==edges.y else Control.CURSOR_BDIAGSIZE
	elif edges.x!=0:mouse_default_cursor_shape=Control.CURSOR_HSIZE
	elif edges.y!=0:mouse_default_cursor_shape=Control.CURSOR_VSIZE
	else:mouse_default_cursor_shape=Control.CURSOR_ARROW

func _detach_anchors() -> void:
	var position_before:=global_position
	var size_before:=size
	set_anchors_preset(Control.PRESET_TOP_LEFT,true)
	global_position=position_before
	size=size_before

func resize_window_by(amount:Vector2) -> void:
	_detach_anchors()
	resize_origin=get_global_rect()
	resize_edges=Vector2.ONE
	_resize_to(resize_origin.end+amount)
	resize_edges=Vector2.ZERO

func _resize_to(point:Vector2) -> void:
	var minimum:=minimum_window_size
	if not ignore_content_minimum:minimum=minimum.max(get_combined_minimum_size())
	var viewport_size:=get_viewport_rect().size
	var start:=resize_origin.position
	var end:=resize_origin.end
	if resize_edges.x<0:start.x=clampf(point.x,0.0,maxf(0.0,end.x-minimum.x))
	elif resize_edges.x>0:end.x=clampf(point.x,start.x+minimum.x,maxf(start.x+minimum.x,viewport_size.x))
	if resize_edges.y<0:start.y=clampf(point.y,0.0,maxf(0.0,end.y-minimum.y))
	elif resize_edges.y>0:end.y=clampf(point.y,start.y+minimum.y,maxf(start.y+minimum.y,viewport_size.y))
	global_position=start
	size=end-start

func _input(event:InputEvent) -> void:
	if not is_visible_in_tree():return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			var edges:=_edges_at(event.position)
			if edges==Vector2.ZERO:return
			_detach_anchors()
			resizing=true
			resize_edges=edges
			resize_origin=get_global_rect()
		elif resizing:
			resizing=false
			resize_edges=Vector2.ZERO
		else:return
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and resizing:
		_resize_to(event.position)
		get_viewport().set_input_as_handled()
