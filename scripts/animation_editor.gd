extends "res://scripts/combat_testing_sandbox.gd"
const Library=preload("res://scripts/animation_catalog.gd")
var browser: Control
var category_list: VBoxContainer
var animation_list: VBoxContainer
var category_heading: Label
var preview_heading: Label
var preview_note: Label
var selection_status: Label
var library_buttons: Dictionary={}
var library_add_buttons: Dictionary={}
var category_buttons: Dictionary={}
var group_buttons: Dictionary={}
var selected_group := "Motion"
var selected_category := "Run"
var selected_entry: Dictionary={}
var settings_row: HBoxContainer
var browse_backdrop: ColorRect
var chain_backdrop: Panel
var live_preview_sequence=preload("res://scripts/motion_sequence.gd").new()
var live_preview_steps: Array[String]=[]
var live_preview_age := 0.0
var live_preview_started := false
var live_preview_loops := 0

func _ready() -> void:
	super._ready()
	field.show()
	browse_backdrop.hide()
	layout_chain(true)
	begin_live_preview()

func build_ui() -> void:
	# Retain the proven playback controller and its controls, then give animation
	# browsing a dedicated UI. The spell workspace keeps its own existing layout.
	super.build_ui()
	for child in get_children():
		if child is CanvasLayer:child.hide()
	var layer:=CanvasLayer.new()
	add_child(layer)
	var ui:=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	browse_backdrop=ColorRect.new()
	browse_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	browse_backdrop.color=Color("0b1420")
	browse_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(browse_backdrop)
	var header:=panel(ui,Vector4(0,0,0,86),true)
	title_label.reparent(header)
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_left=20
	title_label.offset_top=10
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	var tabs:=HBoxContainer.new()
	tabs.position=Vector2(20,43)
	tabs.add_theme_constant_override("separation",10)
	header.add_child(tabs)
	for group in ["Motion","Attack"]:
		var tab:=button(tabs,group.to_upper(),func():select_group(group))
		tab.custom_minimum_size=Vector2(160,34)
		group_buttons[group]=tab
	selection_status=menu_label(header,"Hover to preview · + adds to chain",14)
	selection_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	selection_status.offset_left=-650
	selection_status.offset_right=-20
	selection_status.offset_top=49
	selection_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	browser=Control.new()
	browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	browser.offset_top=90
	browser.offset_bottom=-250
	browser.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(browser)
	var categories:=panel(browser,Vector4(12,0,164,0))
	categories.anchor_bottom=1
	category_list=VBoxContainer.new()
	category_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	category_list.offset_left=8
	category_list.offset_top=8
	category_list.offset_right=-8
	category_list.offset_bottom=-8
	category_list.add_theme_constant_override("separation",5)
	categories.add_child(category_list)
	var choices:=panel(browser,Vector4(176,0,450,0))
	choices.anchor_bottom=1
	var choices_column:=VBoxContainer.new()
	choices_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices_column.offset_left=10
	choices_column.offset_right=-10
	choices_column.offset_top=10
	choices_column.offset_bottom=-10
	choices.add_child(choices_column)
	category_heading=menu_label(choices_column,"Animations",19)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	choices_column.add_child(scroll)
	animation_list=VBoxContainer.new()
	animation_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	animation_list.add_theme_constant_override("separation",8)
	scroll.add_child(animation_list)
	var preview_panel:=panel(browser,Vector4(462,0,-12,62),true)
	var preview_column:=VBoxContainer.new()
	preview_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_column.offset_left=8
	preview_column.offset_right=-8
	preview_column.offset_top=8
	preview_column.offset_bottom=-8
	preview_panel.add_child(preview_column)
	preview_heading=menu_label(preview_column,"Animation preview",20)
	preview_note=menu_label(preview_column,"Looping preview · + adds to chain",13)
	chain_backdrop=panel(ui,Vector4(0,0,0,0),true)
	chain_panel.reparent(ui)
	chain_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	chain_panel.offset_left=16
	chain_panel.offset_right=-16
	settings_row=HBoxContainer.new()
	settings_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	settings_row.offset_left=16
	settings_row.offset_right=-16
	settings_row.alignment=BoxContainer.ALIGNMENT_CENTER
	settings_row.add_theme_constant_override("separation",10)
	ui.add_child(settings_row)
	menu_label(settings_row,"Distance (m)",13)
	for node in [distance_input,dash_direction_menu,block_menu]:node.reparent(settings_row)
	var bottom:=panel(ui,Vector4(0,-124,0,0),true)
	bottom.anchor_top=1
	bottom.anchor_bottom=1
	var footer:=VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.offset_top=8
	bottom.add_child(footer)
	var actions:=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",8)
	footer.add_child(actions)
	play_button=button(actions,"Play [R]",run_setup)
	repeat_play_button=button(actions,"Repeat Play",toggle_repeat_play)
	button(actions,"Reset [X]",reset_setup)
	slow_button=button(actions,"Slow [T]",toggle_slow)
	button(actions,"Browse",browse_animations)
	button(actions,"Home [Esc]",return_home)
	result_label.reparent(footer)
	resources_label.reparent(footer)
	menu_label(footer,"Hover previews live · + adds to chain · × removes · WASD / middle mouse / wheel camera controls",13)
	populate_group("Motion")

