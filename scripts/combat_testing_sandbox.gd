extends "res://scripts/combat_showcase.gd"
## User-configurable scenarios share the showcase's real combat/reset paths.
var moves: Array[Dictionary]=[]
var move_menu: OptionButton
var distance_input: SpinBox
var block_menu: OptionButton
var jump_toggle: CheckBox
var target_jump_toggle: CheckBox
var charge_toggle: CheckBox
var weak_toggle: CheckBox
var repeat_toggle: CheckBox
var hint_label: Label
var armed := false
var configuring := true
var pending_air_action := false
var partner_jumping := false
var partner_air_ready := false

func _ready() -> void:
	auto_advance=false
	camera_upper_allowance=0.40
	super._ready()
	configuring=false
	settings_changed()

func build_ui() -> void:
	var ids: Array[String]=["fireball_ground","cinder_slash_ground","freezing_ray_ground","armor_ground","overdrive_ground","flash_ground","melee_0","melee_1","melee_4","melee_2","melee_5","melee_3","uppercut","fire_kick","ice_knee","shield_palm","shield_brace","armor_fireball","armor_punch","overdrive_run","flash_overdrive","movement_run","movement_approach","movement_retreat","movement_strafe_left","movement_strafe_right","movement_dodge_back","movement_roll_back","movement_flip","death_fireball","death_punch"]
	for id in ids:
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
	title_label=menu_label(column,"COMBAT SANDBOX",20)
	var row:=HBoxContainer.new()
	row.alignment=BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",10)
	column.add_child(row)
	menu_label(row,"Move",15)
	move_menu=OptionButton.new()
	move_menu.custom_minimum_size=Vector2(350,32)
	for entry in moves:
		var name_: String=entry.title.replace(" — Ground Cast","").replace(" — Unblocked","")
		move_menu.add_item(["FIRE","ICE","STORM"][entry.team]+"  /  "+name_)
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
	for text_ in ["Partner: No block","Partner: Palm shield","Partner: Brace shield"]:
		block_menu.add_item(text_)
	row.add_child(block_menu)
	var options:=HBoxContainer.new()
	options.alignment=BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation",12)
	column.add_child(options)
	jump_toggle=checkbox(options,"Caster jumps")
	target_jump_toggle=checkbox(options,"Partner jumps")
	charge_toggle=checkbox(options,"Charged cast")
	weak_toggle=checkbox(options,"Weaken guard")
	repeat_toggle=checkbox(options,"Repeat setup")
	hint_label=menu_label(column,"",13)
	detail_label=menu_label(column,"",13)
	resources_label=menu_label(column,"",13)
	var bottom:=PanelContainer.new()
	bottom.add_theme_stylebox_override("panel",panel_style)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top=-80
	ui.add_child(bottom)
	var footer:=VBoxContainer.new()
	bottom.add_child(footer)
	var actions:=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",8)
	footer.add_child(actions)
	button(actions,"Run / Replay [R]",run_setup)
	button(actions,"Reset [X]",reset_setup)
	pause_button=button(actions,"Pause [Space]",toggle_pause)
	slow_button=button(actions,"Slow [S]",toggle_slow)
	button(actions,"54-case tour",open_tour)
	button(actions,"Battle [B]",return_to_battle)
	result_label=menu_label(footer,"Ready — choose a move, then Run",15)
	move_menu.item_selected.connect(func(_index):settings_changed())
	distance_input.value_changed.connect(func(_value):settings_changed())
	block_menu.item_selected.connect(func(_index):settings_changed())
	for toggle in [jump_toggle,target_jump_toggle,charge_toggle,weak_toggle]:
		toggle.toggled.connect(func(_value):settings_changed())
	# Space belongs to pause; arrows belong to the menu when it has focus.
	for node in [move_menu,block_menu,jump_toggle,target_jump_toggle,charge_toggle,weak_toggle,repeat_toggle]:
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
	var can_jump: bool=entry.kind in ["spell","melee","uppercut","shield"]
	jump_toggle.disabled=not can_jump
	if not can_jump:
		jump_toggle.set_pressed_no_signal(false)
	var can_charge: bool=entry.id in ["fireball_ground","cinder_slash_ground","freezing_ray_ground"] and not jump_toggle.button_pressed
	charge_toggle.disabled=not can_charge
	if not can_charge:
		charge_toggle.set_pressed_no_signal(false)
	charge_toggle.tooltip_text="Held charge is available for grounded Fireball, Cinder Slash and Freezing Ray. Jump casts are quick; Flash Step and uppercut include their own charge."
	weak_toggle.disabled=block_menu.selected==0
	if weak_toggle.disabled:
		weak_toggle.set_pressed_no_signal(false)
	hint_label.text="Spawn distance is center to center. "
	if entry.kind in ["melee","uppercut"]:
		hint_label.text+="Suggested melee distance: %.2f m. Distant strikes can miss."%float(entry.distance)
	elif jump_toggle.button_pressed:
		hint_label.text+="Jump casts use the quick release; held charge is grounded."
	else:
		hint_label.text+="Settings reset the stage. Run plays once; Repeat replays the same setup."
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
	if block_menu.selected>0:
		entry.block="palm" if block_menu.selected==1 else "brace"
		entry.weak_guard=weak_toggle.button_pressed
	return entry

func prepare_setup(run: bool) -> void:
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
	title_label.text="COMBAT SANDBOX  ·  "+str(catalog[0].title).replace(" — Ground Cast","").replace(" — Unblocked","")
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
	if target_jump_toggle.button_pressed:
		target.start_jump("flip")
		target.air_momentum=Vector3.ZERO
		partner_jumping=true
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
	if finished and repeat_toggle.button_pressed and not get_tree().paused:
		run_setup()

func show_resources() -> void:
	resources_label.text="Caster: HP %d · Mana %d · Stamina %d · Armor %d   |   Partner: HP %d · Guard %d   |   Current distance %.1f m"%[ceili(actor.health),floori(actor.mana),floori(actor.stamina),ceili(actor.armor_hp),ceili(target.health),floori(target.guard_energy),Vector2(actor.position.x-target.position.x,actor.position.z-target.position.z).length()]

func update_controls() -> void:
	if pause_button==null:
		return
	pause_button.text="Pause [Space]" if not get_tree().paused else ("Run [Space]" if not armed else "Resume [Space]")
	slow_button.text="Normal [S]" if Engine.time_scale<1 else "Slow [S]"

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

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R,KEY_ENTER: run_setup()
		KEY_X: reset_setup()
		KEY_SPACE: toggle_pause()
		KEY_S: toggle_slow()
		KEY_B:
			get_viewport().set_input_as_handled()
			return_to_battle()
			return
		KEY_M:
			field.audio.muted=not field.audio.muted
			if field.audio.muted:field.audio.stop_all()
		KEY_ESCAPE:
			get_tree().paused=false
			write_report()
			field.finish_run()
		_: return
	get_viewport().set_input_as_handled()
