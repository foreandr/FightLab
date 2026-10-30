extends Control
## Saved fight replays can be loaded into the arena with a free camera.

var list: VBoxContainer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()

func _build_ui() -> void:
	var book_theme := Theme.new()
	book_theme.set_color("font_color", "Label", Color("382c1c"))
	book_theme.set_color("font_color", "Button", Color("382c1c"))
	theme = book_theme
	var bg := ColorRect.new()
	bg.color = Color("302116")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 42)
	add_child(margin)
	var page := PanelContainer.new()
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color("e8ddc4")
	page_style.border_color = Color("765b38")
	page_style.set_border_width_all(2)
	page.add_theme_stylebox_override("panel", page_style)
	margin.add_child(page)
	var page_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		page_margin.add_theme_constant_override("margin_" + side, 26)
	page.add_child(page_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	page_margin.add_child(column)
	var eyebrow := Label.new()
	eyebrow.text = "BOOK 1  ·  CHAPTER 1  ·  COLOSSEUM"
	eyebrow.add_theme_color_override("font_color", Color("e9c982"))
	column.add_child(eyebrow)
	var title := Label.new()
	title.text = "REPLAYS"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var intro := Label.new()
	intro.text = "Choose a saved fight. Drag over the arena to orbit, use the wheel to zoom, and scrub the timeline."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color("655740"))
	column.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_populate()
	var back := Button.new()
	back.text = "BACK TO FIGHT HISTORY"
	back.custom_minimum_size.y = 48
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/story_opponents.tscn"))
	column.add_child(back)

func _populate() -> void:
	var folder := "user://story_replays"
	var absolute := ProjectSettings.globalize_path(folder)
	if not DirAccess.dir_exists_absolute(absolute):
		_add_empty("No saved replays yet. Use SAVE REPLAY after a fight.")
		return
	var dir := DirAccess.open(folder)
	if dir == null:
		_add_empty("Replay folder could not be opened.")
		return
	dir.list_dir_begin()
	var filename := dir.get_next()
	var files: Array[String] = []
	while not filename.is_empty():
		if not dir.current_is_dir() and filename.to_lower().ends_with(".json"): files.append(filename)
		filename = dir.get_next()
	dir.list_dir_end()
	files.sort()
	files.reverse()
	for name in files:
		var path := folder + "/" + name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null: continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary: continue
		var data: Dictionary = parsed
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 84
		button.text = "%s  ·  Fight %d\n%s vs %s  ·  %.1f seconds" % [name.trim_suffix(".json"), int(data.get("fight", 1)), str(data.get("player", "Player")), str(data.get("opponent", "Rival")), float(data.get("duration", 0.0))]
		button.pressed.connect(_watch.bind(data))
		list.add_child(button)
	if files.is_empty(): _add_empty("No saved replays yet. Use SAVE REPLAY after a fight.")

func _add_empty(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color("655740"))
	list.add_child(label)

func _watch(data: Dictionary) -> void:
	get_tree().set_meta("story_replay_data", data)
	get_tree().change_scene_to_file("res://scenes/fight_loading.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/story_opponents.tscn")
		get_viewport().set_input_as_handled()
