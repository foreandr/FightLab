extends SceneTree
func _initialize() -> void:call_deferred("run")
func press_one(builder:Node) -> void:
	var key:=InputEventKey.new()
	key.keycode=KEY_1;key.physical_keycode=KEY_1;key.pressed=true
	builder._input(key)
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
	var editor=current_scene
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/followthrough_draft.cfg"
	b.preview_preferences_path="user://logs/followthrough_prefs.cfg"
	b.open_projectile_workspace();b.preview_projectile_effect("Fire")
	b.set_process(false);b.set_physics_process(false);editor.field.set_physics_process(false)
	b.stop_preview_controls(true);b.clear_shots()
	b.hide();b.select_demo_choice("cross",false);b.set_demo_duration(4.0);b.set_release_fraction(0.3);b.show()
	b.show_creation_step("projectile")
	var actor=editor.actor
	b.set_character_god_mode(actor,false)
	actor.mana=100;actor.stamina=100
	var spec:Dictionary=b.demo_preview_spec()
	var animation:Dictionary=b.casting_animation.duplicate(true)
	press_one(b);b.process_demo_preview(0.6);press_one(b)
	assert(is_equal_approx(actor.stamina,100.0-float(spec.stamina_cost)*0.5) and actor.mana==100)
	b.process_demo_preview(1.21)
	assert(b.cast_committed() and editor.field.shots.size()==1)
	var paid_mana:float=actor.mana
	var paid_stamina:float=actor.stamina
	for i in 4:press_one(b)
	assert(is_equal_approx(b.elapsed,1.21) and editor.field.shots.size()==1)
	assert(actor.mana==paid_mana and actor.stamina==paid_stamina)
	# Draft edits remain live, but cannot shorten or replace the committed pose.
	b.set_demo_duration(0.1);b.set_release_fraction(0.55)
	assert(is_equal_approx(b.playback_duration(),4.0) and b.playback_animation()==animation)
	b.stop_preview_controls()
	assert(b.playing and b.cast_committed())
	b.process_demo_preview(2.8)
	assert(not b.playing and not b.cast_committed())
	actor.mana=100;actor.stamina=100
	press_one(b)
	assert(b.playing and b.elapsed==0 and is_equal_approx(b.playback_duration(),0.1))
	b.stop_preview_controls(true);b.hide()
	# A normal gameplay actor uses the same commitment gate, not a Create-only flag.
	actor.practice_spell_animation=animation
	actor.practice_projectile_spec=spec
	actor.practice_release_fraction=0.3
	actor.mana=100;actor.stamina=100;actor.mode="idle"
	actor.start_cast(false)
	assert(actor.tick_cast(1.21))
	assert(editor.field.combat().release(actor,actor.current_spell,actor.bone_point("hand_r")))
	assert(editor.field.combat().cast_committed(actor))
	actor.start_cast(false);actor.start_jump("jump_cast")
	assert(actor.mode=="cast" and is_equal_approx(actor.cast_time,1.21))
	assert(not actor.start_motion_dash(0))
	actor.tick_cast(2.8)
	assert(not editor.field.combat().cast_committed(actor))
	# Reset remains an explicit development escape; damage/death can still interrupt.
	actor.mode="cast"
	editor.field.combat().begin_cast_attempt(actor,spec,1.2)
	assert(editor.field.combat().release(actor,spec,actor.bone_point("hand_r")))
	actor.mode="hit"
	assert(not editor.field.combat().cast_committed(actor))
	actor.reset_fighter(actor.position)
	assert(not editor.field.combat().cast_committed(actor))
	print("CAST FOLLOWTHROUGH PASS: cancellable windup, post-release 1 spam blocked, immutable active duration/profile, no duplicate payments/shots, completion unlock, shared gameplay guard, forced hit and reset")
	quit()
