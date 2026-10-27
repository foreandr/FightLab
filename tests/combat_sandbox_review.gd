extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:await physics_frame
func run() -> void:
	var sandbox=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(sandbox)
	sandbox.set_process_unhandled_key_input(false)
	await frames(30)
	sandbox.run_setup()
	await frames(120)
	sandbox.block_menu.select(1)
	sandbox.settings_changed()
	sandbox.run_setup()
	await frames(120)
	sandbox.block_menu.select(0)
	sandbox.jump_toggle.set_pressed_no_signal(true)
	sandbox.settings_changed()
	sandbox.run_setup()
	await frames(120)
	sandbox.jump_toggle.set_pressed_no_signal(false)
	sandbox.charge_toggle.set_pressed_no_signal(true)
	sandbox.distance_input.value=6
	sandbox.settings_changed()
	sandbox.run_setup()
	await frames(180)
	sandbox.reset_setup()
	await frames(30)
	paused=false
	sandbox.field.write_report()
	sandbox.field.finish_run()