func panel(parent: Node,bounds: Vector4,wide:=false) -> Panel:
	var node:=Panel.new()
	if wide:node.anchor_right=1
	node.offset_left=bounds.x
	node.offset_top=bounds.y
	node.offset_right=bounds.z
	node.offset_bottom=bounds.w
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("142333")
	node.add_theme_stylebox_override("panel",style)
	parent.add_child(node)
	return node

func clear_list(container: Node) -> void:
	for node in container.get_children():
		container.remove_child(node)
		node.queue_free()

func select_group(group: String) -> void:
	browse_animations()
	populate_group(group)

func populate_group(group: String) -> void:
	selected_group=group
	clear_list(category_list)
	category_buttons.clear()
	for tab in group_buttons:
		group_buttons[tab].modulate=Color("f2ce85") if tab==group else Color.WHITE
	for category in Library.GROUPS[group]:
		var node:=button(category_list,category,func():select_category(category))
		node.custom_minimum_size=Vector2(130,34)
		category_buttons[category]=node
	select_category(Library.GROUPS[group][0])

func select_category(category: String) -> void:
	selected_category=category
	clear_list(animation_list)
	library_buttons.clear()
	library_add_buttons.clear()
	category_heading.text=category
	for name_ in category_buttons:
		category_buttons[name_].modulate=Color("f2ce85") if name_==category else Color.WHITE
	for entry in Library.entries():
		if entry.group!=selected_group or entry.category!=category:continue
		var row:=HBoxContainer.new()
		animation_list.add_child(row)
		var node:=button(row,entry.title,func():preview_animation(entry))
		node.custom_minimum_size=Vector2(190,42)
		node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		node.add_theme_font_size_override("font_size",15)
		node.mouse_entered.connect(func():preview_animation(entry))
		node.focus_entered.connect(func():preview_animation(entry))
		node.tooltip_text="Hover or click to preview. Use + to add to the chain."
		library_buttons[entry.step]=node
		var add:=button(row,"+",func():add_library_animation(entry))
		add.custom_minimum_size=Vector2(38,42)
		add.mouse_entered.connect(func():preview_animation(entry))
		library_add_buttons[entry.step]=add
	refresh_library_add_buttons()
	if not library_buttons.is_empty():
		for entry in Library.entries():
			if entry.group==selected_group and entry.category==category:
				preview_animation(entry)
				break

func refresh_chain_options() -> void:
	super.refresh_chain_options()
	refresh_library_add_buttons()

func refresh_library_add_buttons() -> void:
	for step in library_add_buttons:
		var add: Button=library_add_buttons[step]
		add.disabled=not can_append_animation(step)
		add.tooltip_text="Add "+step+" to the chain" if not add.disabled else ("Chain is full" if chain_data.size()>=MAX_CHAIN_STEPS else ("Add Jump first" if step in ["Flip","Twist","Land"] else "Add Land before a grounded move"))

func preview_animation(entry: Dictionary) -> void:
	selected_entry=entry.duplicate()
	preview_heading.text=entry.title
	preview_note.text="Live arena - hover loops the real action"
	if is_instance_valid(actor):begin_live_preview()

func add_library_animation(entry: Dictionary) -> void:
	var steps:=chosen_steps()
	if steps.size()>=MAX_CHAIN_STEPS:
		selection_status.text="Chain is full"
		return
	var grounded:=true
	for step in steps:grounded=sequence.state_after(step,grounded)
	if not sequence.allowed_for_state(entry.step,grounded):
		selection_status.text="Add Jump first" if grounded else "Add Land before a grounded move"
		return
	steps.append(entry.step)
	set_chain(steps)
	selection_status.text="Added: "+entry.title
	reveal_last_chain_step()

func layout_chain(browsing: bool) -> void:
	if browsing:
		chain_backdrop.anchor_top=1
		chain_backdrop.anchor_bottom=1
		chain_backdrop.offset_top=-240
		chain_backdrop.offset_bottom=-128
		chain_panel.anchor_top=1
		chain_panel.anchor_bottom=1
		chain_panel.offset_top=-240
		chain_panel.offset_bottom=-184
		settings_row.anchor_top=1
		settings_row.anchor_bottom=1
		settings_row.offset_top=-180
		settings_row.offset_bottom=-136
	else:
		chain_backdrop.anchor_top=0
		chain_backdrop.anchor_bottom=0
		chain_backdrop.offset_top=90
		chain_backdrop.offset_bottom=194
		chain_panel.anchor_top=0
		chain_panel.anchor_bottom=0
		chain_panel.offset_top=90
		chain_panel.offset_bottom=146
		settings_row.anchor_top=0
		settings_row.anchor_bottom=0
		settings_row.offset_top=150
		settings_row.offset_bottom=190

