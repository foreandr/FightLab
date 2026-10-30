extends Node3D
const Catalog=preload("res://scripts/showcase_catalog.gd")
var field: Node3D
var catalog: Array[Dictionary]=[]
var case_ids: Array[String]=[]
var exit_when_done := false
var auto_advance := true
var current := 0
var age := 0.0
var started := false
var followup := false
var finished := false
var actor: CharacterBody3D
var target: CharacterBody3D
var title_label: Label
var detail_label: Label
var resources_label: Label
var result_label: Label
var pause_button: Button
var auto_button: Button
var slow_button: Button
var results: Array[Dictionary]=[]
var marks := {}
var seen := {}
var report_path := ""
var camera_upper_allowance := 0.64

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	catalog=Catalog.cases()
	if not case_ids.is_empty():
		var selected: Array[Dictionary]=[]
		for id in case_ids:
			for entry in catalog:
				if entry.id==id:
					selected.append(entry)
		catalog=selected
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--showcase-report="):
			report_path=arg.trim_prefix("--showcase-report=")
	field=load("res://scenes/main.tscn").instantiate()
	field.creation_bot_profiles=creation_bot_outfits()
	field.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(field)
	field.duration=0
	field.review_camera=true
	field.set_process_unhandled_key_input(false)
	field.subtitle.hide()
	field.hud.get_parent().hide()
	field.round_label.hide()
	field.camera.position=Vector3(0,3,9)
	field.camera.fov=45
	build_ui()
	open_case(0)

func creation_bot_outfits() -> Array[Dictionary]:
	return []

func open_case(index: int) -> void:
	get_tree().paused=false
	current=posmod(index,catalog.size())
	age=0
	started=false
	followup=false
	finished=false
	seen={"armor":false,"aura":false,"freeze":false,"shield":false,"air":false,"movement":0.0}
	field.audio.stop_all()
	field.clear_battle_effects()
	field.round_active=true
	field.warmup=0
	field.intermission=0
	field.target_timer=99999
	field.eliminated.clear()
	var entry: Dictionary=catalog[current]
	actor=field.fighters[entry.team]
	target=field.fighters[0 if entry.team==2 else 2]
	if entry.kind=="armor_impact":
		target=field.fighters[0]
	var distance: float=entry.distance
	for f in field.fighters:
		var active: bool=f==actor or f==target
		f.brain_enabled=false
		f.reset_fighter(Vector3(-distance/2,0.02,0) if f==actor else (Vector3(distance/2,0.02,0) if f==target else Vector3(32,0.02,-32)))
		f.visible=active
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
		f.rival=target if f==actor else actor
		f.rotation.y=PI/2 if f==actor else -PI/2
		f.collision_layer=(128<<f.team) if active else 0
		for item in f.targets:
			item[0].collision_layer=(8<<f.team) if active else 0
		for item in f.limb_targets:
			item[0].collision_layer=(8<<f.team) if active else 0
		field.health_labels[f.team].get_parent().visible=active
	if entry.get("plain",false):
		actor.mana=0
	if entry.get("lethal",false):
		target.health=1
	if entry.has("block"):
		set_shield(target,entry.block,float(entry.duration)+1)
		if entry.get("weak_guard",false):
			target.guard_energy=16
	marks={"damage":target.damage_taken,"actor_damage":actor.damage_taken,"blocks":target.blocks,"guard_breaks":target.guard_breaks,"hits":actor.hits_scored,"actor_start":actor.global_position,"event":field.events.size()}
	title_label.text="%02d / %02d   ·   %s"%[current+1,catalog.size(),entry.title]
	detail_label.text="%s  ·  %s  ·  %s"%[field.element_name(actor.team),entry.group,"Partner attacks once" if entry.kind=="armor_impact" else ("Blocking target" if entry.has("block") else "Passive target — reacts to hits")]
	update_controls()

func set_shield(f: CharacterBody3D,style: String,length:=1.35) -> void:
	f.start_shield()
	f.guard_style=style
	f.mode_length=length
	f.clip=""
	f.play("duel/shield_raise_"+style)

