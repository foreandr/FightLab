extends Control
## Simple story staging area for spawning, selecting, and arranging characters.

const CHARACTER_SCENE := preload("res://scripts/story_character.gd")
const LAYOUT_PATH := "user://created_characters.cfg"

var viewport: SubViewport
var viewport_container: SubViewportContainer
var camera: Camera3D
var characters: Array[Node3D] = []
var selected_character: Node3D
var dragging := false
var drag_offset := Vector3.ZERO
var status: Label
var selected_label: Label
var spawn_count := 0
var camera_distance := 13.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_build_interface()
	_load_layout()

func _build_world() -> void:
	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.gui_input.connect(_on_viewport_input)
	add_child(viewport_container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 800)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("111d2a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9bfd0")
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	viewport.add_child(environment_node)
	camera = Camera3D.new()
	camera.position = Vector3(0, 8.5, camera_distance)
	camera.fov = 44
	viewport.add_child(camera)
	_camera_look_at_center()
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48, -32, 0)
	key_light.light_energy = 1.35
	viewport.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-5, 5, 3)
	fill_light.light_color = Color("82acd1")
	fill_light.light_energy = 1.0
	fill_light.omni_range = 16
	viewport.add_child(fill_light)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(18, 18)
	floor.mesh = floor_mesh
	floor.position.y = -0.08
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("263949")
	floor_material.roughness = 0.91
	floor.material_override = floor_material
	viewport.add_child(floor)
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.12
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(18, 0.2, 18)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	viewport.add_child(floor_body)
	_add_grid_lines()
	var center_marker := MeshInstance3D.new()
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.045
	marker_mesh.bottom_radius = 0.045
	marker_mesh.height = 0.012
	center_marker.mesh = marker_mesh
	center_marker.position.y = -0.01
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color("d2b475")
	marker_material.emission_enabled = true
	marker_material.emission = Color("8d6a35")
	center_marker.material_override = marker_material
	viewport.add_child(center_marker)

func _add_grid_lines() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for coordinate in range(-9, 10):
		var color := Color("5b768a", 0.38) if coordinate % 3 == 0 else Color("526c7e", 0.19)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(float(coordinate), -0.065, -9))
		mesh.surface_add_vertex(Vector3(float(coordinate), -0.065, 9))
		mesh.surface_add_vertex(Vector3(-9, -0.065, float(coordinate)))
		mesh.surface_add_vertex(Vector3(9, -0.065, float(coordinate)))
	mesh.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = false
	lines.material_override = material
	viewport.add_child(lines)

func _build_interface() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.size = Vector2(338, 672)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101925ee")
	panel_style.border_color = Color("3c5266")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var brand := Label.new()
	brand.text = "FIGHTLAB  /  CREATE"
	brand.add_theme_font_size_override("font_size", 12)
	brand.add_theme_color_override("font_color", Color("e7c77d"))
	content.add_child(brand)
	var title := Label.new()
	title.text = "Stage your cast"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f0f3f5"))
	content.add_child(title)
	var description := Label.new()
	description.text = "Spawn characters, then arrange them in the story space."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color("9eb0c1"))
	content.add_child(description)
	var divider := HSeparator.new()
	content.add_child(divider)
	var spawn_heading := Label.new()
	spawn_heading.text = "ADD CHARACTER"
	spawn_heading.add_theme_font_size_override("font_size", 11)
	spawn_heading.add_theme_color_override("font_color", Color("d8b975"))
	content.add_child(spawn_heading)
	var masculine := _button("+  Masculine", Color("355f82"))
	masculine.pressed.connect(func(): _spawn_character("Masculine"))
	content.add_child(masculine)
	var feminine := _button("+  Feminine", Color("654e79"))
	feminine.pressed.connect(func(): _spawn_character("Feminine"))
	content.add_child(feminine)
	var selection_heading := Label.new()
	selection_heading.text = "SELECTED"
	selection_heading.add_theme_font_size_override("font_size", 11)
	selection_heading.add_theme_color_override("font_color", Color("d8b975"))
	content.add_child(selection_heading)
	selected_label = Label.new()
	selected_label.text = "None"
	selected_label.add_theme_font_size_override("font_size", 18)
	selected_label.add_theme_color_override("font_color", Color("eef2f4"))
	content.add_child(selected_label)
	var controls := Label.new()
	controls.text = "[ / ] selects characters. I/J/K/L moves them.\nShift makes fine adjustments. R rotates. Delete removes.\n+ / - zooms. F10 opens every keyboard action.\nMouse selection and dragging are also available."
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color("9eb0c1"))
	content.add_child(controls)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	status = Label.new()
	status.text = "Your layout is saved on this device."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("8fa6b9"))
	content.add_child(status)
	var save_button := _button("Save layout", Color("b99555"), true)
	save_button.pressed.connect(_save_layout)
	content.add_child(save_button)
	var back_button := _button("Back to menu", Color("1c2b3a"))
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/home.tscn"))
	content.add_child(back_button)
	var help := Label.new()
	help.text = "STAGING VIEW   ·   DRAG TO PLACE"
	help.position = Vector2(390, 28)
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("c5d2dc"))
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)

