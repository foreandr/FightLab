extends SceneTree
const Allocation=preload("res://scripts/projectile_allocation.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("TOTAL POWER FAILED: "+message)
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
	b.draft_path="user://logs/total_power_draft_test.cfg"
	b.preview_preferences_path="user://logs/total_power_preferences_test.cfg"
	b.open_projectile_workspace()
	b.set_process(false);b.set_physics_process(false)
	b.preview_effect="Fire";b.element="Fire"
	b.select_demo_choice("cross",false)
	b.set_demo_duration(1.0)
	b.set_character_god_mode(editor.actor,true)
	b.projectile_allocations["Fire"]={"size":1.0/3,"speed":1.0/3,"effect":1.0/3}
	b.set_total_power(1.0)
	var full:Dictionary=b.demo_preview_spec()
	b.total_power_slider.set_value(10.0)
	var weak:Dictionary=b.demo_preview_spec()
	if not check(weak.projectile_radius<full.projectile_radius and weak.projectile_velocity<full.projectile_velocity and weak.potency<full.potency,"Lower power does not make spell small, slow and weak"):return
	var used:float=0
	for value in weak.power_allocation.values():used+=float(value)
	if not check(is_equal_approx(used,0.1),"Unused power was automatically redistributed"):return
	b.set_projectile_allocation("speed",0.07)
	weak=b.demo_preview_spec()
	if not check(is_equal_approx(float(weak.power_allocation.speed),0.07) and is_equal_approx(float(weak.power_allocation.size+weak.power_allocation.effect),0.03),"Channel sliders do not share selected power amount"):return
	b.clear_shots();b.playing=false
	b.launch_projectile()
	var shot:Dictionary=editor.field.shots.back()
	var expected:Dictionary=preload("res://scripts/basic_projectile.gd").resolved_motion(weak)
	if not check(is_equal_approx(float(shot.radius),float(expected.radius)) and is_equal_approx(shot.velocity.length(),float(expected.speed)) and is_equal_approx(float(shot.spec.potency),float(weak.potency)),"Actual spell ignores total power"):return
	var mix:Dictionary=b.allocation_for("Fire").duplicate()
	b.set_total_power(0)
	var minimum:Dictionary=b.projectile_effect_spec("Fire")
	if not check(minimum.potency==0 and minimum.projectile_velocity==1 and is_equal_approx(float(minimum.projectile_radius),0.1),"Zero power does not give minimum projectile and no effect"):return
	if not check(not b.allocation_sliders.speed.editable,"Channel remains editable with zero budget"):return
	b.set_total_power(0.25)
	if not check(b.allocation_for("Fire")==mix,"Power slider destroys chosen mix"):return
	var before_unlimited:Dictionary=b.demo_preview_spec()
	b.set_limiter_enabled(false);b.limiter_warning.hide()
	if not check(not b.total_power_row.visible,"Independent testing retains confusing budget control"):return
	b.set_test_value("speed",1000)
	b.set_limiter_enabled(true)
	if not check(b.total_power_row.visible and b.total_power==0.25 and is_equal_approx(float(b.demo_preview_spec().projectile_velocity),float(before_unlimited.projectile_velocity)),"Limiter restoration loses balanced power/mix"):return
	b.save_draft()
	b.total_power=1
	b.load_draft()
	if not check(b.total_power==0.25,"Power not saved/reloaded"):return
	var cfg:=ConfigFile.new();cfg.load(b.draft_path)
	cfg.erase_section_key("spell","total_power");cfg.save(b.draft_path)
	b.load_draft()
	if not check(b.total_power==1.0,"Older drafts do not default to full power"):return
	b.set_total_power(0.1)
	b.refresh_effect_choices()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_total_power.png")
	for with_effect in [false,true]:
		for fraction in [0.0,0.1,0.5,1.0]:
			var shares:Dictionary=Allocation.spend({},with_effect,fraction)
			var total:float=0
			for value in shares.values():total+=float(value)
			if not check(is_equal_approx(total,fraction),"Power allocation exceeds selected budget"):return
	print("TOTAL POWER PASSED: unused budget preserved, tiny slow weak actual projectile, sharing selected budget, zero minimum, mix preserved, limiter isolation, persistence and old-draft migration")
	quit()
