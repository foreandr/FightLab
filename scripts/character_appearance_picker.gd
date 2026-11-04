extends VBoxContainer
## A page inside the existing creator, not a floating dialog.
const Design = preload("res://scripts/ui_design.gd")
var creator: Control
var slot := ""
var settings: Dictionary
var page := 0
var grid: GridContainer
var page_label: Label
var previous: Button
var next: Button
var colors: ColorPickerButton
var size_slider: HSlider
var size_label: Label
var thumbnails: Node
var cards: Array[Button] = []
func open_section(key: String, definition: Dictionary) -> void:
	slot = key; settings = definition; page = 0
	for child in get_children(): remove_child(child); child.queue_free()
	thumbnails = preload("res://scripts/character_appearance_thumbnails.gd").new()
	add_child(thumbnails)
	var heading := HBoxContainer.new(); add_child(heading)
	var back := Button.new(); back.text = "‹ Back"; back.pressed.connect(creator.close_appearance_section); heading.add_child(back)
	var title := Label.new(); title.text = str(settings.title); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 26); heading.add_child(title)
	grid = GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 6); grid.add_theme_constant_override("v_separation", 6); add_child(grid)
	var navigation := HBoxContainer.new(); add_child(navigation)
	previous = Button.new(); previous.text = "‹"; previous.pressed.connect(func(): page -= 1; show_page()); navigation.add_child(previous)
	page_label = Label.new(); page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; navigation.add_child(page_label)
	next = Button.new(); next.text = "›"; next.pressed.connect(func(): page += 1; show_page()); navigation.add_child(next)
	var color_row := HBoxContainer.new(); add_child(color_row)
	var color_title := Label.new(); color_title.text = "Color"; color_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; color_row.add_child(color_title)
	colors = ColorPickerButton.new(); colors.color = creator.profile.get(settings.color_key, Color.WHITE); colors.custom_minimum_size = Vector2(90,36); color_row.add_child(colors)
	colors.color_changed.connect(func(value: Color):
		creator.profile[settings.color_key] = value
		settings.color.color = value
		creator._refresh_preview()
	)
	if not str(settings.size_key).is_empty():
		size_label = Label.new(); add_child(size_label)
		size_slider = HSlider.new(); size_slider.name = "ClothingSize"; size_slider.min_value = 0.85; size_slider.max_value = 1.50; size_slider.step = 0.01
		size_slider.value = float(creator.profile.get(settings.size_key, 1.0)); add_child(size_slider); update_size_label(size_slider.value)
		size_slider.value_changed.connect(func(value: float):
			creator.profile[settings.size_key] = value
			creator.shape_sliders[settings.size_key].set_value_no_signal(value)
			creator._set_preview_wardrobe_size(slot,value)
			update_size_label(value)
		)
	show_page()
	back.grab_focus()
func update_size_label(value: float) -> void: size_label.text = "Size  %d%%" % roundi(value * 100.0)
func show_page() -> void:
	thumbnails.jobs.clear()
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	cards.clear()
	var option: OptionButton = settings.option
	var total := ceili(option.item_count / 6.0)
	page = clampi(page,0,maxi(0,total-1)); previous.disabled = page == 0; next.disabled = page >= total-1
	page_label.text = "%d / %d  ·  %d styles" % [page+1,total,option.item_count]
	for index in range(page*6,mini(page*6+6,option.item_count)):
		var value := option.get_item_text(index)
		var card := Button.new(); card.custom_minimum_size = Vector2(125,125); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card.toggle_mode = true; card.button_pressed = str(creator.profile.get(slot,"")) == value
		card.tooltip_text = value; grid.add_child(card); cards.append(card)
		var layout := VBoxContainer.new(); layout.mouse_filter = Control.MOUSE_FILTER_IGNORE; layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout.offset_left = 6; layout.offset_right = -6; layout.offset_top = 6; layout.offset_bottom = -6; card.add_child(layout)
		var picture := TextureRect.new(); picture.custom_minimum_size = Vector2(110,85); picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL; picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; picture.mouse_filter = Control.MOUSE_FILTER_IGNORE; layout.add_child(picture)
		var caption := Label.new(); caption.text = value; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; caption.add_theme_font_size_override("font_size",14); caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; layout.add_child(caption)
		var candidate: Dictionary = creator.profile.duplicate(true); candidate[slot] = value; candidate.rotation = 0.0
		thumbnails.request(candidate,slot,picture)
		card.pressed.connect(func():
			creator.choose_appearance(slot,value)
			for other in cards: other.set_pressed_no_signal(other == card)
		)
