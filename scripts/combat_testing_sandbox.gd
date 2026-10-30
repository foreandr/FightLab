extends "res://scripts/combat_showcase.gd"
@export_enum("Animations","Spells") var editor_section := "Animations"
## User-configurable scenarios share the showcase's real combat/reset paths.
var moves: Array[Dictionary]=[]
var move_menu: OptionButton
var distance_input: SpinBox
var block_menu: OptionButton
var jump_toggle: CheckBox
var charge_toggle: CheckBox
var hint_label: Label
var armed := false
var configuring := true
var pending_air_action := false
var partner_jumping := false
var partner_air_ready := false
var inspection_camera=preload("res://scripts/sandbox_camera.gd").new()
var camera_input_enabled := true
var camera_dragging := false
var camera_mouse_origin := Vector2.ZERO
var camera_initialized := false
var sequence=preload("res://scripts/motion_sequence.gd").new()
var chain_data: Array[String]=[]
var chain_profiles:Array[Dictionary]=[]
var chain_settings_path := "user://animation_chain.cfg"
var chain_chips: Array[Control]=[]
var chain_remove_buttons: Array[Button]=[]
var chain_panel: HBoxContainer
var dash_direction_menu: OptionButton
const MAX_CHAIN_STEPS := 32
var chain_steps: HBoxContainer
var chain_scroll: ScrollContainer
var remove_step_button: Button
var chain_count: Label
var play_button: Button
var repeat_play_button: Button
var repeat_playing := false
var repeat_wait := 0.0
var repeat_cycles := 0

func creation_bot_outfits() -> Array[Dictionary]:
	var profiles: Array[Dictionary] = []
	for index in 3: profiles.append(preload("res://scripts/creation_bot_outfit.gd").profile(index))
	return profiles

func _ready() -> void:
	auto_advance=false
	load_chain_state()
	camera_upper_allowance=0.40
	super._ready()
	configuring=false
	settings_changed()
	update_camera(1)

