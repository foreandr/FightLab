extends Control
## Book 1: chapter ledger, sequential unlocks, and rival record.

const CHARACTER_PATH := "user://story_character.cfg"
const BOOK_COUNT := 5
const CHAPTER_COUNT := 5
const StoryRivals = preload("res://scripts/story_rivals.gd")
const PreviewCharacter = preload("res://scripts/story_character.gd")

var profile: Dictionary = {}
var selected_chapter := 1
var chapter_buttons: Array[Button] = []
var book_detail: VBoxContainer
var fight_button: Button
var loadout_button: Button
var available_stage := 1
var history: Array = []
var selected_tutorial := 1
var selected_book := 1
var view_level := "books"
var introduction_expanded := true
var detail_scroll: ScrollContainer
var contents_entries: VBoxContainer
var book_title_label: Label
var back_button: Button
var loadout_wrapper_control: Control
var intro_toggle: Button
var intro_entries: VBoxContainer
var combat_warning_layer: CanvasLayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var config := ConfigFile.new()
	if config.load(CHARACTER_PATH) != OK:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		return
	profile = config.get_value("character", "profile", {})
	if profile.is_empty():
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		return
	history = profile.get("story_history", [])
	_migrate_unseen_loadout_items()
	available_stage = clampi(int(profile.get("story_stage", 1)), 1, CHAPTER_COUNT)
	selected_chapter = available_stage
	selected_tutorial = 1 if not _tutorial_done(1) else (2 if not _tutorial_done(2) else 0)
	if get_tree().has_meta("story_selected_chapter"):
		selected_chapter = clampi(int(get_tree().get_meta("story_selected_chapter", available_stage)), 1, CHAPTER_COUNT)
		selected_tutorial = 0
		get_tree().remove_meta("story_selected_chapter")
		view_level = "contents"
	elif get_tree().has_meta("story_book_view"):
		view_level = str(get_tree().get_meta("story_book_view", "books"))
		get_tree().remove_meta("story_book_view")
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("302116")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	add_child(margin)
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", _panel_style(Color("e8ddc4"), Color("7e6846"), 8))
	margin.add_child(page)
	var page_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		page_margin.add_theme_constant_override("margin_" + side, 24)
	page.add_child(page_margin)
	var book := VBoxContainer.new()
	book.add_theme_constant_override("separation", 12)
	page_margin.add_child(book)
	var heading := HBoxContainer.new()
	book.add_child(heading)
	book_title_label = Label.new()
	book_title_label.text = "BOOK 1  ·  CHAPTER 1"
	book_title_label.add_theme_font_size_override("font_size", 22)
	book_title_label.add_theme_color_override("font_color", Color("614421"))
	book_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(book_title_label)
	var author := Label.new()
	author.text = str(profile.get("name", "Your character"))
	author.add_theme_color_override("font_color", Color("75664f"))
	heading.add_child(author)
	var rule := ColorRect.new()
	rule.color = Color("b5a27f")
	rule.custom_minimum_size.y = 1
	book.add_child(rule)
	var spread := HBoxContainer.new()
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation", 0)
	book.add_child(spread)
	var left_page := PanelContainer.new()
	left_page.custom_minimum_size.x = 370
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.size_flags_stretch_ratio = 0.85
	left_page.add_theme_stylebox_override("panel", _panel_style(Color("e8ddc4"), Color("b5a27f"), 0))
	spread.add_child(left_page)
	var left_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		left_margin.add_theme_constant_override("margin_" + side, 16)
	left_page.add_child(left_margin)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 8)
	left_margin.add_child(contents)
	var contents_title := Label.new()
	contents_title.text = "CONTENTS"
	contents_title.add_theme_font_size_override("font_size", 18)
	contents_title.add_theme_color_override("font_color", Color("614421"))
	contents.add_child(contents_title)
	var entry_scroll := ScrollContainer.new()
	entry_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contents.add_child(entry_scroll)
	contents_entries = VBoxContainer.new()
	contents_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents_entries.add_theme_constant_override("separation", 4)
	entry_scroll.add_child(contents_entries)
	_populate_hierarchy_entries()
	var spine := ColorRect.new()
	spine.color = Color("b5a27f")
	spine.custom_minimum_size.x = 3
	spine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_child(spine)
	var right_page := PanelContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.size_flags_stretch_ratio = 1.15
	right_page.add_theme_stylebox_override("panel", _panel_style(Color("e8ddc4"), Color("b5a27f"), 0))
	spread.add_child(right_page)
	var right_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		right_margin.add_theme_constant_override("margin_" + side, 40)
	right_page.add_child(right_margin)
	detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_margin.add_child(detail_scroll)
	book_detail = VBoxContainer.new()
	book_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(book_detail)
	var bottom_rule := ColorRect.new()
	bottom_rule.color = Color("b5a27f")
	bottom_rule.custom_minimum_size.y = 1
	book.add_child(bottom_rule)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	book.add_child(actions)
	var replays := Button.new()
	replays.text = "REPLAYS"
	replays.custom_minimum_size.y = 44
	replays.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/story_replays.tscn"))
	actions.add_child(replays)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	loadout_wrapper_control = Control.new()
	loadout_wrapper_control.custom_minimum_size = Vector2(170, 44)
	actions.add_child(loadout_wrapper_control)
	loadout_button = Button.new()
	loadout_button.text = "LOADOUT"
	loadout_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loadout_button.pressed.connect(_open_selected_loadout)
	loadout_wrapper_control.add_child(loadout_button)
	if _has_unseen_loadout_items():
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(45, 21)
		badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		badge.offset_left = -8
		badge.offset_right = 37
		badge.offset_top = -8
		badge.offset_bottom = 13
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("4b9a62")
		badge_style.border_color = Color("2f7044")
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(4)
		badge.add_theme_stylebox_override("panel", badge_style)
		var badge_text := Label.new()
		badge_text.text = "NEW"
		badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_text.add_theme_font_size_override("font_size", 12)
		badge_text.add_theme_color_override("font_color", Color.WHITE)
		badge.add_child(badge_text)
		loadout_wrapper_control.add_child(badge)
	fight_button = Button.new()
	fight_button.text = "FIGHT"
	fight_button.custom_minimum_size = Vector2(170, 44)
	fight_button.pressed.connect(_start_selected_chapter)
	actions.add_child(fight_button)
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(110, 44)
	back_button.pressed.connect(_go_back_in_book)
	actions.add_child(back_button)
	_refresh_detail()
	_update_hierarchy_actions()

