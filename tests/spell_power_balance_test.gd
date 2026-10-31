extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("POWER BALANCE FAILED: "+message)
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
	var original_draft:String=b.draft_path
	var original_prefs:String=b.preview_preferences_path
	b.draft_path="user://logs/power_balance_test.cfg"
	b.preview_preferences_path="user://logs/power_balance_preview.cfg"
	b.projectile_allocations={}
	b.open_projectile_workspace()
	b.select_demo_choice("cross")
	b.set_demo_duration(1.0)
	b.set_release_fraction(0.55)
	b.preview_projectile_effect("None")
	if not check(not b.allocation_rows.effect.visible and b.allocation_rows.size.visible and b.allocation_rows.speed.visible,"Neutral projectile should show only size and speed sliders"):return
	for slider in [b.demo_duration_slider,b.release_slider,b.allocation_sliders.size,b.allocation_sliders.speed,b.allocation_sliders.effect]:
		if not check(b.demo_timing_panel.is_ancestor_of(slider) and not b.projectile_screen.is_ancestor_of(slider),"A slider is outside the right panel"):return
	var neutral:Dictionary=b.demo_preview_spec()
	var shares:Dictionary=b.allocation_for("None")
	var old_radius:float=0.1*pow(20.0,float(shares["size"]))*1.25
	if not check(is_equal_approx(float(neutral.projectile_radius),old_radius/3.0),"Projectile is not one third its former size at identical settings"):return
	b.allocation_sliders.size.value=90.0
	var large:Dictionary=b.demo_preview_spec()
	if not check(float(large.projectile_radius)>float(neutral.projectile_radius) and float(large.projectile_velocity)<float(neutral.projectile_velocity) and is_equal_approx(float(large.mana),float(neutral.mana)),"Neutral size/speed do not trade at fixed mana"):return
	b.allocation_sliders.speed.value=100.0
	var fast:Dictionary=b.demo_preview_spec()
	if not check(float(fast.physical_damage)>float(large.physical_damage) and is_equal_approx(float(fast.physical_damage)/float(large.physical_damage),float(fast.projectile_velocity)/float(large.projectile_velocity)),"Speed does not multiply physical damage linearly"):return
	if not check(is_equal_approx(float(fast.physical_damage),float(b.demo_physical_stats().damage)*float(fast.projectile_velocity)/float(b.NEUTRAL_DAMAGE_VELOCITY)),"Physical damage baseline is incorrect"):return
	if not check(b.demo_damage_label.text=="Physical damage: %.1f"%float(fast.physical_damage),"Displayed physical damage differs from actual impact"):return
	b.allocation_sliders.size.value=90.0
	b.preview_projectile_effect("Fire")
	if not check(b.allocation_rows.effect.visible and b.demo_burn_label.visible,"Fire does not show burn slider and DPS"):return
	b.allocation_sliders.effect.value=100.0
	var strong:Dictionary=b.demo_preview_spec()
	if not check(is_equal_approx(float(strong.potency),5.0) and is_equal_approx(float(strong.projectile_radius),0.125/3.0) and is_equal_approx(float(strong.projectile_velocity),1.25),"All burn should yield tiny, slow, strong projectile"):return
	b.allocation_sliders.effect.value=1.0
	b.allocation_sliders.size.value=90.0
	var weak:Dictionary=b.demo_preview_spec()
	if not check(float(weak.projectile_radius)>float(strong.projectile_radius) and float(weak.potency)<float(strong.potency) and float(weak.projectile_velocity)<14.0,"Cannot build large slow projectile with tiny burn"):return
	b.confirm_projectile_effect()
	var allocation:Dictionary=b.allocation_for("Fire").duplicate()
	b.projectile_allocations={}
	b.load_draft()
	if not check(b.allocation_for("Fire")==allocation,"Power balance was not saved"):return
	b.preview_projectile_effect("None")
	if not check(is_equal_approx(float(b.allocation_for("None")["size"]),0.9),"Neutral balance was lost when switching effect"):return
	b.preview_projectile_effect("Fire")
	b.allocation_sliders.effect.value=100.0
	b.playing=false
	b.clear_shots()
	var shot_spec:Dictionary=b.demo_preview_spec()
	var dummy=editor.target
	var origin:Vector3=dummy.bone_point("spine_03")-editor.actor.global_basis.z*1.5
	shot_spec["aim_direction"]=editor.actor.global_basis.z
	editor.field.spawn_projectile(editor.actor,shot_spec,origin)
	var shot:Dictionary=editor.field.shots.back()
	if not check(is_equal_approx(float(shot.spec.damage),float(b.demo_projectile_stats().physical_damage)) and is_equal_approx(editor.field.damage_for(shot.spec),float(shot.spec.physical_damage)),"Actual projectile hit damage differs from speed-scaled physical damage"):return
	if not check(is_equal_approx(float(shot.radius),float(shot_spec.projectile_radius)) and is_equal_approx(shot.velocity.length(),float(shot_spec.projectile_velocity)),"Spawned size/speed differs from balance"):return
	var until:=Time.get_ticks_msec()+3000
	while Time.get_ticks_msec()<until and dummy.burn_time<=0.0:await process_frame
	if not check(dummy.burn_time>0.0 and is_equal_approx(float(dummy.burn_damage)*2.0,float(b.demo_projectile_stats().burn_dps)),"Actual fire hit does not apply shown burn damage"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/power_balance_fire.png")
	b.draft_path=original_draft
	b.preview_preferences_path=original_prefs
	b.load_draft()
	b.load_demo_preferences()
	b.prepare_preview_targets()
	b.open_projectile_workspace()
	print("POWER BALANCE PASSED: two/three sliders, size/speed/burn tradeoffs, fixed cost, independent saved balances, actual projectile and burn")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