func build_ui() -> void:
	if editor_section=="Animations":
		moves.append({"id":"motion_chain","title":"Animation Chain","team":0,"kind":"sequence","group":"Motion","expect":"movement","distance":4.4,"plain":true})
	var ids: Array[String]=["fireball_ground","cinder_slash_ground","freezing_ray_ground","armor_ground","overdrive_ground","flash_ground","melee_0","melee_1","melee_4","melee_2","melee_5","melee_3","uppercut","fire_kick","ice_knee","shield_palm","shield_brace","armor_fireball","armor_punch","overdrive_run","flash_overdrive","movement_run","movement_approach","movement_retreat","movement_strafe_left","movement_strafe_right","movement_dodge_back","movement_roll_back","movement_flip","death_fireball","death_punch"]
	for id in ids:
		if editor_section=="Spells" and id not in ["fireball_ground","cinder_slash_ground","freezing_ray_ground","armor_ground","overdrive_ground","flash_ground","armor_fireball","armor_punch","overdrive_run","flash_overdrive","death_fireball"]:
			continue
		for entry in Catalog.cases():
			if entry.id==id:
				moves.append(entry.duplicate(true))
	var layer:=CanvasLayer.new()
	add_child(layer)
	var ui:=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var top:=PanelContainer.new()
	var panel_style:=StyleBoxFlat.new()
	panel_style.bg_color=Color(0.025,0.035,0.05,0.94)
	top.add_theme_stylebox_override("panel",panel_style)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ui.add_child(top)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,8)
	top.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	margin.add_child(column)
	title_label=menu_label(column,"CREATE · "+editor_section.to_upper(),20)
	var row:=HBoxContainer.new()
	row.alignment=BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",10)
	column.add_child(row)
	menu_label(row,"Move",15)
	move_menu=OptionButton.new()
	move_menu.custom_minimum_size=Vector2(350,32)
	for entry in moves:
		var name_: String=entry.title.replace(" — Ground Cast","").replace(" — Unblocked","")
		move_menu.add_item(name_ if entry.kind=="sequence" else ["FIRE","ICE","STORM"][entry.team]+"  /  "+name_)
	row.add_child(move_menu)
	menu_label(row,"Distance (m)",15)
	distance_input=SpinBox.new()
	distance_input.min_value=0.5
	distance_input.max_value=26
	distance_input.step=0.1
	distance_input.value=4.4
	distance_input.custom_minimum_size=Vector2(100,32)
	row.add_child(distance_input)
	block_menu=OptionButton.new()
	for text_ in ["Partner: No block","Partner: Palm shield","Partner: Brace shield","Partner: Jump","Partner: Jump + palm shield","Partner: Jump + brace shield"]:
		block_menu.add_item(text_)
	row.add_child(block_menu)
	chain_panel=HBoxContainer.new()
	chain_panel.alignment=BoxContainer.ALIGNMENT_CENTER
	chain_panel.add_theme_constant_override("separation",6)
	column.add_child(chain_panel)
	chain_count=menu_label(chain_panel,"Animation Chain",14)
	remove_step_button=button(chain_panel,"−",remove_chain_step)
	remove_step_button.custom_minimum_size=Vector2(36,32)
	remove_step_button.tooltip_text="Remove the last animation"
	chain_scroll=ScrollContainer.new()
	chain_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	chain_scroll.custom_minimum_size=Vector2(100,48)
	chain_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	chain_panel.add_child(chain_scroll)
	chain_steps=HBoxContainer.new()
	chain_steps.add_theme_constant_override("separation",6)
	chain_scroll.add_child(chain_steps)
	refresh_chain_options()
	var options:=HBoxContainer.new()
	options.alignment=BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation",12)
	column.add_child(options)
	dash_direction_menu=OptionButton.new()
	for text_ in ["Forward","Forward-right","Right","Back-right","Backward","Back-left","Left","Forward-left"]:
		dash_direction_menu.add_item(text_)
	dash_direction_menu.focus_mode=Control.FOCUS_NONE
	options.add_child(dash_direction_menu)
	jump_toggle=checkbox(options,"Caster jumps")
	charge_toggle=checkbox(options,"Charged cast")
	hint_label=menu_label(column,"",13)
	detail_label=menu_label(column,"",13)
	resources_label=menu_label(column,"",13)
	var bottom:=PanelContainer.new()
	bottom.add_theme_stylebox_override("panel",panel_style)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top=-100
	ui.add_child(bottom)
	var footer:=VBoxContainer.new()
	bottom.add_child(footer)
	var actions:=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",8)
	footer.add_child(actions)
	play_button=button(actions,"Play [R]",run_setup)
	repeat_play_button=button(actions,"Repeat Play",toggle_repeat_play)
	button(actions,"Reset [X]",reset_setup)
	slow_button=button(actions,"Slow [T]",toggle_slow)
	button(actions,"Home [Esc]",return_home)
	result_label=menu_label(footer,"Ready — choose a move, then Play",15)
	menu_label(footer,"Camera: WASD move · Q/E height · Hold middle mouse rotate · Wheel zoom · Shift faster",13)
	move_menu.item_selected.connect(func(_index):settings_changed())
	distance_input.value_changed.connect(func(_value):settings_changed())
	block_menu.item_selected.connect(func(_index):settings_changed())
	dash_direction_menu.item_selected.connect(func(_index):settings_changed())
	for toggle in [jump_toggle,charge_toggle]:
		toggle.toggled.connect(func(_value):settings_changed())
	# Space belongs to pause; arrows belong to the menu when it has focus.
	for node in [move_menu,block_menu,jump_toggle,charge_toggle]:
		node.focus_mode=Control.FOCUS_NONE

func menu_label(parent: Node,text_: String,size: int) -> Label:
	var label:=Label.new()
	label.text=text_
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",size)
	parent.add_child(label)
	return label

func checkbox(parent: Node,text_: String) -> CheckBox:
	var node:=CheckBox.new()
	node.text=text_
	parent.add_child(node)
	return node

