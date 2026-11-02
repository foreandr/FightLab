extends SceneTree
const Appearance=preload("res://scripts/spell_appearance.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("FIRE SHAPE WORKSPACE FAILED: "+message)
	quit(1)
	return false
func press_one(builder:Node) -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_1;event.physical_keycode=KEY_1;event.pressed=true
	builder._input(event)
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/fire_shapes_draft.cfg"
	b.preview_preferences_path="user://logs/fire_shapes_preview.cfg"
	b.open_projectile_workspace();b.stop_preview_controls();b.clear_shots()
	b.set_process(false);b.set_physics_process(false);editor.field.set_physics_process(false)
	editor.actor.practice_god_mode=true
	editor.target.practice_god_mode=true
	b.effect_choices.Fire.pressed.emit()
	if not check(b.fire_shape_screen.visible and not b.effect_selection.visible and b.preview_effect=="Fire" and b.element=="Fire","Fire click does not open its focused shape page"):return
	if not check(not b.playing and editor.field.shots.is_empty(),"Choosing Fire casts before pressing Play"):return
	if not check(preload("res://scripts/fire_style_catalog.gd").entries().size()>=20 and b.spell_playback_panel.visible and b.demo_timing_panel.visible,"Shape options, playback or RHS disappeared"):return
	var stats:Dictionary=b.demo_projectile_stats()
	for shape in Appearance.SHAPES:
		if shape in ["Element style","Drawn"]:continue
		b.stop_preview_controls(true)
		var count:int=editor.field.shots.size()
		b.set_fire_shape(shape)
		if not check(Appearance.settings("Fire",b.appearances.Fire).shape==shape and b.fire_style_gallery.selected_id==preload("res://scripts/fire_style_catalog.gd").active_id(b.appearances.Fire),"Shape selection is not reflected by its controls"):return
		if not check(editor.field.shots.size()==count,"Selecting shape deletes existing projectiles or casts automatically"):return
		press_one(b)
		b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
		if not check(editor.field.shots.size()==count+1,"1 does not cast selected shape: "+shape):return
		var shot:Dictionary=editor.field.shots.back()
		if not check(shot.node.get_meta("look").shape==shape and shot.spec.appearance.shape==shape,"Actual projectile does not use selected visual shape: "+shape):return
		if not check(shot.node.mesh!=null and not shot.node.mesh.get_aabb().size.is_zero_approx(),"Empty projectile mesh: "+shape):return
		var current:Dictionary=b.demo_projectile_stats()
		for key in ["physical_damage","mana","radius","velocity","burn_dps"]:
			if not check(is_equal_approx(current[key],stats[key]),"Shape unexpectedly alters shared mechanics: "+key):return
	b.set_fire_shape("Star")
	b.save_draft()
	b.appearances={}
	b.load_draft();b.refresh_fire_shape()
	if not check(b.appearances.Fire.shape=="Star" and b.demo_preview_spec().appearance.shape=="Star","Chosen shape does not persist in spell metadata"):return
	if not check(not b.demo_damage_breakdown.visible and not b.demo_mana_base_label.visible and not b.demo_amp_breakdown.visible and b.demo_damage_label.tooltip_text.to_lower().contains("base"),"Compact RHS loses calculation details or still shows clutter"):return
	# Fresh cast sizes still come from the universal size/amp resolver.
	var small:=Appearance.visual("Fire",0.1,{"shape":"Cube"})
	var large:=Appearance.visual("Fire",0.2,{"shape":"Cube"})
	if not check(large.mesh.get_aabb().size.is_equal_approx(small.mesh.get_aabb().size*2),"Selected geometry ignores size"):return
	small.free();large.free()
	b.stop_preview_controls()
	b.fire_shapes_open=false;b.refresh_effect_choices()
	if not check(b.effect_selection.visible and not b.fire_shape_screen.visible,"Effects back-navigation fails"):return
	b.preview_projectile_effect("Fire")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/fire_shape_workspace.png")
	b.open_fire_shape_picker()
	await RenderingServer.frame_post_draw
	if not check(b.fire_shape_popup.visible,"Shape picker does not open"):return
	root.get_texture().get_image().save_png("user://logs/fire_shape_picker.png")
	print("FIRE SHAPE WORKSPACE PASSED: Fire navigation, 13 shapes, actual 1-key projectile visuals, no automatic cast/shot deletion, shared costs/size/speed/burn, saved metadata, back navigation and compact RHS with hover details")
	quit()
