extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PREVIEW MANA FAILED: "+message)
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
	b.draft_path="user://logs/mana_test_draft.cfg"
	b.preview_preferences_path="user://logs/mana_test_preview.cfg"
	b.open_projectile_workspace()
	b.set_process(false)
	b.preview_repeating=false
	b.preview_effect="None"
	b.select_demo_choice("cross",false)
	b.set_demo_duration(1.0)
	b.set_release_fraction(0.55)
	editor.actor.mana=50.0
	editor.actor.stamina=50.0
	editor.actor.guard_energy=20.0
	editor.actor.mana_delay=0.0
	editor.actor.stamina_delay=0.0
	editor.actor.guard_recovery=0.0
	editor.actor.mode="idle"
	editor.actor.story_block_held=false
	var round_active:bool=editor.field.round_active
	editor.field.round_active=true
	editor.actor.recover_resources(0.1)
	if not check(is_equal_approx(float(editor.actor.mana),51.7) and is_equal_approx(float(editor.actor.stamina),51.7) and is_equal_approx(float(editor.actor.guard_energy),21.7),"Combat resources recover at different rates"):return
	b.playing=false
	b.process_demo_preview(0.1)
	if not check(is_equal_approx(float(editor.actor.mana),53.4) and is_equal_approx(float(editor.actor.stamina),53.4) and is_equal_approx(float(editor.actor.guard_energy),23.4),"Create resources recover at different rates"):return
	editor.field.round_active=round_active
	editor.actor.mana=100.0
	editor.actor.mana_delay=0.0
	editor.actor.stamina=100.0
	if not check(is_equal_approx(float(b.demo_projectile_stats().mana),10.0),"One-second neutral spell must cost 10"):return
	for choice in ["cross","hook","knee"]:
		b.casting_animation["demo_choice"]=choice
		b.casting_animation["effort"]=73.0
		if not check(is_equal_approx(float(b.demo_physical_stats().stamina),10.0),"One-second cast inherited source effort: "+choice):return
	b.casting_animation["demo_choice"]="cross"
	b.demo_duration=0.5
	if not check(is_equal_approx(float(b.demo_physical_stats().stamina),20.0) and is_equal_approx(float(b.demo_physical_stats().damage),5.0),"Half-second cost/damage is wrong"):return
	b.demo_duration=2.0
	if not check(is_equal_approx(float(b.demo_physical_stats().stamina),20.0) and is_equal_approx(float(b.demo_physical_stats().damage),20.0),"Two-second cost/damage is wrong"):return
	for row in [[0.1,100.0,1.0],[0.25,40.0,2.5],[1.0,10.0,10.0],[4.0,40.0,40.0],[10.0,100.0,100.0],[20.0,200.0,200.0],[60.0,600.0,600.0]]:
		b.demo_duration=row[0]
		var physical:Dictionary=b.demo_physical_stats()
		if not check(is_equal_approx(float(physical.stamina),row[1]) and is_equal_approx(float(physical.damage),row[2]),"Duration curve mismatch at "+str(row[0])):return
	b.set_demo_duration(20.0)
	b.play_demo_preview()
	if not check(not b.playing and b.demo_stamina_note.text.contains("200.0"),"Unaffordable cast was capped or allowed"):return
	b.set_demo_duration(1.0)
	editor.actor.stamina=9.0
	b.play_demo_preview()
	if not check(not b.playing,"Insufficient stamina still starts cast"):return
	editor.actor.stamina=100.0
	b.set_projectile_allocation("speed",1.0)
	b.set_release_fraction(0.55)
	if not check(is_equal_approx(float(b.demo_projectile_stats().base_velocity),15.7),"Full speed must equal the former 30 percent speed"):return
	if not check(is_equal_approx(float(b.release_timing_stats().multiplier),1.25) and is_equal_approx(float(b.demo_projectile_stats().physical_damage),10.0*15.7/14.0*1.25),"Speed/amp stacked incorrectly"):return
	if not check(b.demo_damage_breakdown.text.contains("10.0 base") and b.demo_damage_breakdown.text.contains("1.12 speed") and b.demo_damage_breakdown.text.contains("1.25 amp"),"Right panel lacks calculation breakdown"):return
	b.demo_duration=1.0
	var tag=editor.actor.get_node("OverheadHealthTag")
	tag.update_tag()
	tag._advance_resource_bars(1.0)
	b.play_demo_preview()
	b.process_demo_preview(0.5)
	if not check(is_equal_approx(float(editor.actor.mana),100.0) and is_equal_approx(float(editor.actor.stamina),100.0),"Resources spent before launch"):return
	b.process_demo_preview(0.06)
	if not check(is_equal_approx(float(editor.actor.mana),90.0) and is_equal_approx(float(editor.actor.stamina),90.0) and is_equal_approx(float(editor.actor.mana_delay),float(editor.actor.stamina_delay)),"Release did not spend matching costs in sync"):return
	b.process_demo_preview(0.44)
	if not check(is_equal_approx(float(editor.actor.mana),90.0),"Mana charged more than once"):return
	if not check(is_equal_approx(float(editor.actor.stamina),100.0-float(b.demo_physical_stats().stamina)),"Stamina deduction differs from displayed cost"):return
	for frame in 90:
		b.process_demo_preview(1.0/60.0)
		if not check(is_equal_approx(float(editor.actor.mana),float(editor.actor.stamina)),"Resource recovery diverged"):return
		tag.update_tag()
		tag._advance_resource_bars(1.0/60.0)
		if not check(absf(float(tag.resource_fills.magica.displayed)-float(tag.resource_fills.stamina.displayed))<0.0001,"Displayed bars diverged during synchronized recovery"):return
	if not check(editor.actor.mana>90.0,"Mana did not recover"):return
	# Story/normal combat uses the same transaction and common recovery gate.
	editor.actor.mana=100.0;editor.actor.stamina=100.0
	if not check(editor.actor.spend_cast_resources(10.0,10.0),"Shared cast payment failed"):return
	editor.actor.mode="cast"
	for frame in 60:
		editor.actor.recover_resources(1.0/60.0)
		if not check(is_equal_approx(float(editor.actor.mana),90.0) and is_equal_approx(float(editor.actor.stamina),90.0),"One resource recovered during combat cast"):return
	editor.actor.mode="idle"
	for frame in 30:
		editor.actor.recover_resources(1.0/60.0)
		if not check(is_equal_approx(float(editor.actor.mana),float(editor.actor.stamina)),"Shared combat recovery diverged"):return
	b.clear_shots()
	editor.actor.mana=9.0
	var spent:float=editor.actor.mana_spent
	b.launch_projectile()
	if not check(is_equal_approx(float(editor.actor.mana),9.0) and is_equal_approx(float(editor.actor.mana_spent),spent),"Insufficient mana still charged"):return
	b.set_demo_duration(10.0)
	editor.actor.mana=0.0
	b.launch_projectile()
	if not check(is_zero_approx(float(editor.actor.mana)),"Free long cast changed mana"):return
	b.set_demo_duration(1.0)
	b.clear_shots()
	b.reset_practice_scene()
	b.set_process(true)
	print("RESOURCE SYNC PASSED: 10/10 paid together at release, identical delays, per-frame equal recovery and HUD easing, common combat transaction/recovery gates")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
