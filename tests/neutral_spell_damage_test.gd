extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("NEUTRAL SPELL DAMAGE FAILED: "+message)
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
	b.draft_path="user://logs/neutral_damage_draft_test.cfg"
	b.preview_preferences_path="user://logs/neutral_damage_preferences_test.cfg"
	b.open_projectile_workspace()
	b.select_demo_choice("cross",false)
	b.set_process(false);b.set_physics_process(false)
	editor.field.set_physics_process(false)
	b.playing=false;b.clear_shots()
	b.set_character_god_mode(editor.actor,false)
	b.set_dummy_god_mode(true)
	editor.actor.mana=100;editor.actor.stamina=100
	editor.target.invulnerability=0.0;editor.target.guard_energy=0.0
	var normal:Dictionary=b.demo_preview_spec()
	if not check(normal.mana==10.0 and normal.stamina_cost==10.0 and is_equal_approx(float(normal.damage),10.0),"Neutral setup is not 10 mana / 10 stamina / 10 damage"):return
	if not check(b.demo_damage_label.text=="Physical damage: 10.0" and "1.00 speed × 1.00 amp" in b.demo_damage_breakdown.text,"RHS does not show neutral damage factors"):return
	if not check(is_equal_approx(float(normal.projectile_velocity),9.39375) and is_equal_approx(float(normal.projectile_radius),sqrt(0.2)/3.0*1.125),"Calibration changed actual projectile speed/size"):return
	b.manual_aim=true;b.manual_aim_valid=true
	b.manual_aim_point=editor.target.bone_point("spine_03")
	var before:float=editor.target.damage_taken
	b.launch_projectile()
	if not check(editor.actor.mana==90 and editor.actor.stamina==90,"Neutral cast does not spend exactly 10/10"):return
	for frame in 100:
		editor.field.step_shots(1.0/60.0)
		if editor.field.shots.is_empty():break
	if not check(is_equal_approx(float(editor.target.damage_taken)-before,10.0),"Actual unblocked impact does not deal 10 damage"):return
	b.set_release_fraction(0.05)
	if not check(float(b.demo_preview_spec().damage)<10,"Earlier timing does not reduce relative damage"):return
	b.set_release_fraction(0.55)
	if not check(float(b.demo_preview_spec().damage)>10,"Later timing does not increase relative damage"):return
	b.set_release_fraction(0.3)
	b.set_projectile_allocation("speed",1.0)
	if not check(float(b.demo_preview_spec().damage)>10,"Faster allocation does not increase damage"):return
	b.set_projectile_allocation("speed",0.0)
	if not check(float(b.demo_preview_spec().damage)<10,"Slower allocation does not reduce damage"):return
	b.open_projectile_workspace()
	b.playing=false
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/neutral_spell_damage.png")
	print("NEUTRAL SPELL DAMAGE PASSED: 10 mana/10 stamina/10 damage on actual unblocked hit, neutral RHS factors, unchanged size/speed, responsive timing and speed")
	quit()
