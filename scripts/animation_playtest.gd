extends RefCounted
const Movement=preload("res://scripts/character_movement.gd")
const ThirdPersonCamera=preload("res://scripts/third_person_camera.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
var editor
var active:=false
var control_button:Button
var held:Dictionary={}
var jump_velocity:=0.0
var jump_height:=0.0
var elapsed:=0.0
var camera_before:=Transform3D.IDENTITY
var camera_offset:=Vector3(0,3.5,7)
var camera_yaw:=PI
var camera_pitch:=0.42
var camera_distance:=8.0
var orbiting:=false
var moving:=false
var camera_offsets_before:=Vector2.ZERO
var round_before:=false
var camera_input_before:=true
var camera_manual_before:=false
var hit_once:Dictionary={}
var previous_points:Dictionary={}
var snapshots:Dictionary={}

func setup(owner_:Node,parent:Container) -> void:
	editor=owner_
	control_button=editor.button(parent,"Take Control",toggle)
	control_button.tooltip_text="WASD move · Shift sprint · Space jump · Click attack · Wheel zoom · Middle/right-drag orbit · Arrows orbit · −/+ zoom · Home reset camera · Backspace reset · Esc release"

func toggle() -> void:
	if active:release();return
	if not editor.can_add_unit_animation():editor.show_unit_selection_warning();return
	editor.stop_timeline()
	active=true
	held.clear()
	jump_height=0
	jump_velocity=0
	camera_before=editor.field.camera.global_transform
	camera_offsets_before=Vector2(editor.field.camera.h_offset,editor.field.camera.v_offset)
	editor.field.camera.h_offset=0
	editor.field.camera.v_offset=0
	camera_input_before=editor.camera_input_enabled
	camera_manual_before=editor.inspection_camera.manual
	editor.camera_input_enabled=false
	editor.inspection_camera.manual=false
	round_before=editor.field.round_active
	var unit:Node=editor.focused_unit
	var backward:Vector3=unit.global_basis.z.normalized()
	camera_offset=-backward*7+Vector3.UP*4
	camera_yaw=atan2(camera_offset.x,camera_offset.z)
	camera_pitch=0.42
	camera_distance=8.0
	orbiting=false
	snapshots.clear()
	for bot in editor.added_units:
		snapshots[bot.get_instance_id()]={"transform":bot.global_transform,"health":bot.health,"stamina":bot.stamina,"mana":bot.mana}
		bot.invulnerability=0
	editor.field.round_active=true
	editor.get_tree().paused=false
	control_button.text="Release Control"
	control_button.release_focus()
	editor._show_library_notice("WASD move · Shift sprint · Space jump · Click attack · Wheel zoom · Middle/right-drag orbit · Esc release")

func release() -> void:
	if not active:return
	editor.stop_timeline()
	editor.clear_jump_tails(null,true)
	active=false
	orbiting=false
	moving=false
	held.clear()
	jump_height=0
	jump_velocity=0
	for bot in editor.added_units:
		bot.global_position.y=float(bot.get_meta("editor_ground_y",0.02))
		if snapshots.has(bot.get_instance_id()):
			var saved:Dictionary=snapshots[bot.get_instance_id()]
			bot.health=saved.health;bot.stamina=saved.stamina;bot.mana=saved.mana
			bot.invulnerability=0
	editor.field.camera.global_transform=camera_before
	editor.field.camera.h_offset=camera_offsets_before.x
	editor.field.camera.v_offset=camera_offsets_before.y
	editor.camera_input_enabled=camera_input_before
	editor.inspection_camera.manual=camera_manual_before
	editor.field.round_active=round_before
	control_button.text="Take Control"

func reset_units() -> void:
	editor.stop_timeline()
	editor.clear_jump_tails(null,true)
	for bot in editor.added_units:
		if not snapshots.has(bot.get_instance_id()):continue
		var saved:Dictionary=snapshots[bot.get_instance_id()]
		bot.global_transform=saved.transform
		bot.health=saved.health;bot.stamina=saved.stamina;bot.mana=saved.mana
		bot.invulnerability=0
	jump_height=0;jump_velocity=0
	hit_once.clear();previous_points.clear()

func handle_input(event:InputEvent) -> bool:
	if active and event is InputEventMouseButton:
		var arena_hover:bool=editor.get_viewport().gui_get_hovered_control()==editor.base_ui.get_node_or_null("ArenaUnitDrop")
		if event.button_index in [MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT] and (arena_hover or orbiting):
			orbiting=event.pressed
			return true
		if arena_hover and event.pressed and not event.ctrl_pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_camera(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)
			return true
	if active and event is InputEventMouseMotion and orbiting:
		camera_yaw-=event.relative.x*0.008
		camera_pitch=clampf(camera_pitch+event.relative.y*0.006,-0.1,1.25)
		_update_camera()
		return true
	if active and event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_RIGHT_STICK:zoom_camera(1)
			JOY_BUTTON_A:
				if jump_height<=0:jump_velocity=6.0
			JOY_BUTTON_X,JOY_BUTTON_RIGHT_SHOULDER:trigger()
			JOY_BUTTON_B:release()
			_:return false
		return true
	if active and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var control:Control=editor.get_viewport().gui_get_hovered_control()
		if control==editor.base_ui.get_node_or_null("ArenaUnitDrop"):
			trigger()
			return true
	if not event is InputEventKey:return false
	if not active:return false
	if event.keycode==KEY_ESCAPE and event.pressed:release();return true
	if editor.get_viewport().gui_get_focus_owner() is LineEdit or editor.get_viewport().gui_get_focus_owner() is TextEdit:return false
	if event.pressed and not event.ctrl_pressed and event.keycode in [KEY_MINUS,KEY_EQUAL,KEY_PAGEUP,KEY_PAGEDOWN,KEY_HOME]:
		if event.keycode==KEY_HOME:camera_pitch=0.42;camera_distance=8.0;camera_yaw=editor.focused_unit.rotation.y+PI;_update_camera()
		else:zoom_camera(1 if event.keycode in [KEY_MINUS,KEY_PAGEDOWN] else -1)
		return true
	if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:held[event.keycode]=event.pressed;return true
	if event.keycode==KEY_BACKSPACE:
		if event.pressed and not event.echo:reset_units()
		return true
	if event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SHIFT,KEY_SPACE]:
		held[event.keycode]=event.pressed
		if event.keycode==KEY_SPACE and event.pressed and not event.echo and jump_height<=0:jump_velocity=6.0
		return true
	return false

