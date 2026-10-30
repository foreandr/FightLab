extends Control
## Choose a saved character and resume their stored story location.

const CHARACTER_PATH := "user://story_character.cfg"
const ROSTER_PATH := "user://story_characters.cfg"

var list: VBoxContainer
var delete_dialog: ConfirmationDialog
var pending_delete: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	_populate_characters()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("302116")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 28)
	add_child(outer)
	var cover := PanelContainer.new()
	var cover_style := StyleBoxFlat.new()
	cover_style.bg_color = Color("d8c7a4")
	cover_style.border_color = Color("765b38")
	cover_style.set_border_width_all(3)
	cover_style.set_corner_radius_all(10)
	cover.add_theme_stylebox_override("panel", cover_style)
	outer.add_child(cover)
	var book_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		book_margin.add_theme_constant_override("margin_" + side, 18)
	cover.add_child(book_margin)
	var book := VBoxContainer.new()
	book.add_theme_constant_override("separation", 14)
	book_margin.add_child(book)
	var header := HBoxContainer.new()
	book.add_child(header)
	var eyebrow := Label.new()
	eyebrow.text = "BOOK 1  ·  INTRODUCTION"
	eyebrow.add_theme_font_size_override("font_size", 24)
	eyebrow.add_theme_color_override("font_color", Color("614421"))
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(eyebrow)
	var book_author := Label.new()
	book_author.text = "FIGHTLAB CHRONICLES"
	book_author.add_theme_color_override("font_color", Color("75664f"))
	header.add_child(book_author)
	var rule := ColorRect.new()
	rule.custom_minimum_size.y = 2
	rule.color = Color("b5a27f")
	book.add_child(rule)
	var spread := HBoxContainer.new()
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation", 0)
	book.add_child(spread)
	var left_page := PanelContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.size_flags_stretch_ratio = 1.0
	left_page.add_theme_stylebox_override("panel", _page_style())
	spread.add_child(left_page)
	var left_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		left_margin.add_theme_constant_override("margin_" + side, 26)
	left_page.add_child(left_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	left_margin.add_child(column)
	var chapter := Label.new()
	chapter.text = "Choose a character to open their book"
	chapter.add_theme_font_size_override("font_size", 27)
	chapter.add_theme_color_override("font_color", Color("382c1c"))
	column.add_child(chapter)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var spine := ColorRect.new()
	spine.color = Color("98794d")
	spine.custom_minimum_size.x = 12
	spine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_child(spine)
	var right_page := PanelContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.size_flags_stretch_ratio = 1.0
	right_page.add_theme_stylebox_override("panel", _page_style())
	spread.add_child(right_page)
	var right_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		right_margin.add_theme_constant_override("margin_" + side, 58)
	right_page.add_child(right_margin)
	var right_text := VBoxContainer.new()
	right_text.alignment = BoxContainer.ALIGNMENT_CENTER
	right_text.add_theme_constant_override("separation", 24)
	right_margin.add_child(right_text)
	var ornament := Label.new()
	ornament.text = "✦"
	ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ornament.add_theme_font_size_override("font_size", 44)
	ornament.add_theme_color_override("font_color", Color("b08a4b"))
	right_text.add_child(ornament)
	var invitation := Label.new()
	invitation.text = "A new life\nbegins here"
	invitation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invitation.add_theme_font_size_override("font_size", 36)
	invitation.add_theme_color_override("font_color", Color("382c1c"))
	right_text.add_child(invitation)
	var right_rule := ColorRect.new()
	right_rule.color = Color("b5a27f")
	right_rule.custom_minimum_size.y = 2
	right_text.add_child(right_rule)
	var hint := Label.new()
	hint.text = "Choose a saved character, or create one to write the first page."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("655740"))
	right_text.add_child(hint)
	var footer_rule := ColorRect.new()
	footer_rule.custom_minimum_size.y = 2
	footer_rule.color = Color("b5a27f")
	book.add_child(footer_rule)
	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "Delete character"
	delete_dialog.confirmed.connect(_delete_pending_character)
	add_child(delete_dialog)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	book.add_child(buttons)
	var create := Button.new()
	create.text = "CREATE CHARACTER"
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.custom_minimum_size.y = 52
	_style_book_button(create, true)
	create.pressed.connect(func():
		get_tree().set_meta("story_create_new", true)
		get_tree().change_scene_to_file("res://scenes/story_character_creator.tscn")
	)
	buttons.add_child(create)
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(150, 52)
	_style_book_button(back, false)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/home.tscn"))
	buttons.add_child(back)

