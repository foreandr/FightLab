extends Control
## Story checkpoint shortcuts for fast, repeatable development runs.

const CHARACTER_PATH := "user://story_character.cfg"
const ROSTER_PATH := "user://story_characters.cfg"
const DEV_CHARACTER_PREFIX := "fightlab-dev-checkpoint-"
const StoryCreatorScript = preload("res://scripts/story_character_creator.gd")
const StoryRivals = preload("res://scripts/story_rivals.gd")

const CHECKPOINTS := [
	{"id":"tutorial_1", "title":"Tutorial 1", "group":"Introduction", "kind":"tutorial", "lesson":1, "completed_tutorials":[], "fight":0, "ready":true},
	{"id":"tutorial_2", "title":"Tutorial 2", "group":"Introduction", "kind":"tutorial", "lesson":2, "completed_tutorials":[1], "fight":0, "ready":true},
	{"id":"fight_1", "title":"Fight 1", "group":"Fights", "kind":"fight", "completed_tutorials":[1, 2], "fight":1, "ready":true},
	{"id":"fight_2", "title":"Fight 2", "group":"Fights", "kind":"fight", "completed_tutorials":[1, 2], "fight":2, "ready":false},
	{"id":"fight_3", "title":"Fight 3", "group":"Fights", "kind":"fight", "completed_tutorials":[1, 2], "fight":3, "ready":false},
	{"id":"fight_4", "title":"Fight 4", "group":"Fights", "kind":"fight", "completed_tutorials":[1, 2], "fight":4, "ready":false},
	{"id":"fight_5", "title":"Fight 5", "group":"Fights", "kind":"fight", "completed_tutorials":[1, 2], "fight":5, "ready":false},
]

var checkpoint_title: Label
var checkpoint_description: Label
var status_label: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("302116")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
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
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	page_margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "DEV  ·  STORY CHECKPOINTS"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("614421"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var home_button := Button.new()
	home_button.text = "HOME"
	home_button.custom_minimum_size = Vector2(110, 42)
	home_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/home.tscn"))
	header.add_child(home_button)
	var rule := ColorRect.new()
	rule.color = Color("b5a27f")
	rule.custom_minimum_size.y = 1
	layout.add_child(rule)

	var notice := Label.new()
	notice.text = "Each shortcut creates a numbered checkpoint fighter in your character list."
	notice.add_theme_font_size_override("font_size", 17)
	notice.add_theme_color_override("font_color", Color("75664f"))
	layout.add_child(notice)

	var spread := HBoxContainer.new()
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation", 18)
	layout.add_child(spread)
	var checkpoints := ScrollContainer.new()
	checkpoints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkpoints.size_flags_vertical = Control.SIZE_EXPAND_FILL
	checkpoints.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	spread.add_child(checkpoints)
	var groups := VBoxContainer.new()
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("separation", 14)
	checkpoints.add_child(groups)
	_add_group(groups, "BOOK 1  ·  CHAPTER 1  ·  INTRODUCTION", "tutorial_1", "tutorial_2")
	_add_group(groups, "BOOK 1  ·  FIGHT CHECKPOINTS", "fight_1", "fight_2", "fight_3", "fight_4", "fight_5")
	_add_future_group(groups)

	var divider := ColorRect.new()
	divider.color = Color("b5a27f")
	divider.custom_minimum_size.x = 2
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_child(divider)
	var detail := PanelContainer.new()
	detail.custom_minimum_size.x = 410
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_stylebox_override("panel", _panel_style(Color("ded1b5"), Color("b5a27f"), 5))
	spread.add_child(detail)
	var detail_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		detail_margin.add_theme_constant_override("margin_" + side, 22)
	detail.add_child(detail_margin)
	var detail_content := VBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 14)
	detail_margin.add_child(detail_content)
	checkpoint_title = Label.new()
	checkpoint_title.text = "Choose a checkpoint"
	checkpoint_title.add_theme_font_size_override("font_size", 25)
	checkpoint_title.add_theme_color_override("font_color", Color("382c1c"))
	detail_content.add_child(checkpoint_title)
	checkpoint_description = Label.new()
	checkpoint_description.text = "Three checkpoints are ready. Future fights are grouped below."
	checkpoint_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	checkpoint_description.add_theme_font_size_override("font_size", 17)
	checkpoint_description.add_theme_color_override("font_color", Color("57452e"))
	detail_content.add_child(checkpoint_description)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_content.add_child(fill)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("52725b"))
	detail_content.add_child(status_label)