func _populate_hierarchy_entries() -> void:
	for child in contents_entries.get_children():
		contents_entries.remove_child(child)
		child.queue_free()
	chapter_buttons.clear()
	intro_toggle = null
	intro_entries = null
	if view_level == "books":
		for book_number in range(1, BOOK_COUNT + 1):
			var unlocked := book_number == 1
			var marker := "▶" if unlocked else "🔒"
			var button := _make_hierarchy_entry("%s  BOOK %d" % [marker, book_number], unlocked, book_number == selected_book)
			button.pressed.connect(_open_book.bind(book_number))
			contents_entries.add_child(button)
	elif view_level == "chapters":
		for chapter_number in range(1, CHAPTER_COUNT + 1):
			var unlocked := selected_book == 1 and chapter_number == 1
			var marker := "▶" if unlocked else "🔒"
			var button := _make_hierarchy_entry("%s  CHAPTER %d" % [marker, chapter_number], unlocked, chapter_number == 1)
			if unlocked:button.pressed.connect(_open_story_chapter)
			contents_entries.add_child(button)
	else:
		intro_toggle = Button.new()
		intro_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		intro_toggle.text = "▼  INTRODUCTION" if introduction_expanded else "▶  INTRODUCTION"
		intro_toggle.custom_minimum_size.y = 48
		intro_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		intro_toggle.add_theme_font_size_override("font_size", 18)
		intro_toggle.add_theme_color_override("font_color", Color("614421"))
		intro_toggle.add_theme_color_override("font_hover_color", Color("614421"))
		intro_toggle.add_theme_color_override("font_pressed_color", Color("614421"))
		intro_toggle.add_theme_color_override("font_focus_color", Color("614421"))
		intro_toggle.add_theme_stylebox_override("normal", _panel_style(Color("ded1b5"), Color("b5a27f"), 4))
		intro_toggle.add_theme_stylebox_override("hover", _panel_style(Color("f0e3c8"), Color("9a7440"), 4))
		intro_toggle.add_theme_stylebox_override("pressed", _panel_style(Color("cfb98c"), Color("9a7440"), 4))
		intro_toggle.add_theme_stylebox_override("focus", _panel_style(Color("ded1b5"), Color("b5a27f"), 4))
		intro_toggle.pressed.connect(func():
			introduction_expanded = not introduction_expanded
			intro_entries.visible = introduction_expanded
			intro_toggle.text = "▼  INTRODUCTION" if introduction_expanded else "▶  INTRODUCTION"
			intro_toggle.add_theme_stylebox_override("normal", _panel_style(Color("d8c7a4") if introduction_expanded else Color("ded1b5"), Color("9a7440") if introduction_expanded else Color("b5a27f"), 4))
		)
		contents_entries.add_child(intro_toggle)
		intro_entries = VBoxContainer.new()
		intro_entries.name = "IntroductionEntries"
		intro_entries.add_theme_constant_override("separation", 4)
		intro_entries.visible = introduction_expanded
		contents_entries.add_child(intro_entries)
		_add_tutorial_entry(intro_entries, 1)
		_add_tutorial_entry(intro_entries, 2)
		var divider := ColorRect.new()
		divider.color = Color("b5a27f")
		divider.custom_minimum_size.y = 1
		contents_entries.add_child(divider)
		for fight_number in range(1, CHAPTER_COUNT + 1):
			_add_chapter_entry(contents_entries, fight_number)

