extends Control
const CyberStyle=preload("res://scripts/ui_design.gd")
## Standalone Store: one reusable level, one preview actor, and the shared catalog.
const StoreIndex=preload("res://scripts/animation_store_index.gd")
const LoadingPacer=preload("res://scripts/loading_progress_pacer.gd")
const Library=preload("res://scripts/animation_catalog.gd")
const RowIcons=preload("res://scripts/animation_row_icons.gd")
const BOOK_PAPER=CyberStyle.PANEL
const BOOK_BORDER=CyberStyle.LINE
const BOOK_INK=CyberStyle.TEXT
var field:Node3D
var actor:CharacterBody3D
var focused_unit:CharacterBody3D
var selected_group:="Motion"
var home_store_mode:=true
var base_ui:Control
var selection_status:Label
var category_store=preload("res://scripts/animation_category_store.gd").new()
var animation_favorites=preload("res://scripts/animation_favorites.gd").new()
var store_panel:PanelContainer
var camera_control=preload("res://scripts/sandbox_camera.gd").new()
var row_preview_unit:CharacterBody3D
var preview_entry:Dictionary={}
var preview_elapsed:=0.0
var preview_duration:=1.0
var preview_enter_pose:Array[Transform3D]=[]
var preview_exit_pose:Array[Transform3D]=[]
var preview_exit_elapsed:=0.0
var store_screen_ready:=false
var zoom:=1.0
var camera_keys:Dictionary={}
var preview_time:=0.0
var orbiting:=false
var panel_zoom_dragging:=false
var zoom_drag_amount:=0.0
var animation_store_list:VBoxContainer
var animation_store_search:LineEdit
var animation_store_count:Label
var animation_store_entries:Array[Dictionary]=[]
var store_index_records:Array[Dictionary]=[]
var store_index_details_path:=""
var store_loading_indicator:VBoxContainer
var store_loading_status:Label
var store_loading_bar:ProgressBar
var store_loading_pacer=LoadingPacer.new()
var store_loading_in_progress:=false
var store_loaded:=false
var store_creator_filter:OptionButton
var store_sort_filter:OptionButton
const STORE_PAGE_SIZE:=20
var store_page:=0
var store_page_label:Label
var store_page_previous:Button
var store_page_next:Button
var store_last_query:=""
var store_page_generation:=0

const StoreLibrary=preload("res://scripts/animation_store_library.gd")
var store_library=StoreLibrary.new()
var store_body_filter:OptionButton
var store_air_filter:OptionButton
var store_view_filter:OptionButton

func _ready()->void:
	var started_usec:=Time.get_ticks_usec()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	store_library.load_state();animation_favorites.load_state()
	var view:=ConfigFile.new()
	if view.load("user://animation_store_view.cfg")==OK:zoom=clampf(float(view.get_value("view","zoom",1.0)),0.6,1.8)
	var account_usec:=Time.get_ticks_usec()
	_build_preview_world()
	var world_usec:=Time.get_ticks_usec()
	_build_ui()
	var ui_usec:=Time.get_ticks_usec()
	await _load_animation_store()
	store_screen_ready=true
	GameDiagnostics.log_event("store_open_timing",{"account_ms":(account_usec-started_usec)/1000.0,"world_ms":(world_usec-account_usec)/1000.0,"ui_ms":(ui_usec-world_usec)/1000.0,"catalog_ms":(Time.get_ticks_usec()-ui_usec)/1000.0})
	GameDiagnostics.log_event("standalone_animation_store_ready",{"records":store_index_records.size(),"rows":animation_store_list.get_child_count(),"editor_loaded":false})

func _build_preview_world()->void:
	field=preload("res://scripts/combat_world.gd").new();field.name="StorePreviewWorld";add_child(field)
	var level=preload("res://scenes/maps/gladiatorial_pit.tscn").instantiate();field.add_child(level);field.use_level(level)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("9cb4b9")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("fff1d5");environment.environment.ambient_light_energy=0.7
	field.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-48,-35,0);light.light_energy=1.3;light.shadow_enabled=true;field.add_child(light)
	actor=field.spawn_combatant(0,Vector3.ZERO,preload("res://scripts/creation_bot_outfit.gd").profile(0));actor.name="StorePreviewBot"
	actor.editor_pose_locked=true;actor.brain_enabled=false;actor.set_physics_process(false);actor.collision_layer=0;focused_unit=actor
	field.camera=Camera3D.new();field.camera.current=true;field.camera.fov=45;field.add_child(field.camera)
	var center:Vector3=actor.focus_position()-Vector3.RIGHT*2.3
	field.camera.position=center+Vector3(0,1.4,6);field.camera.look_at(center);camera_control.capture_view(field.camera,6)

