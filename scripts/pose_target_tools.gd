extends RefCounted
## Group posing and speed-limited, baked target transitions; callable by internal scripts.
var editor:Node
var selected:Array[String]=[]
var boxing:=false
var box_start:=Vector2.ZERO
var box_end:=Vector2.ZERO
var origin:Dictionary={}
var undo_state:Dictionary={}
var speed:SpinBox
var acceleration:SpinBox
var angle:SpinBox
var axis:OptionButton
var info:Label

func setup(owner_:Node,parent:Control) -> void:
	editor=owner_
	var tools:=VBoxContainer.new()
	parent.add_child(tools)
	info=editor.menu_label(tools,"Ctrl-drag a box over joints; select a target start, then rotate or drag.",13)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var row:=HFlowContainer.new()
	tools.add_child(row)
	editor.button(row,"Select All Joints",select_all)
	editor.button(row,"Clear Selection",func():selected.clear();update_info())
	editor.button(row,"Set Target Start",begin_target)
	axis=OptionButton.new()
	for label_ in ["Rotate X","Rotate Y","Rotate Z"]:axis.add_item(label_)
	row.add_child(axis)
	angle=SpinBox.new()
	angle.min_value=-180;angle.max_value=180;angle.step=5;angle.value=15
	angle.tooltip_text="Rotation in degrees around the selected joints' shared pivot"
	row.add_child(angle)
	editor.button(row,"Rotate Selection",func():rotate_selected(axis.selected,angle.value))
	var limits:=HFlowContainer.new()
	tools.add_child(limits)
	editor.menu_label(limits,"Max °/s",12)
	speed=SpinBox.new();speed.min_value=10;speed.max_value=1440;speed.value=360
	limits.add_child(speed)
	editor.menu_label(limits,"Max °/s²",12)
	acceleration=SpinBox.new();acceleration.min_value=30;acceleration.max_value=10000;acceleration.value=1800
	limits.add_child(acceleration)
	speed.value_changed.connect(func(_v:float):update_info())
	acceleration.value_changed.connect(func(_v:float):update_info())
	editor.button(limits,"Build Transition",build_transition)
	editor.button(limits,"Cancel Target",cancel_target)
	editor.button(limits,"Undo Transition",undo_transition)

func select_all() -> void:
	selected.assign(editor.DragSolver.JOINTS)
	update_info()

func capture_pose() -> Dictionary:
	var pose:Dictionary=editor.capture_custom_local_pose()
	pose["world_y"]=editor.actor.global_position.y
	return pose

func snapshot() -> Dictionary:
	return {"frames":editor.custom_frames.duplicate(true),"duration":editor.custom_duration,"elapsed":editor.custom_preview_elapsed,"repeat":editor.custom_preview_repeat}

func restore(state:Dictionary) -> void:
	editor.custom_frames.assign(state.frames.duplicate(true))
	editor.custom_duration=state.duration
	editor.custom_preview_elapsed=state.elapsed
	editor.custom_preview_repeat=state.repeat
	editor.custom_preview_playing=false
	editor.custom_drag_undo.clear()
	editor.refresh_custom_editor()
	editor.advance_custom_preview(0.0,false)

func begin_target() -> void:
	if editor.custom_recording or editor.custom_randomizing:return
	editor.pause_custom_preview()
	editor.select_custom_frame(editor.custom_frame_index)
	origin=snapshot()
	origin["index"]=editor.custom_frame_index
	origin["pose"]=capture_pose()
	update_info()

func cancel_target() -> void:
	if origin.is_empty():return
	var state:=origin.duplicate(true)
	origin.clear()
	restore(state)
	update_info()

func rotate_selected(axis_index:int,degrees:float) -> void:
	if selected.is_empty() or editor.custom_recording or editor.custom_randomizing:return
	if origin.is_empty():begin_target()
	if int(origin.index)!=editor.custom_frame_index:
		info.text="Return to the target start frame, or cancel and set a new start."
		return
	var rig:Skeleton3D=editor.actor.skeleton
	rig.force_update_all_bone_transforms()
	var world_axis:Vector3=[Vector3.RIGHT,Vector3.UP,Vector3.BACK][clampi(axis_index,0,2)]
	var turn:=Basis(world_axis,deg_to_rad(degrees))
	# Only selected roots rotate: selected descendants inherit the transformation.
	for bone in selected:
		var index:int=editor.actor.bones[bone]
		var parent_index:=rig.get_bone_parent(index)
		var ancestor:=parent_index
		var inherited:=false
		while ancestor>=0:
			if selected.has(rig.get_bone_name(ancestor)):inherited=true;break
			ancestor=rig.get_bone_parent(ancestor)
		if inherited:continue
		var parent_basis:=Basis.IDENTITY if parent_index<0 else rig.get_bone_global_pose(parent_index).basis.orthonormalized()
		var local:=parent_basis.inverse()*turn*parent_basis*Basis(rig.get_bone_pose_rotation(index))
		var base:Quaternion=editor.custom_source_frames[editor.custom_frame_index].rotations[bone]
		editor.custom_frames[editor.custom_frame_index][bone]=(base.inverse()*local.get_rotation_quaternion()).get_euler()*180.0/PI
	editor.advance_custom_preview(0.0,false)
	update_info()