func settings_changed() -> void:
	if configuring:
		return
	configuring=true
	var entry: Dictionary=moves[move_menu.selected]
	var motion: bool=entry.kind=="sequence"
	chain_panel.visible=motion
	dash_direction_menu.visible=motion
	refresh_chain_options()
	jump_toggle.visible=not motion
	charge_toggle.visible=not motion
	camera_upper_allowance=0.30 if motion else 0.40
	var can_jump: bool=entry.kind in ["spell","melee","uppercut","shield"]
	jump_toggle.disabled=not can_jump
	if not can_jump:
		jump_toggle.set_pressed_no_signal(false)
	var can_charge: bool=entry.id in ["fireball_ground","cinder_slash_ground","freezing_ray_ground"] and not jump_toggle.button_pressed
	charge_toggle.disabled=not can_charge
	if not can_charge:
		charge_toggle.set_pressed_no_signal(false)
	charge_toggle.tooltip_text="Held charge is available for grounded Fireball, Cinder Slash and Freezing Ray. Jump casts are quick; Flash Step and uppercut include their own charge."
	hint_label.text="Spawn distance is center to center. "
	if motion:
		hint_label.text="Use + beside an animation to add it. Attacks work in the air; an attack after Twist plays during the turn."
	elif entry.kind in ["melee","uppercut"]:
		hint_label.text+="Suggested melee distance: %.2f m. Distant strikes can miss."%float(entry.distance)
	elif jump_toggle.button_pressed:
		hint_label.text+="Jump casts use the quick release; held charge is grounded."
	else:
		hint_label.text+="Settings reset the fighters. Play runs once; Repeat Play loops."
	configuring=false
	reset_setup()

func configured_entry() -> Dictionary:
	var entry: Dictionary=moves[move_menu.selected].duplicate(true)
	entry.distance=float(distance_input.value)
	entry.duration=9.0
	entry.erase("block")
	entry.erase("weak_guard")
	entry.charged=charge_toggle.button_pressed
	entry.air=jump_toggle.button_pressed and entry.kind=="spell"
	entry.sandbox_air=jump_toggle.button_pressed and entry.kind!="spell"
	if entry.kind=="sequence":
		entry.plain=not sequence.needs_mana(chosen_steps())
		entry.duration=maxf(9,chosen_steps().size()*3.0+1)
		entry.air=false
		entry.sandbox_air=false
	var shield:=partner_shield_style()
	if not shield.is_empty():entry.block=shield
	return entry

func partner_jumps() -> bool:
	return block_menu.selected in [3,4,5]

func partner_shield_style() -> String:
	if block_menu.selected in [1,4]:return "palm"
	if block_menu.selected in [2,5]:return "brace"
	return ""

func chosen_steps() -> Array[String]:
	return chain_data.duplicate()

func can_append_animation(step: String) -> bool:
	var grounded:=true
	for existing in chain_data:grounded=sequence.state_after(existing,grounded)
	return chain_data.size()<MAX_CHAIN_STEPS and sequence.allowed_for_state(step,grounded)

func refresh_chain_options() -> void:
	var grounded:=true
	var valid_steps: Array[String]=[]
	var valid_profiles:Array[Dictionary]=[]
	for step in chain_data:
		if step=="End" or not sequence.OPTIONS.has(step) or not sequence.allowed_for_state(step,grounded):break
		var slot:=valid_steps.size()
		valid_profiles.append(chain_profiles[slot].duplicate(true) if slot<chain_profiles.size() else {})
		valid_steps.append(step)
		grounded=sequence.state_after(step,grounded)
	chain_data=valid_steps
	chain_profiles=valid_profiles
	for child in chain_steps.get_children():
		chain_steps.remove_child(child)
		child.queue_free()
	chain_chips.clear()
	chain_remove_buttons.clear()
	if chain_data.is_empty():
		menu_label(chain_steps,"Use + beside an animation to build your chain",14)
	for i in chain_data.size():
		if i>0:menu_label(chain_steps,"→",15)
		var chip:=HBoxContainer.new()
		chain_steps.add_child(chip)
		var animation_name:String=str(chain_profiles[i].get("title",chain_data[i]))
		menu_label(chip,"%d. %s"%[i+1,animation_name],15)
		var remove:=button(chip,"×",func():remove_chain_step(i))
		remove.custom_minimum_size=Vector2(30,30)
		remove.tooltip_text="Remove "+animation_name
		chain_chips.append(chip)
		chain_remove_buttons.append(remove)
	chain_count.text="Animation Chain (%d)"%chain_data.size()
	remove_step_button.disabled=chain_data.is_empty()
	update_playback_buttons()

func reveal_last_chain_step() -> void:
	await get_tree().process_frame
	if is_inside_tree() and not chain_chips.is_empty():
		chain_scroll.ensure_control_visible(chain_chips[-1])