func perform_case() -> void:
	var entry: Dictionary=catalog[current]
	match entry.kind:
		"spell":
			actor.spell_cursor=entry.get("spell",0)
			actor.charge_requested=1 if entry.get("charged",false) else 0
			if entry.get("air",false):
				actor.start_jump("jump_cast")
			else:
				actor.start_cast(false)
		"melee":
			actor.melee_sequence=entry.move
			actor.start_punch()
		"uppercut":
			actor.start_uppercut()
		"shield":
			set_shield(actor,entry.style)
		"armor_impact", "overdrive_run", "powered_flash":
			actor.spell_cursor=0
			actor.charge_requested=0
			actor.start_cast(false)
		"movement":
			var move: String=entry.movement
			if move=="flip":
				actor.start_jump("flip")
			elif move=="run":
				actor.mode="run"
				actor.mode_time=0
				actor.mode_length=1.6
			elif move.begins_with("strafe"):
				actor.decision=0 if move=="strafe_left" else 1
				actor.start_footwork("strafe")
			else:
				actor.start_footwork(move)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(field) or get_tree().paused or field.ending:
		return
	age+=delta
	var entry: Dictionary=catalog[current]
	if not started and age>=0.55:
		started=true
		perform_case()
	if started and not followup and age>=1.85 and entry.kind in ["armor_impact","overdrive_run","powered_flash"]:
		followup=true
		if entry.kind=="armor_impact":
			if entry.incoming=="fireball":
				target.spell_cursor=0
				target.charge_requested=0
				target.start_cast(false)
			else:
				target.melee_sequence=0
				target.start_punch()
		elif entry.kind=="overdrive_run":
			actor.mode="chase"
			actor.mode_time=0
			actor.mode_length=2.0
		else:
			actor.spell_cursor=1
			actor.start_cast(false)
	seen.armor=seen.armor or actor.armor_hp>0
	seen.aura=seen.aura or (actor.team==2 and field.storm_aura.visible)
	seen.freeze=seen.freeze or target.freeze_time>0
	seen.shield=seen.shield or actor.shield_active()
	seen.air=seen.air or actor.global_position.y>0.8
	seen.movement=maxf(seen.movement,actor.global_position.distance_to(marks.actor_start))
	update_camera(delta)
	var outcome: String="Watching"
	if target.guard_breaks>marks.guard_breaks:
		outcome="Guard broken"
	elif target.blocks>marks.blocks:
		outcome="Blocked"
	elif target.damage_taken>marks.damage:
		outcome="Hit registered"
	elif actor.damage_taken>marks.actor_damage:
		outcome="Armor impact"
	elif seen.armor:
		outcome="Armor active"
	elif seen.aura:
		outcome="Power-up visible"
	elif seen.shield:
		outcome="Shield active"
	result_label.text="%s   ·   %s%s"%[outcome,"Auto" if auto_advance else "Manual", "   ·   Slow motion" if Engine.time_scale<1 else ""]
	resources_label.text="%s: HP %d  ·  Mana %d  ·  Stamina %d  ·  Armor %d     |     Partner: HP %d  ·  Guard %d"%[field.element_name(actor.team),ceili(actor.health),floori(actor.mana),floori(actor.stamina),ceili(actor.armor_hp),ceili(target.health),floori(target.guard_energy)]
	if age>=float(entry.duration) and not finished:
		finish_case()
	if finished and auto_advance:
		if current==catalog.size()-1 and exit_when_done:
			write_report()
			field.write_report()
			field.finish_run()
		else:
			open_case(current+1)

func update_camera(delta: float) -> void:
	var points: Array[Vector3]=[]
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	for f in [actor,target]:
		for point in [f.focus_position(),f.bone_point("Head")+Vector3.UP*0.2,f.bone_point("foot_l")-Vector3.UP*0.15,f.bone_point("foot_r")-Vector3.UP*0.15]:
			points.append(point)
			low=low.min(point)
			high=high.max(point)
	var center: Vector3=(low+high)*0.5+Vector3.UP*0.35
	var back:=Vector3(0.15,0.36,1).normalized()
	var right:=Vector3(1,0,-0.15).normalized()
	var up:=back.cross(right).normalized()
	var distance:=6.8
	var aspect: float=get_viewport().get_visible_rect().size.aspect()
	for point in points:
		var offset:=point-center
		var allowance:=camera_upper_allowance if offset.dot(up)>0 else 0.74
		var fit:=maxf(absf(offset.dot(right))/(tan(deg_to_rad(22.5))*aspect*0.88),absf(offset.dot(up))/(tan(deg_to_rad(22.5))*allowance))
		distance=maxf(distance,offset.dot(back)+fit+0.8)
	var goal:=center+back*distance
	field.camera.position=field.camera.position.lerp(goal,minf(1,delta*6))
	field.camera.look_at(center)

