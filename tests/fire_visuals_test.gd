extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
	var editor=current_scene
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/fire_visuals_draft.cfg"
	b.preview_preferences_path="user://logs/fire_visuals_prefs.cfg"
	b.open_projectile_workspace();b.preview_projectile_effect("Fire")
	b.set_process(false);b.set_physics_process(false)
	b.stop_preview_controls();b.clear_shots()
	var world=editor.field
	editor.set_process(false);editor.set_physics_process(false)
	world.set_physics_process(false)
	world.set_process(false)
	world.spell_environment.set_physics_process(false)
	var human=b.practice_human
	human.practice_god_mode=true
	human.receive_status(editor.actor,{"projectile_element":"Fire","potency":1.0})
	human.update_status(0.0)
	var visual=human.burn_visual
	assert(is_instance_valid(visual) and visual.anchors.size()==6)
	visual._process(0.2)
	var before:Vector3=visual.anchors[0].node.global_position
	human.position+=Vector3(0.5,0,0)
	visual._process(0.1)
	assert(visual.anchors[0].node.global_position.is_equal_approx(before+Vector3(0.5,0,0)))
	for anchor in visual.anchors:
		var expected:Vector3=human.bone_point(anchor.bone)+human.global_basis*anchor.offset+Vector3.UP*float(anchor.height)*0.5
		assert(anchor.node.global_position.is_equal_approx(expected))
	var ground=world.spell_environment.ground_fire(human.global_position+Vector3(-1.4,0,1.0),0.8,{})
	assert(ground.flames.size()>=7 and ground.flames.size()<=16)
	for flame in ground.flames:assert(flame.material_override.shader.resource_path.ends_with("fire_plume.gdshader"))
	ground.fade(0.3)
	assert(is_equal_approx(ground.flames[0].material_override.get_shader_parameter("strength"),0.25) and not ground.embers.emitting)
	ground.fade(8.0)
	var camera:Camera3D=world.camera
	camera.global_position=human.global_position+Vector3(3.5,2.7,5.0)
	camera.look_at(human.global_position+Vector3(-0.9,0.9,0.1))
	for i in 40:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/fire_visuals.png")
	human.burn_time=0.0
	visual._process(0.3)
	assert(visual.is_queued_for_deletion())
	human.burn_time=2.0
	human.update_status(0.0)
	human.reset_fighter(human.position)
	assert(human.burn_visual==null)
	var dummy=editor.target
	dummy.receive_status(editor.actor,{"projectile_element":"Fire","potency":1.0})
	dummy.update_status(0.0)
	for anchor in dummy.burn_visual.anchors:assert(dummy.practice_dummy_visual.markers.has(anchor.bone))
	print("FIRE VISUALS PASSED: ground shader rendered, bounded flame/particle counts, six moving bone anchors, fade, expiry/reset and shared actor integration")
	quit()
