extends Control
## First playable Story step: build and save the player's character.

const SAVE_PATH := "user://story_character.cfg"
const ROSTER_PATH := "user://story_characters.cfg"
const CHARACTER_NAME_MAX_LENGTH := 32
const PreviewCharacter := preload("res://scripts/story_character.gd")
const RANDOM_FIRST_NAMES: Array[String] = [
	"Ari", "Asha", "Bram", "Bryn", "Cato", "Cira", "Dain", "Dara", "Eira", "Elian",
	"Ember", "Enna", "Faye", "Finn", "Galen", "Gwen", "Hale", "Ilya", "Iris", "Jora",
	"Kael", "Kara", "Kellan", "Lio", "Liora", "Maeve", "Mara", "Mika", "Neri", "Niko",
	"Nora", "Orin", "Pax", "Quinn", "Rhea", "Riven", "Rowan", "Sable", "Tarin", "Tessa",
	"Thea", "Vale", "Vera", "Wren", "Yara", "Zara", "Zev", "Alden", "Mira", "Sylvi"
]
const RANDOM_SURNAMES: Array[String] = [
	"Ashford", "Ashvale", "Blackthorn", "Brightwater", "Dawnmere", "Duskwood", "Emberfall", "Fairwind",
	"Frostvale", "Goldleaf", "Graymantle", "Greenbriar", "Hawthorne", "Highfield", "Ironwood", "Kestrel",
	"Lakewood", "Lightfoot", "Longstride", "Morningsong", "Nightbrook", "Northwind", "Oakenshield", "Pineward",
	"Quickwater", "Redfern", "Riversong", "Rosewood", "Silvermere", "Skylark", "Softstep", "Starling",
	"Stillwater", "Stormcrow", "Sunweaver", "Thornfield", "Underhill", "Valehart", "Westbrook", "Wildmere",
	"Windrow", "Winterborne", "Wolfsbane", "Yarrow", "Cloudrest", "Dawnbreak", "Farstrider", "Moonwell", "Stonepath", "Trueheart"
]
const RANDOM_NAME_WORDS: Array[String] = [
	"Ash", "Blaze", "Brook", "Cloud", "Comet", "Dawn", "Echo", "Ember", "Flint", "Frost",
	"Gale", "Glimmer", "Hollow", "Hope", "Iron", "Jade", "Lark", "Leaf", "Mistral", "Moon",
	"Moss", "Nova", "Oak", "Onyx", "Rain", "Reed", "River", "Shadow", "Silver", "Sky",
	"Sparrow", "Star", "Stone", "Storm", "Sun", "Thistle", "Vale", "Willow", "Winter", "Zephyr"
]

var profile := {
	"name": "Avery",
	"body": "Masculine",
	"skin": "Dark",
	"skin_color": Color("925438"),
	"hair": "Short",
	"hair_color": Color("151515"),
	"outfit_color": Color("426c91"),
	"trim_color": Color("d0b77b"),
	"height": 1.0,
	"build": 1.0,
	"arms_size": 1.0,
	"legs_size": 1.0,
	"hands_size": 1.0,
	"feet_size": 1.0,
	"head_size": 1.0,
	"top_size": 1.08,
	"bottoms_size": 1.0,
	"gloves_size": 1.0,
	"handwear_size": 1.0,
	"belt_size": 1.0,
	"footwear_size": 1.0,
	"hat_size": 1.0,
	"mask_size": 1.0,
	"back_size": 1.0,
	"mask_offset_x": 0.0,
	"mask_offset_y": 0.0,
	"mask_offset_z": 0.0,
	"back_offset_x": 0.0,
	"back_offset_y": 0.0,
	"back_offset_z": 0.0,
	"shirt_color": Color("426c91"),
	"bottoms_color": Color("34383e"),
	"gloves_color": Color("29313b"),
	"handwear_color": Color("29313b"),
	"belt_color": Color("8a6135"),
	"footwear_color": Color("354438"),
	"hat_color": Color("3b3028"),
	"mask_color": Color("29313b"),
	"back_color": Color("426c91"),
	"rotation": 0.0,
	"wardrobe_style": "Mix & match",
	"wardrobe_shirt": "Peasant",
	"wardrobe_pants": "Peasant",
	"wardrobe_arms": "Peasant",
	"wardrobe_hands": "None",
	"wardrobe_belt": "None",
	"wardrobe_boots": "Peasant",
	"wardrobe_hat": "None",
	"wardrobe_mask": "None",
	"wardrobe_back": "None",
}
var preview: Node3D
var preview_camera: Camera3D
var name_input: LineEdit
var body_choice: OptionButton
var skin_choice: OptionButton
var skin_picker: ColorPickerButton
var hair_choice: OptionButton
var height_slider: HSlider
var shape_sliders: Dictionary = {}
var hair_picker: ColorPickerButton
var wardrobe_rows: VBoxContainer
var shirt_choice: OptionButton
var pants_choice: OptionButton
var arms_choice: OptionButton
var hands_choice: OptionButton
var belt_choice: OptionButton
var boots_choice: OptionButton
var hat_choice: OptionButton
var mask_choice: OptionButton
var back_choice: OptionButton
var gear_color_pickers: Dictionary = {}
var underclothes_button: Button
var status_label: Label
var page_content: VBoxContainer
var name_profanity_filter := RegEx.new()
var dragging := false
var last_pointer := Vector2.ZERO
var saved := false
var applying := false
var editing_existing := false

