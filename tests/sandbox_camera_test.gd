extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func key(code: Key) -> InputEventKey:
	var event:=InputEventKey.new()
	event.keycode=code
	event.pressed=true
	return event
func run() -> void:
	var sandbox=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(sandbox)
	sandbox.run_setup()
	sandbox.reset_setup()
	sandbox.camera_input_enabled=false
	for i in 5:await physics_frame
	check(paused,"Camera inspection must start with the sandbox ready and paused")
	sandbox.reframe_camera()
	sandbox.take_camera_control()
	var rig=sandbox.inspection_camera
	var original_focus: Vector3=rig.focus
	var original_distance: float=rig.distance
	rig.move(Vector3(1,0,1),0.5)
	rig.apply(sandbox.field.camera)
	check(rig.focus.distance_to(original_focus)>1,"Camera movement must translate the inspection pivot while combat is paused")
	check(is_equal_approx(original_distance,rig.distance),"WASD movement must preserve orbit distance")
	rig.zoom(2)
	check(rig.distance<original_distance,"Wheel up must zoom in")
	rig.zoom(-1000)
	check(rig.distance<=65,"Zoom out must remain bounded")
	rig.zoom(1000)
	check(rig.distance>=1.2,"Zoom in must remain bounded")
	rig.orbit(Vector2(40,10000))
	check(rig.pitch<=1.4,"Orbit must clamp at the top rather than flip")
	rig.orbit(Vector2(-80,-20000))
	check(rig.pitch>=0.05,"Orbit must stay above the floor")
	rig.distance=7
	rig.apply(sandbox.field.camera)
	var position_before: Vector3=sandbox.field.camera.position
	var basis_before: Basis=sandbox.field.camera.basis
	sandbox.run_setup()
	sandbox.update_camera(1)
	check(sandbox.field.camera.position.is_equal_approx(position_before) and sandbox.field.camera.basis.is_equal_approx(basis_before),"Run must preserve a manually chosen camera")
	sandbox.reset_setup()
	sandbox.update_camera(1)
	check(sandbox.field.camera.position.is_equal_approx(position_before),"Reset must preserve the inspection view")
	sandbox._unhandled_key_input(key(KEY_S))
	check(Engine.time_scale==1,"S must no longer toggle slow motion")
	sandbox._unhandled_key_input(key(KEY_T))
	check(Engine.time_scale<1,"T must toggle slow motion")
	sandbox._unhandled_key_input(key(KEY_T))
	sandbox._unhandled_key_input(key(KEY_F))
	check(not rig.manual,"F must restore automatic fighter framing")
	sandbox.distance_input.get_line_edit().grab_focus()
	check(sandbox.camera_text_editing(),"Editing the distance must suppress camera movement")
	sandbox.camera_input_enabled=true
	var middle:=InputEventMouseButton.new()
	middle.button_index=MOUSE_BUTTON_MIDDLE
	middle.position=Vector2(500,400)
	middle.pressed=true
	sandbox._unhandled_input(middle)
	check(not sandbox.camera_text_editing(),"Clicking the arena must release the distance editor for camera control")
	check(sandbox.camera_dragging and rig.manual,"Middle mouse must engage rotation")
	var yaw_before: float=rig.yaw
	var motion:=InputEventMouseMotion.new()
	motion.relative=Vector2(50,10)
	sandbox._input(motion)
	check(not is_equal_approx(yaw_before,rig.yaw),"Dragging middle mouse must rotate the camera")
	middle.pressed=false
	sandbox._input(middle)
	check(not sandbox.camera_dragging and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Releasing middle mouse must restore the cursor even over the UI")
	paused=false
	sandbox.queue_free()
	for i in 3:await physics_frame
	if failures.is_empty():print("PASS: sandbox inspection camera movement, orbit, zoom limits, paused operation, persistent view, reframe, text focus and shortcut separation")
	quit(0 if failures.is_empty() else 1)
