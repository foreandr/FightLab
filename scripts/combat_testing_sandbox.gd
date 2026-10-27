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
var chain_menu: Array[OptionButton]=[]
var chain_panel: HBoxContainer
var dash_direction_menu: OptionButton
const MAX_CHAIN_STEPS := 32
var chain_steps: HBoxContainer
var chain_scroll: ScrollContainer
var add_step_button: Button
var remove_step_button: Button
var chain_count: Label

func _ready() -> void:
	auto_advance=false
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
	chain_count=menu_label(chain_panel,"Chain",14)
	add_step_button=button(chain_panel,"+",add_chain_step)
	add_step_button.custom_minimum_size=Vector2(36,32)
	add_step_button.tooltip_text="Add an animation to the end of the combo"
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
	append_chain_slot(0)
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
	button(actions,"Run / Replay [R]",run_setup)
	button(actions,"Reset [X]",reset_setup)
	slow_button=button(actions,"Slow [T]",toggle_slow)
	button(actions,"Home [Esc]",return_home)
	result_label=menu_label(footer,"Ready — choose a move, then Run",15)
	menu_label(footer,"Camera: WASD move · Q/E height · Hold middle mouse rotate · Wheel zoom · F reframe · Shift faster",13)
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
		hint_label.text="Choose the first animation; + adds steps. Jump unlocks Flip / Twist. Land restores grounded moves."
	elif entry.kind in ["melee","uppercut"]:
		hint_label.text+="Suggested melee distance: %.2f m. Distant strikes can miss."%float(entry.distance)
	elif jump_toggle.button_pressed:
		hint_label.text+="Jump casts use the quick release; held charge is grounded."
	else:
		hint_label.text+="Settings reset the fighters. Run plays the setup once."
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
	var steps: Array[String]=[]
	for slot in chain_menu:
		if slot.selected==0:break
		steps.append(sequence.OPTIONS[slot.selected])
	return steps

func refresh_chain_options() -> void:
	var grounded:=true
	var ended:=false
	for slot in chain_menu:
		slot.disabled=ended
		slot.tooltip_text="After landing: ground moves" if grounded else "Airborne: Flip, Twist or Land"
		for i in sequence.OPTIONS.size():
			var allowed: bool=sequence.allowed_for_state(sequence.OPTIONS[i],grounded)
			slot.set_item_disabled(i,not allowed)
			slot.set_item_tooltip(i,"" if allowed else ("Requires airborne — add Jump first" if grounded else "Requires grounded — add Land first"))
		if ended or not sequence.allowed_for_state(sequence.OPTIONS[slot.selected],grounded):
			slot.select(0)
		var step: String=sequence.OPTIONS[slot.selected]
		if step=="End":ended=true
		grounded=sequence.state_after(step,grounded)
	chain_count.text="Chain (%d)"%chain_menu.size()
	add_step_button.disabled=chosen_steps().size()>=MAX_CHAIN_STEPS
	remove_step_button.disabled=chain_menu.size()<=1

func append_chain_slot(choice: int=0) -> void:
	var row:=HBoxContainer.new()
	chain_steps.add_child(row)
	if not chain_menu.is_empty():menu_label(row,"→",15)
	var slot:=OptionButton.new()
	slot.custom_minimum_size=Vector2(115,30)
	for text_ in sequence.OPTIONS:slot.add_item(text_)
	slot.select(choice)
	slot.focus_mode=Control.FOCUS_NONE
	slot.item_selected.connect(func(_index):settings_changed())
	row.add_child(slot)
	chain_menu.append(slot)

func resize_chain(count: int) -> void:
	count=clampi(count,1,MAX_CHAIN_STEPS)
	while chain_menu.size()>count:
		var slot: OptionButton=chain_menu.pop_back()
		var row:=slot.get_parent()
		chain_steps.remove_child(row)
		row.queue_free()
	while chain_menu.size()<count:append_chain_slot()

func add_chain_step() -> void:
	var steps:=chosen_steps()
	if steps.size()>=MAX_CHAIN_STEPS:return
	var grounded:=true
	for step in steps:grounded=sequence.state_after(step,grounded)
	# Replace unused End placeholders so + always creates an editable active step.
	resize_chain(steps.size()+1)
	chain_menu[-1].select(1 if grounded else 6)
	settings_changed()
	reveal_last_chain_step()

func reveal_last_chain_step() -> void:
	await get_tree().process_frame
	if is_inside_tree() and not chain_menu.is_empty():
		chain_scroll.ensure_control_visible(chain_menu[-1])

func remove_chain_step() -> void:
	if chain_menu.size()<=1:return
	resize_chain(chain_menu.size()-1)
	settings_changed()

func set_chain(steps: Array) -> void:
	move_menu.select(0)
	resize_chain(maxi(1,steps.size()))
	for i in chain_menu.size():
		chain_menu[i].select(maxi(0,sequence.OPTIONS.find(steps[i])) if i<steps.size() else 0)
	settings_changed()

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
	result_label.text="Ready — Run plays this setup; Reset restores both fighters."
	update_controls()

func reset_setup() -> void:
	prepare_setup(false)

func run_setup() -> void:
	prepare_setup(true)

func perform_case() -> void:
	if partner_jumps():
		target.start_jump("flip")
		target.air_momentum=Vector3.ZERO
		partner_jumping=true
	if catalog[0].kind=="sequence":
		sequence.start(actor,chosen_steps(),dash_direction_menu.selected)
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
	for slot in chain_menu:
		if slot.get_popup().visible:return true
	return false

func _process(delta: float) -> void:
	if not is_instance_valid(field):
		return
	if camera_input_enabled and get_window().has_focus() and not camera_text_editing():
		var direction:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		if direction.length_squared()>0:
			take_camera_control()
			inspection_camera.move(direction,delta/maxf(Engine.time_scale,0.01),Input.is_physical_key_pressed(KEY_SHIFT))
	if inspection_camera.manual:
		inspection_camera.apply(field.camera)

func stop_camera_drag() -> void:
	if camera_dragging:
		camera_dragging=false
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		Input.warp_mouse(camera_mouse_origin)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		stop_camera_drag()

func _input(event: InputEvent) -> void:
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
		KEY_R,KEY_ENTER: run_setup()
		KEY_X: reset_setup()
		KEY_SPACE: toggle_pause()
		KEY_T: toggle_slow()
		KEY_F: reframe_camera()
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