func required_intervals() -> int:
	if origin.is_empty():return 0
	var target:Dictionary=capture_pose()
	var duration:=0.0
	for bone in editor.DragSolver.JOINTS:
		var distance:=rad_to_deg((origin.pose.rotations[bone] as Quaternion).angle_to(target.rotations[bone]))
		# Smoothstep has max velocity 1.5*d/T and acceleration 6*d/T².
		duration=maxf(duration,maxf(1.5*distance/speed.value,sqrt(6.0*distance/acceleration.value)))
	var displacement:float=(origin.pose.pelvis as Vector3).distance_to(target.pelvis)
	duration=maxf(duration,maxf(1.5*displacement/2.0,sqrt(6.0*displacement/8.0)))
	return maxi(1,ceili(duration/(float(origin.duration)/origin.frames.size())))

func update_info() -> void:
	if not is_instance_valid(info):return
	if origin.is_empty():info.text="%d joints selected · Ctrl-drag to box select · Set Target Start, then pose."%selected.size()
	else:info.text="%d joints selected · Target needs %d intervals (%.2f s) at this timeline's frame spacing. Build to insert; Cancel to restore."%[selected.size(),required_intervals(),required_intervals()*float(origin.duration)/origin.frames.size()]

func build_transition() -> void:
	if origin.is_empty() or editor.custom_recording:return
	if editor.custom_frame_index!=int(origin.index):info.text="Return to the target start frame before building.";return
	var target:Dictionary=capture_pose()
	var steps:=required_intervals()
	if (origin.frames.size()+steps)*float(origin.duration)/origin.frames.size()>60.0:
		info.text="Transition exceeds the 60-second animation limit. Increase the speed limits."
		return
	if origin.frames.size()+steps>editor.MAX_CUSTOM_FRAMES:
		info.text="Transition exceeds the %d-frame limit. Increase the speed limits or shorten the animation."%editor.MAX_CUSTOM_FRAMES
		return
	undo_state=origin.duplicate(true)
	var start_index:int=origin.index
	var poses:Array[Dictionary]=[]
	# Capture existing absolute local poses before changing source sampling times.
	restore(origin)
	for i in editor.custom_frames.size():
		editor.select_custom_frame(i)
		poses.append(capture_pose())
	for i in range(1,steps+1):
		var weight:=smoothstep(0.0,1.0,float(i)/steps)
		var pose:Dictionary={"world_y":lerpf(origin.pose.world_y,target.world_y,weight),"rotations":{},"pelvis":(origin.pose.pelvis as Vector3).lerp(target.pelvis,weight),"hands":editor._blend_hand_pose(origin.pose.hands,target.hands,weight)}
		for bone in editor.DragSolver.JOINTS:pose.rotations[bone]=(origin.pose.rotations[bone] as Quaternion).slerp(target.rotations[bone],weight)
		poses.insert(start_index+i,pose)
	var spacing:float=float(origin.duration)/origin.frames.size()
	editor.custom_duration=spacing*poses.size()
	editor.custom_frames=editor._default_jump_frames(poses.size())
	for i in poses.size():
		editor.apply_custom_source_pose(float(i)/poses.size())
		var frame:Dictionary={"hands":poses[i].hands.duplicate(true)}
		for bone in editor.DragSolver.JOINTS:
			var base:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(editor.actor.bones[bone])
			frame[bone]=(base.inverse()*(poses[i].rotations[bone] as Quaternion)).get_euler()*180.0/PI
		frame.pelvis_offset=(poses[i].pelvis as Vector3)-editor.actor.skeleton.get_bone_pose_position(editor.actor.bones.pelvis)
		frame.pelvis_offset+=editor.actor.skeleton.global_basis.inverse()*(Vector3.UP*(float(poses[i].world_y)-editor.actor.global_position.y))
		editor.custom_frames[i]=frame
	origin.clear()
	editor.custom_preview_elapsed=start_index*spacing
	editor.custom_preview_repeat=false
	editor.refresh_custom_editor()
	editor.advance_custom_preview(0.0,false)
	editor.custom_status.text="Inserted %d transition frames (%.2f s). Play to review, Save to keep, or Undo Transition."%[steps,steps*spacing]
	update_info()

func undo_transition() -> void:
	if undo_state.is_empty():return
	origin.clear()
	restore(undo_state)
	undo_state.clear()
	update_info()

func handle_input(event:InputEvent) -> bool:
	if not editor.direct_pose_handles_visible() or editor.custom_recording:return false
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and event.ctrl_pressed and event.position.x>editor.get_viewport().get_visible_rect().size.x*0.61:
			boxing=true;box_start=event.position;box_end=event.position
			return true
		if boxing and not event.pressed:
			boxing=false
			var rect:=Rect2(box_start,box_end-box_start).abs().grow(3)
			selected.clear()
			for bone in editor.DragSolver.JOINTS:
				var point:Vector3=editor.DragSolver.point(editor.actor,bone)
				if not editor.field.camera.is_position_behind(point) and rect.has_point(editor.field.camera.unproject_position(point)):selected.append(bone)
			update_info()
			return true
	if event is InputEventMouseMotion and boxing:box_end=event.position;return true
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode==KEY_A:
		if editor.get_viewport().gui_get_focus_owner() is LineEdit:return false
		select_all();return true
	return false