func zoom_camera(steps:int) -> void:
	camera_distance=clampf(camera_distance*pow(1.15,steps),2.0,30.0)
	_update_camera()

func _update_camera() -> void:
	if not active or not is_instance_valid(editor.focused_unit):return
	camera_offset=Vector3(sin(camera_yaw)*cos(camera_pitch),sin(camera_pitch),cos(camera_yaw)*cos(camera_pitch))*camera_distance
	ThirdPersonCamera.update(editor.field.camera,editor.focused_unit,null,camera_yaw,camera_pitch,camera_distance,1.0)

func trigger() -> void:
	if not active or editor.timeline_playing:return
	if editor.timeline_clips.is_empty():editor._show_library_notice("Add an animation to the timeline first");return
	var cost:=0.0
	for clip in editor.timeline_clips:cost+=float(editor._clip_combat_stats(clip).stamina)
	if editor.focused_unit.stamina+0.001<cost:editor._show_library_notice("Not enough stamina · Backspace resets test units");return
	editor.timeline_playhead=0
	editor.repeat_playing=false
	editor.actor.global_basis=editor.focused_unit.global_basis
	hit_once.clear();previous_points.clear()
	editor.play_timeline()
	editor.field.round_active=true

func physics(delta:float) -> void:
	if not active:return
	if not editor.can_add_unit_animation():release();return
	elapsed+=delta
	var unit:CharacterBody3D=editor.focused_unit
	var camera:Camera3D=editor.field.camera
	var forward:=Movement.camera_forward(camera)
	var right:=forward.cross(Vector3.UP)
	var direction:=Movement.camera_direction(Locomotion.axes(held),camera)
	camera_yaw+=(float(held.get(KEY_LEFT,false))-float(held.get(KEY_RIGHT,false)))*delta*1.8
	camera_pitch=clampf(camera_pitch+(float(held.get(KEY_DOWN,false))-float(held.get(KEY_UP,false)))*delta*1.2,-0.1,1.25)
	var pads:=Input.get_connected_joypads()
	var pad_sprint:=false
	if not pads.is_empty():
		var pad:int=pads[0]
		var move_stick:=Vector2(Input.get_joy_axis(pad,JOY_AXIS_LEFT_X),Input.get_joy_axis(pad,JOY_AXIS_LEFT_Y))
		var look_stick:=Vector2(Input.get_joy_axis(pad,JOY_AXIS_RIGHT_X),Input.get_joy_axis(pad,JOY_AXIS_RIGHT_Y))
		if move_stick.length()>0.2:direction+=right*move_stick.x-forward*move_stick.y
		if look_stick.length()>0.2:
			camera_yaw-=look_stick.x*delta*2.0
			camera_pitch=clampf(camera_pitch+look_stick.y*delta*1.5,-0.1,1.25)
		pad_sprint=Input.is_joy_button_pressed(pad,JOY_BUTTON_LEFT_STICK)
	direction=direction.limit_length(1)
	moving=direction.length()>0.01
	var speed:=7.0 if held.get(KEY_SHIFT,false) or pad_sprint else 4.0
	var before:=unit.global_position
	var next:=before+direction*speed*delta
	var flat:=Vector2(next.x,next.z).limit_length(float(editor.field.Boundary.RADIUS)-1.0)
	next.x=flat.x;next.z=flat.y
	for other in editor.added_units:
		if other==unit or not is_instance_valid(other):continue
		other.invulnerability=maxf(0,other.invulnerability-delta)
		var separation:=Vector2(next.x-other.global_position.x,next.z-other.global_position.z)
		if separation.length()<0.65 and separation.length()>0.001:
			separation=separation.normalized()*0.65
			next.x=other.global_position.x+separation.x;next.z=other.global_position.z+separation.y
	if direction.length()>0.01 and not editor.timeline_playing:
		Movement.turn(unit,forward,delta)
	if not editor.timeline_playing:
		jump_velocity-=18.0*delta
		jump_height=maxf(0,jump_height+jump_velocity*delta)
		next.y=float(unit.get_meta("editor_ground_y",0.02))+jump_height
	unit.global_position=next
	var movement:=next-before
	if editor.timeline_playing:
		editor.timeline_unit_origin+=Vector3(movement.x,0,movement.z)
		editor.timeline_origin_position+=Vector3(movement.x,0,movement.z)
	elif direction.length()>0.01:
		var move_axes:=Vector2(direction.dot(right),direction.dot(forward)).limit_length(1.0)
		Locomotion.pose(editor.actor,move_axes,elapsed,speed>4)
		editor._set_unit_pose_target(unit)
	_update_camera()