func _button(text: String, color: Color, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = color.lightened(0.2)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.14)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.14)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("111820") if primary else Color("edf2f5"))
	return button

func _camera_look_at_center() -> void:
	if camera != null:
		camera.look_at(Vector3(0, 0.7, 0), Vector3.UP)

func _spawn_character(body_type: String, saved_profile: Dictionary = {}, position_override: Variant = null, rotation_override := 0.0) -> void:
	spawn_count += 1
	var profile := saved_profile.duplicate(true)
	if profile.is_empty():
		profile = {
			"name": "%s %d" % [body_type, spawn_count],
			"body": body_type,
			"skin": "Light",
			"hair": "Buns" if body_type == "Feminine" else "Buzz",
			"hair_color": Color("3c2b25"),
			"outfit_color": Color("426c91") if body_type == "Masculine" else Color("75558e"),
			"trim_color": Color("d0b77b"),
			"height": 1.0,
			"rotation": rotation_override,
		}
	var character := CHARACTER_SCENE.new()
	character.name = str(profile.get("name", "Character %d" % spawn_count)).validate_node_name()
	character.set_meta("character_profile", profile)
	viewport.add_child(character)
	character.set_profile(profile)
	if position_override is Vector3:
		character.position = position_override
	else:
		var column := (characters.size() % 5) - 2
		var row := int(characters.size() / 5)
		character.position = Vector3(column * 1.7, 0, row * 1.8)
	character.rotation.y = float(profile.get("rotation", rotation_override))
	var pick_area := Area3D.new()
	pick_area.name = "SelectionArea"
	pick_area.collision_layer = 2
	pick_area.collision_mask = 0
	pick_area.monitoring = false
	pick_area.set_meta("placement_character", character)
	var pick_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	pick_shape.shape = capsule
	pick_shape.position.y = 0.88
	pick_area.add_child(pick_shape)
	character.add_child(pick_area)
	var name_tag := Label3D.new()
	name_tag.name = "CharacterName"
	name_tag.text = str(profile.get("name", character.name))
	name_tag.position.y = 2.1
	name_tag.font_size = 48
	name_tag.pixel_size = 0.006
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.modulate = Color("e4edf4")
	character.add_child(name_tag)
	var selection_ring := MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.43
	ring_mesh.outer_radius = 0.49
	ring_mesh.rings = 20
	ring_mesh.ring_segments = 6
	selection_ring.mesh = ring_mesh
	selection_ring.position.y = 0.025
	selection_ring.rotation.x = PI * 0.5
	selection_ring.visible = false
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color("78c9ef")
	ring_material.emission_enabled = true
	ring_material.emission = Color("3b9dcc")
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = ring_material
	character.add_child(selection_ring)
	characters.append(character)
	_select_character(character)
	status.text = "%s added. Drag it into place." % profile.get("name", character.name)

func _select_character(character: Node3D) -> void:
	selected_character = character
	for item in characters:
		var ring := item.get_node_or_null("SelectionRing") as MeshInstance3D
		if ring != null:
			ring.visible = item == selected_character
	selected_label.text = str(character.get_meta("character_profile", {}).get("name", "Character")) if character != null else "None"

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag(_to_viewport_position(event.position))
			else:
				dragging = false
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			camera_distance = clampf(camera_distance + (-0.8 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 8.0, 21.0)
			camera.position = Vector3(0, camera_distance * 0.65, camera_distance)
			_camera_look_at_center()
	elif event is InputEventMouseMotion and dragging and selected_character != null:
		var ground_position: Variant = _ground_point(_to_viewport_position(event.position))
		if ground_position is Vector3:
			selected_character.position = ground_position + drag_offset

func _to_viewport_position(point: Vector2) -> Vector2:
	var size := viewport_container.size
	if size.x <= 0 or size.y <= 0:
		return point
	return Vector2(point.x * float(viewport.size.x) / size.x, point.y * float(viewport.size.y) / size.y)

func _begin_drag(view_position: Vector2) -> void:
	var ray_origin := camera.project_ray_origin(view_position)
	var ray_direction := camera.project_ray_normal(view_position)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 80.0)
	query.collision_mask = 3
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := viewport.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider is Area3D and collider.has_meta("placement_character"):
			_select_character(collider.get_meta("placement_character") as Node3D)
			var hit_point: Vector3 = hit.get("position", Vector3.ZERO)
			drag_offset = selected_character.position - Vector3(hit_point.x, 0, hit_point.z)
			dragging = true
			return
	if selected_character != null:
		var ground_position: Variant = _ground_point(view_position)
		if ground_position is Vector3:
			drag_offset = Vector3.ZERO
			selected_character.position = ground_position
			dragging = true
	else:
		_select_character(null)

