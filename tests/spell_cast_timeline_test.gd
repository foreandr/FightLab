extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/cast_timeline_draft.cfg"
	b.preview_preferences_path="user://logs/cast_timeline_prefs.cfg"
	b.open_projectile_workspace()
	b.preview_projectile_effect("Fire")
	b.set_process(false);b.set_physics_process(false)
	b.hide() # Test edits must not auto-cast or spend resources.
	b.set_demo_duration(1.0)
	b.set_release_fraction(0.3)
	b.show()
	await process_frame
	var timeline=b.get_meta("cast_timeline")
	assert(timeline.visible and not b.demo_duration_slider.get_parent().visible and not b.release_slider.get_parent().visible)
	timeline.dragging="duration"
	timeline.set_at_position("duration",timeline.time_x(1.5))
	assert(is_equal_approx(b.demo_duration,1.5))
	assert(is_equal_approx(b.release_fraction,0.3))
	assert(is_equal_approx(b.release_timing_stats().seconds,0.45))
	timeline.dragging="release"
	timeline.set_at_position("release",timeline.time_x(1.5*0.5))
	assert(is_equal_approx(b.release_fraction,0.5))
	timeline.set_at_position("release",timeline.time_x(1.5))
	assert(is_equal_approx(b.release_fraction,b.MAX_RELEASE_FRACTION))
	timeline.dragging=""
	var key:=InputEventKey.new()
	key.keycode=KEY_LEFT;key.pressed=true;key.shift_pressed=true
	timeline.handle_input(key,"duration",timeline.duration_handle)
	assert(is_equal_approx(b.demo_duration,1.4))
	timeline.handle_input(key,"release",timeline.release_handle)
	assert(is_equal_approx(b.release_fraction,0.54))
	b.set_limiter_enabled(false)
	b.limiter_warning.hide()
	assert(b.demo_duration_slider.get_parent().visible and b.release_slider.get_parent().visible and b.test_inputs.duration.visible)
	b.set_test_value("duration",0.0)
	timeline.refresh()
	assert(is_finite(timeline.time_x(0.0)))
	b.set_limiter_enabled(true)
	b.hide();b.set_demo_duration(1.0);b.set_release_fraction(0.3);b.show()
	timeline.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/cast_timeline.png")
	print("CAST TIMELINE PASSED: stretch, release marker, apex limit, keyboard editing, linked timing, limiter inputs and zero duration")
	quit()
