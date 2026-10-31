extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("HUMAN TARGET FAILED: "+message)
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
	b.open_projectile_workspace()
	b.playing=false
	b.clear_shots()
	var human=b.practice_human
	var dummy=editor.target
	if not check(is_instance_valid(human) and human.visible and human.model.visible and not human.practice_wooden_dummy,"Human model is absent"):return
	var offset:Vector3=human.position-dummy.position
	if not check(is_equal_approx(offset.length(),3.0) and offset.normalized().dot(dummy.global_basis.x)>0.99,"Human is not three metres beside dummy"):return
	for fighter in [editor.actor,dummy,human]:
		var screen:Vector2=editor.field.camera.unproject_position(fighter.position+Vector3.UP)
		if not check(screen.x>b.get_global_rect().end.x and screen.x<b.demo_timing_panel.get_global_rect().position.x,"A character is covered by the panels"):return
	var wait_until:=Time.get_ticks_msec()+400
	while Time.get_ticks_msec()<wait_until:await process_frame
	var idle_clip:String=preload("res://scripts/default_idle.gd").resolve(human,human.player,"Idle cannon")
	if not check(human.clip==idle_clip and human.player.current_animation==idle_clip,"Human target is guarding instead of using Idle cannon"):return
	human.invulnerability=0.0
	human.receive_magic(10000.0,editor.actor.global_basis.z,editor.actor,human.bone_point("spine_03"))
	if not check(human.health<=0.0 and editor.field.round_active and dummy.health>0.0,"Human cannot die independently during practice"):return
	b.reset_scene_button.pressed.emit()
	await RenderingServer.frame_post_draw
	if not check(human.health>0.0 and human.position.distance_to(human.practice_home)<0.1,"Reset scene did not restore human"):return
	wait_until=Time.get_ticks_msec()+200
	while Time.get_ticks_msec()<wait_until:await process_frame
	if not check(human.player.current_animation==idle_clip,"Reset reverted human to guard"):return
	editor.select_group("Motion")
	if not check(not human.practice_damageable_dummy,"Human practice flags leaked outside Spells"):return
	editor.select_group("Spells")
	b.open_projectile_workspace()
	b.reset_practice_scene()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/human_beside_dummy.png")
	print("HUMAN TARGET PASSED: visible human three metres right of wooden dummy, all three fit view, mortal damage, reset restores both, workspace isolation")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