func _add_group(parent: VBoxContainer, heading: String, first_id: String, second_id := "", third_id := "", fourth_id := "", fifth_id := "") -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("ded1b5"), Color("b5a27f"), 5))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("8b642d"))
	content.add_child(title)
	for checkpoint_id in [first_id, second_id, third_id, fourth_id, fifth_id]:
		if checkpoint_id.is_empty():
			continue
		var checkpoint := _checkpoint_for_id(checkpoint_id)
		if not checkpoint.is_empty():
			_add_checkpoint_button(content, checkpoint)

func _add_future_group(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("d2c7ae"), Color("c2b69a"), 5))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var label := Label.new()
	label.text = "MORE BOOKS AND CHAPTERS"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("8b642d"))
	content.add_child(label)
	var later := Label.new()
	later.text = "Reserved for future checkpoint groups."
	later.add_theme_color_override("font_color", Color("75664f"))
	content.add_child(later)

func _add_checkpoint_button(parent: VBoxContainer, checkpoint: Dictionary) -> void:
	var button := Button.new()
	button.text = str(checkpoint.get("title", "Checkpoint")) if bool(checkpoint.get("ready", false)) else str(checkpoint.get("title", "Checkpoint")) + "  ·  NOT READY"
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not bool(checkpoint.get("ready", false))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("382c1c"))
	button.add_theme_color_override("font_hover_color", Color("382c1c"))
	button.add_theme_color_override("font_pressed_color", Color("382c1c"))
	button.add_theme_color_override("font_focus_color", Color("382c1c"))
	button.add_theme_color_override("font_disabled_color", Color("8d877a"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("f0e3c8"), Color("b5a27f"), 4))
	button.add_theme_stylebox_override("hover", _panel_style(Color("f7ecd7"), Color("9a7440"), 4))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("cfb98c"), Color("9a7440"), 4))
	button.add_theme_stylebox_override("focus", _panel_style(Color("f0e3c8"), Color("9a7440"), 4))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("d2c7ae"), Color("c2b69a"), 4))
	button.pressed.connect(func(): _show_checkpoint(checkpoint))
	if bool(checkpoint.get("ready", false)):
		button.pressed.connect(func(): _start_checkpoint(str(checkpoint.id)))
	parent.add_child(button)

func _show_checkpoint(checkpoint: Dictionary) -> void:
	checkpoint_title.text = str(checkpoint.get("title", "Checkpoint"))
	var kind := str(checkpoint.get("kind", ""))
	if kind == "tutorial":
		checkpoint_description.text = "Creates a new fighter and starts Tutorial %d." % int(checkpoint.get("lesson", 1))
	else:
		checkpoint_description.text = "Creates a new fighter with earlier rewards and starts Fight %d." % int(checkpoint.get("fight", 1))
	status_label.text = "READY" if bool(checkpoint.get("ready", false)) else "NOT READY"
	status_label.add_theme_color_override("font_color", Color("52725b") if bool(checkpoint.get("ready", false)) else Color("8b642d"))

