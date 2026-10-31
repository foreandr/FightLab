extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("THIRD PERSON FAILED: "+message)
	quit(1)
	return false
func key(code:int,pressed:=true) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	root.push_input(event,true)
func button(code:int,point:Vector2,pressed:=true) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=code;event.position=point;event.global_position=point;event.pressed=pressed
	root.push_input(event,true)
func move(point:Vector2,relative:=Vector2.ZERO) -> void:
	if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:root.warp_mouse(point)
	var event:=InputEventMouseMotion.new()
	event.position=point;event.global_position=point;event.relative=relative
	root.push_input(event,true)
func run() -> void:
	if not check(load("res://scripts/fight_mode.gd")!=null,"Story does not compile"):return
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace()
	b.playing=false;b.preview_repeating=false
	root.grab_focus()
	var arena:Control=editor.base_ui.get_node("ArenaUnitDrop")
	await process_frame
	await process_frame
	move(arena.get_global_rect().get_center())
	await process_frame
	await process_frame
	b.update_third_person_view(2.0)
	if not check(b.manual_aim and editor.field.camera_focus_target==null and b.third_person_crosshair.visible,"Default view is not free third person with crosshair"):return
	var unit=editor.target
	var point:Vector2=editor.field.camera.unproject_position(unit.focus_position()+Vector3.UP*1.05)
	var before:Transform3D=editor.field.camera.global_transform
	move(point)
	await process_frame
	await process_frame
	if not check(editor.hovered_unit==unit and editor.field.camera_focus_target==null,"Hover locks camera or misses blue target"):return
	button(MOUSE_BUTTON_LEFT,point);button(MOUSE_BUTTON_LEFT,point,false)
	await process_frame
	if not check(editor.focused_unit==unit and editor.field.camera_focus_target==null,"Click changed lock-on instead of only selecting"):return
	if not check(editor.field.camera.global_position.distance_to(before.origin)<0.03,"Hover/click moved the camera"):return
	key(KEY_F);key(KEY_F,false)
	await process_frame
	if not check(editor.field.camera_focus_target==unit and not b.manual_aim,"F did not lock target"):return
	var area:Control=editor.base_ui.get_node("ArenaUnitDrop")
	var middle:Vector2=area.get_global_rect().get_center()
	var zoom:float=editor.field.camera_zoom
	button(MOUSE_BUTTON_WHEEL_UP,middle)
	if not check(editor.field.camera_zoom<zoom,"Wheel zoom does not work while locked"):return
	button(MOUSE_BUTTON_MIDDLE,middle)
	var yaw:float=editor.field.camera_orbit_yaw
	move(middle,Vector2(70,-15))
	button(MOUSE_BUTTON_MIDDLE,middle,false)
	if not check(not is_equal_approx(float(editor.field.camera_orbit_yaw),yaw),"Middle drag does not orbit while locked"):return
	key(KEY_D)
	for frame in 18:await physics_frame
	key(KEY_D,false)
	var toward:Vector3=(unit.global_position-editor.actor.global_position).normalized()
	var facing:Vector3=editor.actor.global_basis.z.normalized()
	if not check(Vector2(facing.x,facing.z).normalized().dot(Vector2(toward.x,toward.z).normalized())>0.99,"Strafing does not keep facing locked target"):return
	var empty:Vector2=area.get_global_rect().position+area.size*Vector2(0.85,0.90)
	if not check(editor._pick_editor_unit(empty)==null,"Empty-ground test point occupied"):return
	button(MOUSE_BUTTON_LEFT,empty);button(MOUSE_BUTTON_LEFT,empty,false)
	await process_frame
	if not check(editor.focused_unit==null and editor.field.camera_focus_target==unit,"Clicking away dropped lock-on"):return
	var ring:MeshInstance3D=unit.get_node("UnitFocusRing")
	if not check(not ring.visible or not ring.material_override.albedo_color.is_equal_approx(Color("e9bf54")),"Cleared selection retains gold ring"):return
	zoom=editor.field.camera_zoom
	var pitch:float=editor.field.camera_orbit_pitch
	key(KEY_F);key(KEY_F,false)
	await process_frame
	if not check(editor.field.camera_focus_target==null and b.manual_aim and editor.focused_unit==null,"F after deselection did not release lock"):return
	if not check(is_equal_approx(float(editor.field.camera_zoom),zoom) and is_equal_approx(float(editor.field.camera_orbit_pitch),pitch),"Unlock reset zoom/pitch"):return
	button(MOUSE_BUTTON_MIDDLE,middle)
	yaw=editor.field.camera_orbit_yaw
	move(middle,Vector2(-100,0))
	button(MOUSE_BUTTON_MIDDLE,middle,false)
	if not check(not is_equal_approx(float(editor.field.camera_orbit_yaw),yaw),"Free camera cannot orbit"):return
	for frame in 20:await process_frame
	var start:Vector3=editor.actor.global_position
	var forward:Vector3=-editor.field.camera.global_basis.z
	forward.y=0;forward=forward.normalized()
	key(KEY_W);key(KEY_SHIFT)
	for frame in 12:await physics_frame
	key(KEY_W,false);key(KEY_SHIFT,false)
	if not check((editor.actor.global_position-start).dot(forward)>0.3,"Free sprint does not follow camera heading"):return
	var mouse_point:Vector2=area.get_global_rect().position+area.size*Vector2(0.7,0.45)
	root.grab_focus()
	move(mouse_point)
	await process_frame
	await process_frame
	var actual_pointer:Vector2=root.get_mouse_position()
	if not check((b.third_person_crosshair.global_position-actual_pointer).length()<1.0,"Crosshair does not follow viewport mouse: drawn=%s actual=%s requested=%s"%[b.third_person_crosshair.global_position,actual_pointer,mouse_point]):return
	var first_aim:Vector3=b.manual_aim_point
	mouse_point=area.get_global_rect().position+area.size*Vector2(0.3,0.45)
	move(mouse_point)
	await process_frame
	await process_frame
	actual_pointer=root.get_mouse_position()
	if not check((b.third_person_crosshair.global_position-actual_pointer).length()<1.0 and b.manual_aim_point.distance_to(first_aim)>0.1,"Mouse movement does not change crosshair and free aim"):return
	b.playing=false
	editor.actor.mana=100
	b.preview_effect="None"
	b.launch_projectile()
	var shot:Dictionary=editor.field.shots.back()
	if not check(shot.velocity.normalized().dot((b.manual_aim_point-shot.node.global_position).normalized())>0.999,"Spell ignores crosshair aim"):return
	print("THIRD PERSON PASSED: free crosshair, hover/select without camera change, F lock, orbit/zoom, facing while strafing, click-away preserves lock, F unlock preserves zoom, camera-relative sprint, crosshair projectile")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
