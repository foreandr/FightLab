extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
	var editor=current_scene
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/pose_status_draft.cfg"
	b.preview_preferences_path="user://logs/pose_status_prefs.cfg"
	b.open_projectile_workspace();b.preview_projectile_effect("Fire")
	b.stop_preview_controls();b.clear_shots()
	var world=editor.field
	world.spell_environment.reset_environment()
	world.round_active=true
	var actor=editor.actor
	var dummy=editor.target
	assert(actor.editor_pose_locked and not dummy.editor_pose_locked)
	for fighter in [actor,dummy]:
		fighter.practice_god_mode=true
		fighter.receive_status(b.practice_human,{"projectile_element":"Fire","potency":1.0})
	actor.freeze_time=0.2;actor.stun_time=0.2;actor.chill_time=0.2
	var caster_before:float=actor.damage_taken
	var dummy_before:float=dummy.damage_taken
	var start:float=world.elapsed
	Engine.time_scale=4.0
	await create_timer(5.7).timeout
	Engine.time_scale=1.0
	assert(world.elapsed-start>=5.0)
	assert(actor.burn_time==0.0 and dummy.burn_time==0.0,"Pose-locked burn did not expire")
	assert(is_equal_approx(actor.damage_taken-caster_before,10.0) and is_equal_approx(dummy.damage_taken-dummy_before,10.0),"Status clock was skipped or double-stepped")
	assert(actor.stun_time==0 and actor.freeze_time==0 and actor.chill_time==0)
	assert(not is_instance_valid(actor.burn_visual) and not is_instance_valid(dummy.burn_visual),"Expired burn visual remained")
	assert(actor.editor_pose_locked,"Fix disabled editor pose ownership")
	print("POSE-LOCKED STATUS PASSED: real Create caster and dummy expire after 5s, 10 damage each, no double ticks, visuals removed, other statuses expire and pose ownership retained")
	quit()