func _build_ui()->void:
	theme=_book_theme();base_ui=self
	var top:=PanelContainer.new();top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_bottom=54;add_child(top)
	var header:=HBoxContainer.new();top.add_child(header)
	icon_button(header,"home","Main Menu",return_to_main_menu)
	var title:=menu_label(header,"Animation Store",20);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	selection_status=menu_label(header,"",12);selection_status.hide()
	store_panel=PanelContainer.new();store_panel.name="StorePanel";add_child(store_panel)
	store_panel.anchor_right=0.57;store_panel.anchor_bottom=1;store_panel.offset_top=54
	var store_content:=VBoxContainer.new();store_panel.add_child(store_content)
	animation_store_count=menu_label(store_content,"Animation Store",16)
	store_loading_indicator=VBoxContainer.new()
	store_loading_indicator.name="StoreLoadingProgress"
	store_loading_indicator.add_theme_constant_override("separation",2)
	store_loading_status=menu_label(store_loading_indicator,"Preparing animation catalog…",12)
	store_loading_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	store_loading_bar=preload("res://scripts/loading_spinner.gd").new()
	store_loading_bar.min_value=0
	store_loading_bar.max_value=100
	store_loading_bar.show_percentage=false
	store_loading_bar.custom_minimum_size=Vector2(0,36)
	store_loading_indicator.add_child(store_loading_bar)
	store_content.add_child(store_loading_indicator)
	store_loading_indicator.hide()
	animation_store_search=LineEdit.new()
	animation_store_search.placeholder_text="Search · type:arm tag:hook state:airborne -tag:fall"
	animation_store_search.text_changed.connect(func(_text:String):_save_store_preferences();_populate_animation_store())
	animation_store_search.right_icon=RowIcons.get_icon("search")
	animation_store_search.clear_button_enabled=true
	store_content.add_child(animation_store_search)
	var browse:=HBoxContainer.new()
	browse.add_theme_constant_override("separation",6)
	store_content.add_child(browse)
	store_sort_filter=OptionButton.new()
	for name_ in ["Top","A–Z","Creator"]:store_sort_filter.add_item(name_)
	store_sort_filter.tooltip_text="Top ranks your favorites, acrobatic moves, and combat clips first"
	store_sort_filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	store_sort_filter.item_selected.connect(func(_index:int):_save_store_preferences();_populate_animation_store())
	browse.add_child(store_sort_filter)
	store_creator_filter=OptionButton.new()
	store_creator_filter.add_item("All creators")
	store_creator_filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	store_creator_filter.item_selected.connect(func(_index:int):_save_store_preferences();_populate_animation_store())
	browse.add_child(store_creator_filter)
	var filters:=HFlowContainer.new()
	filters.add_theme_constant_override("separation",6)
	store_content.add_child(filters)
	store_body_filter=OptionButton.new()
	for name_ in preload("res://scripts/animation_store_types.gd").LABELS:store_body_filter.add_item(name_)
	store_body_filter.tooltip_text="Filter by animation type: arm, leg, head or movement"
	filters.add_child(store_body_filter)
	store_air_filter=OptionButton.new()
	for name_ in ["Air + ground","Airborne","Grounded"]:store_air_filter.add_item(name_)
	filters.add_child(store_air_filter)
	store_view_filter=OptionButton.new()
	for name_ in ["Available","Downloaded","Blocked","All items"]:store_view_filter.add_item(name_)
	store_view_filter.tooltip_text="Download an animation into your Downloaded folder; it stays out of Available"
	filters.add_child(store_view_filter)
	for filter in [store_body_filter,store_air_filter,store_view_filter]:
		filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		filter.item_selected.connect(func(_index:int):_save_store_preferences();_populate_animation_store())
	for i in store_body_filter.item_count:store_body_filter.set_item_icon(i,RowIcons.get_icon(["person","arm","leg","head","movement"][i]))
	for i in store_air_filter.item_count:store_air_filter.set_item_icon(i,RowIcons.get_icon("air" if i<2 else "ground"))
	for i in store_view_filter.item_count:store_view_filter.set_item_icon(i,RowIcons.get_icon(["store","downloaded","block","folder"][i]))
	for i in store_sort_filter.item_count:store_sort_filter.set_item_icon(i,RowIcons.get_icon(["favorite","folder","person"][i]))
	for filter in [store_sort_filter,store_creator_filter,store_body_filter,store_air_filter,store_view_filter]:
		filter.fit_to_longest_item=false;filter.clip_text=true
	var pages:=HBoxContainer.new()
	store_content.add_child(pages)
	store_page_previous=icon_button(pages,"previous","Previous page",func():store_page=maxi(0,store_page-1);_populate_animation_store())
	store_page_label=menu_label(pages,"Page 1",12)
	store_page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	store_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	store_page_next=icon_button(pages,"next","Next page",func():store_page+=1;_populate_animation_store())
	var store_scroll:=ScrollContainer.new()
	store_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	store_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	store_content.add_child(store_scroll)
	animation_store_list=VBoxContainer.new()
	animation_store_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	animation_store_list.add_theme_constant_override("separation",6)
	_padded_scroll_content(store_scroll,animation_store_list)