func _make_hierarchy_entry(text_value:String, unlocked:bool, selected:bool) -> Button:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "      " + text_value
	button.disabled = not unlocked
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("50391f") if unlocked else Color("8d877a"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("cfb98c") if selected else Color("ded1b5") if unlocked else Color("d2c7ae"), Color("9a7440") if selected else Color("b5a27f"), 4))
	button.add_theme_stylebox_override("hover", _panel_style(Color("f0e3c8"), Color("9a7440"), 4))
	return button

func _open_book(book_number:int) -> void:
	if book_number != 1:return
	selected_book = book_number
	view_level = "chapters"
	_refresh_hierarchy_view()

func _open_story_chapter() -> void:
	if selected_book != 1:return
	view_level = "contents"
	selected_tutorial = 1 if not _tutorial_done(1) else (2 if not _tutorial_done(2) else 0)
	selected_chapter = available_stage
	_refresh_hierarchy_view()

func _refresh_hierarchy_view() -> void:
	_populate_hierarchy_entries()
	_refresh_detail()
	_update_hierarchy_actions()

func _update_hierarchy_actions() -> void:
	var in_contents := view_level == "contents"
	loadout_wrapper_control.visible = in_contents
	fight_button.visible = in_contents
	back_button.text = "BACK" if view_level == "books" else "PREVIOUS"
	book_title_label.text = "BOOK 1  ·  CHAPTER 1" if in_contents else ("BOOK 1" if view_level == "chapters" else "THE FIGHTLAB CHRONICLES")

func _go_back_in_book() -> void:
	if view_level == "contents":
		view_level = "chapters"
	elif view_level == "chapters":
		view_level = "books"
	else:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		return
	_refresh_hierarchy_view()

func _add_tutorial_entry(parent: VBoxContainer, lesson: int) -> void:
	var done := _tutorial_done(lesson)
	var unlocked := lesson == 1 or _tutorial_done(1)
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "      %s  TUTORIAL %d" % ["✓" if done else ("▶" if unlocked else "🔒"), lesson]
	button.disabled = not unlocked
	button.add_theme_color_override("font_color", Color("52725b") if done else Color("50391f") if unlocked else Color("8d877a"))
	button.add_theme_color_override("font_hover_color", Color("50391f"))
	button.add_theme_color_override("font_pressed_color", Color("50391f"))
	button.add_theme_color_override("font_focus_color", Color("50391f"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("d8c7a4") if selected_tutorial == lesson else Color("ded1b5") if unlocked else Color("d2c7ae"), Color("9a7440") if selected_tutorial == lesson else Color("b5a27f"), 4))
	button.add_theme_stylebox_override("hover", _panel_style(Color("f0e3c8"), Color("9a7440"), 4))
	button.pressed.connect(func(): selected_tutorial = lesson; selected_chapter = 1; _refresh_detail())
	parent.add_child(button)

func _add_chapter_entry(parent: VBoxContainer, chapter: int) -> void:
	var summary := _fight_summary(chapter)
	var unlocked := chapter <= available_stage and (chapter != 1 or _tutorial_done(2))
	var cleared := int(summary.wins) > 0
	var marker := "✓" if cleared else ("▶" if unlocked else "🔒")
	var text_color := Color("52725b") if cleared else (Color("50391f") if unlocked else Color("8d877a"))
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "      %s  FIGHT %d" % [marker, chapter]
	button.disabled = not unlocked
	button.add_theme_color_override("font_color", text_color)
	var selected := selected_tutorial == 0 and selected_chapter == chapter
	button.add_theme_stylebox_override("normal", _panel_style(Color("cfb98c") if selected else (Color("ded1b5") if unlocked else Color("d2c7ae")), Color("9a7440") if selected else Color("b5a27f"), 4))
	button.add_theme_stylebox_override("hover", _panel_style(Color("f0e3c8"), Color("9a7440"), 4))
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.pressed.connect(func(): selected_tutorial = 0; selected_chapter = chapter; _refresh_detail())
	parent.add_child(button)
	chapter_buttons.append(button)