func contacts() -> void:
	if not active or not editor.timeline_playing:return
	var unit:CharacterBody3D=editor.focused_unit
	for clip in editor.timeline_clips:
		if float(editor._clip_combat_stats(clip).damage)<=0:continue
		var effective:=false
		for pose in editor.timeline_active.values():
			if int(pose.get("id",-1))==int(clip.id):effective=true;break
		if not effective:continue
		var time:float=editor.timeline_playhead-float(clip.start)
		var progress:float=time/maxf(0.05,float(clip.duration))
		if progress<0.15 or progress>0.85:continue
		var bones:Array=[str(clip.get("attack_bone","hand_l"))]
		if not clip.has("attack_bone"):bones=["hand_l","hand_r","foot_l","foot_r"]
		for bone in bones:
			if not unit.bones.has(bone):continue
			var point:Vector3=unit.bone_point(bone)
			var key:="%s:%s"%[clip.id,bone]
			var previous:Vector3=previous_points.get(key,point)
			previous_points[key]=point
			for victim in editor.added_units:
				if victim==unit or victim.health<=0:continue
				var hit_key:="%s:%s"%[clip.id,victim.get_instance_id()]
				if hit_once.has(hit_key):continue
				for zone in ["Head","spine_03","pelvis","thigh_l","thigh_r"]:
					var target:Vector3=victim.bone_point(zone)
					var nearest:=Geometry3D.get_closest_point_to_segment(target,previous,point)
					if nearest.distance_to(target)>0.32:continue
					var damage:float=editor._clip_combat_stats(clip).damage
					# Creation targets retain their authored pose while taking real resource damage.
					var applied:=minf(victim.health,damage)
					victim.health=maxf(0,victim.health-damage)
					victim.damage_taken+=applied;unit.damage_dealt+=applied
					hit_once[hit_key]=true
					editor.field.impact_burst(nearest,unit.team,true)
					editor._show_library_notice("Hit %s · %.1f damage"%[victim.name,applied])
					var tag:Node=victim.get_node_or_null("OverheadHealthTag")
					if tag!=null:tag.update_tag()
					break