func _ready() -> void:
	var setup_started_usec := Time.get_ticks_usec()
	name_profanity_filter.compile("(?i)(^|[^a-z0-9])(motherfucker|fuck\\w*|shit\\w*|bitch\\w*|asshole|cunt|dick\\w*|piss\\w*|damn\\w*|bastard\\w*|whore|slut|nigger|nigga|faggot|retard)(?=$|[^a-z0-9])")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	editing_existing = get_tree().has_meta("story_edit_existing") and bool(get_tree().get_meta("story_edit_existing"))
	if get_tree().has_meta("story_edit_existing"):
		get_tree().remove_meta("story_edit_existing")
	var create_new_character := get_tree().has_meta("story_create_new") and bool(get_tree().get_meta("story_create_new"))
	if get_tree().has_meta("story_create_new"):
		get_tree().remove_meta("story_create_new")
	if not create_new_character:
		_load_profile()
	else:
		profile.erase("character_id")
		profile["punch_tutorial_complete"] = false
		profile["punch_tutorial_1_complete"] = false
		profile["punch_tutorial_2_complete"] = false
	# Replace the starter placeholder on entry, while preserving names already
	# chosen and saved by the player.
	if str(profile.get("name", "Avery")) == "Avery":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		profile["name"] = _random_character_name(rng)
	_build_ui()
	_refresh_preview()
	GameDiagnostics.log_timing("character_creator_setup", setup_started_usec, {"editing_existing":editing_existing, "wardrobe_parts":gear_color_pickers.size()})

func _process(_delta: float) -> void:
	if preview != null:
		profile["rotation"] = preview.rotation.y

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not get_viewport().gui_get_focus_owner() is LineEdit:
		if event.keycode in [KEY_BRACKETLEFT,KEY_BRACKETRIGHT] and preview!=null:
			preview.rotation.y+=(-1 if event.keycode==KEY_BRACKETLEFT else 1)*PI/8
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_MINUS,KEY_EQUAL,KEY_KP_ADD,KEY_KP_SUBTRACT]:
			_zoom_camera(-0.25 if event.keycode in [KEY_EQUAL,KEY_KP_ADD] else 0.25)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/story_opponents.tscn" if editing_existing else "res://scenes/home.tscn")
		get_viewport().set_input_as_handled()

func _load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var stored: Variant = config.get_value("character", "profile", {})
	if stored is Dictionary:
		for key in stored:
			profile[key] = stored[key]
	profile["wardrobe_style"] = "Mix & match"
	# Accessories are reserved for earned gear and stay off the tutorial starter.
	profile["wardrobe_hat"] = "None"
	profile["wardrobe_mask"] = "None"
	profile["wardrobe_back"] = "None"
	profile["height"] = clampf(float(profile.get("height", 1.0)), 0.9, 1.1)
	profile["build"] = clampf(float(profile.get("build", 1.0)), 0.947, 1.06)
	for slot in ["mask", "back"]:
		for axis in ["x", "y", "z"]:
			var key := "%s_offset_%s" % [slot, axis]
			profile[key] = clampf(float(profile.get(key, 0.0)), -0.25, 0.25)
	if str(profile.get("wardrobe_mask", "None")) == "Cloth mask":
		profile["wardrobe_mask"] = "Rogue mask"
	if str(profile.get("hair", "")) == "Buzz":
		profile["hair"] = "Short"
	for key in ["wardrobe_shirt", "wardrobe_pants", "wardrobe_arms", "wardrobe_boots"]:
		if str(profile.get(key, "")) == "Commoner":
			profile[key] = "Traveler"
		elif str(profile.get(key, "")) == "Field worker":
			profile[key] = "Guard castoff"
		elif str(profile.get(key, "")) == "Ranger":
			profile[key] = "Traveler"
	profile.erase("chin_size")