func _refresh_detail() -> void:
	for child in book_detail.get_children():
		child.queue_free()
	if view_level != "contents":
		var shelf := Label.new()
		shelf.text = "BOOKS" if view_level == "books" else "BOOK 1"
		shelf.add_theme_font_size_override("font_size", 32)
		shelf.add_theme_color_override("font_color", Color("382c1c"))
		book_detail.add_child(shelf)
		var note := Label.new()
		note.text = "Select a book" if view_level == "books" else "Select a chapter"
		note.add_theme_font_size_override("font_size", 18)
		note.add_theme_color_override("font_color", Color("655740"))
		book_detail.add_child(note)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		book_detail.add_child(spacer)
		return
	if selected_tutorial > 0:
		var title := Label.new()
		title.text = "TUTORIAL %d" % selected_tutorial
		title.add_theme_font_size_override("font_size", 30)
		title.add_theme_color_override("font_color", Color("382c1c"))
		book_detail.add_child(title)
		var done := Label.new()
		done.text = "✓" if _tutorial_done(selected_tutorial) else ""
		done.add_theme_font_size_override("font_size", 28)
		done.add_theme_color_override("font_color", Color("52725b"))
		book_detail.add_child(done)
		fight_button.text = "REPLAY" if _tutorial_done(selected_tutorial) else "START"
		fight_button.disabled = false
		loadout_button.disabled = true
		if detail_scroll != null: detail_scroll.scroll_vertical = 0
		return
	var chapter := clampi(selected_chapter, 1, CHAPTER_COUNT)
	var summary := _fight_summary(chapter)
	var unlocked := chapter <= available_stage and (chapter != 1 or _tutorial_done(2))
	var title := Label.new()
	title.text = "FIGHT %d" % chapter
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("8b642d"))
	book_detail.add_child(title)
	var rival_name := Label.new()
	rival_name.text = StoryRivals.name_for_stage(chapter)
	rival_name.add_theme_font_size_override("font_size", 26)
	rival_name.add_theme_color_override("font_color", Color("382c1c"))
	book_detail.add_child(rival_name)
	_add_rival_preview(chapter)
	var loot_title := Label.new()
	loot_title.text = "LOOT"
	loot_title.add_theme_font_size_override("font_size", 20)
	loot_title.add_theme_color_override("font_color", Color("8b642d"))
	book_detail.add_child(loot_title)
	if int(summary.wins) > 0:
		_add_reward_section("GEAR", summary.gear)
		_add_reward_section("SPELLS", summary.spells)
		_add_reward_section("ANIMATIONS", summary.animations)
	else:
		_add_reward_section("GEAR", [])
		_add_reward_section("SPELLS", [])
		_add_reward_section("ANIMATIONS", [])
	var has_combat_animation := _has_equipped_combat_animation()
	if not has_combat_animation:
		_add_combat_animation_notice()
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_detail.add_child(fill)
	fight_button.text = "FIGHT AGAIN" if int(summary.wins) > 0 else "FIGHT"
	fight_button.disabled = not unlocked or not has_combat_animation
	fight_button.tooltip_text = ""
	loadout_button.disabled = not unlocked
	if detail_scroll != null: detail_scroll.scroll_vertical = 0

func _has_unseen_loadout_items() -> bool:
	var unseen: Variant = profile.get("unseen_loadout_ids", [])
	return unseen is Array and not unseen.is_empty()

func _migrate_unseen_loadout_items() -> void:
	if profile.has("unseen_loadout_ids"):
		return
	var unseen: Array = []
	for entry in history:
		if not entry is Dictionary or not bool(entry.get("won", false)):
			continue
		for item in entry.get("opponent_loot", []):
			if item is Dictionary:
				var item_id := str(item.get("id", ""))
				if not item_id.is_empty() and not unseen.has(item_id): unseen.append(item_id)
	profile["unseen_loadout_ids"] = unseen
	var config := ConfigFile.new()
	config.set_value("character", "profile", profile)
	if config.save(CHARACTER_PATH) == OK:
		var roster := ConfigFile.new()
		if roster.load("user://story_characters.cfg") == OK:
			var characters: Array = roster.get_value("roster", "characters", [])
			var character_id := str(profile.get("character_id", ""))
			for index in range(characters.size()):
				if characters[index] is Dictionary and str(characters[index].get("character_id", "")) == character_id:
					characters[index] = profile.duplicate(true)
					break
			roster.set_value("roster", "characters", characters)
			roster.save("user://story_characters.cfg")

