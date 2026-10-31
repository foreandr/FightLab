extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PROJECTILE WORKSPACE FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var deadline:=Time.get_ticks_msec()+90000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	if not check(editor!=null and is_instance_valid(editor.get("actor")),"Create was not ready"):return
	var builder=editor.spell_builder
	var original_draft:String=builder.draft_path
	var original_preferences:String=builder.preview_preferences_path
	builder.draft_path="user://logs/projectile_workspace_test.cfg"
	builder.preview_preferences_path="user://logs/projectile_preview_test.cfg"
	builder.projectile_initialized=false
	builder.projectile_effect_confirmed=false
	builder.release_fraction=0.05
	editor.select_group("Spells")
	builder.select_demo_choice("cross")
	builder.set_demo_duration(4.0)
	builder.demo_confirm_button.pressed.emit()
	var camera_before:Transform3D=editor.field.camera.global_transform
	builder.delivery_choices.Projectile.pressed.emit()
	if not check(editor.field.camera.global_transform.is_equal_approx(camera_before),"Projectile choice reset the camera"):return
	if not check(builder.creation_step=="projectile" and builder.projectile_screen.is_visible_in_tree(),"Projectile choice did not open its editor"):return
	if not check(builder.demo_timing_panel.is_visible_in_tree() and builder.demo_timing_panel.anchor_left>0.5 and builder.anchor_left==0.0,"Timing must stay on the right and Fireball on the left"):return
	if not check(builder.demo_mana_cost_label.is_visible_in_tree() and builder.demo_amplifier_label.is_visible_in_tree() and is_equal_approx(float(builder.demo_duration),1.0),"Projectile editor lost timing readouts or one-second entry default"):return
	var base:Dictionary=builder.projectile_spec()
	if not check(base.projectile_element=="None","Default projectile must be elementless"):return
	builder.set_demo_duration(0.5)
	builder.set_release_fraction(0.55)
	var example:Dictionary=builder.demo_preview_spec()
	if not check(is_equal_approx(float(example.mana),10.0*sqrt(2.0)) and builder.demo_mana_cost_label.text=="Mana cost: 14.1","Half-second neutral spell does not cost 14.1 mana"):return
	if not check(is_equal_approx(float(example.projectile_radius),float(base.projectile_radius)*1.25/3.0) and is_equal_approx(float(example.projectile_velocity),float(base.projectile_velocity)*1.25),"Timing amp does not apply the new 25 percent bonus"):return
	if not check(builder.demo_amplifier_label.text=="Spell amp: +25.0%" and "1.25 timing" in builder.demo_amp_breakdown.text,"Bonus readouts do not show reduced timing amp"):return
	for effect in ["Ice","Lightning","Wind","Water","Earth"]:
		if not check(builder.effect_choices[effect].disabled,"Unavailable element is enabled: "+effect):return
	builder.preview_projectile_effect("Ice")
	if not check(builder.preview_effect=="None","Disabled effect can still be selected"):return
	builder.set_demo_duration(1.0)
	for sample in [0.05,0.30,0.55]:
		builder.set_release_fraction(sample)
		var serial:int=editor.field.shot_serial
		var previous_elapsed:=0.0
		while builder.playing:
			previous_elapsed=builder.elapsed
			await process_frame
			if editor.field.shot_serial>serial:
				if not check(float(builder.elapsed)>=sample and previous_elapsed<=sample+0.1,"Projectile missed configured release timing"):return
				break
		if not check(editor.field.shot_serial==serial+1,"Release did not fire exactly once"):return
		var expected:float=1.0+0.25*(sample-0.05)/0.50
		if not check(is_equal_approx(float(builder.demo_preview_spec().potency),float(base.potency)*expected),"Timing amp does not match release"):return
		if not editor.field.shots.is_empty():
			var shot:Dictionary=editor.field.shots.back()
			if not check(is_equal_approx(float(shot.radius),float(base.projectile_radius)*expected/3.0) and is_equal_approx(shot.velocity.length(),float(base.projectile_velocity)*expected),"Actual projectile size/speed does not match amp"):return
	builder.set_release_fraction(-1.0)
	if not check(is_equal_approx(float(builder.release_fraction),0.05),"Release allowed before 5 percent"):return
	builder.set_release_fraction(2.0)
	if not check(is_equal_approx(float(builder.release_fraction),0.55),"Release allowed past apex"):return
	builder.load_draft()
	if not check(is_equal_approx(float(builder.release_fraction),0.55),"Release setting did not persist"):return
	builder.set_release_fraction(0.05)
	base=builder.projectile_spec()
	if not check(builder.spell_playback_panel.is_visible_in_tree() and builder.projectile_preview_button.get_parent().get_parent()==builder.spell_playback_panel,"Playback controls are not in the bottom bar"):return
	builder.effect_choices.Fire.pressed.emit()
	if not check(builder.element=="None" and builder.demo_preview_spec().projectile_element=="Fire","Effect preview changed saved selection or failed to preview"):return
	builder.effect_confirm_button.pressed.emit()
	if not check(builder.element=="Fire" and builder.projectile_effect_confirmed,"Confirm did not save effect"):return
	builder.effect_choices.None.pressed.emit()
	if not check(builder.element=="Fire" and builder.demo_preview_spec().projectile_element=="None","Pending neutral effect was not independent"):return
	builder.effect_choices.Fire.pressed.emit()
	base=builder.projectile_spec()
	builder.set_demo_duration(1.0)
	var normal:Dictionary=builder.demo_physical_stats()
	builder.set_demo_duration(0.5)
	var fast:Dictionary=builder.demo_physical_stats()
	if not check(float(fast.stamina)>float(normal.stamina) and float(fast.damage)<float(normal.damage),"Faster cast must cost more stamina and deal less base damage"):return
	builder.set_demo_duration(0.1)
	if not check(is_equal_approx(float(builder.demo_physical_stats().stamina),100.0),"Stamina cap is not 100"):return
	for choice in ["block","mend"]:
		builder.select_demo_choice(choice)
		if not check(is_zero_approx(float(builder.demo_physical_stats().damage)),"Passive demo deals physical damage"):return
	builder.select_demo_choice("cross")
	builder.set_demo_duration(0.5)
	var serial_before:int=editor.field.shot_serial
	builder.projectile_preview_button.pressed.emit()
	var fired:=false
	var until:=Time.get_ticks_msec()+2500
	while Time.get_ticks_msec()<until:
		await RenderingServer.frame_post_draw
		if editor.field.shot_serial>serial_before:
			fired=true
			if not editor.field.shots.is_empty():
				var shot:Dictionary=editor.field.shots.back()
				if not check(is_equal_approx(float(shot.spec.damage),float(builder.demo_projectile_stats().physical_damage)) and shot.spec.projectile_element=="Fire" and shot.velocity.normalized().dot(shot.spec.aim_direction)>0.999,"Fireball did not fire toward its practice aim"):return
			root.get_texture().get_image().save_png("user://logs/projectile_workspace_fireball.png")
			break
	if not check(fired,"Preview button did not create a projectile"):return
	builder.set_demo_duration(0.4)
	serial_before=editor.field.shot_serial
	builder.projectile_preview_button.pressed.emit()
	until=Time.get_ticks_msec()+1400
	while Time.get_ticks_msec()<until:await process_frame
	if not check(editor.field.shot_serial==serial_before+1,"Play did not cast exactly once"):return
	serial_before=editor.field.shot_serial
	builder.projectile_repeat_button.set_pressed(true)
	until=Time.get_ticks_msec()+2600
	while Time.get_ticks_msec()<until:await process_frame
	if not check(editor.field.shot_serial>=serial_before+2,"Repeat did not cast multiple times"):return
	builder.projectile_repeat_button.set_pressed(false)
	until=Time.get_ticks_msec()+650
	while Time.get_ticks_msec()<until:await process_frame
	var stopped_serial:int=editor.field.shot_serial
	until=Time.get_ticks_msec()+800
	while Time.get_ticks_msec()<until:await process_frame
	if not check(editor.field.shot_serial==stopped_serial,"Repeat continued after being disabled"):return
	var initial_scale:=Engine.time_scale
	builder.projectile_slow_button.set_pressed(true)
	if not check(is_equal_approx(Engine.time_scale,0.25),"Slow mo did not set quarter speed"):return
	builder.projectile_preview_button.pressed.emit()
	until=Time.get_ticks_msec()+250
	while Time.get_ticks_msec()<until:await process_frame
	if not check(float(builder.elapsed)>0.01 and float(builder.elapsed)<0.2,"Slow mo did not slow the animation"):return
	builder.projectile_back_button.pressed.emit()
	if not check(is_equal_approx(Engine.time_scale,initial_scale) and not builder.preview_repeating and not builder.preview_slow,"Back leaked slow motion or repeating into the workspace"):return
	builder.delivery_choices.Projectile.pressed.emit()
	base=builder.projectile_spec()
	builder.set_demo_duration(16.0)
	var amplified:Dictionary=builder.demo_preview_spec()
	if not check(is_zero_approx(float(amplified.mana)) and is_equal_approx(float(amplified.potency),float(base.potency)*(34.0/9.0)),"Live preview does not match the mana/amp readout"):return
	if not check(builder.projectile_spec()==base,"Demo timing modified the saved spell's base stats"):return
	builder.projectile_back_button.pressed.emit()
	if not check(builder.creation_step=="delivery" and builder.demo_timing_panel.is_visible_in_tree(),"Back hid the timing readout"):return
	builder.delivery_choices.Projectile.pressed.emit()
	if not check(is_equal_approx(float(builder.demo_duration),1.0) and builder.total_power==1.0 and is_equal_approx(float(builder.release_fraction),0.3) and builder.element=="None" and builder.projectile_initialized,"Reopening projectile did not restore requested defaults"):return
	print("PROJECTILE WORKSPACE PASSED: Fire-only selection, neutral default, release at 5/30/55 percent, timing amp, release bounds and persistence, effect confirmation, playback, stamina/damage and mana/amp")
	builder.draft_path=original_draft
	builder.preview_preferences_path=original_preferences
	builder.load_draft()
	builder.choose_default(false)
	builder.load_demo_preferences()
	builder.open_projectile_workspace()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/projectile_workspace.png")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