func run_setup() -> void:
	if is_instance_valid(browser):
		browser.hide()
		browse_backdrop.hide()
		field.show()
		live_preview_sequence.reset()
		layout_chain(false)
	super.run_setup()

func browse_animations() -> void:
	stop_repeat_play()
	stop_camera_drag()
	browser.show()
	browse_backdrop.hide()
	field.show()
	layout_chain(true)
	begin_live_preview()

func reset_setup() -> void:
	super.reset_setup()
	if not is_instance_valid(browser):return
	if move_menu.selected!=0:
		browser.hide()
		browse_backdrop.hide()
		field.show()
		layout_chain(false)
	elif browser.visible and not selected_entry.is_empty():
		begin_live_preview()

func begin_live_preview(reset_loops: bool=true) -> void:
	if selected_entry.is_empty() or not is_instance_valid(actor):return
	# Reset real fighters/effects without altering the user's composed chain.
	super.reset_setup()
	if field.events.size()>4000:field.events=field.events.slice(-2000)
	live_preview_steps.assign([selected_entry.step])
	if selected_entry.step in ["Flip","Twist"]:
		live_preview_steps.assign(["Jump",selected_entry.step,"Land"])
	elif selected_entry.step=="Land":
		live_preview_steps.assign(["Jump","Land"])
	actor.mana=100 if sequence.needs_mana(live_preview_steps) else 0
	live_preview_sequence.reset()
	live_preview_age=0
	live_preview_started=false
	if reset_loops:live_preview_loops=0
	field.show()
	get_tree().paused=false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(browser) or not browser.visible:
		super._physics_process(delta)
		return
	if get_tree().paused:return
	live_preview_age+=delta
	if not live_preview_started and live_preview_age>=0.25:
		live_preview_started=true
		if partner_jumps():
			target.start_jump("flip")
			target.air_momentum=Vector3.ZERO
			partner_jumping=true
		live_preview_sequence.start(actor,live_preview_steps,dash_direction_menu.selected)
	elif live_preview_started:
		if not sequence.needs_mana(live_preview_steps):actor.mana=0
		live_preview_sequence.tick(actor,delta)
	if partner_jumping and not partner_air_ready and target.mode=="flip":
		partner_air_ready=true
		target.mode="air"
		target.mode_time=0
		if catalog[0].has("block"):set_shield(target,catalog[0].block,9.0)
	update_camera(delta)
	show_resources()
	result_label.text="LIVE ARENA · %s · Damage %.1f · %s"%[selected_entry.title,target.damage_taken-marks.damage,live_preview_sequence.status]
	var cycle: float={"Run":1.8,"Sprint":1.8,"Dash":1.5,"Crouch":1.8,"Block":2.0,"Brace Block":2.0,"Uppercut":5.0,"Spell Throw":3.5,"Slash Throw":3.5}.get(selected_entry.step,2.5)
	if live_preview_age>=cycle:
		begin_live_preview(false)
		live_preview_loops+=1

func update_camera(delta: float) -> void:
	if camera_initialized:return
	if not is_instance_valid(browser) or not browser.visible:
		super.update_camera(delta)
		return
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	var points: Array[Vector3]=[]
	for f in [actor,target]:
		for point in [f.focus_position(),f.bone_point("Head")+Vector3.UP*0.2,f.bone_point("foot_l"),f.bone_point("foot_r")]:
			points.append(point)
			low=low.min(point)
			high=high.max(point)
	var center: Vector3=(low+high)*0.5+Vector3.UP*0.65
	var back:=Vector3(0.15,0.36,1).normalized()
	var right:=Vector3(1,0,-0.15).normalized()
	var up:=back.cross(right).normalized()
	var distance:=12.0
	var aspect: float=get_viewport().get_visible_rect().size.aspect()
	var tangent:=tan(deg_to_rad(field.camera.fov*0.5))
	for point in points:
		var offset:=point-center
		var fit:=maxf(absf(offset.dot(right))/(tangent*aspect*0.5),absf(offset.dot(up))/(tangent*0.4))
		distance=maxf(distance,offset.dot(back)+fit+0.6)
	# One initial composition. No tracking, interpolation, or per-cycle zoom.
	var shift: Vector3=right*(-distance*tangent*aspect*0.40)
	field.camera.position=center+back*distance+shift
	field.camera.look_at(center+shift)
	field.camera.h_offset=0
	field.camera.v_offset=0
	inspection_camera.capture_view(field.camera,distance)
	camera_initialized=true

func _process(delta: float) -> void:
	super._process(delta)

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