func _add_combat_animation_notice() -> void:
	var notice := PanelContainer.new()
	notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f1d4cc")
	style.border_color = Color("a93532")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	notice.add_theme_stylebox_override("panel", style)
	var message := Label.new()
	message.text = "CAN’T GO INTO A FIGHT WITH NO COMBAT ANIMATIONS"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 23)
	message.add_theme_color_override("font_color", Color("9f2927"))
	notice.add_child(message)
	book_detail.add_child(notice)

func _has_equipped_combat_animation() -> bool:
	var equipped:Dictionary=profile.get("story_part_gear",{})
	var gear_items:Array=profile.get("gear_inventory",[])
	for part_id in equipped:
		var gear_id:=str(equipped[part_id])
		if gear_id.is_empty():continue
		for item in gear_items:
			if not item is Dictionary or str(item.get("id", ""))!=gear_id:continue
			for animation in item.get("native_animations", []):
				if not str(animation).is_empty():return true
			for pair in item.get("animation_slots",[]):
				if not pair is Dictionary or str(pair.get("animation", "")).is_empty():continue
				return true
	return false

func _show_combat_animation_warning() -> void:
	if combat_warning_layer != null and is_instance_valid(combat_warning_layer):
		combat_warning_layer.queue_free()
	combat_warning_layer = CanvasLayer.new()
	combat_warning_layer.layer = 20
	add_child(combat_warning_layer)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.08, 0.025, 0.02, 0.58)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	combat_warning_layer.add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	combat_warning_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 190)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("351d1b")
	style.border_color = Color("c9433e")
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var message := Label.new()
	message.text = "CAN’T GO INTO A FIGHT WITH NO COMBAT ANIMATIONS"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 26)
	message.add_theme_color_override("font_color", Color("ff7770"))
	content.add_child(message)
	var close := Button.new()
	close.text = "OK"
	close.custom_minimum_size.y = 42
	close.pressed.connect(func(): combat_warning_layer.queue_free(); combat_warning_layer = null)
	content.add_child(close)

func _contains_spell_id(value:Variant) -> bool:
	if value is Array:return not value.is_empty()
	if value is Dictionary:return _contains_spell_id(value.get("spell_ids", []))
	return not str(value).is_empty()

func _tutorial_done(lesson: int) -> bool:
	var key := "punch_tutorial_%d_complete" % lesson
	if profile.has(key):
		return bool(profile.get(key, false))
	return bool(profile.get("punch_tutorial_complete", false))

func _fight_summary(chapter: int) -> Dictionary:
	var wins := 0
	var losses := 0
	var known_gear: Array = []
	var known_spells: Array = []
	var known_animations: Array = []
	for entry in history:
		if not entry is Dictionary or int(entry.get("fight", 0)) != chapter:
			continue
		if bool(entry.get("won", false)):
			wins += 1
			var reward_items: Array = entry.get("opponent_loot", [])
			if reward_items.is_empty():
				for item in profile.get("story_loot", []):
					if item is Dictionary and str(item.get("id", "")).begins_with("fight-%d-" % chapter):
						reward_items.append(item)
			if reward_items.is_empty():
				reward_items = entry.get("opponent_gear", [])
			for item in reward_items:
				var item_name := str(item.get("name", "Gear")) if item is Dictionary else str(item)
				if not known_gear.has(item_name):
					known_gear.append(item_name)
				if item is Dictionary:
					var ability := str(item.get("ability", ""))
					if not ability.is_empty():
						var animation_name := ability.replace("_", " ").capitalize()
						if not known_animations.has(animation_name):
							known_animations.append(animation_name)
					for animation in item.get("native_animations", []):
						var native_name := str(animation).replace("_", " ").capitalize()
						if not known_animations.has(native_name):
							known_animations.append(native_name)
					for animation_slot in item.get("animation_slots", []):
						if not animation_slot is Dictionary: continue
						var slot_animation := str(animation_slot.get("animation", ""))
						if not slot_animation.is_empty():
							var slot_name := slot_animation.replace("_", " ").capitalize()
							if not known_animations.has(slot_name):
								known_animations.append(slot_name)
					var spell_name := str(item.get("spell", ""))
					if not spell_name.is_empty() and not known_spells.has(spell_name):
						known_spells.append(spell_name)
					for spell in item.get("spells", []):
						var name := str(spell.get("spell", spell.get("name", "Spell"))) if spell is Dictionary else str(spell)
						if not name.is_empty() and not known_spells.has(name):
							known_spells.append(name)
			for spell in entry.get("opponent_spells", []):
				var spell_name := str(spell.get("spell", spell.get("name", "Spell"))) if spell is Dictionary else str(spell)
				if not spell_name.is_empty() and not known_spells.has(spell_name):
					known_spells.append(spell_name)
		else:
			losses += 1
	return {"wins":wins, "losses":losses, "gear":known_gear, "spells":known_spells, "animations":known_animations}

