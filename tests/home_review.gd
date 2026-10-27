extends SceneTree
func _initialize() -> void:call_deferred("run")
func frames(count: int) -> void:
	for i in count:await process_frame
func quiet_home() -> void:
	current_scene.set_process_unhandled_key_input(false)
	for button in current_scene.navigation_buttons.values():
		button.release_focus()
		button.focus_mode=Control.FOCUS_NONE
func run() -> void:
	var home=load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	current_scene=home
	quiet_home()
	await frames(45)
	home.show_page("Create")
	quiet_home()
	await frames(45)
	home.open_scene("res://scenes/combat_sandbox.tscn")
	await frames(3)
	current_scene.camera_input_enabled=false
	current_scene.set_process_unhandled_key_input(false)
	await frames(45)
	current_scene.return_home()
	await frames(3)
	current_scene.open_scene("res://scenes/spell_editor.tscn")
	await frames(3)
	current_scene.camera_input_enabled=false
	current_scene.set_process_unhandled_key_input(false)
	await frames(45)
	current_scene.return_home()
	await frames(3)
	current_scene.open_scene("res://scenes/main.tscn")
	await frames(3)
	current_scene.set_process_unhandled_key_input(false)
	await frames(45)
	current_scene.write_report()
	current_scene.audio.stop_all()
	change_scene_to_file("res://scenes/home.tscn")
	await frames(3)
	current_scene.show_page("Story")
	quiet_home()
	await frames(45)
	quit()