func _start_checkpoint(checkpoint_id: String) -> void:
	var checkpoint := _checkpoint_for_id(checkpoint_id)
	if checkpoint.is_empty() or not bool(checkpoint.get("ready", false)):
		return
	var character_number := _next_dev_character_number()
	var created_at := Time.get_datetime_string_from_system(false, true)
	var profile := _new_default_dev_profile(character_number, created_at)
	var completed_tutorials: Array = checkpoint.get("completed_tutorials", [])
	for lesson in [1, 2]:
		profile["punch_tutorial_%d_complete" % lesson] = completed_tutorials.has(lesson)
	profile["punch_tutorial_complete"] = completed_tutorials.has(1) and completed_tutorials.has(2)
	var fight := int(checkpoint.get("fight", 0))
	profile["story_stage"] = maxi(1, fight)
	if fight > 1:
		_seed_completed_fights(profile, fight - 1)
	if not _save_dev_character(profile):
		checkpoint_title.text = "Could not save new fighter"
		status_label.text = "Check the game log for the save error."
		status_label.add_theme_color_override("font_color", Color("a93532"))
		return
	get_tree().set_meta("story_selected_character_id", str(profile.get("character_id", "")))
	if get_tree().has_meta("story_fight_stage"):
		get_tree().remove_meta("story_fight_stage")
	if get_tree().has_meta("story_punch_tutorial"):
		get_tree().remove_meta("story_punch_tutorial")
	if get_tree().has_meta("story_tutorial_lesson"):
		get_tree().remove_meta("story_tutorial_lesson")
	if str(checkpoint.get("kind", "")) == "tutorial":
		get_tree().set_meta("story_punch_tutorial", true)
		get_tree().set_meta("story_tutorial_lesson", int(checkpoint.get("lesson", 1)))
	else:
		get_tree().set_meta("story_fight_stage", fight)
	GameDiagnostics.log_event("dev_story_checkpoint_started", {"checkpoint":checkpoint_id,"character_id":profile.get("character_id", ""),"character_name":profile.get("name", ""),"tutorials_complete":completed_tutorials,"fight":fight})
	get_tree().change_scene_to_file("res://scenes/fight_loading.tscn")

func _next_dev_character_number() -> int:
	var roster := ConfigFile.new()
	if roster.load(ROSTER_PATH) != OK:
		return 1
	var characters: Array = roster.get_value("roster", "characters", [])
	var highest := 0
	for character in characters:
		if not character is Dictionary:
			continue
		var number := int(character.get("dev_checkpoint_number", 0))
		if number <= 0:
			var character_id := str(character.get("character_id", ""))
			if character_id.begins_with(DEV_CHARACTER_PREFIX):
				number = int(character_id.trim_prefix(DEV_CHARACTER_PREFIX).get_slice("-", 0))
		highest = maxi(highest, number)
	return highest + 1

func _new_default_dev_profile(character_number: int, created_at: String) -> Dictionary:
	var creator := StoryCreatorScript.new()
	var base_profile: Variant = creator.get("profile")
	var profile: Dictionary = base_profile.duplicate(true) if base_profile is Dictionary else {}
	creator.free()
	profile["name"] = "New char %d created %s" % [character_number, created_at]
	profile["character_id"] = "%s%04d-%d" % [DEV_CHARACTER_PREFIX, character_number, int(Time.get_unix_time_from_system())]
	profile["dev_checkpoint_number"] = character_number
	profile["created_at"] = created_at
	profile["story_location"] = "Colosseum"
	profile["story_stage"] = 1
	profile["story_history"] = []
	profile["story_loot"] = []
	profile["last_fight_loot"] = []
	profile["seen_loot_ids"] = []
	profile["gear_inventory"] = []
	profile["story_part_gear"] = {}
	profile["story_equipped_items"] = []
	profile["spell_inventory"] = []
	profile["crystal_inventory"] = []
	profile["animation_inventory"] = []
	profile["spell_catalog"] = []
	profile["spell_inventory_initialized"] = true
	profile["combat_abilities"] = []
	profile["combat_hotkeys"] = {"punch_left":"mouse_left"}
	profile["gear_slots"] = _default_gear_slots()
	_build_starter_gear(profile)
	return profile

func _default_gear_slots() -> Dictionary:
	var slots: Dictionary = {}
	for part_id in ["chest", "left_arm", "right_arm", "left_hand", "right_hand", "left_leg", "right_leg", "left_boot", "right_boot", "head", "face", "belt", "back"]:
		slots[part_id] = {"ability":"", "input":"key_1"}
	slots["left_arm"] = {"ability":"punch_left", "input":"mouse_left"}
	slots["right_arm"] = {"ability":"", "input":"mouse_right"}
	slots["chest"] = {"ability":"", "input":"mouse_both"}
	return slots