func remove_chain_step(index: int=-1) -> void:
	if chain_data.is_empty():return
	if index<0:index=chain_data.size()-1
	if index>=chain_data.size():return
	chain_data.remove_at(index)
	if index<chain_profiles.size():chain_profiles.remove_at(index)
	settings_changed()
	save_chain_state()

func set_chain(steps: Array,profiles:Array=[]) -> void:
	move_menu.select(0)
	var selected_steps:Array=steps.slice(0,MAX_CHAIN_STEPS)
	var selected_profiles:Array=profiles.duplicate(true)
	chain_data.clear()
	chain_profiles.clear()
	for i in selected_steps.size():
		if not sequence.OPTIONS.has(str(selected_steps[i])):continue
		chain_data.append(str(selected_steps[i]))
		chain_profiles.append(selected_profiles[i] if i<selected_profiles.size() and selected_profiles[i] is Dictionary else {})
	settings_changed()
	save_chain_state()

func save_chain_state() -> void:
	if editor_section!="Animations" or chain_settings_path.is_empty():return
	var config:=ConfigFile.new()
	config.set_value("chain","version",3)
	config.set_value("chain","steps",chain_data)
	config.set_value("chain","animations",chain_profiles)
	config.save(chain_settings_path)

func load_chain_state() -> void:
	if editor_section!="Animations" or chain_settings_path.is_empty():return
	var config:=ConfigFile.new()
	if config.load(chain_settings_path)!=OK:
		seed_default_chain()
		return
	var version:int=int(config.get_value("chain","version",1))
	var steps=config.get_value("chain","steps",[])
	var profiles=config.get_value("chain","animations",[])
	if not steps is Array or not profiles is Array:return
	chain_data.clear()
	chain_profiles.clear()
	for i in mini(steps.size(),MAX_CHAIN_STEPS):
		if not sequence.OPTIONS.has(str(steps[i])):continue
		chain_data.append(str(steps[i]))
		chain_profiles.append(profiles[i].duplicate(true) if i<profiles.size() and profiles[i] is Dictionary else {})
	# Replace the old one-step starter example once, while preserving any chain
	# the player has already built.
	if version<2 and chain_data==["Idle"]:
		seed_default_chain()
	elif version<3 and chain_data.size()==3 and chain_profiles.all(func(profile):return profile.is_empty()):
		append_default_chain_steps(2)
		save_chain_state()
	elif version<3:
		save_chain_state()

func seed_default_chain() -> void:
	chain_data.clear()
	chain_profiles.clear()
	append_default_chain_steps(5)
	save_chain_state()

func append_default_chain_steps(count:int) -> void:
	var pool:Array[String]=["Run","Dash","Punch","Block","Crouch","Cross","Hook","Kick","Elbow"]
	for existing in chain_data:pool.erase(existing)
	var rng:=RandomNumberGenerator.new()
	rng.randomize()
	for _i in mini(count,pool.size()):
		var step:String=pool.pop_at(rng.randi_range(0,pool.size()-1))
		chain_data.append(step)
		chain_profiles.append({})

func prepare_setup(run: bool) -> void:
	sequence.reset()
	armed=run
	pending_air_action=false
	partner_jumping=false
	partner_air_ready=false
	catalog.assign([configured_entry()])
	super.open_case(0)
	# The ready stage is paused before the arena's first visual update. Clear
	# shared meshes immediately so old shields/armor cannot remain at reset.
	for node in field.shields+field.charges+field.freeze_effects:
		node.hide()
	for pieces in field.armor_meshes:
		for piece in pieces:
			piece[0].hide()
	field.storm_aura.hide()
	field.shield_hit_age=[2.0,2.0,2.0]
	title_label.text="CREATE · %s  ·  %s"%[editor_section.to_upper(),str(catalog[0].title).replace(" — Ground Cast","").replace(" — Unblocked","")]
	detail_label.text="%.1f m apart  ·  %s  ·  %s"%[float(distance_input.value),"Caster jumps" if jump_toggle.button_pressed else "Grounded caster",block_menu.get_item_text(block_menu.selected)]
	get_tree().paused=not run
	show_resources()
	result_label.text="Ready — Play runs once; Repeat Play loops; Reset restores both fighters."
	update_controls()

