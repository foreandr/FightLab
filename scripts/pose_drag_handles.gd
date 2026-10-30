extends Control
## The rings are projected from real bones and never intercept camera input.
var editor:Node

func _draw() -> void:
	if not is_instance_valid(editor) or not editor.direct_pose_handles_visible():return
	var font:=ThemeDB.fallback_font
	var target_tools=editor.pose_targets
	if target_tools.boxing:
		var rect:=Rect2(target_tools.box_start,target_tools.box_end-target_tools.box_start).abs()
		draw_rect(rect,Color(0.3,0.8,1.0,0.15))
		draw_rect(rect,Color.SKY_BLUE,false,2.0)
	for bone in target_tools.selected:
		var point:Vector3=editor.DragSolver.point(editor.actor,bone)
		if not editor.field.camera.is_position_behind(point):draw_circle(editor.field.camera.unproject_position(point),10,Color(1,0.8,0.2,0.5))
	for handle in editor.direct_pose_handle_points():
		var active:bool=handle.bone==editor.custom_drag_handle or handle.bone==editor.custom_drag_hover
		var color:=Color("ffda85") if active else Color("80f4d0")
		draw_circle(handle.screen,8.0 if active else 6.0,Color(0.04,0.09,0.12,0.85))
		draw_arc(handle.screen,8.0 if active else 6.0,0,TAU,24,color,2.0,true)
		draw_circle(handle.screen,2.0,color)
		if active:
			var label_position:Vector2=handle.screen+Vector2(13,-12)
			draw_string(font,label_position+Vector2(1,1),handle.label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.BLACK)
			draw_string(font,label_position,handle.label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
	if not editor.custom_drag_handle.is_empty():
		var camera:Camera3D=editor.field.camera
		var target:Vector2=camera.unproject_position(editor.custom_drag_target)
		draw_circle(target,4.0,Color("ffda85"))