func _build_starter_gear(profile: Dictionary) -> void:
	var definitions := [
		{"part":"chest", "slot":"Chest", "gear_key":"wardrobe_shirt", "name":"Peasant chest"},
		{"part":"left_arm", "slot":"Left arm", "gear_key":"wardrobe_arms", "name":"Peasant left arm wraps"},
		{"part":"right_arm", "slot":"Right arm", "gear_key":"wardrobe_arms", "name":"Peasant right arm wraps"},
		{"part":"left_leg", "slot":"Left leg", "gear_key":"wardrobe_pants", "name":"Peasant left trouser leg"},
		{"part":"right_leg", "slot":"Right leg", "gear_key":"wardrobe_pants", "name":"Peasant right trouser leg"},
		{"part":"left_boot", "slot":"Left boot", "gear_key":"wardrobe_boots", "name":"Peasant left boot"},
		{"part":"right_boot", "slot":"Right boot", "gear_key":"wardrobe_boots", "name":"Peasant right boot"},
	]
	var inventory: Array[Dictionary] = []
	var equipped: Dictionary = {}
	for definition in definitions:
		var part_id := str(definition.part)
		var gear_id := "starter_%s" % part_id
		var appearance := profile.duplicate(true)
		var animation_slots: Array = []
		var native_animations: Array = []
		if part_id == "left_arm":
			native_animations = ["punch_left"]
			animation_slots = [{"animation":"punch_left", "spell_ids":[], "spell_id":"", "input":"mouse_left"}]
		var item := {
			"id":gear_id,
			"name":str(definition.name),
			"part":part_id,
			"slot":str(definition.slot),
			"rarity":1,
			"appearance":appearance,
			"native_animations":native_animations,
			"animation_slots":animation_slots,
			"crystal_links":{},
		}
		inventory.append(item)
		equipped[part_id] = gear_id
	profile["gear_inventory"] = inventory
	profile["story_part_gear"] = equipped
	profile["story_equipped_items"] = inventory.map(func(item: Dictionary) -> String: return str(item.get("id", "")))

func _seed_completed_fights(profile: Dictionary, count: int) -> void:
	var history: Array = profile.get("story_history", [])
	var loot_inventory: Array = profile.get("story_loot", [])
	var gear_inventory: Array = profile.get("gear_inventory", [])
	for fight in range(1, count + 1):
		var drops := _loot_for_fight(fight)
		var names: Array[String] = []
		var spells: Array[String] = []
		for drop in drops:
			names.append(str(drop.get("name", "Gear")))
			var loot_item: Dictionary = drop.duplicate(true)
			loot_inventory.append(loot_item)
			var ability := str(drop.get("ability", ""))
			var animation_slots: Array = []
			if not ability.is_empty():
				var spell_name := str(drop.get("spell", ""))
				var spell_ids: Array = []
				if not spell_name.is_empty():
					var spell_id := "spell_%s" % spell_name.to_lower().replace(" ", "_")
					spell_ids = [spell_id]
					spells.append(spell_name)
				animation_slots.append({"animation":ability, "spell_ids":spell_ids, "spell_id":spell_ids[0] if not spell_ids.is_empty() else "", "input":"mouse_both" if ability == "block" else "key_1"})
			var item := {
				"id":str(drop.get("id", "")),
				"name":str(drop.get("name", "Gear")),
				"part":str(drop.get("part", _part_for_loot_slot(str(drop.get("slot", ""))))),
				"slot":str(drop.get("slot", "")),
				"rarity":int(drop.get("rarity", 1)),
				"native_animations":[ability] if not ability.is_empty() else [],
				"animation_slots":animation_slots,
				"crystal_links":{},
			}
			gear_inventory.append(item)
		if not spells.is_empty():
			var spell_entries: Array = profile.get("spell_inventory", [])
			for spell_name in spells:
				var spell_id := "spell_%s" % spell_name.to_lower().replace(" ", "_")
				spell_entries.append({"id":spell_id, "name":spell_name, "spell":spell_name, "rarity":1})
			profile["spell_inventory"] = spell_entries
			profile["crystal_inventory"] = spell_entries.duplicate(true)
		history.append({"fight":fight, "opponent":StoryRivals.name_for_stage(fight), "won":true, "opponent_gear":names, "opponent_loot":drops, "opponent_spells":spells, "time":0.0, "dev_seeded":true})
	profile["story_history"] = history
	profile["story_loot"] = loot_inventory
	profile["gear_inventory"] = gear_inventory
	profile["seen_loot_ids"] = loot_inventory.map(func(item: Dictionary) -> String: return str(item.get("id", "")))

