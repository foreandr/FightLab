extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("SPELL LIMITER FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.preview_preferences_path="user://logs/limiter_preferences_test.cfg"
	b.draft_path="user://logs/limiter_draft_test.cfg"
	b.open_projectile_workspace()
	b.set_process(false);b.set_physics_process(false)
	b.preview_effect="Fire"
	b.select_demo_choice("cross",false)
	b.set_demo_duration(1.0)
	b.clear_shots()
	b.playing=false
	b.save_draft()
	var saved:=FileAccess.get_file_as_string(b.draft_path)
	var normal:Dictionary=b.demo_preview_spec()
	if not check(b.limiter_enabled and b.limiter_toggle.button_pressed and not b.test_inputs.duration.visible,"Default limiter state incorrect"):return
	b.limiter_toggle.set_pressed(false)
	if not check(not b.limiter_enabled and b.limiter_warning.visible and b.limiter_notice.visible,"Warning or off state missing"):return
	b.limiter_warning.hide()
	for key in ["duration","release","mana","stamina","damage"]:
		b.test_inputs[key].set_value(0.0)
	for key in ["size","speed","effect"]:b.test_inputs[key].set_value(1000.0)
	var raw:Dictionary=b.demo_preview_spec()
	if not check(raw.testing_only and raw.unrestricted_preview and raw.mana==0 and raw.stamina_cost==0 and raw.damage==0,"Independent zero-cost/damage values not honored"):return
	if not check(is_equal_approx(float(raw.potency),40.0),"Effect input clamped or correlated"):return
	var motion:Dictionary=preload("res://scripts/basic_projectile.gd").resolved_motion(raw)
	if not check(is_equal_approx(float(motion.speed),157.0) and is_equal_approx(float(motion.radius),20.0/3.0),"Runtime clamps testing size/speed"):return
	b.test_inputs.damage.set_value(234.0)
	var changed:Dictionary=b.demo_preview_spec()
	if not check(changed.damage==234 and changed.mana==0 and changed.stamina_cost==0 and changed.projectile_velocity==raw.projectile_velocity and changed.potency==40,"Changing damage correlates another value"):return
	b.test_inputs.damage.set_value(0)
	b.save_draft()
	if not check(FileAccess.get_file_as_string(b.draft_path)==saved,"Off-mode save overwrote valid draft"):return
	editor.actor.mana=0;editor.actor.stamina=0
	var before:int=editor.field.shot_serial
	b.play_demo_preview()
	if not check(editor.field.shot_serial==before+1 and not b.playing,"Zero-duration cast is not immediate"):return
	var shot:Dictionary=editor.field.shots.back()
	if not check(is_equal_approx(shot.velocity.length(),157.0) and is_equal_approx(float(shot.radius),20.0/3.0) and shot.spec.damage==0,"Actual spawned projectile ignores independent values"):return
	b.test_inputs.speed.set_value(0)
	if not check(preload("res://scripts/basic_projectile.gd").resolved_motion(b.demo_preview_spec()).speed==0,"Stationary projectile input not honored"):return
	b.limiter_toggle.set_pressed(true)
	var restored:Dictionary=b.demo_preview_spec()
	if not check(not restored.has("unrestricted_preview") and is_equal_approx(float(restored.damage),float(normal.damage)) and is_equal_approx(float(restored.mana),float(normal.mana)),"Re-enabling limiter retains unrestricted values"):return
	if not check(not b.test_inputs.damage.visible and not b.limiter_notice.visible and b.cast_duration()==1.0,"Balanced UI/duration not restored"):return
	b.set_projectile_allocation("size",0.8)
	var shares:Dictionary=b.allocation_for("Fire")
	if not check(is_equal_approx(float(shares.size+shares.speed+shares.effect),1.0),"Normal budget no longer linked"):return
	if not check(FileAccess.get_file_as_string(b.draft_path)!=saved,"Re-enabled limiter cannot save valid edits"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_limiter_on.png")
	b.set_limiter_enabled(false)
	b.limiter_warning.hide()
	for key in ["size","speed","effect"]:b.set_test_value(key,1000)
	for key in ["duration","mana","stamina"]:b.set_test_value(key,0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_limiter_off.png")
	print("SPELL LIMITER PASSED: warning, independent 1000% inputs, zero resources and immediate cast, actual runtime geometry/speed, stationary shot, no draft overwrite, balanced restoration and linked budget")
	quit()
