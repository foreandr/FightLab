extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func render_frame() -> void:
	if DisplayServer.get_name()=="headless":await process_frame
	else:await RenderingServer.frame_post_draw
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("DIRECTIONAL MOVEMENT FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace()
	b.set_physics_process(false)
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
	# Keep expected rates independent from the implementation under test.
	var rates:=[1.0,0.6,0.8,0.8,0.9,0.9,0.7,0.7,1.0]
	for index in 8:
		var sample:Array=cases[index].duplicate(true)
		sample[0].append(KEY_SHIFT)
		if sample[1].y>0:sample[2][0]="duel/run"
		cases.append(sample)
		rates.append([1.0,0.5,0.75,0.75,0.9,0.9,0.6,0.6][index])
	var case_index:=0
	for sample in cases:
		root.grab_focus()
		for frame in 30:
			await render_frame()
			if root.has_focus():break
		b.reset_practice_scene()
		var focused:=root.gui_get_focus_owner()
		if focused!=null:focused.release_focus()
		# Measure locomotion without the practice targets blocking the path.
		editor.actor.collision_mask=1
		b.focus_spell_target(editor.target)
		for frame in 4:await process_frame
		var before:Vector3=editor.actor.position
		var forward:Vector3=-editor.field.camera.global_basis.z
		forward.y=0;forward=forward.normalized()
		var right:Vector3=forward.cross(Vector3.UP)
		var expected:Vector3=(forward*sample[1].y+right*sample[1].x).normalized()
		for frame in 21:
			await physics_frame
			b.move_caster(1.0/60.0,sample[1].normalized(),KEY_SHIFT in sample[0])
			b.process_demo_preview(1.0/60.0)
		await render_frame()
		var moved:Vector3=editor.actor.position-before
		if not check(moved.length()>0.35 and moved.normalized().dot(expected)>0.95,"Movement direction is wrong: keys=%s moved=%s expected=%s velocity=%s focus=%s text=%s held=%s"%[sample[0],moved,expected,editor.actor.velocity,root.has_focus(),editor.camera_text_editing(),b.movement_keys]):return
		var speed:float=(7.0 if KEY_SHIFT in sample[0] else 4.0)*rates[case_index]*editor.actor.movement_multiplier()
		case_index+=1
		if not check(absf(Vector2(editor.actor.velocity.x,editor.actor.velocity.z).length()-speed)<0.05,"Directional speed incorrect: keys=%s expected=%s actual=%s"%[sample[0],speed,editor.actor.velocity]):return
		var facing:Vector3=(editor.target.position-editor.actor.position).normalized()
		if not check(editor.actor.global_basis.z.dot(facing)>0.98,"Strafe/backpedal turned away from target: keys=%s forward=%s toward=%s lock=%s mode=%s playing=%s"%[sample[0],editor.actor.global_basis.z,facing,editor.field.camera_focus_target,editor.actor.mode,b.playing]):return
		if not check(editor.actor.get_meta("creation_locomotion_clips",[])==sample[2],"Incorrect directional animation: "+str(sample[0])):return
		b.move_caster(1.0/60.0,Vector2.ZERO,false)
		for frame in 14:await process_frame
		if not check(not b.caster_moving and editor.actor.clip.begins_with("default_idle/"),"Stopping did not return to idle"):return
	editor.select_group("Motion")
	editor.playtest.toggle()
	editor.set_physics_process(false)
	for sample in [cases[1],cases[2],cases[3],cases[5]]:
		editor.playtest.reset_units()
		var unit=editor.focused_unit
		var before:Vector3=unit.position
		editor.playtest.held.clear()
		for code in sample[0]:editor.playtest.held[code]=true
		for frame in 21:
			await physics_frame
			editor.playtest.physics(1.0/60.0)
		var facing:Vector3=-editor.field.camera.global_basis.z
		facing.y=0;facing=facing.normalized()
		if not check(unit.position.distance_to(before)>0.5 and unit.global_basis.z.dot(facing)>0.98,"Take Control turns toward travel direction"):return
		if not check(editor.actor.get_meta("creation_locomotion_clips",[])==sample[2],"Take Control lacks matching directional animation"):return
		editor.playtest.held.clear()
	editor.playtest.release()
	editor.select_group("Spells")
	b.open_projectile_workspace()
	b.reset_practice_scene()
	print("DIRECTIONAL MOVEMENT PASSED: scripted eight-way walk/sprint rates, strafe/backpedal poses, diagonal blend, normalized input, forward facing, idle return, Take Control parity")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