func _book_theme()->Theme:
	var book:Theme=preload("res://scripts/game_settings_access.gd").service().dialog.theme.duplicate(true)
	book.default_font_size=14
	book.set_stylebox("panel","PanelContainer",_book_box(BOOK_PAPER,BOOK_BORDER))
	book.set_color("font_placeholder_color","LineEdit",CyberStyle.DISABLED)
	return book
func _book_box(fill:Color,border:Color)->StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=fill;box.border_color=border;box.set_border_width_all(1);box.set_corner_radius_all(4)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:box.set_content_margin(side,6)
	return box
func button(parent:Container,title:String,action:Callable)->Button:
	var node:=Button.new();node.text=title;node.focus_mode=Control.FOCUS_ALL;node.pressed.connect(action);parent.add_child(node);return node
func menu_label(parent:Container,title:String,font_size:int)->Label:
	var label:=Label.new();label.text=title;label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label
func icon_button(parent:Container,action:String,hint:String,callback:Callable)->Button:
	var node:=button(parent,"",callback);node.icon=RowIcons.get_icon(action);node.tooltip_text=hint;node.custom_minimum_size=Vector2(38,38);return node
func animation_icon_button(parent:Container,action:String,hint:String,callback:Callable)->Button:return icon_button(parent,action,hint,callback)
func clear_list(list:Node)->void:
	for child in list.get_children():list.remove_child(child);child.queue_free()
func _padded_scroll_content(scroll:ScrollContainer,content:Control)->void:
	var padding:=MarginContainer.new();padding.size_flags_horizontal=Control.SIZE_EXPAND_FILL;padding.add_theme_constant_override("margin_right",6);scroll.add_child(padding);padding.add_child(content)
func load_custom_motion(_category:String)->Array[Dictionary]:return []
func store_owned_metadata()->Array:
	return store_library.taken.values()
func animation_info_text(entry:Dictionary)->String:return str(entry.get("title","Animation"))
func can_add_unit_animation()->bool:return is_instance_valid(focused_unit)
func show_unit_selection_warning()->void:_show_library_notice("Select the preview bot first")
func select_group(group:String)->void:selected_group=group
func select_category(_category:String,_preserve:bool=true)->void:pass
func _show_library_notice(message:String)->void:
	selection_status.text=message;selection_status.show()
func _apply_panel_zoom(_key:String)->void:
	var view:=ConfigFile.new();view.set_value("view","zoom",zoom);view.save("user://animation_store_view.cfg")
	store_panel.add_theme_font_size_override("font_size",roundi(16*zoom))
	for item in _all_controls(store_panel):
		if item is Label or item is Button or item is LineEdit:item.add_theme_font_size_override("font_size",roundi(14*zoom))
func _all_controls(node:Node)->Array[Control]:
	var result:Array[Control]=[]
	for child in node.get_children():
		if child is Control:result.append(child)
		result.append_array(_all_controls(child))
	return result
func play_animation_row(entry:Dictionary)->void:
	if not _ensure_animation_source(entry):return
	preview_enter_pose=preload("res://scripts/spell_cast_motion.gd").capture(actor)
	preview_exit_pose.clear()
	preview_entry=entry.duplicate(true);preview_elapsed=0.0
	preview_duration=actor.player.get_animation(str(entry.clip)).length if bool(entry.get("store_raw",false)) else preload("res://scripts/animation_source_pose.gd").duration(actor,str(entry.step),str(entry.clip))
	row_preview_unit=actor
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:camera_keys.clear()

func _physics_process(delta:float)->void:
	var focus:=get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit or focus is SpinBox:return
	var direction:=Vector3(float(camera_keys.get(KEY_D,false))-float(camera_keys.get(KEY_A,false)),0.0,float(camera_keys.get(KEY_W,false))-float(camera_keys.get(KEY_S,false)))
	camera_control.move(direction,delta,bool(camera_keys.get(KEY_SHIFT,false)))