func _build_ui() -> void:
	var book_theme := Theme.new()
	book_theme.set_color("font_color", "Label", Color("382c1c"))
	book_theme.set_color("font_color", "Button", Color("382c1c"))
	book_theme.set_color("font_color", "OptionButton", Color("382c1c"))
	book_theme.set_color("font_color", "LineEdit", Color("382c1c"))
	theme = book_theme
	var bg := ColorRect.new()
	bg.color = Color("302116")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var backdrop := ColorRect.new()
	backdrop.color = Color("e8ddc4")
	backdrop.anchor_left = 0.0
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 28)
	root_margin.add_theme_constant_override("margin_right", 28)
	root_margin.add_theme_constant_override("margin_top", 20)
	root_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(root_margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	root_margin.add_child(columns)
	var sidebar := _panel()
	sidebar.custom_minimum_size = Vector2(355, 0)
	columns.add_child(sidebar)
	var sidebar_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		sidebar_margin.add_theme_constant_override("margin_" + side, 22 if side in ["left", "right"] else 18)
	sidebar.add_child(sidebar_margin)
	var sidebar_stack := VBoxContainer.new()
	sidebar_stack.add_theme_constant_override("separation", 10)
	sidebar_margin.add_child(sidebar_stack)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# The vertical bar is drawn inside the scroll viewport, so reserve a little
	# room for it and prevent a narrow sidebar from creating horizontal overflow.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	sidebar_stack.add_child(scroll)
	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_right", 14)
	scroll.add_child(content_margin)
	page_content = VBoxContainer.new()
	page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_content.add_theme_constant_override("separation", 12)
	content_margin.add_child(page_content)
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 7)
	sidebar_stack.add_child(footer)
	var title := Label.new()
	title.text = "YOUR STORY"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("8b642d"))
	page_content.add_child(title)
	var heading := Label.new()
	heading.text = "Create your fighter"
	heading.add_theme_font_size_override("font_size", 29)
	heading.add_theme_color_override("font_color", Color("382c1c"))
	page_content.add_child(heading)
	var description := Label.new()
	description.text = "Choose how you look. You can change this any time before we begin the story."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color("655740"))
	page_content.add_child(description)
	var random_button := _button("Randomize character", false)
	random_button.custom_minimum_size.y = 44
	random_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_button.pressed.connect(_randomize_character)
	page_content.add_child(random_button)
	_add_divider()
	_add_section_label("IDENTITY")
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	page_content.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "NAME:"
	name_label.custom_minimum_size.x = 76
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("382c1c"))
	name_row.add_child(name_label)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Choose a name"
	name_input.max_length = CHARACTER_NAME_MAX_LENGTH
	name_input.text = str(profile.get("name", "Avery")).substr(0, CHARACTER_NAME_MAX_LENGTH)
	name_input.custom_minimum_size.y = 42
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_field_style := StyleBoxFlat.new()
	name_field_style.bg_color = Color("f0e8d5")
	name_field_style.border_color = Color("b5a27f")
	name_field_style.set_border_width_all(1)
	name_field_style.set_corner_radius_all(4)
	name_input.add_theme_stylebox_override("normal", name_field_style)
	name_input.add_theme_stylebox_override("focus", name_field_style)
	name_input.text_changed.connect(_on_name_changed)
	name_row.add_child(name_input)
	body_choice = _option_row("Body", ["Masculine", "Feminine"], str(profile.get("body", "Masculine")))
	body_choice.item_selected.connect(_on_body_changed)
	skin_choice = _option_row("Skin", ["Light", "Dark"], str(profile.get("skin", "Light")))
	skin_choice.item_selected.connect(_on_appearance_changed)
	skin_picker = _color_row("Skin color", profile.get("skin_color", Color("925438")))
	skin_picker.tooltip_text = "Choose any RGB skin tint"
	skin_picker.color_changed.connect(_on_skin_color_changed)
	hair_choice = _option_row("Hair", ["Short", "Buns", "Long", "Side part", "None"], str(profile.get("hair", "Short")))
	hair_choice.item_selected.connect(_on_hair_changed)
	hair_picker = _color_row("Hair color", profile.get("hair_color", Color("3c2b25")))
	hair_picker.color_changed.connect(_on_hair_color_changed)
	_add_divider()
	_add_section_label("OUTFIT")
	wardrobe_rows = VBoxContainer.new()
	wardrobe_rows.add_theme_constant_override("separation", 6)
	page_content.add_child(wardrobe_rows)
	underclothes_button = _button("Underclothes only", false)
	underclothes_button.pressed.connect(_set_underclothes_only)
	wardrobe_rows.add_child(underclothes_button)
	var garment_variants: Array[String] = ["Peasant", "Traveler", "Guard castoff", "Underclothes"]
	var body_variants: Array[String] = ["Peasant", "Traveler", "Guard castoff", "Bare"]
	shirt_choice = _add_gear_row("Chest", "wardrobe_shirt", garment_variants, "top_size", "shirt_color", Color("426c91"))
	pants_choice = _add_gear_row("Bottoms", "wardrobe_pants", garment_variants, "bottoms_size", "bottoms_color", Color("34383e"))
	arms_choice = _add_gear_row("Arms", "wardrobe_arms", body_variants, "gloves_size", "gloves_color", Color("29313b"))
	var handwear_variants: Array[String] = ["None", "Fingerless gloves"]
	hands_choice = _add_gear_row("Hands", "wardrobe_hands", handwear_variants, "handwear_size", "handwear_color", Color("29313b"))
	var belt_variants: Array[String] = ["None", "Leather belt"]
	belt_choice = _add_gear_row("Belt", "wardrobe_belt", belt_variants, "belt_size", "belt_color", Color("8a6135"))
	boots_choice = _add_gear_row("Footwear", "wardrobe_boots", body_variants, "footwear_size", "footwear_color", Color("354438"))
	_sync_wardrobe_controls()
	_add_divider()
	_add_section_label("BODY SHAPE")
	height_slider = HSlider.new()
	height_slider.min_value = 0.9
	height_slider.max_value = 1.1
	height_slider.step = 0.01
	height_slider.value = float(profile.get("height", 1.0))
	height_slider.value_changed.connect(_on_height_changed)
	_add_labeled_control("Height", height_slider)
	_add_shape_slider("build", "Overall build", 0.947, 1.06)
	_add_shape_slider("arms_size", "Biceps", 0.88, 1.16)
	_add_shape_slider("legs_size", "Leg size", 0.88, 1.16)
	_add_shape_slider("hands_size", "Hand size", 0.88, 1.16)
	_add_shape_slider("feet_size", "Feet", 0.88, 1.16)
	_add_shape_slider("head_size", "Head size", 0.90, 1.12)
	status_label = Label.new()
	status_label.text = "Drag the preview to turn your character."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color("655740"))
	footer.add_child(status_label)
	var confirm := _button("Confirm character", true)
	confirm.custom_minimum_size.y = 50
	confirm.pressed.connect(_confirm_character)
	footer.add_child(confirm)
	var back := _button("Back to menu", false)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/home.tscn"))
	footer.add_child(back)
	var preview_column := VBoxContainer.new()
	preview_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_column.add_theme_constant_override("separation", 8)
	columns.add_child(preview_column)
	var preview_header := HBoxContainer.new()
	preview_column.add_child(preview_header)
	var preview_title := Label.new()
	preview_title.text = "CHARACTER PREVIEW"
	preview_title.add_theme_font_size_override("font_size", 13)
	preview_title.add_theme_color_override("font_color", Color("614421"))
	preview_header.add_child(preview_title)
	var preview_hint := Label.new()
	preview_hint.text = "  DRAG TO ROTATE  ·  WHEEL TO ZOOM"
	preview_hint.add_theme_font_size_override("font_size", 11)
	preview_hint.add_theme_color_override("font_color", Color("75664f"))
	preview_header.add_child(preview_hint)
	var view_container := SubViewportContainer.new()
	view_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view_container.stretch = true
	view_container.gui_input.connect(_on_preview_input)
	preview_column.add_child(view_container)
	var viewport := SubViewport.new()
	viewport.name = "CharacterViewport"
	viewport.size = Vector2i(800, 800)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view_container.add_child(viewport)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("e8ddc4")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9bed1")
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	viewport.add_child(world)
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(0, 1.0, 4.15)
	preview_camera.fov = 33
	viewport.add_child(preview_camera)
	preview_camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -28, 0)
	key_light.light_energy = 1.45
	viewport.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-1.8, 1.4, 1.5)
	fill_light.light_color = Color("f0d9a7")
	fill_light.light_energy = 0.7
	fill_light.omni_range = 7
	viewport.add_child(fill_light)
	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(1.5, 2.2, -1.0)
	rim_light.light_color = Color("e5b971")
	rim_light.light_energy = 1.0
	rim_light.omni_range = 6
	viewport.add_child(rim_light)
	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 0.82
	floor_mesh.bottom_radius = 0.9
	floor_mesh.height = 0.10
	floor.mesh = floor_mesh
	floor.position.y = -0.055
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("9b8158")
	floor_material.metallic = 0.35
	floor_material.roughness = 0.5
	floor.material_override = floor_material
	viewport.add_child(floor)
	preview = PreviewCharacter.new()
	preview.position.y = 0.0
	viewport.add_child(preview)

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e8ddc4")
	style.border_color = Color("b5a27f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("8b642d"))
	page_content.add_child(label)

func _add_divider() -> void:
	var line := HSeparator.new()
	line.add_theme_color_override("separator", Color("b5a27f"))
	page_content.add_child(line)

func _option_row(title: String, options: Array[String], selected: String, parent: Control = null) -> OptionButton:
	var option := OptionButton.new()
	_style_book_option(option)
	for value in options:
		option.add_item(value)
	option.select(maxi(0, options.find(selected)))
	_add_labeled_control(title, option, parent)
	return option

func _color_row(title: String, initial: Color) -> ColorPickerButton:
	var picker := ColorPickerButton.new()
	picker.color = initial
	picker.custom_minimum_size = Vector2(86, 34)
	_add_labeled_control(title, picker)
	return picker

func _add_labeled_control(title: String, control: Control, parent: Control = null) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var target := page_content if parent == null else parent
	target.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 92
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("655740"))
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)

