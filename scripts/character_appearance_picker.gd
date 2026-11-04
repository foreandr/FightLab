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
var search: LineEdit
var library_status: Label
var filtered: Array = []
func _ready() -> void:
	WardrobeLibrary.catalog_ready.connect(_library_ready)
func _library_ready() -> void:
	if slot.is_empty() or slot == "hair": return
	creator.refresh_appearance_items(slot)
	if is_instance_valid(grid): show_page()
func open_section(key: String, definition: Dictionary) -> void:
	slot = key; settings = definition; page = 0
	for child in get_children(): remove_child(child); child.queue_free()
	thumbnails = preload("res://scripts/character_appearance_thumbnails.gd").new()
	add_child(thumbnails)
	var heading := HBoxContainer.new(); add_child(heading)
	var back := Button.new(); back.text = "‹ Back"; back.pressed.connect(creator.close_appearance_section); heading.add_child(back)
	var title := Label.new(); title.text = str(settings.title); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 26); heading.add_child(title)
	search = LineEdit.new(); search.placeholder_text = "Search names, creator or source…"; search.text_changed.connect(func(_text: String): page = 0; show_page()); add_child(search)
	library_status = Label.new(); library_status.add_theme_font_size_override("font_size",13); library_status.add_theme_color_override("font_color",Design.MUTED); library_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(library_status)
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
	# Keep color and size immediately accessible even with a large paged library.
	move_child(color_row,grid.get_index())
	if not str(settings.size_key).is_empty():
		move_child(size_label,grid.get_index())
		move_child(size_slider,grid.get_index())
	show_page()
	back.grab_focus()
func update_size_label(value: float) -> void: size_label.text = "Size  %d%%" % roundi(value * 100.0)
func show_page() -> void:
	thumbnails.jobs.clear()
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	cards.clear()
	filtered.clear()
	var query := search.text.strip_edges().to_lower()
	for item in settings.items:
		if query.is_empty() or query in (str(item.name)+" "+str(item.get("author",""))+" "+str(item.get("source",""))).to_lower(): filtered.append(item)
	var total := maxi(1,ceili(filtered.size() / 6.0))
	page = clampi(page,0,total-1); previous.disabled = page == 0; next.disabled = page >= total-1
	page_label.text = "%d / %d  ·  %d items" % [page+1,total,filtered.size()]
	library_status.text = "Loading reviewed clothing…" if slot != "hair" and not WardrobeLibrary.loaded else ("No matching items" if filtered.is_empty() else "")
	library_status.visible = not library_status.text.is_empty()
	for index in range(page*6,mini(page*6+6,filtered.size())):
		var item: Dictionary = filtered[index]
		var value := str(item.value)
		var label := str(item.name)
		var card := Button.new(); card.custom_minimum_size = Vector2(125,125); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card.toggle_mode = true; card.button_pressed = str(creator.profile.get(slot,"")) == value
		card.tooltip_text = label + ("\n" + str(item.get("source","")) if item.has("source") else ""); grid.add_child(card); cards.append(card)
		var layout := VBoxContainer.new(); layout.mouse_filter = Control.MOUSE_FILTER_IGNORE; layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout.offset_left = 6; layout.offset_right = -6; layout.offset_top = 6; layout.offset_bottom = -6; card.add_child(layout)
		var picture := TextureRect.new(); picture.custom_minimum_size = Vector2(110,85); picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL; picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; picture.mouse_filter = Control.MOUSE_FILTER_IGNORE; layout.add_child(picture)
		var caption := Label.new(); caption.text = label; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; caption.add_theme_font_size_override("font_size",14); caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; layout.add_child(caption)
		var candidate: Dictionary = creator.appearance_candidate(slot,value); candidate.rotation = 0.0
		thumbnails.request(candidate,slot,picture)
		card.pressed.connect(func():
			creator.choose_appearance(slot,value)
			for other in cards: other.set_pressed_no_signal(other == card)
		)
