extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PROJECTILE DEFAULTS FAILED: "+message)
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
	b.draft_path="user://logs/projectile_entry_test.cfg"
	b.preview_preferences_path="user://logs/projectile_entry_preferences_test.cfg"
	for unrestricted in [false,true]:
		b.open_projectile_workspace()
		b.set_total_power(0.15)
		b.set_demo_duration(4)
		b.set_release_fraction(0.55)
		b.preview_projectile_effect("Fire")
		b.confirm_projectile_effect()
		if not check(b.demo_duration==4 and b.total_power==0.15 and b.element=="Fire","Defaults prevent editing within stage"):return
		if unrestricted:b.set_limiter_enabled(false)
		b.show_creation_step("delivery")
		b.choose_delivery_type("Projectile")
		if not check(b.limiter_enabled and b.total_power==1 and b.demo_duration==1 and b.cast_duration()==1,"Entry did not reset balanced power/duration"):return
		if not check(b.element=="None" and b.preview_effect=="None" and not b.projectile_effect_confirmed,"Entry did not reset to elementless projectile"):return
		var midpoint:float=(b.release_slider.min_value+b.release_slider.max_value)*0.5
		if not check(is_equal_approx(float(b.release_slider.value),midpoint) and is_equal_approx(float(b.release_fraction),0.3),"Timing slider is not centered"):return
		if not check(b.total_power_slider.value==100 and b.demo_duration_slider.value==1 and (not is_instance_valid(b.limiter_warning) or not b.limiter_warning.visible),"Default UI differs from values or leaves old modal open"):return
	print("PROJECTILE DEFAULTS PASSED: every entry resets to 100% power, 1 second, centered timing, neutral effect and Limiter on; edits remain usable within stage")
	quit()
