extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("SCENE RESET FAILED: "+message)
	quit(1)
	return false
func settings(b:Node) -> Dictionary:
	return {"animation":b.casting_animation.duplicate(true),"duration":b.demo_duration,"release":b.release_fraction,"allocation":b.projectile_allocations.duplicate(true),"effect":b.preview_effect,"saved_effect":b.element,"step":b.creation_step}
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	var draft:String=b.draft_path
	var prefs:String=b.preview_preferences_path
	b.draft_path="user://logs/scene_reset_test.cfg"
	b.preview_preferences_path="user://logs/scene_reset_preview.cfg"
	b.open_projectile_workspace()
	b.preview_projectile_effect("Fire")
	b.set_demo_duration(0.5)
	b.set_release_fraction(0.3)
	b.set_projectile_allocation("effect",0.75)
	b.set_dummy_god_mode(false)
	var preserved:=settings(b)
	var dummy=editor.target
	dummy.invulnerability=0.0
	dummy.receive_magic(10000.0,editor.actor.global_basis.z,editor.actor,dummy.bone_point("spine_03"))
	if not check(dummy.health<=0.0,"Test did not kill mannequin"):return
	editor.actor.position+=Vector3(5,0,0)
	editor.actor.health=30.0
	editor.actor.mana=4.0
	editor.actor.stamina=2.0
	editor.actor.burn_time=9.0
	var spec:Dictionary=b.demo_preview_spec()
	editor.field.spawn_projectile(editor.actor,spec,Vector3(8,1,8))
	var shot:Dictionary=editor.field.shots.back()
	editor.field.spell_environment.projectile_step(shot,Vector3(8,1,8),Vector3(8,0.02,8),true)
	editor.field.spell_environment.add_water(1.0,Vector3(6,0,6))
	b.dummy_total_damage=123.0
	b.dummy_last_damage=45.0
	b.set_preview_repeat(true)
	b.set_preview_slow(true)
	b.reset_scene_button.pressed.emit()
	await RenderingServer.frame_post_draw
	if not check(is_equal_approx(float(editor.actor.health),float(editor.actor.MAX_HEALTH)) and is_equal_approx(float(editor.actor.mana),float(editor.actor.MAX_MANA)) and is_equal_approx(float(editor.actor.stamina),float(editor.actor.MAX_STAMINA)),"Caster resources were not restored"):return
	if not check(dummy.health>0.0 and not dummy.practice_god_mode and not b.dummy_god_mode,"Mannequin was not revived or God mode changed"):return
	if not check(Vector2(editor.actor.position.x,editor.actor.position.z).length()<0.01 and dummy.position.distance_to(dummy.practice_home)<0.1,"Positions were not restored"):return
	if not check(editor.field.shots.is_empty() and editor.field.spell_environment.patches.is_empty() and editor.field.spell_environment.water.is_empty() and editor.actor.burn_time<=0.0,"Projectiles or lingering effects survived reset"):return
	if not check(not b.playing and not b.preview_repeating and not b.preview_slow and is_equal_approx(Engine.time_scale,1.0) and is_zero_approx(float(b.dummy_total_damage)),"Playback, slow motion or damage counters survived reset"):return
	if not check(settings(b)==preserved,"Reset changed spell settings"):return
	for fighter in editor.field.fighters:
		if not fighter.visible and not check(fighter.collision_layer==0,"Hidden fighter regained collisions"):return
	b.draft_path=draft
	b.preview_preferences_path=prefs
	b.load_draft()
	b.load_demo_preferences()
	b.reset_practice_scene()
	print("SCENE RESET PASSED: bottom button, revive/heal/resources, positions, projectiles/environment/status cleared, playback stopped, spell/God settings preserved")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
