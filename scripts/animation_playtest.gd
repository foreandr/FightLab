extends RefCounted
var editor
var active:=false
var control_button:Button
var held:Dictionary={}
var jump_velocity:=0.0
var jump_height:=0.0
var elapsed:=0.0
var camera_before:=Transform3D.IDENTITY
var camera_offset:=Vector3(0,3.5,7)
var round_before:=false
var camera_input_before:=true
var camera_manual_before:=false
var hit_once:Dictionary={}
var previous_points:Dictionary={}
var snapshots:Dictionary={}

func setup(owner_:Node,parent:Container) -> void:
	editor=owner_
	control_button=editor.button(parent,"Take Control",toggle)
	control_button.tooltip_text="Control selected bot: WASD move, Shift sprint, Space jump, click arena to use timeline, Backspace resets test units, Escape releases"

func toggle() -> void:
	if active:release();return
	if not editor.can_add_unit_animation():editor.show_unit_selection_warning();return
	editor.stop_timeline()
	active=true
	held.clear()
	jump_height=0
	jump_velocity=0
	camera_before=editor.field.camera.global_transform
	camera_input_before=editor.camera_input_enabled
	camera_manual_before=editor.inspection_camera.manual
	editor.camera_input_enabled=false
	editor.inspection_camera.manual=false
	round_before=editor.field.round_active
	var unit:Node=editor.focused_unit
	var backward:Vector3=unit.global_basis.z.normalized()
	camera_offset=-backward*7+Vector3.UP*4
	snapshots.clear()
	for bot in editor.added_units:
		snapshots[bot.get_instance_id()]={"transform":bot.global_transform,"health":bot.health,"stamina":bot.stamina,"mana":bot.mana}
		bot.invulnerability=0
	editor.field.round_active=true
	editor.get_tree().paused=false
	control_button.text="Release Control"
	control_button.release_focus()
	editor._show_library_notice("WASD move · Shift sprint · Space jump · Click arena to use timeline · Backspace reset · Esc release")

func release() -> void:
	if not active:return
	editor.stop_timeline()
	editor.clear_jump_tails(null,true)
	active=false
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
	if active and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE:return true
	if active and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var control:Control=editor.get_viewport().gui_get_hovered_control()
		if control==editor.base_ui.get_node_or_null("ArenaUnitDrop"):
			trigger()
			return true
	if not event is InputEventKey:return false
	if not active:return false
	if event.keycode==KEY_ESCAPE and event.pressed:release();return true
	if editor.get_viewport().gui_get_focus_owner() is LineEdit or editor.get_viewport().gui_get_focus_owner() is TextEdit:return false
	if event.keycode==KEY_BACKSPACE:
		if event.pressed and not event.echo:reset_units()
		return true
	if event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SHIFT,KEY_SPACE]:
		held[event.keycode]=event.pressed
		if event.keycode==KEY_SPACE and event.pressed and not event.echo and jump_height<=0:jump_velocity=6.0
		return true
	return false

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
	var forward:Vector3=-camera.global_basis.z;forward.y=0;forward=forward.normalized()
	var right:Vector3=camera.global_basis.x;right.y=0;right=right.normalized()
	var direction:Vector3=forward*(float(held.get(KEY_W,false))-float(held.get(KEY_S,false)))+right*(float(held.get(KEY_D,false))-float(held.get(KEY_A,false)))
	direction=direction.limit_length(1)
	var speed:=7.0 if held.get(KEY_SHIFT,false) else 4.0
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
		unit.rotation.y=atan2(direction.x,direction.z)
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
		var entry:Dictionary={"group":"Motion","category":"Run","title":"Run","step":"Sprint" if speed>4 else "Run","clip":"duel/run" if speed>4 else "ual1/Jog_Fwd","duration":0.8}
		if editor.actor.player.has_animation(entry.clip):
			editor._sample_row_animation(entry,fposmod(elapsed,0.8))
			editor._set_unit_pose_target(unit)
	camera.global_position=unit.global_position+camera_offset
	camera.look_at(unit.global_position+Vector3.UP*1.1)

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