func _add_shape_slider(key: String, title: String, minimum: float, maximum: float) -> void:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.01
	slider.value = float(profile.get(key, 1.0))
	if key == "build":
		slider.tooltip_text = "Adjust overall frame build"
	slider.value_changed.connect(func(value: float): _on_shape_changed(key, value))
	shape_sliders[key] = slider
	_add_labeled_control(title, slider)

func _add_gear_row(title: String, choice_key: String, options: Array[String], size_key: String, color_key: String, default_color: Color, accessory_options_key := "") -> OptionButton:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	wardrobe_rows.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 66
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("655740"))
	row.add_child(label)
	var option := OptionButton.new()
	_style_book_option(option)
	for value in options:
		option.add_item(value)
	var selected := str(profile.get(choice_key, options[0]))
	option.select(maxi(0, options.find(selected)))
	option.custom_minimum_size.x = 112
	option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	option.fit_to_longest_item = false
	option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	option.clip_contents = true
	option.item_selected.connect(func(_index: int): _on_wardrobe_piece_changed(choice_key, option))
	row.add_child(option)
	var picker := ColorPickerButton.new()
	picker.color = profile.get(color_key, default_color)
	picker.custom_minimum_size = Vector2(32, 32)
	picker.tooltip_text = "RGB color picker"
	picker.color_changed.connect(func(color: Color): _on_gear_color_changed(color_key, color))
	gear_color_pickers[color_key] = picker
	row.add_child(picker)
	if accessory_options_key.is_empty():
		var slider := HSlider.new()
		slider.min_value = 0.85
		slider.max_value = 1.50
		slider.step = 0.01
		slider.value = float(profile.get(size_key, 1.0 if size_key != "top_size" else 1.08))
		slider.custom_minimum_size.x = 52
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.tooltip_text = "Size: 85%–150%"
		slider.value_changed.connect(func(value: float):
			profile[size_key] = value
			_set_preview_wardrobe_size(choice_key, value)
		)
		shape_sliders[size_key] = slider
		row.add_child(slider)
	else:
		var options_button := Button.new()
		options_button.text = "⚙"
		options_button.custom_minimum_size = Vector2(34, 32)
		options_button.tooltip_text = "Position and size options"
		options_button.pressed.connect(func(): _open_accessory_options(title, accessory_options_key, size_key))
		row.add_child(options_button)
	return option