func _ground_point(view_position: Vector2) -> Variant:
	var origin := camera.project_ray_origin(view_position)
	var direction := camera.project_ray_normal(view_position)
	if absf(direction.y) < 0.001:
		return null
	var distance := -origin.y / direction.y
	if distance < 0:
		return null
	var point := origin + direction * distance
	point.x = clampf(point.x, -8.7, 8.7)
	point.z = clampf(point.z, -8.7, 8.7)
	return Vector3(point.x, 0, point.z)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:return
	if event.keycode in [KEY_MINUS,KEY_EQUAL,KEY_KP_ADD,KEY_KP_SUBTRACT]:
		camera_distance=clampf(camera_distance+(-0.8 if event.keycode in [KEY_EQUAL,KEY_KP_ADD] else 0.8),8.0,21.0)
		camera.position=Vector3(0,camera_distance*0.65,camera_distance)
		_camera_look_at_center()
		get_viewport().set_input_as_handled()
		return
	if event.keycode in [KEY_BRACKETLEFT,KEY_BRACKETRIGHT] and not characters.is_empty():
		var index := characters.find(selected_character)
		_select_character(characters[posmod(index+(-1 if event.keycode==KEY_BRACKETLEFT else 1),characters.size())])
		get_viewport().set_input_as_handled()
		return
	if selected_character!=null and event.keycode in [KEY_I,KEY_J,KEY_K,KEY_L]:
		var step := 0.05 if event.shift_pressed else 0.25
		var direction := Vector3(-1,0,0) if event.keycode==KEY_J else (Vector3(1,0,0) if event.keycode==KEY_L else (Vector3(0,0,-1) if event.keycode==KEY_I else Vector3(0,0,1)))
		selected_character.position=(selected_character.position+direction*step).clamp(Vector3(-8.7,0,-8.7),Vector3(8.7,0,8.7))
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		get_viewport().set_input_as_handled()
	elif selected_character != null and event.keycode == KEY_R:
		selected_character.rotation.y += PI / 8.0
		get_viewport().set_input_as_handled()
	elif selected_character != null and event.keycode in [KEY_DELETE, KEY_BACKSPACE]:
		characters.erase(selected_character)
		selected_character.queue_free()
		_select_character(null)
		status.text = "Character removed."
		get_viewport().set_input_as_handled()

func _save_layout() -> void:
	var config := ConfigFile.new()
	var layout: Array[Dictionary] = []
	for character in characters:
		var profile: Dictionary = character.get_meta("character_profile", {}).duplicate(true)
		profile["rotation"] = character.rotation.y
		layout.append({"profile": profile, "position": character.position})
	config.set_value("layout", "characters", layout)
	var result := config.save(LAYOUT_PATH)
	status.text = "%d character%s saved." % [characters.size(), "" if characters.size() == 1 else "s"] if result == OK else "Could not save this layout."

func _load_layout() -> void:
	var config := ConfigFile.new()
	if config.load(LAYOUT_PATH) != OK:
		return
	var layout: Variant = config.get_value("layout", "characters", [])
	if not layout is Array:
		return
	for entry in layout:
		if not entry is Dictionary:
			continue
		var profile: Dictionary = entry.get("profile", {})
		var body_type := str(profile.get("body", "Masculine"))
		_spawn_character(body_type, profile, entry.get("position", Vector3.ZERO), float(profile.get("rotation", 0.0)))
	if characters.is_empty():
		status.text = "No saved characters yet."
	else:
		status.text = "Loaded %d saved character%s." % [characters.size(), "" if characters.size() == 1 else "s"]