func _add_reward_section(heading_text: String, rewards: Array) -> void:
	var heading := Label.new()
	heading.text = heading_text
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color("8b642d"))
	book_detail.add_child(heading)
	if rewards.is_empty():
		return
	var item_tiles := HFlowContainer.new()
	item_tiles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_tiles.add_theme_constant_override("h_separation", 8)
	item_tiles.add_theme_constant_override("v_separation", 8)
	book_detail.add_child(item_tiles)
	for reward in rewards:
		var reward_name := str(reward)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(112, 138)
		tile.add_theme_stylebox_override("panel", _panel_style(Color("ded1b5"), Color("b5a27f"), 5))
		tile.tooltip_text = reward_name
		var contents := VBoxContainer.new()
		contents.alignment = BoxContainer.ALIGNMENT_CENTER
		contents.add_theme_constant_override("separation", 4)
		tile.add_child(contents)
		var image_placeholder := PanelContainer.new()
		image_placeholder.custom_minimum_size = Vector2(88, 68)
		var image_style := StyleBoxFlat.new()
		image_style.bg_color = Color.WHITE
		image_style.border_color = Color("c5c0b5")
		image_style.set_border_width_all(1)
		image_style.set_corner_radius_all(2)
		image_placeholder.add_theme_stylebox_override("panel", image_style)
		contents.add_child(image_placeholder)
		var name_label := Label.new()
		name_label.text = reward_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color("57452e"))
		name_label.custom_minimum_size.y = 48
		contents.add_child(name_label)
		item_tiles.add_child(tile)

func _add_rival_preview(chapter: int) -> void:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, 150)
	var frame_style := _panel_style(Color("d8c7a4"), Color("b5a27f"), 5)
	frame.add_theme_stylebox_override("panel", frame_style)
	book_detail.add_child(frame)
	var view := SubViewportContainer.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.stretch = true
	frame.add_child(view)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(600, 180)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(viewport)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("d8c7a4")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("ffe6bb")
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	viewport.add_child(environment_node)
	var camera := Camera3D.new()
	camera.position = Vector3(0.05, 1.12, 2.25)
	camera.fov = 50
	viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-28, -25, 0)
	key_light.light_energy = 1.5
	viewport.add_child(key_light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.5, 1.6, 1.6)
	fill.light_color = Color("f0d9a7")
	fill.light_energy = 0.55
	fill.omni_range = 6
	viewport.add_child(fill)
	var rival_preview := PreviewCharacter.new()
	viewport.add_child(rival_preview)
	rival_preview.set_profile(StoryRivals.profile_for_stage(chapter))

func _start_selected_chapter() -> void:
	if selected_tutorial > 0:
		if selected_tutorial == 2 and not _tutorial_done(1): return
		get_tree().set_meta("story_punch_tutorial", true)
		get_tree().set_meta("story_tutorial_lesson", selected_tutorial)
		get_tree().change_scene_to_file("res://scenes/fight_loading.tscn")
		return
	if selected_chapter > available_stage:
		return
	if selected_chapter == 1 and not _tutorial_done(2): return
	if not _has_equipped_combat_animation():
		_show_combat_animation_warning()
		return
	get_tree().set_meta("story_fight_stage", selected_chapter)
	get_tree().change_scene_to_file("res://scenes/fight_loading.tscn")

func _open_selected_loadout() -> void:
	if selected_chapter > available_stage:
		return
	get_tree().set_meta("story_selected_chapter", selected_chapter)
	get_tree().change_scene_to_file("res://scenes/story_loadout.tscn")

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		get_viewport().set_input_as_handled()
