extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("SPELL PRACTICE FAILED: "+message)
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
	var prefs:String=b.preview_preferences_path
	var draft:String=b.draft_path
	b.preview_preferences_path="user://logs/practice_preview_test.cfg"
	b.draft_path="user://logs/practice_spell_test.cfg"
	b.open_projectile_workspace()
	b.set_dummy_god_mode(false)
	b.select_demo_choice("cross")
	b.preview_projectile_effect("None")
	b.set_demo_duration(0.5)
	b.set_release_fraction(0.55)
	b.playing=false
	b.clear_shots()
	var dummy=editor.target
	if not check(dummy.visible and dummy.practice_damageable_dummy and dummy.get_node("OverheadHealthTag").visible,"Mannequin is hidden or not damageable"):return
	if not check(dummy.practice_wooden_dummy and not dummy.model.visible and dummy.practice_dummy_visual.enabled and dummy.practice_dummy_visual.hurtboxes.size()==5,"Combat dummy is still showing a human or missing its own hitboxes"):return
	var toward:Vector3=(dummy.position-editor.actor.position).normalized()
	if not check(editor.actor.visible and editor.actor.global_basis.z.dot(toward)>0.999,"Default caster is not present and facing mannequin"):return
	for fighter in [editor.actor,dummy]:
		var screen:Vector2=editor.field.camera.unproject_position(fighter.position+Vector3.UP)
		if not check(screen.x>b.get_global_rect().end.x and screen.x<b.demo_timing_panel.get_global_rect().position.x,"Both default characters do not fit in arena view"):return
	var before:Vector3=editor.actor.position
	var camera_before:Vector3=editor.inspection_camera.focus
	root.grab_focus()
	var move_key:=InputEventKey.new()
	move_key.physical_keycode=KEY_D
	move_key.keycode=KEY_D
	move_key.pressed=true
	Input.parse_input_event(move_key)
	var until:=Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<until:await process_frame
	move_key.pressed=false
	Input.parse_input_event(move_key)
	if not check(editor.actor.position.distance_to(before)>0.3,"WASD did not move caster"):return
	if not check(editor.inspection_camera.focus.distance_to(camera_before)>0.3 and not editor.camera_keyboard_enabled(),"Camera did not follow movement or WASD still pans camera"):return
	editor.actor.position=before
	b.prepare_preview_targets()
	editor.actor.rotation.y=atan2(dummy.position.x-before.x,dummy.position.z-before.z)
	var health:float=dummy.health
	var damage:float=dummy.damage_taken
	b.projectile_preview_button.pressed.emit()
	until=Time.get_ticks_msec()+2400
	while Time.get_ticks_msec()<until and dummy.damage_taken<=damage:await process_frame
	if dummy.damage_taken<=damage:
		print("PRACTICE DIAGNOSTICS ", {"caster":editor.actor.position,"forward":editor.actor.global_basis.z,"dummy":dummy.position,"dummy_health":dummy.health,"dummy_invulnerability":dummy.invulnerability,"dummy_hurt":dummy.collision_layer,"shots":editor.field.shot_serial,"active":editor.field.round_active,"events":editor.field.events.slice(-8)})
		for unit in editor.field.fighters:print("FIGHTER ",unit.team," damage ",unit.damage_taken," at ",unit.position," visible ",unit.visible)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://logs/spell_practice_failure.png")
	if not check(dummy.damage_taken>damage and dummy.health<health,"Playing a projectile did not damage mannequin"):return
	await RenderingServer.frame_post_draw
	if not check(b.dummy_hit_text.visible,"Damage number did not appear"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_practice_hit.png")
	dummy.invulnerability=0.0
	dummy.receive_magic(10000.0,editor.actor.global_basis.z,editor.actor,dummy.bone_point("spine_03"))
	if not check(dummy.health<=0.0,"Mannequin health does not deplete on lethal hit"):return
	until=Time.get_ticks_msec()+2500
	while Time.get_ticks_msec()<until:await process_frame
	if not check(dummy.health<=0.0 and editor.field.round_active,"Mortal mannequin revived automatically or ended practice"):return
	if not check(absf(dummy.practice_dummy_visual.body.rotation.z)>1.0 and not is_instance_valid(dummy.ragdoll),"Defeated dummy did not fall over or spawned human ragdoll"):return
	b.reset_training_dummy()
	if not check(dummy.health>0.0 and not dummy.practice_god_mode,"Manual reset did not restore mortal mannequin"):return
	b.dummy_god_button.set_pressed(true)
	if not check(dummy.practice_god_mode and dummy.practice_immortal,"God mode toggle did not apply"):return
	for hit in 2:
		dummy.invulnerability=0.0
		dummy.receive_magic(10000.0,editor.actor.global_basis.z,editor.actor,dummy.bone_point("spine_03"),"chest","spine_03",Vector3.FORWARD*0.1)
		await RenderingServer.frame_post_draw
		if not check(dummy.health>0.0,"God mode mannequin died from a lethal hit"):return
	if not check(b.dummy_total_damage>=20000.0 and dummy.get_meta("practice_damage_readout","").begins_with("Last spell damage:"),"God mode does not count full damage or display the last damage"):return
	b.dummy_god_button.set_pressed(false)
	b.load_demo_preferences()
	if not check(not b.dummy_god_mode and not b.dummy_god_button.button_pressed,"God mode preference was not saved"):return
	editor.select_group("Motion")
	if not check(not dummy.practice_wooden_dummy and not dummy.practice_dummy_visual.enabled and dummy.model.visible,"Dummy appearance leaked outside spellcrafting"):return
	editor.select_group("Spells")
	if not check(dummy.practice_wooden_dummy and not dummy.model.visible,"Reentering Spells lost wooden dummy"):return
	b.draft_path=draft
	b.preview_preferences_path=prefs
	b.load_draft()
	b.load_demo_preferences()
	b.prepare_preview_targets()
	b.open_projectile_workspace()
	editor.frame_spell_preview(editor.actor)
	print("SPELL PRACTICE PASSED: movement, projectile hit, mortal death persists, manual reset, God mode absorbs repeated lethal hits, full damage totals/readout and saved toggle")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_practice_workspace.png")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
