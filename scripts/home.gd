extends Control
const LoadingPacer=preload("res://scripts/loading_progress_pacer.gd")
var page := "Home"
var content: VBoxContainer
var navigation_buttons := {}
var scene_loading_overlay: Control
var scene_loading_progress: ProgressBar
var scene_loading_status: Label
var scene_loading_pacer=LoadingPacer.new()

func _ready() -> void:
	get_tree().paused=false
	Engine.time_scale=1
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var background:=TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color("49321f"),Color("21160f")])
	var texture:=GradientTexture2D.new()
	texture.gradient=gradient
	texture.fill_from=Vector2(0,0)
	texture.fill_to=Vector2(1,1)
	background.texture=texture
	add_child(background)
	var outer:=MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 28)
	add_child(outer)
	var book:=PanelContainer.new()
	var cover:=StyleBoxFlat.new()
	cover.bg_color=Color("d8c7a4")
	cover.border_color=Color("765b38")
	cover.set_border_width_all(3)
	cover.set_corner_radius_all(12)
	book.add_theme_stylebox_override("panel",cover)
	outer.add_child(book)
	var book_margin:=MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		book_margin.add_theme_constant_override("margin_" + side, 18)
	book.add_child(book_margin)
	var spread:=HBoxContainer.new()
	spread.add_theme_constant_override("separation",0)
	book_margin.add_child(spread)
	var left_page:=PanelContainer.new()
	left_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left_page.size_flags_stretch_ratio=0.72
	var page_style:=StyleBoxFlat.new()
	page_style.bg_color=Color("e8ddc4")
	page_style.border_color=Color("c3ad82")
	page_style.set_border_width_all(1)
	page_style.set_corner_radius_all(6)
	left_page.add_theme_stylebox_override("panel",page_style)
	spread.add_child(left_page)
	var left_margin:=MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		left_margin.add_theme_constant_override("margin_" + side, 34)
	left_page.add_child(left_margin)
	content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	left_margin.add_child(content)
	var spine:=ColorRect.new()
	spine.color=Color("98794d")
	spine.custom_minimum_size.x=12
	spine.size_flags_vertical=Control.SIZE_EXPAND_FILL
	spread.add_child(spine)
	var right_page:=PanelContainer.new()
	right_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right_page.size_flags_stretch_ratio=1.28
	var right_style:=page_style.duplicate() as StyleBoxFlat
	right_style.bg_color=Color("e8ddc4")
	right_page.add_theme_stylebox_override("panel",right_style)
	spread.add_child(right_page)
	var right_margin:=MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		right_margin.add_theme_constant_override("margin_" + side, 58)
	right_page.add_child(right_margin)
	var cover_content:=VBoxContainer.new()
	cover_content.alignment=BoxContainer.ALIGNMENT_CENTER
	cover_content.add_theme_constant_override("separation",22)
	right_margin.add_child(cover_content)
	var placeholder:=Label.new()
	placeholder.text="WILL FILL THIS LATER"
	placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size",22)
	placeholder.add_theme_color_override("font_color",Color("655740"))
	cover_content.add_child(placeholder)
	show_page("Home")
	if get_tree().get_meta("return_to_dev",false):
		get_tree().remove_meta("return_to_dev")
		show_page("Dev")

func label(text_: String,size: int,color:=Color.WHITE) -> void:
	var node:=Label.new()
	node.text=text_
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	content.add_child(node)

func nav(text_: String,callback: Callable) -> void:
	var node:=Button.new()
	node.text=text_
	node.custom_minimum_size=Vector2(0,66)
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",24)
	var normal:=StyleBoxFlat.new()
	normal.bg_color=Color("20354a")
	normal.set_corner_radius_all(8)
	normal.border_color=Color("45677d")
	normal.set_border_width_all(1)
	var hover:=normal.duplicate()
	hover.bg_color=Color("304e66")
	var pressed:=normal.duplicate()
	pressed.bg_color=Color("142333")
	node.add_theme_stylebox_override("normal",normal)
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",pressed)
	node.pressed.connect(callback)
	content.add_child(node)
	navigation_buttons[text_]=node

func show_page(next: String) -> void:
	page=next
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	navigation_buttons.clear()
	match page:
		"Home":
			nav("Story",_open_story)
			nav("Free Fight",func():open_scene("res://scenes/fight.tscn"))
			navigation_buttons["Free Fight"].disabled=true
			nav("Create",open_create_workspace)
			var menu_spacer:=Control.new()
			menu_spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
			content.add_child(menu_spacer)
			nav("Options",func():show_page("Options"))
			nav("Dev",func():show_page("Dev"))
			nav("Quit",func():get_tree().quit())
		"Dev":
			label("DEV",24,Color("655740"))
			nav("Checkpoints",func():open_scene("res://scenes/story_dev_menu.tscn"))
			nav("Animation Pavlov",func():open_scene("res://scenes/animation_pavlov.tscn"))
			nav("Clothing Pavlov",func():open_scene("res://scenes/clothing_pavlov.tscn"))
			nav("Back",func():show_page("Home"))
		"Options":
			label("OPTIONS",24,Color("655740"))
			var fullscreen := get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
			label("Display: " + ("Fullscreen" if fullscreen else "Windowed"),20,Color("655740"))
			nav("Fullscreen",func():_set_fullscreen(true))
			nav("Windowed",func():_set_fullscreen(false))
			navigation_buttons["Fullscreen"].disabled=fullscreen
			navigation_buttons["Windowed"].disabled=not fullscreen
			nav("Back",func():show_page("Home"))
	if navigation_buttons.is_empty():
		return
	var first: Button=navigation_buttons.values()[0]
	first.grab_focus()

