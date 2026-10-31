extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func press_f() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_F
	event.physical_keycode=KEY_F
	event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("CAMERA FOCUS FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	editor.spell_builder.open_projectile_workspace()
	editor.spell_builder.playing=false
	var position:Vector3=editor.actor.position
	editor.select_editor_unit(editor.target)
	press_f()
	await RenderingServer.frame_post_draw
	if not check(editor.field.camera_focus_target==editor.target and editor.actor.position.is_equal_approx(position),"F did not lock spell target without moving caster"):return
	editor.select_group("Motion")
	editor.inspection_camera.focus+=Vector3(30,0,0)
	editor.inspection_camera.apply(editor.field.camera)
	press_f()
	await RenderingServer.frame_post_draw
	if not check(editor.inspection_camera.focus.distance_to(editor.focused_unit.global_position+Vector3.UP*1.1)<0.1,"F did not focus selected unit"):return
	var entry:=LineEdit.new()
	editor.base_ui.add_child(entry)
	entry.grab_focus()
	var before:Vector3=editor.inspection_camera.focus
	press_f()
	await RenderingServer.frame_post_draw
	if not check(editor.inspection_camera.focus.is_equal_approx(before),"Typing F moved camera"):return
	entry.release_focus()
	entry.queue_free()
	editor.select_group("Spells")
	editor.spell_builder.open_projectile_workspace()
	print("CAMERA FOCUS PASSED: F locks spell target and frames selected animation unit, no position reset, typing protected")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
