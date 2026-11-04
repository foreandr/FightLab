extends Control
const CyberStyle=preload("res://scripts/ui_design.gd")
const LoadingPacer=preload("res://scripts/loading_progress_pacer.gd")
var page := "Home"
var content: VBoxContainer
var navigation_buttons := {}
var controls_dialog:AcceptDialog
var scene_loading_overlay: Control
var scene_loading_progress: ProgressBar
var scene_loading_status: Label
var scene_loading_pacer=LoadingPacer.new()

func _ready() -> void:
	get_tree().paused=false
	Engine.time_scale=1
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var music:=get_tree().root.get_node_or_null("SharedMusic")
	if music:music.enter_context("menu",self)
	theme=CyberStyle.theme()
	var background=preload("res://scripts/cyber_menu_backdrop.gd").new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var outer:=MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:outer.add_theme_constant_override("margin_"+side,36)
	add_child(outer)
	var layout:=HBoxContainer.new();layout.add_theme_constant_override("separation",40);outer.add_child(layout)
	var menu_panel:=PanelContainer.new();menu_panel.custom_minimum_size.x=320
	menu_panel.add_theme_stylebox_override("panel",CyberStyle.box(Color("09141ff5"),CyberStyle.LINE));layout.add_child(menu_panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
	menu_panel.add_child(margin)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",18);margin.add_child(stack)
	var brand:=Label.new();brand.text="FIGHTLAB";brand.add_theme_font_override("font",CyberStyle.BOLD);brand.add_theme_font_size_override("font_size",46);brand.add_theme_color_override("font_color",CyberStyle.CYAN);stack.add_child(brand)
	var line:=HSeparator.new();stack.add_child(line)
	content=VBoxContainer.new();content.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);stack.add_child(content)
	var version:=Label.new();version.text="BUILD  /  FIGHT  /  EVOLVE";version.add_theme_font_size_override("font_size",14);version.add_theme_color_override("font_color",CyberStyle.MUTED);stack.add_child(version)
	var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.alignment=BoxContainer.ALIGNMENT_END;right.add_theme_constant_override("separation",12);layout.add_child(right)
	var heading:=Label.new();heading.text="MAKE YOUR MOVE.";heading.add_theme_font_override("font",CyberStyle.BOLD);heading.add_theme_font_size_override("font_size",52);heading.add_theme_color_override("font_color",CyberStyle.TEXT);right.add_child(heading)
	var subtitle:=Label.new();subtitle.text="Your animations. Your spells. Your fight.";subtitle.add_theme_font_size_override("font_size",22);subtitle.add_theme_color_override("font_color",CyberStyle.MUTED);right.add_child(subtitle)
	show_page(str(get_tree().get_meta("home_page","Home")))
	if get_tree().has_meta("home_page"):get_tree().remove_meta("home_page")
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
	node.custom_minimum_size=Vector2(0,44)
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",20)
	var icon_name:String={"Story":"story","Free Fight":"shield","Sandbox":"simulation","Create":"person","Store":"store","Settings":"info","Back":"previous"}.get(text_,"")
	if not icon_name.is_empty():node.icon=preload("res://scripts/animation_row_icons.gd").get_icon(icon_name)
	node.alignment=HORIZONTAL_ALIGNMENT_LEFT
	node.pressed.connect(callback)
	content.add_child(node)
	navigation_buttons[text_]=node

func show_page(next: String) -> void:
	page="Free Fight" if next=="Fight" else next
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	navigation_buttons.clear()
	match page:
		"Home":
			nav("Story",_open_story)
			nav("Free Fight",func():show_page("Free Fight"))
			nav("Sandbox",func():open_scene("res://scenes/sandbox.tscn"))
			var menu_spacer:=Control.new()
			menu_spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
			content.add_child(menu_spacer)
			nav("Create",func():show_page("Create"))
			nav("Store",func():open_scene("res://scenes/animation_store.tscn"))
			nav("Options",func():show_page("Options"))
			nav("Dev",func():show_page("Dev"))
			nav("Quit",func():get_tree().quit())
		"Free Fight":
			label("FREE FIGHT",24,CyberStyle.MUTED)
			nav("CPU 1v1",func():open_scene("res://scenes/cpu_duel.tscn"))
			nav("Back",func():show_page("Home"))
		"Create":
			label("CREATE",24,CyberStyle.MUTED)
			nav("Character",open_create_character)
			nav("Animation",func():open_create_workspace("Animation"))
			nav("Spell",func():open_create_workspace("Spell"))
			nav("Back",func():show_page("Home"))
		"Dev":
			label("DEV",24,CyberStyle.MUTED)
			nav("Checkpoints",func():open_scene("res://scenes/story_dev_menu.tscn"))
			nav("Animation Pavlov",func():open_scene("res://scenes/animation_pavlov.tscn"))
			nav("Clothing Pavlov",func():open_scene("res://scenes/clothing_pavlov.tscn"))
			nav("Back",func():show_page("Home"))
		"Options":
			label("OPTIONS",24,CyberStyle.MUTED)
			nav("Settings",func():preload("res://scripts/game_settings_access.gd").service().open())
			nav("Sound",func():preload("res://scripts/game_settings_access.gd").service().open("Sound"))
			nav("Controls",open_controls)
			var fullscreen := get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
			label("Display: " + ("Fullscreen" if fullscreen else "Windowed"),20,CyberStyle.MUTED)
			nav("Fullscreen",func():_set_fullscreen(true))
			nav("Windowed",func():_set_fullscreen(false))
			navigation_buttons["Fullscreen"].disabled=fullscreen
			navigation_buttons["Windowed"].disabled=not fullscreen
			nav("Back",func():show_page("Home"))
	if navigation_buttons.is_empty():
		return
	var first: Button=navigation_buttons.values()[0]
	first.grab_focus()

