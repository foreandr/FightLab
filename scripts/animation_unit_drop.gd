extends Control

var editor
var dragged_unit:CharacterBody3D
var drag_origin:=Vector2.ZERO
var drag_offset:=Vector3.ZERO
var moving:=false

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var unit:CharacterBody3D=editor._pick_editor_unit(global_position+event.position)
		if unit!=null:
			editor.select_editor_unit(unit)
			var hit:Variant=editor.arena_drag_point(global_position+event.position)
			if hit!=null:
				dragged_unit=unit
				drag_origin=global_position+event.position
				drag_offset=unit.global_position-(hit as Vector3)
				moving=false
			accept_event()
		else:
			editor.clear_editor_unit_selection()
			accept_event()

func _input(event:InputEvent) -> void:
	if not is_instance_valid(dragged_unit):return
	if event is InputEventMouseMotion:
		if not moving and event.position.distance_to(drag_origin)<4.0:return
		if not moving:
			if editor.selected_group!="Spells":editor.stop_timeline()
			moving=true
		var hit:Variant=editor.arena_drag_point(event.position)
		if hit!=null:editor.move_editor_unit(dragged_unit,(hit as Vector3)+drag_offset)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		dragged_unit=null
		moving=false
		get_viewport().set_input_as_handled()

func _can_drop_data(_position:Vector2,data:Variant) -> bool:
	return data is Dictionary and data.get("type","")=="fightlab_editor_unit"

func _drop_data(position_:Vector2,_data:Variant) -> void:
	editor.spawn_editor_unit_at_screen(global_position+position_)