func _style_book_option(option: OptionButton) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f0e8d5")
	style.border_color = Color("b5a27f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	option.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("fff7e6")
	option.add_theme_stylebox_override("hover", hover)

func _open_accessory_options(title: String, slot: String, size_key: String) -> void:
	var popup := PopupPanel.new()
	popup.exclusive = true
	popup.size = Vector2i(360, 450)
	add_child(popup)
	popup.popup_hide.connect(func(): popup.queue_free())
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("101925")
	panel_style.border_color = Color("405569")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	popup.add_child(panel)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(330, 420)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = "%s options" % title
	heading.add_theme_font_size_override("font_size", 18)
	content.add_child(heading)
	var hint := Label.new()
	hint.text = "Drag the dot to move it left/right and up/down."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("9eb0c1"))
	content.add_child(hint)
	var pad := Panel.new()
	pad.custom_minimum_size = Vector2(300, 170)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	var pad_style := StyleBoxFlat.new()
	pad_style.bg_color = Color("172637")
	pad_style.border_color = Color("405569")
	pad_style.set_border_width_all(1)
	pad_style.set_corner_radius_all(8)
	pad.add_theme_stylebox_override("panel", pad_style)
	content.add_child(pad)
	var cross_x := ColorRect.new()
	cross_x.color = Color("31475a")
	cross_x.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross_x.custom_minimum_size = Vector2(1, 1)
	pad.add_child(cross_x)
	var cross_y := ColorRect.new()
	cross_y.color = Color("31475a")
	cross_y.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross_y.custom_minimum_size = Vector2(1, 1)
	pad.add_child(cross_y)
	var marker := ColorRect.new()
	marker.color = Color("d8b975")
	marker.custom_minimum_size = Vector2(16, 16)
	marker.size = Vector2(16, 16)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(marker)
	var coordinates := Label.new()
	coordinates.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coordinates.add_theme_color_override("font_color", Color("c7d5e0"))
	content.add_child(coordinates)
	var drag_state := {"dragging": false, "slot": slot}
	pad.focus_mode=Control.FOCUS_ALL
	pad.tooltip_text="Arrow keys adjust accessory position; Shift makes fine adjustments."
	pad.gui_input.connect(_on_accessory_pad_input.bind(pad, marker, coordinates, drag_state))
	pad.resized.connect(_position_accessory_marker.bind(pad, marker, coordinates, slot))
	_position_accessory_marker(pad, marker, coordinates, slot)
	var depth_title := Label.new()
	depth_title.text = "Forward / back offset"
	content.add_child(depth_title)
	var depth := HSlider.new()
	depth.min_value = -0.25
	depth.max_value = 0.25
	depth.step = 0.005
	depth.value = float(profile.get(slot + "_offset_z", 0.0))
	depth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	depth.value_changed.connect(func(value: float): _on_accessory_setting_changed(slot + "_offset_z", value))
	content.add_child(depth)
	var size_title := Label.new()
	size_title.text = "Size: %d%%" % roundi(float(profile.get(size_key, 1.0)) * 100.0)
	content.add_child(size_title)
	var size_slider := HSlider.new()
	size_slider.min_value = 0.85
	size_slider.max_value = 1.50
	size_slider.step = 0.01
	size_slider.value = float(profile.get(size_key, 1.0))
	size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_slider.value_changed.connect(func(value: float):
		profile[size_key] = value
		size_title.text = "Size: %d%%" % roundi(value * 100.0)
		_set_preview_wardrobe_size("wardrobe_%s" % slot, value)
	)
	content.add_child(size_slider)
	var close := _button("Done", false)
	close.pressed.connect(popup.hide)
	content.add_child(close)
	popup.popup_centered()
	_position_accessory_marker.call_deferred(pad, marker, coordinates, slot)