func reset_setup() -> void:
	stop_repeat_play()
	prepare_setup(false)

func run_setup() -> void:
	stop_repeat_play()
	prepare_setup(true)

func update_playback_buttons() -> void:
	var empty: bool=move_menu!=null and moves[move_menu.selected].kind=="sequence" and chain_data.is_empty()
	if is_instance_valid(play_button):play_button.disabled=empty
	if is_instance_valid(repeat_play_button):
		repeat_play_button.disabled=empty
		repeat_play_button.text="Stop Repeat" if repeat_playing else "Repeat Play"

func stop_repeat_play() -> void:
	repeat_playing=false
	repeat_wait=0
	update_playback_buttons()

func toggle_repeat_play() -> void:
	if repeat_playing:
		reset_setup()
		return
	if moves[move_menu.selected].kind=="sequence" and chain_data.is_empty():return
	run_setup()
	repeat_playing=true
	repeat_cycles=1
	update_playback_buttons()

func tick_repeat_play(delta: float) -> void:
	if not repeat_playing or get_tree().paused:return
	var complete: bool=finished or (catalog[0].kind=="sequence" and started and not sequence.active and actor.is_on_floor() and field.shots.is_empty() and field.channels.is_empty())
	if not complete:
		repeat_wait=0
		return
	# Give landing and impact a short readable pause before resetting the setup.
	repeat_wait+=delta
	if repeat_wait<0.75:return
	repeat_wait=0
	repeat_cycles+=1
	if field.events.size()>4000:field.events=field.events.slice(-2000)
	prepare_setup(true)

func perform_case() -> void:
	if partner_jumps():
		target.start_jump("flip")
		target.air_momentum=Vector3.ZERO
		partner_jumping=true
	if catalog[0].kind=="sequence":
		sequence.start(actor,chosen_steps(),dash_direction_menu.selected,chain_profiles)
		return
	if catalog[0].get("sandbox_air",false):
		actor.start_jump("flip")
		actor.air_momentum=Vector3.ZERO
		pending_air_action=true
	else:
		super.perform_case()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(field):
		return
	if not armed:
		update_camera(delta)
		return
	if not get_tree().paused:
		if catalog[0].kind=="sequence" and not sequence.needs_mana(chosen_steps()):
			actor.mana=0 # Motion chains stay physical, including long chains.
		sequence.tick(actor,delta)
		if partner_jumping and not partner_air_ready and target.mode=="flip":
			partner_air_ready=true
			target.mode="air"
			target.mode_time=0
			if catalog[0].has("block"):
				set_shield(target,catalog[0].block,9.0)
		if pending_air_action and actor.mode=="flip":
			pending_air_action=false
			actor.mode="air"
			super.perform_case()
	super._physics_process(delta)
	show_resources()
	var damage: float=target.damage_taken-marks.damage
	var absorbed: int=target.blocks-marks.blocks
	result_label.text="%s  ·  Damage %.1f  ·  Blocks %d  ·  Guard breaks %d"%["Finished — replay or change settings" if finished else ("Paused" if get_tree().paused else "Running"),damage,absorbed,target.guard_breaks-marks.guard_breaks]
	if catalog[0].kind=="sequence":
		result_label.text+="  ·  "+("Grounded" if actor.is_on_floor() else "Airborne")+"  ·  "+sequence.status
	if repeat_playing:result_label.text+="  ·  Repeat %d"%repeat_cycles
	tick_repeat_play(delta)

func show_resources() -> void:
	resources_label.text="Caster: HP %d · Mana %d · Stamina %d · Armor %d   |   Partner: HP %d · Guard %d   |   Current distance %.1f m"%[ceili(actor.health),floori(actor.mana),floori(actor.stamina),ceili(actor.armor_hp),ceili(target.health),floori(target.guard_energy),Vector2(actor.position.x-target.position.x,actor.position.z-target.position.z).length()]

func update_camera(delta: float) -> void:
	if camera_initialized:return
	super.update_camera(1)
	inspection_camera.capture_view(field.camera,field.camera.position.distance_to((actor.focus_position()+target.focus_position())*0.5+Vector3.UP))
	camera_initialized=true

func take_camera_control() -> void:
	inspection_camera.take_control(field.camera,(actor.focus_position()+target.focus_position())*0.5+Vector3.UP*0.35)

