extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("DIRECTIONAL MOVEMENT FAILED: "+message)
	quit(1)
	return false
func keys(codes:Array,pressed:bool) -> void:
	for code in codes:
		var event:=InputEventKey.new()
		event.keycode=code
		event.physical_keycode=code
		event.pressed=pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace()
	root.grab_focus()
	var cases:Array=[
		[[KEY_W],Vector2(0,1),["ual1/Jog_Fwd"]],
		[[KEY_S],Vector2(0,-1),["duel/walk_back"]],
		[[KEY_A],Vector2(-1,0),["duel/strafe_left"]],
		[[KEY_D],Vector2(1,0),["duel/strafe_right"]],
		[[KEY_W,KEY_A],Vector2(-1,1),["ual1/Jog_Fwd","duel/strafe_left"]],
		[[KEY_W,KEY_D],Vector2(1,1),["ual1/Jog_Fwd","duel/strafe_right"]],
		[[KEY_S,KEY_A],Vector2(-1,-1),["duel/walk_back","duel/strafe_left"]],
		[[KEY_S,KEY_D],Vector2(1,-1),["duel/walk_back","duel/strafe_right"]],
		[[KEY_W,KEY_SHIFT],Vector2(0,1),["duel/run"]]
	]
	for sample in cases:
		b.reset_practice_scene()
		b.focus_spell_target(editor.target)
		for frame in 4:await process_frame
		var before:Vector3=editor.actor.position
		var forward:Vector3=-editor.field.camera.global_basis.z
		forward.y=0;forward=forward.normalized()
		var right:Vector3=forward.cross(Vector3.UP)
		var expected:Vector3=(forward*sample[1].y+right*sample[1].x).normalized()
		keys(sample[0],true)
		var until:=Time.get_ticks_msec()+350
		while Time.get_ticks_msec()<until:await process_frame
		await RenderingServer.frame_post_draw
		var moved:Vector3=editor.actor.position-before
		if not check(moved.length()>0.5 and moved.normalized().dot(expected)>0.95,"Movement direction is wrong: "+str(sample[0])):return
		var speed:=7.0 if KEY_SHIFT in sample[0] else 4.0
		if not check(absf(editor.actor.velocity.length()-speed)<0.05,"Diagonal speed differs from straight movement"):return
		var facing:Vector3=(editor.target.position-editor.actor.position).normalized()
		if not check(editor.actor.global_basis.z.dot(facing)>0.98,"Strafe/backpedal turned away from target: keys=%s forward=%s toward=%s lock=%s mode=%s playing=%s"%[sample[0],editor.actor.global_basis.z,facing,editor.field.camera_focus_target,editor.actor.mode,b.playing]):return
		if not check(editor.actor.get_meta("creation_locomotion_clips",[])==sample[2],"Incorrect directional animation: "+str(sample[0])):return
		keys(sample[0],false)
		until=Time.get_ticks_msec()+220
		while Time.get_ticks_msec()<until:await process_frame
		if not check(not b.caster_moving and editor.actor.clip.begins_with("default_idle/"),"Stopping did not return to idle"):return
	editor.select_group("Motion")
	editor.playtest.toggle()
	for sample in [cases[1],cases[2],cases[3],cases[5]]:
		editor.playtest.reset_units()
		var unit=editor.focused_unit
		var before:Vector3=unit.position
		keys(sample[0],true)
		var until:=Time.get_ticks_msec()+350
		while Time.get_ticks_msec()<until:await process_frame
		var facing:Vector3=-editor.field.camera.global_basis.z
		facing.y=0;facing=facing.normalized()
		if not check(unit.position.distance_to(before)>0.5 and unit.global_basis.z.dot(facing)>0.98,"Take Control turns toward travel direction"):return
		if not check(editor.actor.get_meta("creation_locomotion_clips",[])==sample[2],"Take Control lacks matching directional animation"):return
		keys(sample[0],false)
	editor.playtest.release()
	editor.select_group("Spells")
	b.open_projectile_workspace()
	b.reset_practice_scene()
	print("DIRECTIONAL MOVEMENT PASSED: eight directions, strafe/backpedal poses, diagonal blend, normalized speed, forward facing, sprint, idle return, Take Control parity")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