func _loot_for_fight(fight: int) -> Array[Dictionary]:
	var loot: Array[Dictionary] = [
		{"name":"Peasant chest", "slot":"Chest", "part":"chest"},
		{"name":"Peasant left trouser leg", "slot":"Left leg", "part":"left_leg"},
		{"name":"Peasant right trouser leg", "slot":"Right leg", "part":"right_leg"},
		{"name":"Leather belt", "slot":"Belt", "part":"belt"},
		{"name":"Peasant left arm wraps", "slot":"Left arm", "part":"left_arm", "ability":"punch_left"},
		{"name":"Bare left hand", "slot":"Left hand", "part":"left_hand"},
		{"name":"Peasant left boot", "slot":"Left boot", "part":"left_boot"},
	]
	if fight >= 3:
		loot[0]["name"] = "Guarded chest wraps"
		loot[0]["ability"] = "block"
		loot[0]["spell"] = "Fireball"
	if fight >= 2:
		loot.append({"name":"Left fingerless glove", "slot":"Left hand", "part":"left_hand"})
		loot.append({"name":"Right fingerless glove", "slot":"Right hand", "part":"right_hand"})
	if fight >= 3:
		loot.append({"name":"Worn hood", "slot":"Head", "part":"head"})
	if fight == 4:
		loot.append({"name":"Left front-kick greave", "slot":"Left leg", "part":"left_leg", "ability":"front_kick"})
		loot.append({"name":"Right front-kick greave", "slot":"Right leg", "part":"right_leg", "ability":"front_kick"})
	if fight == 5:
		loot.append({"name":"Left reinforced front-kick greave", "slot":"Left leg", "part":"left_leg", "ability":"front_kick"})
		loot.append({"name":"Right reinforced front-kick greave", "slot":"Right leg", "part":"right_leg", "ability":"front_kick"})
	if fight >= 5:
		loot.append({"name":"Left dash boot", "slot":"Left boot", "part":"left_boot", "ability":"dash"})
		loot.append({"name":"Right dash boot", "slot":"Right boot", "part":"right_boot", "ability":"dash"})
	for index in range(loot.size()):
		loot[index]["id"] = "fight-%d-item-%d" % [fight, index]
	loot.append({"id":"fight-%d-right-arm" % fight, "name":"Peasant right arm wraps", "slot":"Right arm", "part":"right_arm", "ability":"punch_right"})
	loot.append({"id":"fight-%d-right-leg" % fight, "name":"Peasant right trouser leg", "slot":"Right leg", "part":"right_leg"})
	loot.append({"id":"fight-%d-right-hand" % fight, "name":"Bare right hand", "slot":"Right hand", "part":"right_hand"})
	loot.append({"id":"fight-%d-right-boot" % fight, "name":"Peasant right boot", "slot":"Right boot", "part":"right_boot"})
	return loot

func _part_for_loot_slot(slot: String) -> String:
	return {"Chest":"chest", "Left arm":"left_arm", "Right arm":"right_arm", "Left leg":"left_leg", "Right leg":"right_leg", "Left hand":"left_hand", "Right hand":"right_hand", "Left boot":"left_boot", "Right boot":"right_boot", "Head":"head", "Face":"face", "Belt":"belt", "Back":"back"}.get(slot, "chest")

func _save_dev_character(profile: Dictionary) -> bool:
	var roster := ConfigFile.new()
	roster.load(ROSTER_PATH)
	var characters: Array = roster.get_value("roster", "characters", [])
	characters.append(profile.duplicate(true))
	roster.set_value("roster", "characters", characters)
	if roster.save(ROSTER_PATH) != OK:
		GameDiagnostics.log_event("dev_character_save_failed", {"reason":"roster_save_failed"})
		return false
	var config := ConfigFile.new()
	config.set_value("character", "profile", profile)
	if config.save(CHARACTER_PATH) != OK:
		GameDiagnostics.log_event("dev_character_save_failed", {"reason":"active_save_failed","character_id":profile.get("character_id", "")})
		return false
	return true

func _checkpoint_for_id(checkpoint_id: String) -> Dictionary:
	for checkpoint in CHECKPOINTS:
		if str(checkpoint.get("id", "")) == checkpoint_id:
			return checkpoint
	return {}

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