func _on_accessory_pad_input(event: InputEvent, pad: Control, marker: Control, coordinates: Label, drag_state: Dictionary) -> void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		var slot := str(drag_state["slot"])
		var step := 0.002 if event.shift_pressed else 0.01
		var horizontal: bool = event.keycode in [KEY_LEFT,KEY_RIGHT]
		var key := slot+("_offset_x" if horizontal else "_offset_y")
		profile[key]=clampf(float(profile.get(key,0.0))+step*(-1 if event.keycode in [KEY_LEFT,KEY_DOWN] else 1),-0.25,0.25)
		_position_accessory_marker(pad,marker,coordinates,slot)
		_refresh_preview()
		pad.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag_state["dragging"] = event.pressed
		if event.pressed:
			_set_accessory_pad_position(event.position, pad, marker, coordinates, str(drag_state["slot"]))
	elif event is InputEventMouseMotion and bool(drag_state.get("dragging", false)):
		_set_accessory_pad_position(event.position, pad, marker, coordinates, str(drag_state["slot"]))

func _set_accessory_pad_position(pointer: Vector2, pad: Control, marker: Control, coordinates: Label, slot: String) -> void:
	var travel := pad.size - marker.size
	if travel.x <= 0.0 or travel.y <= 0.0:
		return
	var normalized := Vector2(clampf(pointer.x / pad.size.x, 0.0, 1.0), clampf(pointer.y / pad.size.y, 0.0, 1.0))
	var x_offset := lerpf(-0.25, 0.25, normalized.x)
	var y_offset := lerpf(0.25, -0.25, normalized.y)
	profile[slot + "_offset_x"] = x_offset
	profile[slot + "_offset_y"] = y_offset
	_position_accessory_marker(pad, marker, coordinates, slot)
	_refresh_preview()

func _position_accessory_marker(pad: Control, marker: Control, coordinates: Label, slot: String) -> void:
	var travel := pad.size - marker.size
	if travel.x <= 0.0 or travel.y <= 0.0:
		return
	var x_offset := clampf(float(profile.get(slot + "_offset_x", 0.0)), -0.25, 0.25)
	var y_offset := clampf(float(profile.get(slot + "_offset_y", 0.0)), -0.25, 0.25)
	marker.position = Vector2((x_offset + 0.25) / 0.5 * travel.x, (0.25 - y_offset) / 0.5 * travel.y)
	var center := pad.size * 0.5
	var horizontal_line := pad.get_child(0) as ColorRect
	horizontal_line.position = Vector2(0, center.y)
	horizontal_line.size = Vector2(pad.size.x, 1)
	var vertical_line := pad.get_child(1) as ColorRect
	vertical_line.position = Vector2(center.x, 0)
	vertical_line.size = Vector2(1, pad.size.y)
	coordinates.text = "X %.2f m     Y %.2f m" % [x_offset, y_offset]

func _on_accessory_setting_changed(key: String, value: float) -> void:
	profile[key] = value
	_refresh_preview()

func _button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("c9a65e") if primary else Color("ded1b5")
	normal.border_color = Color("9a7440")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("dfbd74") if primary else Color("f0e3c8")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("a98444") if primary else Color("cfb98c")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("382c1c"))
	return button

func _selected(option: OptionButton) -> String:
	return option.get_item_text(option.selected)

func _refresh_preview(rebuild := true) -> void:
	if preview == null:
		return
	if rebuild:
		preview.set_profile(profile)
	else:
		preview.scale = Vector3.ONE * float(profile.get("height", 1.0))
		preview.rotation.y = float(profile.get("rotation", 0.0))

func _on_name_changed(value: String) -> void:
	profile["name"] = value.strip_edges()
	if status_label == null:
		return
	if _name_contains_profanity(value):
		status_label.text = "Please choose a name without profanity."
		status_label.add_theme_color_override("font_color", Color("a33d32"))
	else:
		status_label.text = "Drag the preview to turn your character."
		status_label.add_theme_color_override("font_color", Color("655740"))

func _name_contains_profanity(value: String) -> bool:
	return name_profanity_filter.search(value) != null

func _on_body_changed(_index: int) -> void:
	profile["body"] = _selected(body_choice)
	var expected_skin := str(profile.get("skin", "Light"))
	if expected_skin not in ["Light", "Dark"]:
		profile["skin"] = "Light"
	_refresh_preview()

func _on_appearance_changed(_index: int) -> void:
	if applying:
		return
	profile["skin"] = _selected(skin_choice)
	_refresh_preview()

func _on_skin_color_changed(color: Color) -> void:
	if applying:
		return
	profile["skin_color"] = color
	_refresh_preview()

func _on_hair_changed(_index: int) -> void:
	if applying:
		return
	profile["hair"] = _selected(hair_choice)
	_refresh_preview()

func _on_hair_color_changed(color: Color) -> void:
	if applying:
		return
	profile["hair_color"] = color
	_refresh_preview()

func _on_outfit_color_changed(color: Color) -> void:
	if applying:
		return
	profile["outfit_color"] = color
	_refresh_preview()