func finish_case() -> Dictionary:
	if finished:
		return results[-1]
	finished=true
	var entry: Dictionary=catalog[current]
	var result: Dictionary={"id":entry.id,"title":entry.title,"expect":entry.expect,"damage":target.damage_taken-marks.damage,"actor_damage":actor.damage_taken-marks.actor_damage,"blocks":target.blocks-marks.blocks,"guard_breaks":target.guard_breaks-marks.guard_breaks,"dead":target.health<=0,"seen":seen.duplicate(true),"action_started":started}
	results.append(result)
	if results.size()>512:
		results.pop_front()
	if field.events.size()>4000:
		field.events=field.events.slice(-2000)
	return result

func write_report() -> void:
	if report_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file:=FileAccess.open(report_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"mode":"combat_showcase","cases":results},"  "))

func build_ui() -> void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var backdrop:=ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_top=0
	backdrop.offset_bottom=106
	backdrop.color=Color(0.025,0.035,0.05,0.88)
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	title_label=Label.new()
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top=10
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size",22)
	root.add_child(title_label)
	detail_label=Label.new()
	detail_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	detail_label.offset_top=45
	detail_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size",14)
	root.add_child(detail_label)
	resources_label=Label.new()
	resources_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	resources_label.offset_top=72
	resources_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	resources_label.add_theme_font_size_override("font_size",14)
	root.add_child(resources_label)
	var panel:=PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top=-80
	root.add_child(panel)
	var column:=VBoxContainer.new()
	panel.add_child(column)
	var buttons:=HBoxContainer.new()
	buttons.alignment=BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation",8)
	column.add_child(buttons)
	button(buttons,"← Previous",func():open_case(current-1))
	button(buttons,"Next →",func():open_case(current+1))
	button(buttons,"Replay [R]",func():open_case(current))
	pause_button=button(buttons,"Pause [Space]",toggle_pause)
	slow_button=button(buttons,"Slow [S]",toggle_slow)
	auto_button=button(buttons,"Auto: On [A]",toggle_auto)
	button(buttons,"Battle [B]",return_to_battle)
	button(buttons,"Animations",return_to_sandbox)
	result_label=Label.new()
	result_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size",15)
	column.add_child(result_label)

func button(row: Container,text_: String,callback: Callable) -> Button:
	var node:=Button.new()
	node.text=text_
	node.custom_minimum_size=Vector2(115,34)
	node.focus_mode=Control.FOCUS_NONE
	node.pressed.connect(callback)
	row.add_child(node)
	return node

func update_controls() -> void:
	pause_button.text="Resume [Space]" if get_tree().paused else "Pause [Space]"
	auto_button.text="Auto: On [A]" if auto_advance else "Auto: Off [A]"
	slow_button.text="Normal [S]" if Engine.time_scale<1 else "Slow [S]"

func toggle_pause() -> void:
	get_tree().paused=not get_tree().paused
	update_controls()

func toggle_slow() -> void:
	Engine.time_scale=0.35 if Engine.time_scale>=1 else 1.0
	update_controls()

func toggle_auto() -> void:
	auto_advance=not auto_advance
	update_controls()

func return_to_battle() -> void:
	get_tree().paused=false
	Engine.time_scale=1
	field.audio.stop_all()
	get_tree().change_scene_to_file("res://scenes/fight.tscn")

func return_to_sandbox() -> void:
	get_tree().paused=false
	Engine.time_scale=1
	field.audio.stop_all()
	get_tree().change_scene_to_file("res://scenes/combat_sandbox.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_RIGHT,KEY_N: open_case(current+1)
		KEY_LEFT,KEY_P: open_case(current-1)
		KEY_R: open_case(current)
		KEY_SPACE: toggle_pause()
		KEY_S: toggle_slow()
		KEY_A: toggle_auto()
		KEY_B:
			get_viewport().set_input_as_handled()
			return_to_battle()
			return
		KEY_M:
			field.audio.muted=not field.audio.muted
			if field.audio.muted:field.audio.stop_all()
		KEY_ESCAPE:
			get_tree().paused=false
			finish_case()
			write_report()
			field.finish_run()
		_: return
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	Engine.time_scale=1
	if get_tree()!=null:
		get_tree().paused=false
