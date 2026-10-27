extends SceneTree
func _initialize() -> void:call_deferred("run")
func frames(count: int) -> void:
	for i in count:await process_frame
func run() -> void:
	var lab=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(lab)
	lab.camera_input_enabled=false
	lab.set_process_unhandled_key_input(false)
	await frames(60)
	lab.inspection_camera.zoom(-2)
	lab.inspection_camera.apply(lab.field.camera)
	lab.distance_input.value=8
	lab.select_category("Sprint")
	await frames(120)
	lab.distance_input.value=4.4
	for pair in [["Motion","Dodges","Dodge Left"],["Motion","Acrobatics","Flip"],["Attack","Kick","Kick"],["Attack","Spell Throwing","Spell Throw"]]:
		lab.select_group(pair[0])
		lab.select_category(pair[1])
		lab.library_buttons[pair[2]].mouse_entered.emit()
		await frames(60)
	lab.set_chain(["Dash","Knee"])
	lab.run_setup()
	await frames(90)
	lab.field.write_report()
	lab.browse_animations()
	await frames(30)
	paused=false
	lab.field.finish_run()