func reframe_camera() -> void:
	stop_camera_drag()
	camera_initialized=false
	update_camera(1)

func camera_text_editing() -> bool:
	if get_viewport().gui_get_focus_owner() is LineEdit or move_menu.get_popup().visible or block_menu.get_popup().visible or dash_direction_menu.get_popup().visible:
		return true
	return false

func _process(delta: float) -> void:
	if not is_instance_valid(field):
		return
	if camera_input_enabled and camera_keyboard_enabled() and get_window().has_focus() and not camera_text_editing():
		var direction:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		if direction.length_squared()>0:
			take_camera_control()
			inspection_camera.move(direction,delta/maxf(Engine.time_scale,0.01),Input.is_physical_key_pressed(KEY_SHIFT))
	if inspection_camera.manual:
		inspection_camera.apply(field.camera)

func camera_keyboard_enabled() -> bool:
	return true

func stop_camera_drag() -> void:
	if camera_dragging:
		camera_dragging=false
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		Input.warp_mouse(camera_mouse_origin)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		stop_camera_drag()

func release_camera_text_focus(event: InputEvent) -> void:
	var focused:=get_viewport().gui_get_focus_owner()
	if not focused is LineEdit:return
	if event is InputEventMouseButton and event.pressed:
		# Panels consume clicks before _unhandled_input, so handle focus here.
		# Include the spinner arrows in the field's interactive area.
		var field_control:Control=focused.get_parent() if focused.get_parent() is SpinBox else focused
		if not field_control.get_global_rect().has_point(event.position):
			if field_control is SpinBox:field_control.apply()
			focused.release_focus()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_ESCAPE]:
		# Let the field submit/revert first, then return the keyboard to the camera.
		focused.release_focus.call_deferred()

func _input(event: InputEvent) -> void:
	release_camera_text_focus(event)
	# Release even over a menu so the cursor can never remain captured.
	if camera_dragging:
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE and not event.pressed:
			stop_camera_drag()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion:
			inspection_camera.orbit(event.relative)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not camera_input_enabled or not event is InputEventMouseButton or not event.pressed:
		return
	var focused:=get_viewport().gui_get_focus_owner()
	if focused is LineEdit:
		focused.release_focus()
	if event.button_index==MOUSE_BUTTON_MIDDLE:
		take_camera_control()
		camera_mouse_origin=event.position
		camera_dragging=true
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		take_camera_control()
		inspection_camera.zoom(1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1)
	else:
		return
	get_viewport().set_input_as_handled()

func update_controls() -> void:
	if pause_button!=null:
		pause_button.text="Pause [Space]" if not get_tree().paused else ("Run [Space]" if not armed else "Resume [Space]")
	if slow_button!=null:
		slow_button.text="Normal [T]" if Engine.time_scale<1 else "Slow [T]"

func toggle_pause() -> void:
	if not armed:
		run_setup()
	else:
		super.toggle_pause()

func open_tour() -> void:
	get_tree().paused=false
	Engine.time_scale=1
	field.audio.stop_all()
	get_tree().change_scene_to_file("res://scenes/combat_showcase.tscn")

func return_home() -> void:
	stop_camera_drag()
	get_tree().paused=false
	Engine.time_scale=1
	field.audio.stop_all()
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN:
			take_camera_control()
			inspection_camera.orbit(Vector2(-15 if event.keycode==KEY_LEFT else (15 if event.keycode==KEY_RIGHT else 0),-15 if event.keycode==KEY_UP else (15 if event.keycode==KEY_DOWN else 0)))
			inspection_camera.apply(field.camera)
		KEY_PAGEUP,KEY_PAGEDOWN:
			take_camera_control()
			inspection_camera.zoom(1 if event.keycode==KEY_PAGEUP else -1)
			inspection_camera.apply(field.camera)
		KEY_R,KEY_ENTER: run_setup()
		KEY_X: reset_setup()
		KEY_SPACE: toggle_pause()
		KEY_T: toggle_slow()
		KEY_B:
			get_viewport().set_input_as_handled()
			return_to_battle()
			return
		KEY_M:
			field.audio.muted=not field.audio.muted
			if field.audio.muted:field.audio.stop_all()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			return_home()
			return
		_: return
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	stop_camera_drag()
	super._exit_tree()