func open_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func open_create_workspace() -> void:
	var path:="res://scenes/combat_sandbox.tscn"
	scene_loading_pacer.begin("home_to_create")
	_show_scene_loading("OPENING CREATE")
	await RenderingServer.frame_post_draw
	var request_error:=ResourceLoader.load_threaded_request(path)
	if request_error!=OK:
		if is_instance_valid(scene_loading_status):scene_loading_status.text="Opening Create scene…"
		_clear_scene_loading()
		open_scene(path)
		return
	var progress:Array=[]
	var status:=ResourceLoader.load_threaded_get_status(path,progress)
	while status==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if is_instance_valid(scene_loading_status):
			if not progress.is_empty():scene_loading_status.text="Loading Create scene · %d%%"%int(round(float(progress[0])*100.0))
			else:scene_loading_status.text="Loading Create scene…"
		if is_instance_valid(scene_loading_progress):scene_loading_progress.value=scene_loading_pacer.progress_percent(float(progress[0]) if not progress.is_empty() else 0.0)
		await get_tree().process_frame
		status=ResourceLoader.load_threaded_get_status(path,progress)
	if status==ResourceLoader.THREAD_LOAD_LOADED:
		if is_instance_valid(scene_loading_status):scene_loading_status.text="Starting Create workspace…"
		while not scene_loading_pacer.target_reached():
			if is_instance_valid(scene_loading_progress):scene_loading_progress.value=scene_loading_pacer.progress_percent(1.0)
			await get_tree().process_frame
		if is_instance_valid(scene_loading_progress):scene_loading_progress.value=100.0
		await RenderingServer.frame_post_draw
		var packed_scene:=ResourceLoader.load_threaded_get(path) as PackedScene
		if packed_scene!=null:
			get_tree().change_scene_to_packed(packed_scene)
			return
	if is_instance_valid(scene_loading_status):scene_loading_status.text="Opening Create scene…"
	_clear_scene_loading()
	open_scene(path)

func _show_scene_loading(title_text:String) -> void:
	_clear_scene_loading()
	scene_loading_overlay=Control.new()
	scene_loading_overlay.name="SceneLoadingScreen"
	scene_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_loading_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	scene_loading_overlay.z_index=100
	add_child(scene_loading_overlay)
	var shade:=ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color("21160f",0.82)
	scene_loading_overlay.add_child(shade)
	var card:=PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left=-190
	card.offset_top=-48
	card.offset_right=190
	card.offset_bottom=48
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("e8ddc4")
	style.border_color=Color("98794d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,6)
	card.add_theme_stylebox_override("panel",style)
	scene_loading_overlay.add_child(card)
	var content_box:=VBoxContainer.new()
	content_box.alignment=BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation",6)
	card.add_child(content_box)
	var title:=Label.new()
	title.text=title_text
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_color",Color("382c1c"))
	content_box.add_child(title)
	scene_loading_status=Label.new()
	scene_loading_status.text="Preparing Create scene…"
	scene_loading_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	scene_loading_status.add_theme_font_size_override("font_size",13)
	scene_loading_status.add_theme_color_override("font_color",Color("382c1c"))
	content_box.add_child(scene_loading_status)
	scene_loading_progress=ProgressBar.new()
	scene_loading_progress.min_value=0
	scene_loading_progress.max_value=100
	scene_loading_progress.show_percentage=false
	scene_loading_progress.custom_minimum_size=Vector2(320,18)
	content_box.add_child(scene_loading_progress)

func _clear_scene_loading() -> void:
	if is_instance_valid(scene_loading_overlay):scene_loading_overlay.queue_free()
	scene_loading_overlay=null
	scene_loading_progress=null
	scene_loading_status=null

func _set_fullscreen(enabled: bool) -> void:
	var window := get_window()
	if enabled:
		get_tree().set_meta("options_window_size",window.size)
		get_tree().set_meta("options_window_position",window.position)
		window.mode=Window.MODE_FULLSCREEN
	else:
		window.mode=Window.MODE_WINDOWED
		window.borderless=false
		window.unresizable=false
		var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
		var target_size: Vector2i=get_tree().get_meta("options_window_size",Vector2i(1280,720))
		window.size=target_size.min(usable.size)
		var target_position: Vector2i=get_tree().get_meta("options_window_position",usable.position+(usable.size-window.size)/2)
		window.position=target_position.clamp(usable.position,usable.end-window.size)
	show_page("Options")

func _open_story() -> void:
	if has_saved_story_character():
		open_scene("res://scenes/story_character_select.tscn")
	else:
		get_tree().set_meta("story_create_new", true)
		open_scene("res://scenes/story_character_creator.tscn")

func has_saved_story_character() -> bool:
	var roster := ConfigFile.new()
	if roster.load("user://story_characters.cfg") == OK:
		var characters: Variant = roster.get_value("roster", "characters", [])
		if characters is Array and not characters.is_empty():
			return true
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:
		return false
	var profile: Variant = config.get_value("character", "profile", {})
	return profile is Dictionary and not profile.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and page!="Home":
		show_page("Home")
		get_viewport().set_input_as_handled()
