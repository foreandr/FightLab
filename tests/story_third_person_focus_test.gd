extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("STORY FOCUS FAILED: "+message)
	quit(1)
	return false
func tap_f() -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=KEY_F;event.physical_keycode=KEY_F;event.pressed=pressed
		root.push_input(event,true)
func run() -> void:
	if not check(FileAccess.file_exists("user://story_character.cfg"),"Need saved Story character"):return
	change_scene_to_file("res://scenes/fight.tscn")
	await process_frame
	await process_frame
	var field=current_scene
	if not check(field.scene_file_path=="res://scenes/fight.tscn" and field.story_mode,"Story did not open"):return
	field.set_physics_process(false)
	field.round_active=true
	field.warmup=0.0
	root.grab_focus()
	var player=field.fighters[0]
	var target=field.fighters[1]
	player.position=Vector3(0,0.02,0)
	target.position=Vector3(0,0.02,5)
	field.camera_focus_target=null
	field.selected_fighter=target
	field.camera_zoom=1.7
	field.update_camera(1.0)
	var zoom:float=field.camera_zoom
	tap_f()
	if not check(field.camera_focus_target==target,"Story F did not lock selected target"):return
	field.rotate_camera_orbit(Vector2(40,10))
	field.update_camera(0.5)
	var pointer:=Vector2(15,15)
	root.warp_mouse(pointer)
	var motion:=InputEventMouseMotion.new()
	motion.position=pointer;motion.global_position=pointer
	root.push_input(motion,true)
	await process_frame
	field._select_fighter_from_mouse()
	if not check(field.selected_fighter==null and field.camera_focus_target==target,"Click-away lost Story lock"):return
	field._update_target_marker()
	if not check(field.target_marker.visible,"Locked target lost overhead diamond after deselection"):return
	var pitch:float=field.camera_orbit_pitch
	tap_f()
	if not check(field.camera_focus_target==null and is_equal_approx(float(field.camera_zoom),zoom) and is_equal_approx(float(field.camera_orbit_pitch),pitch),"Story unlock resets zoom or retains target"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/story_third_person_focus.png")
	print("STORY THIRD PERSON PASSED: real Story scene, shared camera, F lock, orbit, click-away retains lock/diamond, F releases without resetting zoom/pitch")
	quit()
