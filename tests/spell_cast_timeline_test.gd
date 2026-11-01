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
	# Many tiny pointer movements must accumulate rather than round to zero.
	var down:=InputEventMouseButton.new()
	down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
	timeline.handle_input(down,"duration",timeline.duration_handle)
	var motion:=InputEventMouseMotion.new()
	motion.relative=Vector2(1,0)
	var drag_start:float=b.demo_duration
	for i in 40:timeline.handle_input(motion,"duration",timeline.duration_handle)
	assert(b.demo_duration>drag_start)
	down.pressed=false
	timeline.handle_input(down,"duration",timeline.duration_handle)
	# Stretch far beyond the original two-second viewport without releasing.
	timeline.dragging="duration"
	for seconds in [5.0,20.0,40.0,60.0]:
		timeline.set_at_position("duration",timeline.time_x(seconds))
		assert(is_equal_approx(b.demo_duration,seconds))
		assert(timeline.duration_handle.position.x+timeline.duration_handle.size.x<=timeline.size.x)
		assert(timeline.release_handle.position.x+timeline.release_handle.size.x<=timeline.size.x)
	timeline.dragging=""
	var zoom_out:Button=timeline.toolbar.get_child(1)
	var zoom_in:Button=timeline.toolbar.get_child(2)
	var original_span:float=timeline.view_span
	zoom_out.pressed.emit()
	assert(timeline.view_span>original_span)
	zoom_in.pressed.emit()
	assert(is_equal_approx(timeline.view_span,original_span))
	b.get_meta("cast_length_input").value=30.0
	assert(is_equal_approx(b.demo_duration,30.0))
	timeline.toolbar.get_child(0).pressed.emit()
	assert(is_equal_approx(timeline.view_span,37.5))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/cast_timeline_long.png")
	b.set_limiter_enabled(false)
	b.limiter_warning.hide()
	assert(b.demo_duration_slider.get_parent().visible and b.release_slider.get_parent().visible and b.test_inputs.duration.visible)
	b.set_test_value("duration",0.0)
	timeline.refresh()
	timeline.fit_time()
	assert(is_finite(timeline.time_x(0.0)))
	b.set_limiter_enabled(true)
	b.hide();b.set_demo_duration(1.0);b.set_release_fraction(0.3);b.show()
	timeline.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/cast_timeline.png")
	print("CAST TIMELINE PASSED: 60s stretch stays visible during drag, fine mouse drag, length input, Fit/zoom buttons, release/apex, keyboard, shared timing and limiter")
	quit()
