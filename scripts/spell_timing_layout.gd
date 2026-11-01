extends RefCounted
## Presentation only. The builder retains every value, signal and cost rule.
static func card(builder:Node,parent:Control,title:String) -> VBoxContainer:
	var panel:=PanelContainer.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("f1e8d3")
	style.border_color=Color("c9b58f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,8)
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	panel.add_child(column)
	var label:Label=builder.editor.menu_label(column,title.to_upper(),12)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_color_override("font_color",Color("8b7658"))
	return column

static func build(b:Node,column:VBoxContainer) -> void:
	column.add_theme_constant_override("separation",6)
	b.demo_mana_cost_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.demo_mana_cost_label.add_theme_font_size_override("font_size",22)
	var headings:Dictionary={}
	for child in column.get_children():
		if child is Label and child.text in ["Animation duration","Spell timing"]:headings[child.text]=child
	var casting:=card(b,column,"Casting")
	var duration:=HBoxContainer.new()
	casting.add_child(duration)
	headings["Animation duration"].reparent(duration)
	headings["Animation duration"].horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	headings["Animation duration"].size_flags_horizontal=Control.SIZE_EXPAND_FILL
	headings["Animation duration"].add_theme_font_size_override("font_size",16)
	b.demo_duration_label.reparent(duration)
	b.demo_duration_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	b.demo_duration_label.add_theme_font_size_override("font_size",22)
	var length_input:=SpinBox.new()
	length_input.min_value=0.1
	length_input.max_value=60.0
	length_input.step=0.1
	length_input.suffix=" s"
	length_input.custom_minimum_size.x=96
	length_input.value_changed.connect(func(value:float):b.demo_duration_slider.value=value)
	duration.add_child(length_input)
	b.set_meta("cast_length_input",length_input)
	b.demo_duration_slider.custom_minimum_size=Vector2(0,26)
	b.demo_duration_slider.get_parent().reparent(casting)
	b.duration_endpoints.reparent(casting)
	headings["Spell timing"].reparent(casting)
	headings["Spell timing"].horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	headings["Spell timing"].add_theme_font_size_override("font_size",16)
	b.release_slider.custom_minimum_size=Vector2(0,26)
	b.release_slider.get_parent().reparent(casting)
	var timeline:=preload("res://scripts/spell_cast_timeline.gd").new()
	casting.add_child(timeline)
	timeline.setup(b)
	b.set_meta("cast_timeline",timeline)
	b.set_meta("release_heading",headings["Spell timing"])
	var power:=card(b,column,"Power balance")
	b.power_balance_label.hide()
	b.total_power_row.reparent(power)
	b.total_power_row.add_theme_constant_override("separation",6)
	b.total_power_label.custom_minimum_size.x=144
	b.total_power_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	for key in b.allocation_rows:
		b.allocation_rows[key].reparent(power)
		b.allocation_labels[key].custom_minimum_size.x=144
		b.allocation_labels[key].horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		b.allocation_labels[key].add_theme_font_size_override("font_size",14)
		b.allocation_sliders[key].custom_minimum_size.y=20
	var results:=card(b,column,"Results")
	for row in b.test_extra_rows:row.reparent(results)
	for label in [b.demo_stamina_label,b.demo_damage_label,b.demo_ragdoll_label,b.demo_amplifier_label,b.demo_size_bonus_label,b.demo_speed_bonus_label,b.demo_burn_label]:
		label.reparent(results)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("normal_font_size" if label is RichTextLabel else "font_size",12 if label==b.demo_ragdoll_label else 16)
	# Keep detailed values available to tooling, with their explanations on hover.
	for label in [b.demo_mana_base_label,b.demo_stamina_note,b.demo_damage_breakdown,b.demo_amp_breakdown]:label.hide()
	refresh_details(b)

static func refresh_details(b:Node) -> void:
	if b.has_meta("cast_timeline"):
		b.get_meta("cast_length_input").visible=b.limiter_enabled
		b.get_meta("cast_length_input").set_value_no_signal(b.demo_duration_slider.value)
		b.demo_duration_label.visible=not b.limiter_enabled
		b.get_meta("cast_timeline").visible=b.limiter_enabled
		b.demo_duration_slider.get_parent().visible=not b.limiter_enabled
		b.release_slider.get_parent().visible=not b.limiter_enabled
		b.get_meta("release_heading").visible=not b.limiter_enabled
		b.duration_endpoints.hide()
		b.get_meta("cast_timeline").refresh()
	for label in [b.demo_mana_base_label,b.demo_stamina_note,b.demo_damage_breakdown,b.demo_amp_breakdown]:
		if is_instance_valid(label):label.hide()
	if not is_instance_valid(b.demo_damage_label):return
	preload("res://scripts/spell_stat_tooltips.gd").refresh(b)

static func update_ragdoll(b:Node,damage:float) -> void:
	var text:=preload("res://scripts/combat_defense_rules.gd").prediction(damage)
	if "(head only)" in text:text=text.replace("Yes","[color=#b38a21]Yes[/color]")
	b.demo_ragdoll_label.text=text