func _on_trim_color_changed(color: Color) -> void:
	if applying:
		return
	profile["trim_color"] = color
	_refresh_preview()

func _sync_wardrobe_controls() -> void:
	if wardrobe_rows == null:
		return
	wardrobe_rows.visible = true
	_select_text(shirt_choice, str(profile.get("wardrobe_shirt", "Peasant")))
	_select_text(pants_choice, str(profile.get("wardrobe_pants", "Peasant")))
	_select_text(arms_choice, str(profile.get("wardrobe_arms", "Peasant")))
	_select_text(hands_choice, str(profile.get("wardrobe_hands", "None")))
	_select_text(belt_choice, str(profile.get("wardrobe_belt", "None")))
	_select_text(boots_choice, str(profile.get("wardrobe_boots", "Peasant")))
	for key in shape_sliders:
		shape_sliders[key].value = float(profile.get(key, 1.08 if key == "top_size" else 1.0))
	for key in gear_color_pickers:
		gear_color_pickers[key].color = profile.get(key, Color.WHITE)

func _set_underclothes_only() -> void:
	if applying:
		return
	profile["wardrobe_shirt"] = "Underclothes"
	profile["wardrobe_pants"] = "Underclothes"
	profile["wardrobe_arms"] = "Bare"
	profile["wardrobe_hands"] = "None"
	profile["wardrobe_belt"] = "None"
	profile["wardrobe_boots"] = "Bare"
	_sync_wardrobe_controls()
	_refresh_preview()

func _on_wardrobe_piece_changed(key: String, option: OptionButton) -> void:
	if applying:
		return
	profile[key] = _selected(option)
	_refresh_preview()

func _on_gear_color_changed(key: String, color: Color) -> void:
	if applying:
		return
	profile[key] = color
	_refresh_preview()

func _on_height_changed(value: float) -> void:
	if applying:
		return
	profile["height"] = value
	_refresh_preview(false)

func _on_shape_changed(key: String, value: float) -> void:
	if applying:
		return
	profile[key] = value
	_refresh_preview()

func _set_preview_wardrobe_size(wardrobe_key: String, value: float) -> void:
	if is_instance_valid(preview):
		preview.set_wardrobe_size(wardrobe_key, value)

func _randomize_character() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	profile["name"] = _random_character_name(rng)
	profile["body"] = ["Masculine", "Feminine"][rng.randi_range(0, 1)]
	# Skin is a real color tint on top of the selected base texture; randomize it
	# as well as the broad Light/Dark texture choice so the button changes both.
	var skin_tones: Array[Color] = [
		Color("f0c7a0"), Color("d9a47d"), Color("bd8059"),
		Color("925438"), Color("70402d"), Color("4b2b22"), Color("321d19")
	]
	var skin_tone_index := rng.randi_range(0, skin_tones.size() - 1)
	profile["skin"] = "Light" if skin_tone_index < 3 else "Dark"
	profile["skin_color"] = skin_tones[skin_tone_index]
	profile["hair"] = ["Short", "Buns", "Long", "Side part", "None"][rng.randi_range(0, 4)]
	profile["hair_color"] = [Color("30211d"), Color("714328"), Color("b4a27f"), Color("17191e")][rng.randi_range(0, 3)]
	profile["wardrobe_shirt"] = ["Peasant", "Traveler", "Guard castoff", "Underclothes"][rng.randi_range(0, 3)]
	profile["wardrobe_pants"] = ["Peasant", "Traveler", "Guard castoff", "Underclothes"][rng.randi_range(0, 3)]
	profile["wardrobe_arms"] = ["Peasant", "Traveler", "Guard castoff", "Bare"][rng.randi_range(0, 3)]
	profile["wardrobe_hands"] = ["None", "Fingerless gloves"][rng.randi_range(0, 1)]
	profile["wardrobe_belt"] = ["None", "Leather belt"][rng.randi_range(0, 1)]
	profile["wardrobe_boots"] = ["Peasant", "Traveler", "Guard castoff", "Bare"][rng.randi_range(0, 3)]
	profile["wardrobe_hat"] = "None"
	profile["wardrobe_mask"] = "None"
	profile["wardrobe_back"] = "None"
	profile["height"] = rng.randf_range(0.94, 1.06)
	for key in ["build", "arms_size", "legs_size", "hands_size", "feet_size", "head_size", "bottoms_size", "gloves_size", "handwear_size", "belt_size", "footwear_size", "hat_size", "mask_size", "back_size"]:
		profile[key] = 1.0
	for key in ["mask_offset_x", "mask_offset_y", "mask_offset_z", "back_offset_x", "back_offset_y", "back_offset_z"]:
		profile[key] = 0.0
	profile["top_size"] = 1.08
	for key in ["shirt_color", "bottoms_color", "gloves_color", "handwear_color", "belt_color", "footwear_color", "hat_color", "mask_color", "back_color"]:
		profile[key] = Color.from_hsv(rng.randf(), 0.38, 0.66)
	applying = true
	name_input.text = str(profile["name"])
	_select_text(body_choice, str(profile["body"]))
	_select_text(skin_choice, str(profile["skin"]))
	_select_text(hair_choice, str(profile["hair"]))
	_sync_wardrobe_controls()
	skin_picker.color = profile.get("skin_color", Color.WHITE)
	hair_picker.color = profile["hair_color"]
	height_slider.value = float(profile["height"])
	for key in shape_sliders:
		shape_sliders[key].value = float(profile.get(key, 1.08 if key == "top_size" else 1.0))
	for key in gear_color_pickers:
		gear_color_pickers[key].color = profile[key]
	applying = false
	_refresh_preview()

