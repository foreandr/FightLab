extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("DEFAULT BOT FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var deadline:=Time.get_ticks_msec()+90000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	if not check(editor!=null and editor.added_units.size()==1,"Create must start with exactly one bot"):return
	var unit:CharacterBody3D=editor.added_units[0]
	if not check(str(unit.name)=="BOT_1" and unit.global_position.is_equal_approx(Vector3(0,0.02,0)),"BOT_1 is not centered"):return
	if not check(editor.focused_unit==unit and editor.can_add_unit_animation(),"Default bot is not selected and ready"):return
	if not check(editor.timeline_clips.is_empty(),"Default bot should not populate the timeline"):return
	var second:CharacterBody3D=editor.spawn_editor_unit(Vector3(2,0.02,0))
	if not check(str(second.name)=="BOT_2","Additional bot numbering is incorrect"):return
	unit.queue_free()
	second.queue_free()
	for frame in 4:await process_frame
	if not check(editor.added_units.size()==1 and is_instance_valid(editor.focused_unit),"Removing the last bot left Create empty"):return
	unit=editor.added_units[0]
	if not check(str(unit.name)=="BOT_1" and unit.global_position.is_equal_approx(Vector3(0,0.02,0)),"Replacement default bot is not centered"):return
	editor.select_group("Spells")
	if not check(editor.actor.visible and editor.actor.global_position.is_equal_approx(Vector3(0,0.02,0)) and not unit.visible,"Spell demo should show one centered character"):return
	editor.select_group("Motion")
	if not check(unit.visible and editor.focused_unit==unit,"Returning to animations lost the default bot"):return
	print("DEFAULT BOT PASSED: centered selected BOT_1, empty timeline, BOT_2 numbering, automatic minimum-one recovery, centered spell demo, workspace switches")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
