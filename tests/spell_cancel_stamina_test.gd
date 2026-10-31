extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("CAST CANCELLATION FAILED: "+message)
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
	b.draft_path="user://logs/cancel_stamina_draft.cfg"
	b.preview_preferences_path="user://logs/cancel_stamina_preview.cfg"
	b.open_projectile_workspace()
	b.set_process(false);b.set_physics_process(false)
	editor.field.set_physics_process(false)
	b.select_demo_choice("cross",false)
	b.set_demo_duration(1.0);b.set_release_fraction(0.55)
	b.interrupt_preview_cast();b.playing=false;b.preview_repeating=false;b.clear_shots()
	var actor=editor.actor
	b.set_character_god_mode(actor,false)
	actor.stamina=100;actor.mana=100
	press_one(b)
	b.process_demo_preview(0.25)
	if not check(actor.stamina==100 and actor.mana==100,"Unreleased cast changed the normal release-payment timing"):return
	press_one(b)
	if not check(is_equal_approx(actor.stamina,97.5) and actor.mana==100 and editor.field.shots.is_empty() and b.playing and b.elapsed==0,"Pressing 1 did not retain the canceled quarter-cast cost"):return
	b.process_demo_preview(0.1)
	press_one(b)
	if not check(is_equal_approx(actor.stamina,96.5),"Repeated restarts erased or duplicated prior costs"):return
	b.process_demo_preview(0.55)
	if not check(is_equal_approx(actor.stamina,86.5) and actor.mana==90 and editor.field.shots.size()==1,"Completed release did not pay its ordinary full cost once"):return
	press_one(b)
	if not check(is_equal_approx(actor.stamina,86.5) and actor.mana==90,"Restarting after a paid release charged stamina twice"):return
	b.process_demo_preview(0.2)
	b.set_demo_duration(2.0)
	if not check(is_equal_approx(actor.stamina,84.5),"Changing duration recalculated an interrupted cast using the new duration/cost"):return
	b.process_demo_preview(0.5)
	b.stop_preview_controls()
	if not check(is_equal_approx(actor.stamina,79.5),"Half a second of a two-second, 20-stamina cast did not cost 5"):return
	b.stop_preview_controls()
	if not check(is_equal_approx(actor.stamina,79.5),"Canceling the same attempt twice charged twice"):return
	b.set_demo_duration(1.0)
	b.interrupt_preview_cast();b.playing=false
	actor.stamina=100;actor.mana=100
	# A gameplay-owned actor uses the same accounting when hit out of its cast.
	actor.practice_projectile_spec=b.demo_preview_spec()
	actor.practice_spell_animation=b.casting_animation.duplicate(true)
	actor.practice_release_fraction=0.55
	actor.start_cast(false)
	actor.tick_cast(0.25)
	actor.mode="hit"
	editor.field.combat().step_actors(0.0)
	if not check(is_equal_approx(actor.stamina,97.5) and actor.mana==100,"Gameplay mode exit did not use shared cancellation accounting"):return
	actor.practice_spell_animation={};actor.practice_projectile_spec={}
	b.set_character_god_mode(actor,true)
	press_one(b);b.process_demo_preview(0.25);press_one(b)
	if not check(actor.stamina==100 and actor.mana==100,"Cancellation bypassed God Mode"):return
	b.set_character_god_mode(actor,false)
	b.interrupt_preview_cast();b.playing=false
	actor.stamina=100
	press_one(b);b.process_demo_preview(0.25)
	actor.stamina=1.0
	b.interrupt_preview_cast()
	if not check(actor.stamina==0.0,"Cancellation overdraws the remaining stamina"):return
	b.reset_practice_scene()
	press_one(b)
	if not check(actor.stamina==100,"Reset left a stale cancellation debt"):return
	print("CAST CANCELLATION PASSED: actual 1 restarts, proportional sunk stamina, cumulative spam costs, no mana before release, full release paid once, immutable duration/cost snapshot, idempotent cancel, native hit interruption, God Mode, exhaustion and clean reset")
	quit()