func _process(delta:float)->void:
	if not is_instance_valid(actor):return
	preview_time+=delta
	if not preview_entry.is_empty():
		preview_elapsed+=delta
		preload("res://scripts/spell_cast_motion.gd").pose(actor,preview_entry,minf(0.9999,preview_elapsed/maxf(0.01,preview_duration)))
		preload("res://scripts/spell_cast_motion.gd").blend_from(actor,preview_enter_pose,clampf(preview_elapsed/0.09,0,1))
		if preview_elapsed>=preview_duration:
			preview_exit_pose=preload("res://scripts/spell_cast_motion.gd").capture(actor);preview_exit_elapsed=0.0
			preview_entry.clear();row_preview_unit=null
	else:
		preload("res://scripts/editor_rig_pose.gd").idle(actor,preview_time)
		if not preview_exit_pose.is_empty():
			preview_exit_elapsed+=delta
			preload("res://scripts/spell_cast_motion.gd").blend_from(actor,preview_exit_pose,clampf(preview_exit_elapsed/0.12,0,1))
			if preview_exit_elapsed>=0.12:preview_exit_pose.clear()
	camera_control.apply(field.camera)
func _input(event:InputEvent)->void:
	if event is InputEventKey and event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SHIFT]:
		camera_keys[event.keycode]=event.pressed
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:return_to_main_menu();return
	if event is InputEventMouseButton:
		var in_panel:=store_panel.get_global_rect().has_point(event.position)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var step:=1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1
			if in_panel and event.ctrl_pressed:zoom=clampf(zoom+step*0.1,0.6,1.8);_apply_panel_zoom("Store");get_viewport().set_input_as_handled()
			elif not in_panel:camera_control.zoom(step);get_viewport().set_input_as_handled()
		if event.button_index==MOUSE_BUTTON_MIDDLE:
			orbiting=event.pressed and not in_panel
			panel_zoom_dragging=event.pressed and in_panel and event.ctrl_pressed
			zoom_drag_amount=0.0
	elif event is InputEventMouseMotion and panel_zoom_dragging:
		zoom_drag_amount-=event.relative.y/40.0
		while absf(zoom_drag_amount)>=1.0:
			var step:=1 if zoom_drag_amount>0 else -1
			zoom=clampf(zoom+step*0.1,0.6,1.8);zoom_drag_amount-=step;_apply_panel_zoom("Store")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and orbiting:camera_control.orbit(event.relative)
func return_to_main_menu()->void:get_tree().change_scene_to_file("res://scenes/home.tscn")
func close_animation_store()->void:return_to_main_menu()

func _load_animation_store() -> void:
	await preload("res://scripts/animation_store_backend.gd")._load_animation_store(self)

func _set_store_loading_progress(fraction:float,status:String) -> void:
	preload("res://scripts/animation_store_backend.gd")._set_store_loading_progress(self ,fraction,status)

func _wait_for_store_thread(thread:Thread,fraction:float,status:String) -> Variant:
	return await preload("res://scripts/animation_store_backend.gd")._wait_for_store_thread(self ,thread,fraction,status)

func _save_store_preferences() -> void:
	preload("res://scripts/animation_store_backend.gd")._save_store_preferences(self)

func _load_store_preferences() -> void:
	preload("res://scripts/animation_store_backend.gd")._load_store_preferences(self)

func _store_creator(entry:Dictionary) -> String:
	return preload("res://scripts/animation_store_backend.gd")._store_creator(self ,entry)

func _populate_store_creators() -> void:
	preload("res://scripts/animation_store_backend.gd")._populate_store_creators(self)

func _style_store_action(control:Button,color:Color) -> void:
	preload("res://scripts/animation_store_backend.gd")._style_store_action(self ,control,color)

func _store_top_score(entry:Dictionary) -> int:
	return preload("res://scripts/animation_store_backend.gd")._store_top_score(self ,entry)

func _download_store_animation(entry:Dictionary) -> void:
	preload("res://scripts/animation_store_backend.gd")._download_store_animation(self ,entry)

func _log_store_action(action:String,entry:Dictionary,details:Dictionary={}) -> void:
	preload("res://scripts/animation_store_backend.gd")._log_store_action(self ,action,entry,details)

func _resolve_store_record(entry:Dictionary) -> Dictionary:
	return preload("res://scripts/animation_store_backend.gd")._resolve_store_record(self ,entry)

func _toggle_store_block(entry:Dictionary,currently_blocked:bool) -> void:
	preload("res://scripts/animation_store_backend.gd")._toggle_store_block(self ,entry,currently_blocked)

func _populate_animation_store() -> void:
	await preload("res://scripts/animation_store_backend.gd")._populate_animation_store(self)

func _play_store_animation(entry:Dictionary) -> void:
	preload("res://scripts/animation_store_backend.gd")._play_store_animation(self ,entry)

func _ensure_animation_source(entry:Dictionary) -> bool:
	return preload("res://scripts/animation_store_backend.gd")._ensure_animation_source(self ,entry)

func _portable_store_animation(entry:Dictionary) -> Animation:
	return preload("res://scripts/animation_store_backend.gd")._portable_store_animation(self ,entry)

func take_store_animation(entry:Dictionary,group:String,category:String) -> void:
	preload("res://scripts/animation_store_backend.gd").take_store_animation(self ,entry,group,category)