func _page_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e8ddc4")
	style.border_color = Color("b5a27f")
	style.set_border_width_all(1)
	return style

func _style_book_button(button: Button, primary: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("c9a65e") if primary else Color("ded1b5")
	style.border_color = Color("9a7440")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("dfbd74") if primary else Color("f0e3c8")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", Color("382c1c"))

func _populate_characters() -> void:
	for child in list.get_children():
		child.queue_free()
	var characters := _load_characters()
	for index in range(characters.size() - 1, -1, -1):
		var profile: Dictionary = characters[index]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 14)
		list.add_child(row)
		var card := Button.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 82
		card.text = "NAME: %s\n%s" % [str(profile.get("name", "Unnamed character")), _character_progress_summary(profile)]
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 16)
		card.add_theme_color_override("font_color", Color("382c1c"))
		card.add_theme_color_override("font_hover_color", Color("382c1c"))
		card.add_theme_color_override("font_pressed_color", Color("382c1c"))
		card.add_theme_color_override("font_focus_color", Color("382c1c"))
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("ded1b5")
		card_style.border_color = Color("b5a27f")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(5)
		card_style.content_margin_left = 18
		card_style.content_margin_right = 18
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 8
		card.add_theme_stylebox_override("normal", card_style)
		var card_hover := card_style.duplicate() as StyleBoxFlat
		card_hover.bg_color = Color("f0e3c8")
		card.add_theme_stylebox_override("hover", card_hover)
		card.pressed.connect(_load_character.bind(profile))
		row.add_child(card)
		var delete := Button.new()
		delete.text = "DELETE"
		delete.custom_minimum_size = Vector2(92, 82)
		delete.tooltip_text = "Delete this character and their saved progress"
		delete.add_theme_color_override("font_color", Color("70432d"))
		_style_book_button(delete, false)
		delete.pressed.connect(_confirm_delete.bind(profile))
		row.add_child(delete)
	if characters.is_empty():
		var empty := Label.new()
		empty.text = "No saved characters yet. Create one to begin."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color("75664f"))
		list.add_child(empty)

func _character_progress_summary(profile: Dictionary) -> String:
	var history_value: Variant = profile.get("story_history", [])
	var history: Array = history_value if history_value is Array else []
	var wins := 0
	var losses := 0
	var next_fight := clampi(int(profile.get("story_stage", 1)), 1, 5)
	var has_fight_history := false
	for result in history:
		if not result is Dictionary:
			continue
		if result.has("fight"):
			has_fight_history = true
		if bool(result.get("won", false)):
			wins += 1
			if result.has("fight"):
				next_fight = maxi(next_fight, mini(5, int(result.get("fight", 1)) + 1))
		else:
			losses += 1

	var next_entry := "FIGHT %d" % next_fight
	if not has_fight_history:
		if not bool(profile.get("punch_tutorial_1_complete", false)):
			next_entry = "TUTORIAL 1"
		elif not bool(profile.get("punch_tutorial_2_complete", false)):
			next_entry = "TUTORIAL 2"
	return "BOOK 1  ·  CHAPTER 1  ·  %s  ·  %dW  ·  %dL" % [next_entry, wins, losses]

