extends Control
var editor

func _process(_delta:float) -> void:
	if editor==null or not is_instance_valid(editor.workspace_choices):return
	global_position=editor.workspace_choices.global_position
	size=editor.workspace_choices.size
	var data:Variant=get_viewport().gui_get_drag_data()
	var active:bool=data is Dictionary and bool(data.get("store_origin",false)) and editor.selected_group in ["Motion","Attack"]
	var store:Control=editor.workspace_nav_panels.get("Store")
	if store!=null and store.is_visible_in_tree() and store.get_global_rect().has_point(get_global_mouse_position()):active=false
	mouse_filter=Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	visible=active
	queue_redraw()

func _draw() -> void:
	if get_rect().has_point(get_local_mouse_position()):
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.91,0.72,0.30,0.15))
		draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("b08a4b"),false,2)

func _can_drop_data(_point:Vector2,data:Variant) -> bool:
	return data is Dictionary and bool(data.get("store_origin",false)) and editor.selected_group in ["Motion","Attack"]

func _drop_data(_point:Vector2,data:Variant) -> void:
	editor.take_store_animation(data.entry,editor.selected_group,editor.selected_category)
