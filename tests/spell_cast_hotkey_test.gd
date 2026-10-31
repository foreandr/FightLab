extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("CAST HOTKEY FAILED: "+message)
	quit(1)
	return false
func press(key:int,echo:=false,ctrl:=false) -> void:
	var event:=InputEventKey.new()
	event.keycode=key
	event.physical_keycode=key
	event.pressed=true
	event.echo=echo
	event.ctrl_pressed=ctrl
	root.push_input(event,true)
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/hotkey_draft.cfg"
	b.preview_preferences_path="user://logs/hotkey_prefs.cfg"
	b.open_projectile_workspace()
	b.set_process(false)
	b.preview_effect="None"
	b.set_demo_duration(1.0)
	b.set_release_fraction(0.3)
	b.clear_shots()
	b.release_target_focus()
	b.manual_aim_point=editor.actor.global_position+Vector3(3,0.9,6)
	b.manual_aim_valid=true
	editor.actor.mana=100.0
	editor.actor.stamina=100.0
	for key in [KEY_1,KEY_KP_1]:
		b.playing=false
		b.preview_repeating=true
		press(key)
		if not check(b.playing and not b.preview_repeating and is_zero_approx(float(b.elapsed)),"1 does not use the Play-once action"):return
		var serial:int=editor.field.shot_serial
		b.process_demo_preview(0.31)
		if not check(editor.field.shot_serial==serial+1,"Hotkey cast did not launch projectile"):return
		var shot:Dictionary=editor.field.shots.back()
		if not check(shot.velocity.normalized().dot((b.manual_aim_point-shot.node.global_position).normalized())>0.999,"Hotkey discarded manual aim"):return
		press(key,true)
		if not check(is_equal_approx(float(b.elapsed),0.31),"Holding 1 restarts the cast"):return
		press(key,false,true)
		if not check(is_equal_approx(float(b.elapsed),0.31),"Ctrl+1 unexpectedly casts"):return
	if not check(b.projectile_preview_button.text=="Play [1]" and b.projectile_hitbox_button.text=="Hitboxes [2]","Buttons do not show hotkeys"):return
	b.set_preview_hitboxes(false)
	press(KEY_2)
	if not check(b.preview_hitboxes and b.projectile_hitbox_button.button_pressed,"2 did not toggle outlines on"):return
	for shot in editor.field.shots:
		var outline:MeshInstance3D=shot.get("hitbox_outline")
		if not check(is_instance_valid(outline) and outline.visible and is_equal_approx(float(outline.get_meta("collision_radius")),float(shot.radius)),"Existing projectile outline does not match collision sphere"):return
	b.set_projectile_allocation("size",0.0)
	editor.actor.mana=100.0
	b.launch_projectile()
	var small:Dictionary=editor.field.shots.back()
	var expected_radius:float=0.1/3.0*float(b.demo_projectile_stats().amplifier)
	if not check(is_equal_approx(float(small.radius),expected_radius) and is_equal_approx(float(small.hitbox_outline.get_meta("collision_radius")),expected_radius),"Zero-percent size outline is inaccurate"):return
	var original_radius:float=small.radius
	press(KEY_2,true)
	if not check(b.preview_hitboxes,"Holding 2 repeatedly toggles outlines"):return
	press(KEY_KP_2)
	if not check(not b.preview_hitboxes and not small.hitbox_outline.visible and is_equal_approx(float(small.radius),original_radius),"Hiding outlines changed actual hitbox"):return
	var text:=LineEdit.new()
	editor.base_ui.add_child(text)
	text.grab_focus()
	b.playing=false
	press(KEY_1)
	if not check(not b.playing,"Typing 1 in text field casts spell"):return
	press(KEY_2)
	if not check(not b.preview_hitboxes,"Typing 2 in text field toggles hitboxes"):return
	text.queue_free()
	var outline:Node=small.hitbox_outline
	b.clear_shots()
	await process_frame
	if not check(not is_instance_valid(outline),"Hitbox outline leaks after projectile cleanup"):return
	print("SPELL HOTKEYS PASSED: Play [1], cast once with manual aim, Hitboxes [2], live/zero-size sphere accuracy, hide without disabling collision, cleanup, text/repeat guards")
	quit()