func _random_character_name(rng: RandomNumberGenerator) -> String:
	var first := RANDOM_FIRST_NAMES[rng.randi_range(0, RANDOM_FIRST_NAMES.size() - 1)]
	var surname := RANDOM_SURNAMES[rng.randi_range(0, RANDOM_SURNAMES.size() - 1)]
	var word := RANDOM_NAME_WORDS[rng.randi_range(0, RANDOM_NAME_WORDS.size() - 1)]
	match rng.randi_range(0, 2):
		0:
			return "%s %s" % [first, surname]
		1:
			return "%s %s" % [first, word]
		_:
			return "%s %s" % [word, surname]

func _select_text(option: OptionButton, value: String) -> void:
	for index in option.item_count:
		if option.get_item_text(index) == value:
			option.select(index)
			return

func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_pointer = event.position
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-0.32)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(0.32)
	elif event is InputEventMouseMotion and dragging and preview != null:
		preview.rotation.y += (event.position.x - last_pointer.x) * 0.012
		last_pointer = event.position
		profile["rotation"] = preview.rotation.y

func _zoom_camera(amount: float) -> void:
	if preview_camera != null:
		preview_camera.position.z = clampf(preview_camera.position.z + amount, 1.0, 5.2)
		var face_zoom := 1.0 - inverse_lerp(1.0, 5.2, preview_camera.position.z)
		var focus_y := lerpf(0.95, 1.62, face_zoom)
		preview_camera.position.y = lerpf(1.0, 1.64, face_zoom)
		preview_camera.look_at(Vector3(0, focus_y, 0), Vector3.UP)

func _confirm_character() -> void:
	profile["name"] = name_input.text.strip_edges()
	if str(profile["name"]).is_empty():
		status_label.text = "Please enter a name."
		status_label.add_theme_color_override("font_color", Color("a33d32"))
		name_input.grab_focus()
		return
	if _name_contains_profanity(str(profile["name"])):
		status_label.text = "Please choose a name without profanity."
		status_label.add_theme_color_override("font_color", Color("a33d32"))
		name_input.grab_focus()
		return
	if not profile.has("character_id"):
		profile["character_id"] = "%s-%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	profile["story_stage"] = int(profile.get("story_stage", 1))
	profile["story_location"] = str(profile.get("story_location", "Colosseum"))
	if not editing_existing:
		# New characters begin at the start of the introduction.
		profile["punch_tutorial_complete"] = false
		profile["punch_tutorial_1_complete"] = false
		profile["punch_tutorial_2_complete"] = false
	if not profile.has("gear_slots"):
		profile["gear_slots"] = {
			"chest":{"ability":"", "input":"mouse_both"},
			"bottoms":{"ability":"", "input":"key_1"},
			"left_arm":{"ability":"punch_left", "input":"mouse_left"},
			"right_arm":{"ability":"", "input":"mouse_right"},
			"left_hand":{"ability":"", "input":"key_1"},
			"right_hand":{"ability":"", "input":"key_1"},
			"belt":{"ability":"", "input":"key_1"},
			"left_foot":{"ability":"", "input":"key_1"},
			"right_foot":{"ability":"", "input":"key_1"},
			"head":{"ability":"", "input":"key_1"},
			"face":{"ability":"", "input":"key_1"},
			"back":{"ability":"", "input":"key_1"},
		}
	var config := ConfigFile.new()
	config.set_value("character", "profile", profile)
	var result := config.save(SAVE_PATH)
	var roster := ConfigFile.new()
	roster.load(ROSTER_PATH)
	var characters: Array = roster.get_value("roster", "characters", [])
	var replaced := false
	for index in characters.size():
		var saved: Variant = characters[index]
		if saved is Dictionary and str(saved.get("character_id", "")) == str(profile["character_id"]):
			characters[index] = profile.duplicate(true)
			replaced = true
			break
	if not replaced:
		characters.append(profile.duplicate(true))
	roster.set_value("roster", "characters", characters)
	if result == OK:
		result = roster.save(ROSTER_PATH)
	if result == OK:
		saved = true
		GameDiagnostics.log_event("character_saved", {"name":profile.get("name", ""), "character_id":profile.get("character_id", ""), "story_stage":profile.get("story_stage", 1), "editing_existing":editing_existing})
		if not editing_existing:
			# New story characters go straight to their animation and spell loadout.
			# From there the player can return to the book and begin the tutorial.
			get_tree().change_scene_to_file("res://scenes/story_loadout.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/story_opponents.tscn")
	else:
		status_label.text = "Could not save this character. Please try again."
		status_label.add_theme_color_override("font_color", Color("e59a91"))