func open_controls()->void:
	if not is_instance_valid(controls_dialog):
		controls_dialog=AcceptDialog.new();controls_dialog.title="Controls";controls_dialog.ok_button_text="Close"
		controls_dialog.theme=preload("res://scripts/game_settings_access.gd").service().dialog.theme
		add_child(controls_dialog)
		var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(520,400);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		controls_dialog.add_child(scroll)
		var legend:=Label.new();legend.custom_minimum_size.x=490;legend.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		legend.text=preload("res://scripts/editor_controls.gd").TEXT
		scroll.add_child(legend)
	controls_dialog.popup_centered()

func open_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func open_create_character()->void:
	get_tree().set_meta("create_character_entry",true)
	get_tree().set_meta("story_create_new",true)
	if get_tree().has_meta("story_edit_existing"):get_tree().remove_meta("story_edit_existing")
	open_scene("res://scenes/story_character_creator.tscn")

func open_create_workspace(section:String="Animation") -> void:
	if section=="Spell":
		open_scene("res://scenes/spell_creation.tscn")
		return
	if section=="Store":
		open_scene("res://scenes/animation_store.tscn")
		return
	get_tree().set_meta("create_workspace_entry",section)
	var destination_name:="Store" if section=="Store" else "Create"
	var path:="res://scenes/combat_sandbox.tscn"
	scene_loading_pacer.begin("home_to_create")
	_show_scene_loading("OPENING STORE" if section=="Store" else "OPENING CREATE")
	await RenderingServer.frame_post_draw
	var request_error:=ResourceLoader.load_threaded_request(path)
	if request_error!=OK:
		if is_instance_valid(scene_loading_status):scene_loading_status.text="Opening %s…"%destination_name
		_clear_scene_loading()
		open_scene(path)
		return
	var progress:Array=[]
	var status:=ResourceLoader.load_threaded_get_status(path,progress)
	while status==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if is_instance_valid(scene_loading_status):
			if not progress.is_empty():scene_loading_status.text="Loading %s · %d%%"%[destination_name,int(round(float(progress[0])*100.0))]
			else:scene_loading_status.text="Loading %s…"%destination_name
		if is_instance_valid(scene_loading_progress):scene_loading_progress.value=scene_loading_pacer.progress_percent(float(progress[0]) if not progress.is_empty() else 0.0)
		await get_tree().process_frame
		status=ResourceLoader.load_threaded_get_status(path,progress)
	if status==ResourceLoader.THREAD_LOAD_LOADED:
		if is_instance_valid(scene_loading_status):scene_loading_status.text="Starting %s…"%destination_name
		while not scene_loading_pacer.target_reached():
			if is_instance_valid(scene_loading_progress):scene_loading_progress.value=scene_loading_pacer.progress_percent(1.0)
			await get_tree().process_frame
		if is_instance_valid(scene_loading_progress):scene_loading_progress.value=100.0
		await RenderingServer.frame_post_draw
		var packed_scene:=ResourceLoader.load_threaded_get(path) as PackedScene
		if packed_scene!=null:
			get_tree().change_scene_to_packed(packed_scene)
			return
	if is_instance_valid(scene_loading_status):scene_loading_status.text="Opening %s…"%destination_name
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
	style.bg_color=CyberStyle.PANEL
	style.border_color=CyberStyle.CYAN
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
	title.add_theme_color_override("font_color",CyberStyle.TEXT)
	content_box.add_child(title)
	scene_loading_status=Label.new()
	scene_loading_status.text="Preparing Create scene…"
	scene_loading_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	scene_loading_status.add_theme_font_size_override("font_size",13)
	scene_loading_status.add_theme_color_override("font_color",CyberStyle.TEXT)
	content_box.add_child(scene_loading_status)
	scene_loading_progress=preload("res://scripts/loading_spinner.gd").new()
	scene_loading_progress.min_value=0
	scene_loading_progress.max_value=100
	scene_loading_progress.show_percentage=false
	scene_loading_progress.custom_minimum_size=Vector2(320,36)
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