func _confirm_delete(profile: Dictionary) -> void:
	pending_delete = profile.duplicate(true)
	delete_dialog.dialog_text = "Delete %s and all of their saved progress and gear? This cannot be undone." % str(profile.get("name", "this character"))
	delete_dialog.popup_centered(Vector2i(430, 150))

func _delete_pending_character() -> void:
	if pending_delete.is_empty():
		return
	var deleted_id := str(pending_delete.get("character_id", ""))
	var roster := ConfigFile.new()
	roster.load(ROSTER_PATH)
	var characters: Array = roster.get_value("roster", "characters", [])
	var kept: Array = []
	var removed := false
	for candidate in characters:
		if not candidate is Dictionary:
			continue
		var matches_id := not deleted_id.is_empty() and str(candidate.get("character_id", "")) == deleted_id
		if not removed and (matches_id or candidate == pending_delete):
			removed = true
			continue
		kept.append(candidate)
	roster.set_value("roster", "characters", kept)
	if roster.save(ROSTER_PATH) != OK:
		GameDiagnostics.log_event("character_delete_failed", {"character_id":deleted_id, "reason":"roster_save_failed"})
		return
	var current := ConfigFile.new()
	if current.load(CHARACTER_PATH) == OK:
		var active: Variant = current.get_value("character", "profile", {})
		if active is Dictionary:
			var active_matches_id := not deleted_id.is_empty() and str(active.get("character_id", "")) == deleted_id
			if active_matches_id or active == pending_delete:
				var active_path := ProjectSettings.globalize_path(CHARACTER_PATH)
				DirAccess.remove_absolute(active_path)
	GameDiagnostics.log_event("character_deleted", {"character_id":deleted_id, "name":pending_delete.get("name", ""), "remaining":kept.size()})
	pending_delete.clear()
	_populate_characters()

func _load_characters() -> Array:
	var roster := ConfigFile.new()
	if roster.load(ROSTER_PATH) == OK:
		var saved: Variant = roster.get_value("roster", "characters", [])
		if saved is Array and not saved.is_empty():
			var valid: Array = []
			for entry in saved:
				if entry is Dictionary and not entry.is_empty():
					valid.append(entry)
			if not valid.is_empty():
				return valid
	var current := ConfigFile.new()
	if current.load(CHARACTER_PATH) == OK:
		var profile: Variant = current.get_value("character", "profile", {})
		if profile is Dictionary and not profile.is_empty():
			return [profile]
	return []

func _load_character(profile: Dictionary) -> void:
	var selected := profile.duplicate(true)
	if not selected.has("character_id"):
		selected["character_id"] = "%s-%s" % [str(selected.get("name", "character")).to_lower().replace(" ", "-"), str(Time.get_unix_time_from_system())]
	selected["story_stage"] = maxi(1, int(selected.get("story_stage", 1)))
	selected["story_location"] = str(selected.get("story_location", "Colosseum"))
	GameDiagnostics.log_event("character_selected", {"name":selected.get("name", ""), "character_id":selected.get("character_id", ""), "story_stage":selected.story_stage, "story_location":selected.story_location})
	var config := ConfigFile.new()
	config.set_value("character", "profile", selected)
	if config.save(CHARACTER_PATH) != OK:
		return
	# Migrate legacy single-character saves and keep the chosen profile in the roster.
	var roster := ConfigFile.new()
	roster.load(ROSTER_PATH)
	var characters: Array = roster.get_value("roster", "characters", [])
	var replaced := false
	for index in range(characters.size()):
		if characters[index] is Dictionary and str(characters[index].get("character_id", "")) == str(selected.character_id):
			characters[index] = selected
			replaced = true
			break
	if not replaced:
		characters.append(selected)
	roster.set_value("roster", "characters", characters)
	roster.save(ROSTER_PATH)
	get_tree().set_meta("story_book_view", "books")
	get_tree().change_scene_to_file("res://scenes/story_opponents.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		get_viewport().set_input_as_handled()
