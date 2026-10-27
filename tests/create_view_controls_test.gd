extends SceneTree
var lab: Node3D
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:await physics_frame
func view() -> Dictionary:
	return {"transform":lab.field.camera.global_transform,"fov":lab.field.camera.fov,"h":lab.field.camera.h_offset,"v":lab.field.camera.v_offset}
func same_view(before: Dictionary) -> bool:
	return lab.field.camera.global_transform.is_equal_approx(before.transform) and is_equal_approx(lab.field.camera.fov,before.fov) and is_equal_approx(lab.field.camera.h_offset,before.h) and is_equal_approx(lab.field.camera.v_offset,before.v)
func hold_view(before: Dictionary,count: int,message: String) -> void:
	var stayed:=true
	for i in count:
		await physics_frame
		stayed=stayed and same_view(before)
	check(stayed,message)
func run() -> void:
	lab=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(lab)
	lab.camera_input_enabled=false
	check(lab.inspection_camera.manual and lab.camera_initialized,"Create must start with a placed camera, not an automatic follower")
	for node in lab.find_children("*","CheckBox",true,false):
		check(node.text not in ["Repeat setup","Weaken guard","Partner jumps"],"Removed standalone controls must not remain in Create")
	check(lab.block_menu.get_item_count()==6 and lab.block_menu.get_item_text(3).contains("Jump"),"Partner jump must be a behavior-menu choice")
	# Reproduce distance -> Sprint before the first manual camera input.
	var initial:=view()
	lab.distance_input.value=12
	lab.select_category("Sprint")
	lab.library_buttons.Sprint.mouse_entered.emit()
	await hold_view(initial,240,"Distance changes and repeated Sprint previews must not zoom, follow or shake the untouched camera")
	check(lab.live_preview_loops>0 and lab.actor.actions.get("editor_sprint",0)>0,"Camera regression must actually exercise repeated physical sprints")
	# Reproduce zooming out, then editing spacing and choosing Sprint again.
	lab.camera_input_enabled=true
	var wheel:=InputEventMouseButton.new()
	wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed=true
	wheel.position=Vector2(800,300)
	for i in 4:lab._unhandled_input(wheel)
	lab._process(0)
	lab.camera_input_enabled=false
	var zoomed:=view()
	check(not zoomed.transform.is_equal_approx(initial.transform),"Wheel zoom must still move the camera intentionally")
	lab.distance_input.value=8
	lab.library_buttons.Sprint.mouse_entered.emit()
	await hold_view(zoomed,150,"Zoomed-out view must survive distance edits, Sprint selection and preview resets exactly")
	# Pan/orbit remains available and subsequent partner edits cannot move the view.
	lab.inspection_camera.move(Vector3(1,0,1),0.5)
	lab.inspection_camera.orbit(Vector2(15,5))
	lab.inspection_camera.apply(lab.field.camera)
	var placed:=view()
	lab.block_menu.select(3)
	lab.block_menu.item_selected.emit(3)
	await frames(60)
	check(lab.partner_jumps() and lab.partner_shield_style().is_empty() and lab.target.position.y>0.8,"Jump menu choice must make the real passive partner jump without a shield")
	check(same_view(placed),"Jumping partner must not move the placed camera")
	lab.block_menu.select(4)
	lab.block_menu.item_selected.emit(4)
	await frames(60)
	check(lab.target.position.y>0.8 and lab.target.mode=="shield" and lab.target.guard_style=="palm","Jump + palm choice must combine both real behaviors")
	lab.block_menu.select(5)
	lab.block_menu.item_selected.emit(5)
	await frames(60)
	check(lab.target.mode=="shield" and lab.target.guard_style=="brace","Jump + brace choice must select the proper shield")
	lab.block_menu.select(0)
	lab.block_menu.item_selected.emit(0)
	lab.set_chain(["Dash","Knee"])
	lab.run_setup()
	await hold_view(placed,100,"Run chain must preserve camera position, orientation, zoom and lens offsets")
	lab.reset_setup()
	check(same_view(placed),"Reset must preserve the exact view")
	lab.browse_animations()
	lab.select_group("Attack")
	await hold_view(placed,70,"Browse, tab changes and new hover actions must not reframe the camera")
	lab.toggle_slow()
	await hold_view(placed,40,"Slow motion must not introduce camera drift")
	lab.toggle_slow()
	paused=false
	lab.queue_free()
	await frames(3)
	lab=load("res://scenes/spell_editor.tscn").instantiate()
	root.add_child(lab)
	lab.camera_input_enabled=false
	var spell_view:=view()
	lab.distance_input.value=8
	lab.jump_toggle.button_pressed=true
	lab.block_menu.select(3)
	lab.block_menu.item_selected.emit(3)
	lab.run_setup()
	await hold_view(spell_view,120,"Spell Create distance/jump/cast changes must also preserve the camera")
	check(lab.actor.air_casts>0 and lab.partner_jumps(),"Spell camera check must exercise real jumping casts and partner jump selection")
	paused=false
	lab.queue_free()
	await frames(3)
	if failures.is_empty():print("PASS: removed controls, partner behavior menu and exact camera stability across distance/Sprint, zoom, loops, run/reset, tabs, jumping and slow motion")
	quit(0 if failures.is_empty() else 1)
