extends "res://scripts/combat_testing_sandbox.gd"
const UI_EDGE_GAP := 6
const PLAYBACK_BAR_HEIGHT := 40 + UI_EDGE_GAP * 2
const UNIT_POSE_BLEND_SECONDS := 0.09
const Library=preload("res://scripts/animation_catalog.gd")
const PoseSelfCollision=preload("res://scripts/pose_self_collision.gd")
const DragSolver=preload("res://scripts/pose_drag_solver.gd")
const DragHandles=preload("res://scripts/pose_drag_handles.gd")
const SourcePose=preload("res://scripts/animation_source_pose.gd")
const RowIcons=preload("res://scripts/animation_row_icons.gd")
const AnimationTrash=preload("res://scripts/animation_trash.gd")
var loading_layer:CanvasLayer
var browser: Control
var spell_builder:PanelContainer
var spell_draft_path:="user://projectile_spell_draft.cfg"
var animation_favorites=preload("res://scripts/animation_favorites.gd").new()
var favorites_path:="user://animation_favorites.cfg"
var animation_sort_menu:OptionButton
var idle_preview_elapsed:=0.0
var practice_ally:CharacterBody3D
var animation_footer:Panel
var category_list: VBoxContainer
var category_scroll: ScrollContainer
var category_store=preload("res://scripts/animation_category_store.gd").new()
var category_dialog: ConfirmationDialog
var category_name_input: LineEdit
var category_error: Label
var animation_list: VBoxContainer
var category_heading: Label
var undo_delete_button:Button
var deleted_animation_records:Array[Dictionary]=[]
var animation_trash_directory := AnimationTrash.DEFAULT_TRASH
var preview_heading: Label
var preview_note: Label
var selection_status: Label
var library_buttons: Dictionary={}
var library_add_buttons: Dictionary={}
var library_add_entries: Dictionary={}
var custom_buttons: Dictionary={}
var category_buttons: Dictionary={}
var group_buttons: Dictionary={}
var selected_group := "Motion"
var selected_category := "Run"
var selected_entry: Dictionary={}
var settings_row: HBoxContainer
var options_button: Button
var options_panel: PanelContainer
var unit_source:Button
var added_units:Array[CharacterBody3D]=[]
var focused_unit:CharacterBody3D
var hovered_unit:CharacterBody3D
var row_preview_unit:CharacterBody3D
var row_preview_remaining:=0.0
var row_preview_elapsed:=0.0
var row_preview_origin:=Vector3.ZERO
var row_preview_stamina_cost:=0.0
var row_preview_action_duration:=1.0
var playtest=preload("res://scripts/animation_playtest.gd").new()
var jump_tails:Array[Dictionary]=[]
var timeline_unit_origin:=Vector3.ZERO
var workspace_category_width:=164.0
var workspace_browser_width:=490.0
var workspace_timeline_height:=350.0
var workspace_categories:Control
var workspace_choices:Control
var workspace_dividers:Array[Control]=[]
var timeline_undo_history:Array[Dictionary]=[]
var timeline_redo_history:Array[Dictionary]=[]
var custom_undo_history:Array[Dictionary]=[]
var custom_redo_history:Array[Dictionary]=[]
var custom_history_baseline:Dictionary={}
var timeline_clip_clipboard:Dictionary={}
var unit_selection_warning:AcceptDialog
var workspace_nav_panels:Dictionary={}
var workspace_collapsed:Dictionary={"Categories":false,"Animations":false}
var workspace_restore_buttons:Dictionary={}
var category_group_tabs:Dictionary={}
var animation_store_list:VBoxContainer
var animation_store_search:LineEdit
var animation_store_count:Label
var animation_store_entries:Array[Dictionary]=[]
const AssetProvenance=preload("res://scripts/asset_provenance.gd")
const StoreLibrary=preload("res://scripts/animation_store_library.gd")
var store_library=StoreLibrary.new()
var store_body_filter:OptionButton
var store_air_filter:OptionButton
var store_view_filter:OptionButton
var custom_provenance:Dictionary={}
var custom_store_source_animation:=""
var browse_backdrop: ColorRect
var chain_backdrop: Panel
var timeline_panel: PanelContainer
var timeline_name: LineEdit
var timeline_save_overlay: Control
var timeline_save_name: LineEdit
var timeline_library_menu: OptionButton
var timeline_library: Array[Dictionary] = []
var timeline_visible_library_indices:Array[int]=[]
var timeline_tracks: VBoxContainer
var timeline_clip_scroll: ScrollContainer
var timeline_scrubber: Control
var timeline_time_label: Label
var timeline_priority: OptionButton
var timeline_length_input: SpinBox
var timeline_motion_panel:PanelContainer
var timeline_motion_name:Label
var timeline_motion_effort:HSlider
var timeline_damage_label:Label
var timeline_stamina_label:Label
var timeline_mana_label:Label
var timeline_spell_label:Label
var timeline_spell_button:Button
var timeline_motion_cost:Label
var timeline_motion_bar:HSlider
var timeline_linked_bars:Dictionary={}
var timeline_motion_output:Label
var timeline_selected_id := -1
var timeline_playing := false
var timeline_duration := 1.0
var timeline_playhead := 0.0
var timeline_clips: Array[Dictionary] = []
var timeline_serial := 0
var timeline_active: Dictionary = {}
var timeline_drag_clip_id := -1
var timeline_drag_original_track := ""
var timeline_origin_position:=Vector3.ZERO
var timeline_origin_basis:=Basis.IDENTITY
var timeline_origin_valid:=false
var preserve_camera_on_setup_reset:=false
const TIMELINE_TRACKS := ["BODY", "HEAD", "TORSO", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG"]
var TIMELINE_PIXELS_PER_SECOND := 100.0
var panel_zoom_levels:Dictionary={}
var panel_zoom_roots:Dictionary={}
const TIMELINE_DEFAULT_CLIP_DURATION := 0.8666667
const TIMELINE_PATH := "user://animation_timeline.cfg"
var live_preview_sequence=preload("res://scripts/motion_sequence.gd").new()
var live_preview_steps: Array[String]=[]
var live_preview_age := 0.0
var live_preview_started := false
var live_preview_loops := 0
var custom_editor: Control
var custom_heading: Label
var custom_action_category := "Jump"
var custom_action_group := "Motion"
var custom_source_mirrored := false
var custom_source_attack_bone := ""
var custom_source_step := "Jump"
var custom_source_clip := "duel/air"
var custom_source_title := "Jump"
var custom_source_timing := "legacy"
var custom_source_duration := 3.0
var custom_source_frames:Array[Dictionary]=[]
var custom_edit_path := ""
var custom_parent_name := ""
var custom_parent_path := ""
var custom_random := RandomNumberGenerator.new()
var custom_randomizing := false
var custom_name: LineEdit
var custom_frame_tabs: HBoxContainer
var custom_timeline_scroll: ScrollContainer
var custom_frame_label: Label
var custom_displayed_frame_index := -1
var custom_body_tab_index := 0
var custom_tools_tabs:TabContainer
var pose_targets=preload("res://scripts/pose_target_tools.gd").new()
var custom_drag_overlay:Control
var custom_direct_enabled := true
var custom_direct_toggle:Button
var custom_drag_undo_button:Button
const MAX_DRAG_UNDO := 100
var custom_drag_undo:Array[Dictionary]=[]
var custom_drag_handle := ""
var custom_drag_hover := ""
var custom_drag_target := Vector3.ZERO
var custom_drag_plane:Plane
var custom_drag_start_world := Vector3.ZERO
var custom_drag_start_mouse := Vector2.ZERO
var custom_drag_depth := false
var custom_drag_stalled := false
var custom_drag_foot_anchors:Dictionary={}
var custom_recording := false
var custom_record_elapsed := 0.0
var custom_record_sample_clock := 0.0
var custom_record_samples:Array[Dictionary]=[]
var custom_record_undo:Dictionary={}
var custom_record_button:Button
var custom_record_cancel_button:Button
var custom_record_undo_button:Button
var custom_record_label:Label
var custom_random_parts: Dictionary={}
var custom_random_part_labels: Dictionary={}
var custom_random_checkboxes: Dictionary={}
var custom_random_selection_label: Label
var custom_random_frame_button: Button
var custom_random_all_button: Button
var custom_restore_selected_button: Button
var custom_undo_random_button: Button
var custom_restore_scope: OptionButton
var custom_random_snapshot: Array[Dictionary]=[]
var custom_random_pending: Dictionary={}
var custom_frame_count_input: SpinBox
var custom_controls: VBoxContainer
var custom_status: Label
var custom_collision_alert: Label
var custom_collision_alert_time := 0.0
var custom_collision_probe_active := false
var custom_frames: Array[Dictionary]=[]
var custom_frame_index := 0
var custom_saved_items: Array[Dictionary]=[]
var custom_pose_controls: Array[Dictionary]=[]
var custom_hand_controls: Array[Dictionary]=[]
var base_ui: Control
var custom_preview_elapsed := 0.0
var custom_preview_frame := -1
var custom_preview_playing := true
var custom_preview_repeat := true
var custom_preview_reseek := false
var custom_play_button: Button
var custom_pause_button: Button
var custom_repeat_button: Button
var custom_copy_next_button: Button
var custom_blend_next_button: Button
var custom_propagate_group:OptionButton
const PROPAGATE_GROUPS := ["All","Arms","Legs","Torso","Hands","Head"]
var custom_range_from: SpinBox
var custom_range_to: SpinBox
var custom_range_active := false
var custom_range_first := 0
var custom_range_last := 5
const CUSTOM_LOOP_DURATION := 3.0
var custom_duration := CUSTOM_LOOP_DURATION
const CUSTOM_DIR := "user://custom_animations"
const MIN_CUSTOM_FRAMES := 2
const MAX_CUSTOM_FRAMES := 900
const HAND_FINGERS := ["thumb","index","middle","ring","pinky"]
const HAND_GESTURES := ["Custom","Open","Fist","Point","Peace","Middle","Shocker","Pinky","Thumbs up"]
const BOOK_INK := Color("382c1c")
const BOOK_PAPER := Color("e8ddc4")
const BOOK_PAPER_LIGHT := Color("f0e8d5")
const BOOK_BORDER := Color("b5a27f")
const BOOK_GOLD := Color("98703d")
const JUMP_JOINTS := [
	{"bone":"upperarm_l","axis":2,"label":"Left arm raise","min":-145.0,"max":145.0},
	{"bone":"upperarm_r","axis":2,"label":"Right arm raise","min":-145.0,"max":145.0},
	{"bone":"lowerarm_l","axis":0,"label":"Left elbow bend","min":0.0,"max":145.0},
	{"bone":"lowerarm_r","axis":0,"label":"Right elbow bend","min":0.0,"max":145.0},
	{"bone":"thigh_l","axis":0,"label":"Left leg swing","min":-100.0,"max":110.0},
	{"bone":"thigh_r","axis":0,"label":"Right leg swing","min":-100.0,"max":110.0},
	{"bone":"calf_l","axis":0,"label":"Left knee bend","min":0.0,"max":145.0},
	{"bone":"calf_r","axis":0,"label":"Right knee bend","min":0.0,"max":145.0},
	{"bone":"spine_03","axis":0,"label":"Torso lean","min":-45.0,"max":45.0},
	{"bone":"Head","axis":0,"label":"Head up / down","min":-55.0,"max":55.0},
	{"bone":"Head","axis":1,"label":"Head turn","min":-75.0,"max":75.0},
	{"bone":"Head","axis":2,"label":"Head side tilt","min":-35.0,"max":35.0}
]

func _ready() -> void:
	loading_layer=CanvasLayer.new()
	loading_layer.layer=110
	add_child(loading_layer)
	var loading_overlay:=ColorRect.new()
	loading_overlay.name="CreateWorkspaceLoading"
	loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.color=Color("21160f",0.82)
	loading_layer.add_child(loading_overlay)
	var loading_card:=PanelContainer.new()
	loading_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	loading_card.offset_left=-190
	loading_card.offset_top=-34
	loading_card.offset_right=190
	loading_card.offset_bottom=34
	var loading_style:=StyleBoxFlat.new()
	loading_style.bg_color=BOOK_PAPER
	loading_style.border_color=BOOK_GOLD
	loading_style.set_border_width_all(2)
	loading_style.set_corner_radius_all(8)
	_set_edge_padding(loading_style)
	loading_card.add_theme_stylebox_override("panel",loading_style)
	loading_overlay.add_child(loading_card)
	var loading_content:=VBoxContainer.new()
	loading_content.alignment=BoxContainer.ALIGNMENT_CENTER
	loading_content.add_theme_constant_override("separation",UI_EDGE_GAP)
	loading_card.add_child(loading_content)
	var loading_title:=Label.new()
	loading_title.text="OPENING CREATE"
	loading_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	loading_title.add_theme_font_size_override("font_size",22)
	loading_title.add_theme_color_override("font_color",BOOK_INK)
	loading_content.add_child(loading_title)
	var loading_bar:=ProgressBar.new()
	loading_bar.min_value=0
	loading_bar.max_value=100
	loading_bar.indeterminate=true
	loading_bar.show_percentage=false
	loading_bar.custom_minimum_size=Vector2(320,18)
	loading_content.add_child(loading_bar)
	await RenderingServer.frame_post_draw
	animation_favorites.path=favorites_path
	animation_favorites.load_state()
	category_store.load_state()
	store_library.load_state()
	process_mode=Node.PROCESS_MODE_ALWAYS
	custom_random.randomize()
	deleted_animation_records=AnimationTrash.list_deleted(animation_trash_directory)
	super._ready()
	field.show()
	browse_backdrop.hide()
	layout_chain(true)
	load_timeline()
	new_timeline()
	_rebuild_timeline_tracks()
	begin_live_preview()

func open_case(index:int) -> void:
	super.open_case(index)
	setup_practice_partners()

func prepare_setup(run:bool) -> void:
	super.prepare_setup(run)
	setup_practice_partners()

func setup_practice_partners() -> void:
	field.editor_animation_only=true
	for shield in field.shields:shield.hide()
	for charge in field.charges:charge.hide()
	for pieces in field.armor_meshes:
		for piece in pieces:piece[0].hide()
	practice_ally=null
	for fighter in field.fighters:
		var preview_tag:Node=fighter.get_node_or_null("OverheadHealthTag")
		if preview_tag!=null:
			preview_tag.display_name="Animation Bot"
			preview_tag.name_label.text="Animation Bot"
		var is_bot:=false
		fighter.brain_enabled=false
		fighter.visible=is_bot
		if not is_bot:
			fighter.collision_layer=0
			for item in fighter.targets:item[0].collision_layer=0
			for item in fighter.limb_targets:item[0].collision_layer=0
		if fighter.team<field.health_labels.size():
			field.health_labels[fighter.team].get_parent().visible=is_bot
		if not is_bot:continue
		preload("res://scripts/editor_rig_pose.gd").idle(fighter)
		fighter.set_meta("practice_role","bot_n")
		var tag=fighter.get_node_or_null("OverheadHealthTag")
		if tag!=null:
			tag.display_name="BOT_N"
			tag.name_label.text="BOT_N"
			tag.name_label.modulate=Color("80d8ff")
	if not preserve_camera_on_setup_reset and not camera_initialized and not inspection_camera.manual:
		call_deferred("_frame_bot_preview")

func _frame_bot_preview() -> void:
	if not is_instance_valid(field) or not is_instance_valid(actor):return
	# A preview reset may have queued this before the user moved the camera.
	if camera_initialized or inspection_camera.manual:return
	update_camera(0.0)

func build_ui() -> void:
	# Retain the proven playback controller and its controls, then give animation
	# browsing a dedicated UI for Motion and Attack.
	super.build_ui()
	for child in get_children():
		if child is CanvasLayer:child.hide()
	var layer:=CanvasLayer.new()
	add_child(layer)
	var ui:=Control.new()
	base_ui=ui
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.theme=_book_theme()
	layer.add_child(ui)
	browse_backdrop=ColorRect.new()
	browse_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	browse_backdrop.color=Color("2b1b11")
	browse_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(browse_backdrop)
	var header:=panel(ui,Vector4(0,0,0,54),true)
	panel_zoom_roots["Header"]=header
	title_label.reparent(header)
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_left=20
	title_label.offset_top=10
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	title_label.hide()
	selection_status=menu_label(header,"",14)
	selection_status.hide()
	options_button=Button.new()
	options_button.text="⚙"
	options_button.focus_mode=Control.FOCUS_ALL
	options_button.pressed.connect(_toggle_options_menu)
	header.add_child(options_button)
	options_button.name="AnimationOptions"
	options_button.tooltip_text="Animation editor options"
	options_button.toggle_mode=true
	options_button.custom_minimum_size=Vector2(42,34)
	options_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	options_button.anchor_left=0.5
	options_button.anchor_right=0.5
	options_button.offset_left=-21
	options_button.offset_top=UI_EDGE_GAP
	options_button.offset_right=21
	options_button.offset_bottom=48
	var navigation:=HBoxContainer.new()
	navigation.name="WorkspaceNavigation"
	navigation.anchor_left=0.5
	navigation.anchor_right=0.5
	navigation.offset_left=-117
	navigation.offset_right=117
	navigation.offset_top=6
	navigation.offset_bottom=48
	navigation.add_theme_constant_override("separation",6)
	header.add_child(navigation)
	for item in [["Animations","person"],["Spells","cast"],["Simulations","simulation"],["Store","store"]]:
		var section:String=item[0]
		var icon_color:Color={"Animations":Color("3278b8"),"Spells":Color("b27608"),"Simulations":Color("38835b"),"Story":Color("8656a3"),"Store":Color("b85d36")}[section]
		var tab:=button(navigation,"",func():_open_workspace_section(section))
		tab.name=section
		tab.icon=RowIcons.get_icon(item[1])
		tab.add_theme_color_override("icon_normal_color",icon_color)
		tab.add_theme_color_override("icon_hover_color",icon_color.lightened(0.12))
		tab.add_theme_color_override("icon_pressed_color",icon_color.darkened(0.12))
		tab.custom_minimum_size=Vector2(42,42)
		tab.tooltip_text=section
	options_button.reparent(navigation)
	options_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	options_button.custom_minimum_size=Vector2(42,42)
	options_button.tooltip_text="Options"
	options_button.add_theme_color_override("font_color",Color("727e94"))
	options_button.add_theme_color_override("font_hover_color",Color("586981"))
	browser=Control.new()
	browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	browser.offset_top=54
	browser.offset_bottom=-350
	browser.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(browser)
	var categories:=panel(browser,Vector4(0,0,164,0))
	workspace_categories=categories
	categories.clip_contents=true
	categories.anchor_bottom=1
	var category_header:=HBoxContainer.new()
	category_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	category_header.offset_left=UI_EDGE_GAP
	category_header.offset_right=-UI_EDGE_GAP
	category_header.offset_top=6
	category_header.offset_bottom=40
	categories.add_child(category_header)
	var category_tabs:=HBoxContainer.new()
	category_tabs.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	category_header.add_child(category_tabs)
	for group in ["Motion","Attack"]:
		var group_tab:=button(category_tabs,group,func():select_group(group))
		group_tab.add_theme_font_size_override("font_size",11)
		group_tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		category_group_tabs[group]=group_tab
	var category_actions:=HBoxContainer.new()
	category_actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	category_actions.offset_left=UI_EDGE_GAP
	category_actions.offset_right=-UI_EDGE_GAP
	category_actions.offset_top=42
	category_actions.offset_bottom=74
	categories.add_child(category_actions)
	var category_caption:=menu_label(category_actions,"Folders",11)
	category_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	category_caption.clip_text=true
	var add_category:=button(category_actions,"+",show_new_category)
	add_category.custom_minimum_size=Vector2(32,32)
	add_category.tooltip_text="Add category"
	var collapse_categories:=button(category_actions,"−",func():toggle_workspace_panel("Categories"))
	collapse_categories.tooltip_text="Collapse categories"
	collapse_categories.size_flags_horizontal=Control.SIZE_SHRINK_END
	collapse_categories.custom_minimum_size=Vector2(26,26)
	_build_category_dialog()
	category_list=VBoxContainer.new()
	category_list.add_theme_constant_override("separation",UI_EDGE_GAP)
	category_scroll=ScrollContainer.new()
	category_scroll.follow_focus=true
	category_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	category_scroll.offset_left=UI_EDGE_GAP
	category_scroll.offset_top=80
	category_scroll.offset_right=-UI_EDGE_GAP
	category_scroll.offset_bottom=-UI_EDGE_GAP
	category_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	categories.add_child(category_scroll)
	var category_padding:=MarginContainer.new()
	category_padding.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	category_padding.add_theme_constant_override("margin_right",UI_EDGE_GAP)
	category_scroll.add_child(category_padding)
	category_padding.add_child(category_list)
	var choices:=panel(browser,Vector4(164,0,490,0))
	workspace_choices=choices
	choices.clip_contents=true
	choices.anchor_bottom=1
	var choices_column:=VBoxContainer.new()
	choices_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices_column.offset_left=UI_EDGE_GAP
	choices_column.offset_right=-UI_EDGE_GAP
	choices_column.offset_top=UI_EDGE_GAP
	choices_column.offset_bottom=-UI_EDGE_GAP
	choices.add_child(choices_column)
	var choices_heading:=HBoxContainer.new()
	choices_column.add_child(choices_heading)
	category_heading=menu_label(choices_heading,"Animations",19)
	category_heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	category_heading.clip_text=true
	var collapse_choices:=button(choices_heading,"−",func():toggle_workspace_panel("Animations"))
	collapse_choices.tooltip_text="Collapse animation list"
	collapse_choices.size_flags_horizontal=Control.SIZE_SHRINK_END
	collapse_choices.custom_minimum_size=Vector2(26,26)
	undo_delete_button=animation_icon_button(choices_heading,"undo","Restore last deleted animation",restore_last_deleted_animation)
	undo_delete_button.custom_minimum_size=Vector2(30,30)
	update_undo_delete_button()
	animation_sort_menu=OptionButton.new()
	animation_sort_menu.alignment=HORIZONTAL_ALIGNMENT_CENTER
	for item in ["Favorites first","Name A–Z","Favorites only"]:animation_sort_menu.add_item(item)
	animation_sort_menu.select(animation_favorites.sort_mode)
	animation_sort_menu.item_selected.connect(set_animation_sort)
	choices_column.add_child(animation_sort_menu)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	choices_column.add_child(scroll)
	animation_list=VBoxContainer.new()
	animation_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	animation_list.add_theme_constant_override("separation",UI_EDGE_GAP)
	_padded_scroll_content(scroll,animation_list)
	var preview_panel:=panel(browser,Vector4(490,0,0,62),true)
	var preview_column:=VBoxContainer.new()
	preview_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_column.offset_left=UI_EDGE_GAP
	preview_column.offset_right=-UI_EDGE_GAP
	preview_column.offset_top=UI_EDGE_GAP
	preview_column.offset_bottom=-UI_EDGE_GAP
	preview_panel.add_child(preview_column)
	preview_heading=menu_label(preview_column,"Animation preview",20)
	preview_note=menu_label(preview_column,"Live arena · hover to preview",13)
	preview_panel.hide()

	chain_backdrop=panel(ui,Vector4(0,0,0,0),true)
	chain_panel.reparent(ui)
	chain_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	chain_panel.offset_left=UI_EDGE_GAP
	chain_panel.offset_right=-UI_EDGE_GAP
	dash_direction_menu.hide()
	block_menu.hide()
	options_panel=PanelContainer.new()
	options_panel.name="AnimationOptionsPanel"
	options_panel.visible=false
	options_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	options_panel.anchor_left=0.5
	options_panel.anchor_right=0.5
	options_panel.offset_left=-167
	options_panel.offset_top=60
	options_panel.offset_right=167
	options_panel.offset_bottom=196
	var options_style:=StyleBoxFlat.new()
	options_style.bg_color=BOOK_PAPER
	options_style.border_color=BOOK_GOLD
	options_style.set_border_width_all(1)
	options_style.set_corner_radius_all(6)
	_set_edge_padding(options_style)
	options_panel.add_theme_stylebox_override("panel",options_style)
	ui.add_child(options_panel)
	var options_column:=VBoxContainer.new()
	options_column.add_theme_constant_override("separation",6)
	options_panel.add_child(options_column)
	menu_label(options_column,"Creator name",13)
	var creator_input:=LineEdit.new()
	creator_input.name="CreatorCreditName"
	creator_input.placeholder_text="Your name for animation/spell credits"
	creator_input.text=AssetProvenance.creator_name()
	creator_input.text_changed.connect(func(value:String):AssetProvenance.set_creator_name(value))
	options_column.add_child(creator_input)
	var animations_content:=_create_workspace_nav_panel("Animations")
	var simulations_content:=_create_workspace_nav_panel("Simulations")
	var store_content:=_create_workspace_nav_panel("Store")
	var store_panel:Control=workspace_nav_panels["Store"]
	store_panel.set_script(preload("res://scripts/resizable_workspace_window.gd"))
	store_panel.set_process_input(true)
	store_panel.set_process(true)
	panel_zoom_roots["Store"]=store_panel
	store_panel.offset_left=-270
	store_panel.offset_right=270
	store_panel.anchor_bottom=1.0
	store_panel.offset_bottom=-60
	var store_header:=HBoxContainer.new()
	store_header.name="StoreWindowTitleBar"
	store_header.set_script(preload("res://scripts/draggable_window_header.gd"))
	store_content.add_child(store_header)
	animation_store_count=menu_label(store_header,"Animation Store",16)
	animation_store_count.clip_text=true
	animation_store_count.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(store_header,"Close",func():store_panel.hide())
	animation_store_search=LineEdit.new()
	animation_store_search.placeholder_text="Search · tag:arm body:head state:airborne -tag:fall"
	animation_store_search.text_changed.connect(func(_text:String):_save_store_preferences();_populate_animation_store())
	store_content.add_child(animation_store_search)
	var filters:=HFlowContainer.new()
	filters.add_theme_constant_override("separation",6)
	store_content.add_child(filters)
	store_body_filter=OptionButton.new()
	for name_ in ["All body parts","Head","Torso","Arms","Legs","Misc"]:store_body_filter.add_item(name_)
	store_body_filter.tooltip_text="Filter by intended body part"
	filters.add_child(store_body_filter)
	store_air_filter=OptionButton.new()
	for name_ in ["Air + ground","Airborne","Grounded"]:store_air_filter.add_item(name_)
	filters.add_child(store_air_filter)
	store_view_filter=OptionButton.new()
	for name_ in ["Available","Taken","Blocked","All items"]:store_view_filter.add_item(name_)
	store_view_filter.tooltip_text="Taken and blocked animations are hidden from Available"
	filters.add_child(store_view_filter)
	for filter in [store_body_filter,store_air_filter,store_view_filter]:
		filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		filter.item_selected.connect(func(_index:int):_save_store_preferences();_populate_animation_store())
	_load_store_preferences()
	var store_scroll:=ScrollContainer.new()
	store_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	store_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	store_content.add_child(store_scroll)
	animation_store_list=VBoxContainer.new()
	animation_store_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	animation_store_list.add_theme_constant_override("separation",6)
	_padded_scroll_content(store_scroll,animation_store_list)
	var group_row:=GridContainer.new()
	group_row.columns=3
	group_row.add_theme_constant_override("h_separation",UI_EDGE_GAP)
	group_row.add_theme_constant_override("v_separation",UI_EDGE_GAP)
	animations_content.add_child(group_row)
	# Motion and Attack live in the browser header; no extra navigation popup.
	var units_toggle:=button(simulations_content,"UNITS",func():unit_source.visible=not unit_source.visible)
	units_toggle.custom_minimum_size=Vector2(86,32)
	units_toggle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_set_button_accent(units_toggle,false)
	units_toggle.tooltip_text="Show units to drag into the arena"
	var controls_dialog:=AcceptDialog.new()
	controls_dialog.name="AnimationControlsLegend"
	controls_dialog.title="Controls"
	controls_dialog.theme=_book_theme()
	controls_dialog.add_theme_stylebox_override("panel",_book_box(BOOK_PAPER,BOOK_BORDER))
	add_child(controls_dialog)
	var controls_scroll:=ScrollContainer.new()
	controls_scroll.custom_minimum_size=Vector2(520,400)
	controls_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	controls_dialog.add_child(controls_scroll)
	var legend:=Label.new()
	legend.custom_minimum_size.x=490
	legend.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	legend.add_theme_color_override("font_color",BOOK_INK)
	legend.add_theme_font_size_override("font_size",15)
	legend.text="UNITS\nSimulations → Units: drag a bot into the arena.\nClick the bot card or press Enter to add one.\nHover a unit to highlight it; click to focus it.\nDrag a unit to move it around the arena.\nReset position / Ctrl+R: restore original placement.\nAlt+arrows: nudge the selected unit (outside clip editing).\n[ / ]: switch the focused unit.\n\nTAKE CONTROL\nSelect a bot, then click Take Control in the bottom bar.\nWASD moves, Shift sprints, Space jumps.\nClick the arena or use Play to perform the current timeline once.\nOther added units are contact-based practice targets.\nBackspace restores test units; Escape or Release Control returns to editing.\n\nPREVIEW & PLAY\n▶ beside an animation: preview its whole body once on the focused unit. The timeline stays unchanged.\nDrag an animation onto a timeline track, then use the bottom ▶ to play it on the focused unit.\nEVERYTHING affects the whole body; other tracks affect that body part. Higher numbers win overlapping pose conflicts. Jump height continues beneath other poses.\nOverlap a backflip with jump airtime, then add a higher-priority slash on LEFT ARM.\n\nEDIT CLIPS\nDrag the middle: move the clip.\nDrag an edge: stretch/shrink playback (changes speed).\nShift-drag an edge: cut/trim (keeps speed).\nShift-click inside a clip: split at that point.\nSelect a clip, place the playhead, then press S: cut there.\nRight-click a clip or press Delete: remove it.\nShaded time is beyond Length and will not play.\n\nSHORTCUTS\nCtrl+Z: undo an animation or timeline edit.\nCtrl+Y: redo.\nCtrl+C: copy the selected clip.\nCtrl+P (or Ctrl+V): paste at the playhead.\nWith a clip focused: S splits at the playhead.\nAlt+← / →: trim the end by one frame.\nCtrl+Alt+← / →: trim the start.\nShift+← / →: stretch/shrink by one frame.\nWith the ruler focused: ← / → seeks one frame; Shift seeks ten; Home / End goes to start/end.\n\nPANELS\nDrag a divider to resize the panels.\nDouble-click a divider to reset it.\nWith a divider focused: arrows resize by 6 px; Shift+arrows resize by 24 px.\nYour panel sizes are remembered.\nUse − to collapse a side panel and + to reopen it."
	legend.text+="\n\nJUMP STAMINA\nStamina depletion controls jump height and airtime. Extending a jump automatically increases its stamina requirement, up to 100. Put Jump on EVERYTHING and a jab on its arm track to combine them. At equal priority the specific body-part track wins."
	legend.text+="\n\nPANEL ZOOM\nCtrl+mouse wheel over a panel: shrink or enlarge its text and controls. Each panel zooms independently. Timeline zoom also scales tracks and time spacing. Ctrl+- / Ctrl+= works over a panel; Ctrl+0 resets it. Zoom levels are saved with your layout."
	legend.text+="\n\nSTORE & PERSONAL LIBRARY\nSearch words or quoted phrases. Combine tag:arm body:head state:airborne source:ual2 author:name; use -tag:fall to exclude. Filters cover body part, air/ground and Available/Taken/Blocked/All items. Drag a Store animation onto a category folder or anywhere in the open category list, including its blank space. Drag the Store title to move it; drag any border or corner to resize the actual window. Taken items hide from Available. Duplicate names receive (1), (2), etc. Use the pencil beside an animation to rename it; its original source and credits remain in metadata. Block hides unwanted items; switch to Blocked to undo it. Source metadata and the full credit history are retained with every animation. Set your credit name in Options → Creator name. Animations and spells preserve prior contributors when modified."
	controls_scroll.add_child(legend)
	var controls_button:=button(options_column,"CONTROLS",func():controls_dialog.popup_centered())
	controls_button.name="ShowControlsLegend"
	controls_button.custom_minimum_size=Vector2(86,32)
	controls_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_set_button_accent(controls_button,false)
	unit_source=button(simulations_content,"BOT_1",add_next_unit)
	unit_source.name="AddNextUnit"
	unit_source.set_script(preload("res://scripts/animation_unit_source.gd"))
	unit_source.tooltip_text="Drag into the arena · Enter or click to add in front of the camera"
	unit_source.hide()
	var unit_drop:=Control.new()
	unit_drop.name="ArenaUnitDrop"
	unit_drop.set_script(preload("res://scripts/animation_unit_drop.gd"))
	unit_drop.set("editor",self)
	unit_drop.anchor_right=1
	unit_drop.anchor_bottom=1
	unit_drop.offset_left=490
	unit_drop.offset_top=54
	unit_drop.offset_bottom=-350
	unit_drop.mouse_filter=Control.MOUSE_FILTER_PASS
	ui.add_child(unit_drop)
	ui.move_child(unit_drop,0)
	var bottom:=panel(ui,Vector4(0,-PLAYBACK_BAR_HEIGHT,0,0),true)
	animation_footer=bottom
	bottom.anchor_top=1
	bottom.anchor_bottom=1
	var footer:=VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.offset_left=UI_EDGE_GAP
	footer.offset_right=-UI_EDGE_GAP
	footer.offset_top=UI_EDGE_GAP
	footer.offset_bottom=-UI_EDGE_GAP
	bottom.add_child(footer)
	var actions:=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",UI_EDGE_GAP)
	footer.add_child(actions)
	var save_button:=button(actions,"Save",open_timeline_save_dialog)
	save_button.tooltip_text="Save animation as"
	save_button.custom_minimum_size=Vector2(72,40)
	var clear_button:=button(actions,"Clear",clear_timeline)
	clear_button.tooltip_text="Clear clips from this timeline"
	clear_button.custom_minimum_size=Vector2(72,40)
	play_button=button(actions,"▶",play_timeline)
	play_button.tooltip_text="Play timeline"
	play_button.custom_minimum_size=Vector2(44,40)
	repeat_play_button=button(actions,"⟳",toggle_timeline_repeat)
	repeat_play_button.tooltip_text="Play timeline repeatedly"
	repeat_play_button.custom_minimum_size=Vector2(44,40)
	var stop_button:=button(actions,"■",stop_timeline)
	stop_button.tooltip_text="Stop playback"
	stop_button.custom_minimum_size=Vector2(44,40)
	var reset_button:=button(actions,"◀|",reset_timeline)
	reset_button.tooltip_text="Reset timeline"
	reset_button.custom_minimum_size=Vector2(54,40)
	var position_reset:=button(actions,"Reset position",reset_focused_unit_position)
	playtest.setup(self,actions)
	position_reset.tooltip_text="Return the selected bot to its original placement (Ctrl+R)"
	position_reset.custom_minimum_size.y=40
	slow_button=button(actions,"SLOW MO",toggle_slow)
	slow_button.tooltip_text="Slow motion (T)"
	slow_button.custom_minimum_size=Vector2(104,40)
	var home_button:=button(actions,"⟵",return_home)
	home_button.tooltip_text="Home (Esc)"
	home_button.custom_minimum_size=Vector2(54,40)
	result_label.reparent(footer)
	resources_label.reparent(footer)
	result_label.hide()
	resources_label.hide()
	build_timeline(ui)
	_build_workspace_dividers(ui)
	var category_drop:=Control.new()
	category_drop.name="OpenCategoryDropArea"
	category_drop.set_script(preload("res://scripts/animation_open_category_drop.gd"))
	category_drop.set("editor",self)
	category_drop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(category_drop)
	populate_group("Motion")
	build_custom_editor()
	spell_builder=preload("res://scripts/spell_builder.gd").new()
	spell_builder.draft_path=spell_draft_path
	ui.add_child(spell_builder)
	spell_builder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spell_builder.anchor_right=0.53
	spell_builder.offset_left=UI_EDGE_GAP
	spell_builder.offset_top=98
	spell_builder.offset_right=0
	spell_builder.offset_bottom=-UI_EDGE_GAP
	spell_builder.setup(self)
	spell_builder.hide()
	_center_box_text(ui)
	loading_layer.queue_free()

func _center_box_text(root: Node) -> void:
	if root is Button:
		root.alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif root is LineEdit:
		root.alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif root is SpinBox:
		root.get_line_edit().alignment=HORIZONTAL_ALIGNMENT_CENTER
	for child in root.get_children():
		_center_box_text(child)

func panel(parent: Node,bounds: Vector4,wide:=false) -> Panel:
	var node:=Panel.new()
	if wide:node.anchor_right=1
	node.offset_left=bounds.x
	node.offset_top=bounds.y
	node.offset_right=bounds.z
	node.offset_bottom=bounds.w
	var style:=StyleBoxFlat.new()
	style.bg_color=BOOK_PAPER
	style.border_color=BOOK_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	node.add_theme_stylebox_override("panel",style)
	parent.add_child(node)
	return node

func _book_theme() -> Theme:
	var theme:=Theme.new()
	for type_name in ["HBoxContainer","VBoxContainer"]:theme.set_constant("separation",type_name,UI_EDGE_GAP)
	theme.set_stylebox("panel","PanelContainer",_book_box(BOOK_PAPER,BOOK_BORDER))
	for control_type in ["Label"]:
		theme.set_color("font_color",control_type,BOOK_INK)
		theme.set_color("font_hover_color",control_type,BOOK_INK)
		theme.set_color("font_pressed_color",control_type,BOOK_INK)
		theme.set_color("font_focus_color",control_type,BOOK_INK)
		theme.set_color("font_disabled_color",control_type,Color("84765f"))
	var button_normal:=_book_box(Color("d8c7a4"),BOOK_BORDER)
	var button_hover:=_book_box(Color("e3d3b3"),BOOK_GOLD)
	var button_pressed:=_book_box(Color("c9b38b"),BOOK_GOLD)
	var button_disabled:=_book_box(Color("c5b99f"),Color("b5a27f"))
	for control_type in ["Button","OptionButton"]:
		theme.set_stylebox("normal",control_type,button_normal)
		theme.set_stylebox("hover",control_type,button_hover)
		theme.set_stylebox("pressed",control_type,button_pressed)
		theme.set_stylebox("disabled",control_type,button_disabled)
		theme.set_stylebox("focus",control_type,button_hover)
		theme.set_color("font_color",control_type,BOOK_INK)
		theme.set_color("font_hover_color",control_type,BOOK_INK)
		theme.set_color("font_pressed_color",control_type,BOOK_INK)
		theme.set_color("font_focus_color",control_type,BOOK_INK)
		theme.set_color("font_disabled_color",control_type,Color("84765f"))
	for control_type in ["LineEdit","SpinBox"]:
		var field_style:=_book_box(BOOK_PAPER_LIGHT,BOOK_BORDER)
		theme.set_stylebox("normal",control_type,field_style)
		theme.set_stylebox("focus",control_type,_book_box(Color("fff8e9"),BOOK_GOLD))
		theme.set_color("font_color",control_type,BOOK_INK)
		theme.set_color("font_placeholder_color",control_type,Color("84765f"))
	for control_type in ["HSlider","VSlider"]:
		theme.set_stylebox("slider",control_type,_book_box(Color("c9b38b"),BOOK_BORDER))
		theme.set_stylebox("grabber_area",control_type,_book_box(Color("b08a4b"),Color("98703d")))
	theme.set_stylebox("panel","TabContainer",_book_box(BOOK_PAPER_LIGHT,BOOK_BORDER))
	for tab_type in ["TabContainer","TabBar"]:
		theme.set_stylebox("tab_selected",tab_type,_book_box(BOOK_PAPER_LIGHT,BOOK_GOLD))
		theme.set_stylebox("tab_unselected",tab_type,_book_box(BOOK_PAPER,BOOK_BORDER))
		theme.set_stylebox("tab_hovered",tab_type,_book_box(Color("e3d3b3"),BOOK_GOLD))
		theme.set_color("font_selected_color",tab_type,BOOK_INK)
		theme.set_color("font_unselected_color",tab_type,Color("77664d"))
		theme.set_color("font_hovered_color",tab_type,BOOK_INK)
	theme.set_color("font_color","CheckButton",BOOK_INK)
	theme.set_color("font_hover_color","CheckButton",BOOK_INK)
	theme.set_stylebox("panel","TooltipPanel",_book_box(BOOK_PAPER_LIGHT,BOOK_BORDER))
	theme.set_color("font_color","TooltipLabel",BOOK_INK)
	theme.set_color("font_shadow_color","TooltipLabel",Color.TRANSPARENT)
	return theme

func _set_edge_padding(style:StyleBox) -> void:
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,UI_EDGE_GAP)

func _padded_scroll_content(scroll:ScrollContainer,content:Control) -> void:
	var padding:=MarginContainer.new()
	padding.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	padding.add_theme_constant_override("margin_right",UI_EDGE_GAP)
	padding.add_theme_constant_override("margin_bottom",UI_EDGE_GAP)
	scroll.add_child(padding)
	padding.add_child(content)

func _book_box(fill:Color,border:Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	_set_edge_padding(style)
	return style

func _set_button_accent(button_:Button,selected:bool) -> void:
	button_.modulate=Color.WHITE
	button_.add_theme_stylebox_override("normal",_book_box(Color("d8c7a4") if selected else BOOK_PAPER_LIGHT,BOOK_GOLD if selected else BOOK_BORDER))
	button_.add_theme_stylebox_override("hover",_book_box(Color("e3d3b3"),BOOK_GOLD))
	button_.add_theme_stylebox_override("pressed",_book_box(Color("c9b38b"),BOOK_GOLD))
	button_.add_theme_stylebox_override("disabled",_book_box(Color("c5b99f"),BOOK_BORDER))
	button_.add_theme_color_override("font_color",BOOK_GOLD if selected else BOOK_INK)
	button_.add_theme_color_override("font_hover_color",BOOK_INK)
	button_.add_theme_color_override("font_pressed_color",BOOK_INK)
	button_.add_theme_color_override("font_disabled_color",Color("84765f"))

func _toggle_options_menu() -> void:
	for section in workspace_nav_panels:
		if section!="Store":workspace_nav_panels[section].hide()
	if not is_instance_valid(options_panel):return
	options_panel.visible=not options_panel.visible
	options_button.set_pressed_no_signal(options_panel.visible)

func _create_workspace_nav_panel(section:String) -> VBoxContainer:
	var popup:=PanelContainer.new()
	popup.name=section+"Menu"
	popup.anchor_left=0.5
	popup.anchor_right=0.5
	popup.offset_left=-167
	popup.offset_right=167
	popup.offset_top=60
	popup.add_theme_stylebox_override("panel",_book_box(BOOK_PAPER,BOOK_BORDER))
	base_ui.add_child(popup)
	popup.hide()
	workspace_nav_panels[section]=popup
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	popup.add_child(column)
	return column

func _open_workspace_section(section:String) -> void:
	if section=="Animations":
		for menu in workspace_nav_panels:
			if menu!="Store":workspace_nav_panels[menu].hide()
		select_group(selected_group if selected_group in ["Motion","Attack"] else "Motion")
		workspace_collapsed["Categories"]=false
		workspace_collapsed["Animations"]=false
		_apply_workspace_layout()
		save_workspace_layout()
		return
	var was_visible:bool=workspace_nav_panels.has(section) and workspace_nav_panels[section].visible
	for menu in workspace_nav_panels:
		if menu=="Store":continue
		workspace_nav_panels[menu].hide()
	options_panel.hide()
	options_button.set_pressed_no_signal(false)
	if section=="Spells":
		select_group("Spells")
		return
	if section=="Animations" and selected_group not in ["Motion","Attack"]:select_group("Motion")
	if section=="Store" and not was_visible:_load_animation_store()
	if workspace_nav_panels.has(section):
		workspace_nav_panels[section].visible=true if section=="Store" else not was_visible
		if not was_visible:base_ui.move_child(workspace_nav_panels[section],base_ui.get_child_count()-1)

func _load_animation_store() -> void:
	animation_store_entries=Library.entries()
	for group in Library.GROUPS:
		for category in category_store.names_for(group):animation_store_entries.append_array(load_custom_motion(category))
	# Include source clips beyond the curated Motion/Attack browser.
	var auxiliary:=load("res://assets/combat/animations/UAL2_Standard.glb") as AnimationLibrary
	var used:Dictionary={}
	for entry in animation_store_entries:used[str(entry.get("clip",""))]=true
	if auxiliary!=null:
		for name_ in auxiliary.get_animation_list():
			if used.has("ual2/"+name_) or name_=="RESET":continue
			animation_store_entries.append({"group":"Motion","category":"Source clips","title":name_.replace("_"," "),"step":"Idle","clip":"store_preview/"+name_,"source_animation":name_,"store_raw":true,"duration":auxiliary.get_animation(name_).length})
	for name_ in actor.player.get_animation_list():
		if name_.begins_with("store_preview/"):continue
		if name_.ends_with("RESET") or used.has(name_):continue
		if name_.begins_with("store_ual2/") and used.has("ual2/"+name_.get_slice("/",1)):continue
		var entry:Dictionary={"group":"Motion","category":"Source clips","title":name_.get_slice("/",1).replace("_"," "),"step":"Idle","clip":name_,"store_raw":true}
		entry["duration"]=actor.player.get_animation(name_).length
		animation_store_entries.append(entry)
	animation_store_entries.sort_custom(func(a:Dictionary,b:Dictionary):return str(a.title).naturalnocasecmp_to(str(b.title))<0)
	for index in animation_store_entries.size():
		var entry:Dictionary=animation_store_entries[index]
		var animation:Animation
		if entry.has("source_animation") and auxiliary!=null:animation=auxiliary.get_animation(str(entry.source_animation))
		elif actor.player.has_animation(str(entry.clip)):animation=actor.player.get_animation(str(entry.clip))
		animation_store_entries[index]=StoreLibrary.enrich(entry,animation)
	_populate_animation_store()

func _save_store_preferences() -> void:
	if not is_instance_valid(store_view_filter):return
	var config:=ConfigFile.new()
	config.set_value("store","search",animation_store_search.text)
	config.set_value("store","body",store_body_filter.selected)
	config.set_value("store","air",store_air_filter.selected)
	config.set_value("store","view",store_view_filter.selected)
	config.save("user://animation_store_preferences.cfg")

func _load_store_preferences() -> void:
	var config:=ConfigFile.new()
	if config.load("user://animation_store_preferences.cfg")!=OK:return
	animation_store_search.text=str(config.get_value("store","search",""))
	for pair in [[store_body_filter,"body"],[store_air_filter,"air"],[store_view_filter,"view"]]:
		var filter:OptionButton=pair[0]
		filter.select(clampi(int(config.get_value("store",pair[1],0)),0,filter.item_count-1))

func _style_store_action(control:Button,color:Color) -> void:
	control.add_theme_stylebox_override("normal",_book_box(color,color.darkened(0.2)))
	control.add_theme_stylebox_override("hover",_book_box(color.lightened(0.15),color.darkened(0.2)))
	control.add_theme_stylebox_override("pressed",_book_box(color.darkened(0.15),color.darkened(0.3)))

func _populate_animation_store() -> void:
	if not is_instance_valid(animation_store_list):return
	clear_list(animation_store_list)
	var query:=animation_store_search.text.strip_edges().to_lower()
	var count:=0
	for entry in animation_store_entries:
		var id:=StoreLibrary.key(entry)
		var taken:bool=store_library.is_taken(entry) or entry.has("path")
		var blocked:bool=store_library.blocked.has(id)
		if store_view_filter.selected==0 and (taken or blocked):continue
		if store_view_filter.selected==1 and not taken:continue
		if store_view_filter.selected==2 and not blocked:continue
		if store_library.taken.has(id):entry=store_library.taken[id].duplicate(true)
		if store_body_filter.selected>0 and store_body_filter.get_item_text(store_body_filter.selected) not in entry.get("body_parts",[]):continue
		if store_air_filter.selected>0 and str(entry.get("air_state",""))!=store_air_filter.get_item_text(store_air_filter.selected):continue
		if not query.is_empty() and not StoreLibrary.matches(entry,query):continue
		count+=1
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		animation_store_list.add_child(row)
		var title:=button(row,str(entry.title),func():_play_store_animation(entry))
		title.set_script(preload("res://scripts/animation_clip_source.gd"))
		title.set("entry",entry.duplicate(true))
		title.set("editor",self)
		title.set("store_origin",true)
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.clip_text=true
		title.tooltip_text=animation_info_text(entry)+"\nTags\t"+", ".join(entry.get("tags",[]))+"\nBody\t"+", ".join(entry.get("body_parts",[]))+"\nState\t"+str(entry.get("air_state","Grounded"))
		var play:=animation_icon_button(row,"play","Play once on selected bot",func():_play_store_animation(entry))
		play.name="StorePlay"
		_style_store_action(play,Color("388753"))
		var reject:=animation_icon_button(row,"undo" if blocked else "block","Unblock this animation" if blocked else "Block this animation from the Store",func():
			if store_library.set_blocked(entry,not blocked):_populate_animation_store())
		reject.name="StoreBlock"
		_style_store_action(reject,Color("b8443e") if not blocked else Color("9c743d"))
	animation_store_count.text="Animations · %d / %d"%[count,animation_store_entries.size()]
	call_deferred("_apply_panel_zoom","Store")

func _play_store_animation(entry:Dictionary) -> void:
	if not can_add_unit_animation():
		show_unit_selection_warning()
		return
	_ensure_animation_source(entry)
	if selected_group=="Spells":
		select_group("Motion")
		workspace_nav_panels.Store.show()
	play_animation_row(entry)

func _ensure_animation_source(entry:Dictionary) -> void:
	if entry.has("source_animation") and not actor.player.has_animation(str(entry.clip)):
		actor.player.stop()
		var source:=load("res://assets/combat/animations/UAL2_Standard.glb") as AnimationLibrary
		if not actor.player.has_animation_library("store_preview"):actor.player.add_animation_library("store_preview",AnimationLibrary.new())
		var library:AnimationLibrary=actor.player.get_animation_library("store_preview")
		library.add_animation(str(entry.source_animation),source.get_animation(str(entry.source_animation)).duplicate(true))

func take_store_animation(entry:Dictionary,group:String,category:String) -> void:
	if entry.has("store_asset_id") and store_library.taken.has(StoreLibrary.key(entry)):
		if store_library.move(StoreLibrary.key(entry),group,category):
			if selected_group!=group:select_group(group)
			select_category(category,true)
			_populate_animation_store()
			_show_library_notice("Moved %s → %s"%[entry.title,category])
		return
	var names:Array=[]
	for animation in Library.entries()+load_custom_motion(category):names.append(str(animation.title))
	if not store_library.take(entry,group,category,names):
		selection_status.text="Could not save animation to your library"
		return
	_populate_animation_store()
	if selected_group!=group:select_group(group)
	select_category(category,true)
	selection_status.text="Added %s to %s / %s"%[entry.title,group,category]
	_show_library_notice("Added %s → %s"%[store_library.last_taken_entry.get("title",entry.title),category])

func open_rename_animation(entry:Dictionary) -> void:
	var dialog:=ConfirmationDialog.new()
	dialog.title="Rename animation"
	dialog.theme=_book_theme()
	dialog.add_theme_stylebox_override("panel",_book_box(BOOK_PAPER,BOOK_BORDER))
	var input:=LineEdit.new()
	input.custom_minimum_size.x=300
	input.text=str(entry.title)
	dialog.add_child(input)
	var commit:=func():
		var requested:=input.text.strip_edges()
		if requested.is_empty():return
		if entry.has("store_asset_id"):
			store_library.rename(str(entry.store_asset_id),requested)
		elif entry.has("path"):
			var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(str(entry.path)))
			if parsed is Dictionary:
				var names:Array=[]
				for animation in Library.entries()+load_custom_motion(str(entry.category)):
					if str(animation.get("path",""))!=str(entry.path):names.append(str(animation.title))
				parsed["name"]=StoreLibrary.unique_name(requested,names)
				parsed["provenance"]=AssetProvenance.derive([AssetProvenance.source(entry)],"animation",str(parsed.name),AssetProvenance.creator_name(),"renamed animation")
				var file:=FileAccess.open(str(entry.path),FileAccess.WRITE)
				if file!=null:file.store_string(JSON.stringify(parsed,"\t"))
		else:
			if store_library.take(entry,str(entry.group),str(entry.category)):
				store_library.rename(StoreLibrary.key(entry),requested)
		select_category(selected_category,true)
		if is_instance_valid(animation_store_list) and workspace_nav_panels.Store.visible:_load_animation_store()
		dialog.queue_free()
	dialog.confirmed.connect(commit)
	input.text_submitted.connect(func(_text:String):commit.call())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
	input.grab_focus()
	input.select_all()

func _show_library_notice(message:String) -> void:
	var previous:=base_ui.get_node_or_null("LibraryNotice")
	if previous!=null:
		previous.hide()
		base_ui.remove_child(previous)
		previous.queue_free()
	var toast:=Label.new()
	toast.name="LibraryNotice"
	toast.text=message
	toast.add_theme_color_override("font_color",BOOK_INK)
	toast.add_theme_stylebox_override("normal",_book_box(BOOK_PAPER_LIGHT,BOOK_GOLD))
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	base_ui.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position=Vector2(maxf(6.0,(base_ui.size.x-toast.get_combined_minimum_size().x)*0.5),60.0)
	get_tree().create_timer(2.5).timeout.connect(toast.queue_free)

func open_take_animation_dialog(entry:Dictionary) -> void:
	var dialog:=ConfirmationDialog.new()
	dialog.title="Move animation to category" if entry.has("store_asset_id") else "Add to your animation library"
	dialog.theme=_book_theme()
	dialog.add_theme_stylebox_override("panel",_book_box(BOOK_PAPER,BOOK_BORDER))
	dialog.get_ok_button().text="Move" if entry.has("store_asset_id") else "Add"
	var choices:=OptionButton.new()
	choices.custom_minimum_size.x=300
	for group in Library.GROUPS:
		for category in category_store.names_for(group):
			choices.add_item(group+" / "+category)
			choices.set_item_metadata(choices.item_count-1,{"group":group,"category":category})
	dialog.add_child(choices)
	dialog.confirmed.connect(func():
		var destination:Dictionary=choices.get_item_metadata(choices.selected)
		take_store_animation(entry,str(destination.group),str(destination.category))
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func inspect_asset_metadata(entry:Dictionary) -> void:
	var dialog:=AcceptDialog.new()
	dialog.title="Animation metadata · "+str(entry.get("title","Asset"))
	dialog.theme=_book_theme()
	dialog.add_theme_stylebox_override("panel",_book_box(BOOK_PAPER,BOOK_BORDER))
	var text:=TextEdit.new()
	text.editable=false
	text.custom_minimum_size=Vector2(620,420)
	text.text=AssetProvenance.inspect_text(AssetProvenance.source(entry))+"\nAll metadata\n"+JSON.stringify(entry,"  ")
	dialog.add_child(text)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func build_timeline(parent:Control) -> void:
	timeline_panel=PanelContainer.new()
	timeline_panel.name="MovieTimeline"
	timeline_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	timeline_panel.offset_left=0
	timeline_panel.offset_right=0
	timeline_panel.offset_top=-350
	timeline_panel.offset_bottom=-PLAYBACK_BAR_HEIGHT
	var style:=StyleBoxFlat.new()
	style.bg_color=BOOK_PAPER
	style.border_color=BOOK_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	timeline_panel.add_theme_stylebox_override("panel",style)
	_set_edge_padding(style)
	parent.add_child(timeline_panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",UI_EDGE_GAP)
	timeline_panel.add_child(column)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(top)
	var title:=menu_label(top,"TIMELINE",16)
	title.custom_minimum_size.x=90
	timeline_name=LineEdit.new()
	timeline_name.placeholder_text="Animation name"
	timeline_name.custom_minimum_size.x=210
	timeline_library_menu=OptionButton.new()
	timeline_library_menu.custom_minimum_size.x=150
	timeline_library_menu.hide()
	timeline_library_menu.item_selected.connect(_select_saved_timeline)
	top.add_child(timeline_library_menu)
	var length_label:=menu_label(top,"Length",13)
	timeline_length_input=SpinBox.new()
	timeline_length_input.min_value=0.1
	timeline_length_input.max_value=120
	timeline_length_input.step=0.1
	timeline_length_input.value=timeline_duration
	timeline_length_input.suffix=" s"
	timeline_length_input.add_theme_icon_override("updown",RowIcons.get_icon("length_arrows"))
	timeline_length_input.custom_minimum_size.x=90
	timeline_length_input.value_changed.connect(_set_timeline_duration)
	top.add_child(timeline_length_input)
	timeline_damage_label=menu_label(top,"DMG 0",13)
	timeline_stamina_label=menu_label(top,"Stamina 0",13)
	timeline_mana_label=menu_label(top,"Mana 0",13)
	timeline_damage_label.hide()
	timeline_stamina_label.hide()
	timeline_mana_label.hide()
	timeline_time_label=menu_label(top,"0.00 s",14)
	timeline_time_label.hide()
	var top_spacer:=Control.new()
	top_spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(top_spacer)
	timeline_time_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	timeline_time_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var priority_label:=menu_label(top,"Priority",13)
	timeline_priority=OptionButton.new()
	for value in range(1,6):timeline_priority.add_item(str(value),value)
	timeline_priority.select(2)
	timeline_priority.tooltip_text="Higher numbers win overlapping pose conflicts. Jump height continues independently beneath backflips and limb attacks."
	timeline_priority.custom_minimum_size.x=54
	timeline_priority.item_selected.connect(_timeline_priority_changed)
	top.add_child(timeline_priority)
	timeline_motion_panel=PanelContainer.new()
	timeline_motion_panel.visible=false
	var motion_style:=StyleBoxFlat.new()
	motion_style.bg_color=BOOK_PAPER_LIGHT
	motion_style.border_color=BOOK_BORDER
	motion_style.set_border_width_all(1)
	motion_style.set_corner_radius_all(4)
	_set_edge_padding(motion_style)
	timeline_motion_panel.add_theme_stylebox_override("panel",motion_style)
	column.add_child(timeline_motion_panel)
	var stat_column:=VBoxContainer.new()
	stat_column.add_theme_constant_override("separation",UI_EDGE_GAP)
	timeline_motion_panel.add_child(stat_column)
	timeline_motion_name=menu_label(stat_column,"ANIMATION",12)
	var motion_row:=HBoxContainer.new()
	motion_row.add_theme_constant_override("separation",UI_EDGE_GAP)
	stat_column.add_child(motion_row)
	for key in ["Stamina depletion","Damage","Mana saved"]:
		var box:=VBoxContainer.new()
		box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation",UI_EDGE_GAP)
		motion_row.add_child(box)
		var readout:=menu_label(box,key,12)
		var color:Color={"Effort":Color("98703d"),"Stamina depletion":Color("398351"),"Damage":Color("b84438"),"Mana saved":Color("397fab")}[key]
		readout.add_theme_color_override("font_color",color)
		var slider:=HSlider.new()
		slider.custom_minimum_size=Vector2(100,24)
		slider.min_value=0.05 if key=="Mana saved" else 0
		slider.max_value=16 if key=="Mana saved" else (200 if key=="Damage" else 100)
		slider.step=0.05 if key=="Mana saved" else 0.1
		slider.tooltip_text={"Effort":"Total stamina spent (0–100)","Stamina depletion":"Stamina spent; 100 means fully depleted","Damage":"Adjust damage by changing stamina depletion. Animation time stays unchanged.","Mana saved":"Adjust mana saved by changing animation time. Damage and stamina depletion stay unchanged."}[key]
		slider.add_theme_stylebox_override("grabber_area",_book_box(color,color))
		slider.add_theme_stylebox_override("grabber_area_highlight",_book_box(color.lightened(0.15),color))
		box.add_child(slider)
		timeline_linked_bars[key]={"slider":slider,"label":readout}
		slider.value_changed.connect(func(value:float):_linked_stat_changed(key,value))
	timeline_motion_effort=timeline_linked_bars["Stamina depletion"].slider
	timeline_motion_bar=timeline_linked_bars["Stamina depletion"].slider
	timeline_motion_output=menu_label(stat_column,"",11)
	timeline_clip_scroll=ScrollContainer.new()
	timeline_clip_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	timeline_clip_scroll.custom_minimum_size.y=120
	timeline_clip_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	timeline_clip_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(timeline_clip_scroll)
	timeline_tracks=VBoxContainer.new()
	timeline_tracks.add_theme_constant_override("separation",2)
	_padded_scroll_content(timeline_clip_scroll,timeline_tracks)
	_rebuild_timeline_tracks()

func open_timeline_save_dialog() -> void:
	if is_instance_valid(timeline_save_overlay):timeline_save_overlay.queue_free()
	timeline_save_overlay=ColorRect.new()
	timeline_save_overlay.name="TimelineSaveAsOverlay"
	timeline_save_overlay.color=Color(0.08,0.06,0.04,0.55)
	timeline_save_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	timeline_save_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_ui.add_child(timeline_save_overlay)
	var card:=PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left=-210
	card.offset_top=-92
	card.offset_right=210
	card.offset_bottom=92
	var card_style:=StyleBoxFlat.new()
	card_style.bg_color=BOOK_PAPER
	card_style.border_color=BOOK_GOLD
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(8)
	_set_edge_padding(card_style)
	card.add_theme_stylebox_override("panel",card_style)
	timeline_save_overlay.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",UI_EDGE_GAP)
	card.add_child(content)
	var heading:=menu_label(content,"SAVE AS",20)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	timeline_save_name=LineEdit.new()
	timeline_save_name.text=timeline_name.text.strip_edges()
	timeline_save_name.placeholder_text="Animation name"
	timeline_save_name.custom_minimum_size.y=38
	timeline_save_name.alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(timeline_save_name)
	var actions:=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",UI_EDGE_GAP)
	content.add_child(actions)
	var confirm:=button(actions,"Save",_confirm_timeline_save)
	confirm.custom_minimum_size=Vector2(110,38)
	var cancel:=button(actions,"Cancel",_close_timeline_save_dialog)
	cancel.custom_minimum_size=Vector2(110,38)
	timeline_save_name.text_submitted.connect(func(_value:String):_confirm_timeline_save())
	timeline_save_name.grab_focus()
	timeline_save_name.select_all()

func _confirm_timeline_save() -> void:
	var name_:=timeline_save_name.text.strip_edges() if is_instance_valid(timeline_save_name) else ""
	if name_.is_empty():
		timeline_save_name.placeholder_text="Enter a name"
		timeline_save_name.grab_focus()
		return
	timeline_name.text=name_
	_close_timeline_save_dialog()
	save_timeline()

func _close_timeline_save_dialog() -> void:
	if is_instance_valid(timeline_save_overlay):timeline_save_overlay.queue_free()
	timeline_save_overlay=null
	timeline_save_name=null

func clear_timeline() -> void:
	_record_timeline_undo()
	stop_timeline()
	timeline_clips.clear()
	timeline_serial=0
	timeline_selected_id=-1
	timeline_playhead=0.0
	_update_timeline_ruler()
	call_deferred("_apply_panel_zoom","Timeline")
	if is_instance_valid(timeline_time_label):timeline_time_label.text="0.00 s"
	_rebuild_timeline_tracks()
	save_timeline()

func seed_timeline() -> void:
	timeline_duration=1.0
	if is_instance_valid(timeline_length_input):timeline_length_input.set_value_no_signal(timeline_duration)
	_update_timeline_ruler()
	var samples:Array[Dictionary]=[
		{"track":"BODY","group":"Attack","category":"Punch","title":"Left jab","step":"Punch","clip":"ual1/Punch_Jab","attack_bone":"hand_l","start":0.0,"duration":TIMELINE_DEFAULT_CLIP_DURATION,"priority":3}
	]
	for sample in samples:
		timeline_serial+=1
		sample["id"]=timeline_serial
		timeline_clips.append(sample)

func _rebuild_timeline_tracks() -> void:
	if not is_instance_valid(timeline_tracks):return
	_update_timeline_combat_totals()
	for child in timeline_tracks.get_children():child.queue_free()
	var width:=maxi(1,roundi(timeline_duration*TIMELINE_PIXELS_PER_SECOND))
	var ruler_row:=HBoxContainer.new()
	ruler_row.custom_minimum_size.y=26
	ruler_row.add_theme_constant_override("separation",UI_EDGE_GAP)
	timeline_tracks.add_child(ruler_row)
	var fit_button:=button(ruler_row,"Fit",fit_timeline_to_clips)
	fit_button.custom_minimum_size=Vector2(86,26)
	fit_button.tooltip_text="Set Length to the end of the last clip, removing unused time"
	timeline_scrubber=Control.new()
	timeline_scrubber.set_script(load("res://scripts/animation_timeline_ruler.gd"))
	timeline_scrubber.set("editor",self)
	timeline_scrubber.custom_minimum_size=Vector2(width,26)
	timeline_scrubber.size=Vector2(width,26)
	timeline_scrubber.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ruler_row.add_child(timeline_scrubber)
	_add_timeline_unused_overlay(timeline_scrubber)
	for track in TIMELINE_TRACKS:
		var row:=HBoxContainer.new()
		row.custom_minimum_size.y=36
		row.add_theme_constant_override("separation",UI_EDGE_GAP)
		timeline_tracks.add_child(row)
		var label:=menu_label(row,"EVERYTHING" if track=="BODY" else track,13)
		label.custom_minimum_size.x=86
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		var lane:=Control.new()
		lane.set_script(load("res://scripts/animation_timeline_lane.gd"))
		lane.set("editor",self)
		lane.set("track_id",track)
		lane.custom_minimum_size=Vector2(width,36)
		lane.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(lane)
		for clip in timeline_clips:
			if str(clip.track)!=track:continue
			var clip_button:=Button.new()
			var combat:=_clip_combat_stats(clip)
			clip_button.text="%s · STA %.1f"%[clip.title,combat.stamina]
			if str(clip.get("group",""))=="Attack" and float(combat.damage)>0:
				clip_button.text+=" · DMG %.1f"%float(combat.damage)
			clip_button.pressed.connect(func():select_timeline_clip(int(clip.id)))
			clip_button.set_script(load("res://scripts/animation_timeline_clip.gd"))
			clip_button.set("editor",self)
			clip_button.set("clip_id",int(clip.id))
			lane.add_child(clip_button)
			clip_button.position=Vector2(float(clip.start)*TIMELINE_PIXELS_PER_SECOND,2)
			clip_button.size=Vector2(maxf(36.0,float(clip.duration)*TIMELINE_PIXELS_PER_SECOND),32)
			clip_button.tooltip_text=animation_info_text(clip)
			clip_button.set_meta("timeline_clip_id",clip.id)
			clip_button.gui_input.connect(func(event):_on_clip_gui_input(event,int(clip.id)))
		_add_timeline_unused_overlay(lane)
		lane.queue_redraw()
	_update_timeline_ruler()
	call_deferred("_apply_panel_zoom","Timeline")

func _add_timeline_unused_overlay(parent:Control) -> void:
	var overlay:=Control.new()
	overlay.set_script(preload("res://scripts/animation_timeline_unused.gd"))
	overlay.set("editor",self)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func add_next_unit() -> void:
	var screen:=get_viewport().get_visible_rect().size
	spawn_editor_unit_at_screen(Vector2((workspace_browser_width+screen.x)*0.5,(54.0+screen.y-workspace_timeline_height)*0.5))

func _build_workspace_dividers(ui:Control) -> void:
	var config:=ConfigFile.new()
	if config.load("user://animation_workspace_layout.cfg")==OK:
		workspace_collapsed=config.get_value("layout","collapsed",workspace_collapsed).duplicate()
		panel_zoom_levels=config.get_value("layout","zoom",{}).duplicate()
		workspace_category_width=float(config.get_value("layout","categories",164.0))
		workspace_browser_width=float(config.get_value("layout","browser",490.0))
		workspace_timeline_height=float(config.get_value("layout","timeline",350.0))
	for panel_name in ["Categories","Animations"]:
		var restore:=Button.new()
		restore.text="+"
		restore.pressed.connect(func():toggle_workspace_panel(panel_name))
		ui.add_child(restore)
		restore.tooltip_text="Expand "+panel_name
		restore.custom_minimum_size=Vector2(28,32)
		workspace_restore_buttons[panel_name]=restore
	for kind in ["categories","browser","timeline"]:
		var handle:=Control.new()
		handle.set_script(preload("res://scripts/animation_workspace_divider.gd"))
		handle.set("editor",self)
		handle.set("kind",kind)
		handle.name="Resize"+kind.capitalize()
		ui.add_child(handle)
		workspace_dividers.append(handle)
	ui.resized.connect(_apply_workspace_layout)
	panel_zoom_roots.merge({"Categories":workspace_categories,"Animations":workspace_choices,"Timeline":timeline_panel,"Options":options_panel,"Playback":animation_footer})
	TIMELINE_PIXELS_PER_SECOND=100.0*float(panel_zoom_levels.get("Timeline",1.0))
	for key in panel_zoom_roots:call_deferred("_apply_panel_zoom",key)
	_apply_workspace_layout()

func _zoom_panel_at(point:Vector2) -> String:
	for key in ["Store","Options","Timeline","Categories","Animations","Playback","Header"]:
		if not panel_zoom_roots.has(key):continue
		var root:Control=panel_zoom_roots[key]
		if root.is_visible_in_tree() and root.get_global_rect().has_point(point):return key
	return ""

func change_panel_zoom(key:String,steps:int,reset:=false) -> void:
	if not panel_zoom_roots.has(key):return
	var zoom:=1.0 if reset else clampf(float(panel_zoom_levels.get(key,1.0))+float(steps)*0.1,0.6,1.8)
	panel_zoom_levels[key]=zoom
	if key=="Timeline":
		TIMELINE_PIXELS_PER_SECOND=100.0*zoom
		_rebuild_timeline_tracks()
	_apply_panel_zoom(key)
	save_workspace_layout()

func _apply_panel_zoom(key:String) -> void:
	if not panel_zoom_roots.has(key):return
	_scale_panel_controls(panel_zoom_roots[key],float(panel_zoom_levels.get(key,1.0)))
	if key=="Animations":_apply_workspace_layout()

func _scale_panel_controls(node:Node,zoom:float) -> void:
	if node is Control:
		if not node.has_meta("zoom_base_minimum"):node.set_meta("zoom_base_minimum",node.custom_minimum_size)
		var base:Vector2=node.get_meta("zoom_base_minimum")
		var is_time_axis:bool=node==timeline_scrubber or node.get_script()==preload("res://scripts/animation_timeline_lane.gd")
		node.custom_minimum_size=Vector2(base.x if is_time_axis else base.x*zoom,base.y*zoom)
		if node is Label or node is Button or node is LineEdit or node is SpinBox:
			if not node.has_meta("zoom_base_font"):node.set_meta("zoom_base_font",node.get_theme_font_size("font_size"))
			node.add_theme_font_size_override("font_size",maxi(8,roundi(float(node.get_meta("zoom_base_font"))*zoom)))
		if node is Button and node.icon!=null:
			node.expand_icon=true
			node.add_theme_constant_override("icon_max_width",maxi(8,roundi(20.0*zoom)))
		if node is Button and node.has_meta("timeline_clip_id"):
			node.size.y=32.0*zoom
			node.position.y=2.0*zoom
		node.queue_redraw()
	for child in node.get_children():_scale_panel_controls(child,zoom)

func resize_workspace(kind:String,coordinate:float) -> void:
	match kind:
		"categories":workspace_category_width=coordinate
		"browser":workspace_browser_width=coordinate
		"timeline":workspace_timeline_height=base_ui.size.y-coordinate
	_apply_workspace_layout()

func toggle_workspace_panel(panel_name:String) -> void:
	workspace_collapsed[panel_name]=not bool(workspace_collapsed.get(panel_name,false))
	_apply_workspace_layout()
	save_workspace_layout()

func _apply_workspace_layout() -> void:
	if not is_instance_valid(base_ui) or workspace_dividers.size()!=3:return
	var screen:=base_ui.size
	if screen.x<1.0 or screen.y<1.0:return
	# Fit this window without overwriting the user's saved panel sizes.
	var browser_width:=clampf(workspace_browser_width,350.0,maxf(350.0,screen.x-240.0))
	var category_width:=clampf(workspace_category_width,130.0,browser_width-180.0)
	var choices_width:=browser_width-category_width
	if workspace_collapsed.get("Categories",false):category_width=32.0
	if workspace_collapsed.get("Animations",false):choices_width=32.0
	browser_width=category_width+choices_width
	for panel_name in ["Categories","Animations"]:
		var collapsed:bool=workspace_collapsed.get(panel_name,false)
		var panel_:Control=workspace_categories if panel_name=="Categories" else workspace_choices
		for child in panel_.get_children():
			if child is CanvasItem:child.visible=not collapsed
		var restore:Button=workspace_restore_buttons[panel_name]
		restore.visible=collapsed
		restore.position=Vector2(2 if panel_name=="Categories" else category_width+2,60)
	var timeline_height:=clampf(workspace_timeline_height,220.0,maxf(220.0,screen.y-204.0))
	workspace_categories.offset_right=category_width
	workspace_choices.offset_left=category_width
	workspace_choices.offset_right=browser_width
	var available:=maxf(100.0,choices_width-20.0)
	for row in animation_list.get_children():
		if not row is HBoxContainer:continue
		var action_count:=maxi(1,row.get_child_count()-1)
		var icon_width:=clampf((available-65.0)/action_count-3.0,14.0,32.0)
		row.add_theme_constant_override("separation",3)
		for child in row.get_children():
			if child is Button and child.icon!=null:
				child.expand_icon=true
				child.custom_minimum_size.x=icon_width
				child.add_theme_constant_override("icon_max_width",int(minf(icon_width-4,20)))
	browser.offset_bottom=-timeline_height
	timeline_panel.offset_top=-timeline_height
	var drop:Control=base_ui.get_node("ArenaUnitDrop")
	drop.offset_left=browser_width
	drop.offset_bottom=-timeline_height
	for index in range(2):
		var x:=category_width if index==0 else browser_width
		workspace_dividers[index].position=Vector2(x-3.0,54.0)
		workspace_dividers[index].size=Vector2(6.0,maxf(0.0,screen.y-timeline_height-54.0))
	workspace_dividers[2].position=Vector2(0,screen.y-timeline_height-3.0)
	workspace_dividers[2].size=Vector2(screen.x,6.0)

func save_workspace_layout() -> void:
	var config:=ConfigFile.new()
	config.set_value("layout","categories",workspace_category_width)
	config.set_value("layout","browser",workspace_browser_width)
	config.set_value("layout","timeline",workspace_timeline_height)
	config.set_value("layout","zoom",panel_zoom_levels)
	config.set_value("layout","collapsed",workspace_collapsed)
	config.save("user://animation_workspace_layout.cfg")

func spawn_editor_unit_at_screen(screen_position:Vector2) -> CharacterBody3D:
	var camera:Camera3D=field.camera
	var origin:=camera.project_ray_origin(screen_position)
	var direction:=camera.project_ray_normal(screen_position)
	var hit:Variant=Plane(Vector3.UP,0.02).intersects_ray(origin,direction)
	if hit==null:return null
	var location:Vector3=hit
	var radius:=float(field.Boundary.RADIUS)-2.0
	var flat:=Vector2(location.x,location.z).limit_length(radius)
	location=Vector3(flat.x,0.02,flat.y)
	return spawn_editor_unit(location)

func spawn_editor_unit(location:Vector3) -> CharacterBody3D:
	var number:=added_units.size()+1
	var unit:=preload("res://scripts/battle_actor.gd").new()
	unit.name="BOT_%d"%number
	unit.team=0
	unit.arena=field
	unit.story_profile=preload("res://scripts/creation_bot_outfit.gd").profile(number-1)
	unit.brain_enabled=false
	unit.editor_pose_locked=true
	unit.set_meta("bot_number",number)
	field.add_child(unit)
	unit.global_position=location
	unit.set_meta("editor_ground_y",location.y)
	unit.global_basis=actor.global_basis
	unit.set_meta("editor_home_transform",unit.global_transform)
	unit.collision_layer=0
	unit.collision_mask=0
	for item in unit.targets:item[0].collision_layer=0
	for item in unit.limb_targets:item[0].collision_layer=0
	preload("res://scripts/fighter_overhead_tag.gd").attach(unit,"BOT_%d"%number)
	unit.player.stop()
	preload("res://scripts/editor_rig_pose.gd").idle(unit)
	added_units.append(unit)
	var ring:=MeshInstance3D.new()
	ring.name="UnitFocusRing"
	var mesh:=TorusMesh.new()
	mesh.inner_radius=0.42
	mesh.outer_radius=0.47
	mesh.rings=24
	mesh.ring_segments=8
	ring.mesh=mesh
	ring.position.y=0.04
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override=material
	unit.add_child(ring)
	focus_editor_unit(added_units.size()-1)
	unit_source.text="BOT_%d"%(number+1)
	selection_status.text="Added BOT_%d"%number
	return unit

func arena_drag_point(screen_position:Vector2) -> Variant:
	var camera:Camera3D=field.camera
	return Plane(Vector3.UP,0.02).intersects_ray(camera.project_ray_origin(screen_position),camera.project_ray_normal(screen_position))

func move_editor_unit(unit:CharacterBody3D,location:Vector3) -> void:
	if not is_instance_valid(unit):return
	var flat:=Vector2(location.x,location.z).limit_length(float(field.Boundary.RADIUS)-2.0)
	unit.global_position=Vector3(flat.x,float(unit.get_meta("editor_ground_y",0.02)),flat.y)
	if unit==focused_unit:_capture_timeline_origin()

func reset_focused_unit_position() -> void:
	if not can_add_unit_animation():
		show_unit_selection_warning()
		return
	stop_timeline()
	clear_jump_tails(focused_unit,true)
	focused_unit.global_transform=focused_unit.get_meta("editor_home_transform",focused_unit.global_transform)
	focused_unit.set_meta("editor_ground_y",focused_unit.global_position.y)
	_capture_timeline_origin()
	selection_status.text="Reset position · "+str(focused_unit.name)

func focus_editor_unit(index:int) -> void:
	if playtest.active:playtest.release()
	if index<0 or index>=added_units.size():return
	row_preview_unit=null
	if timeline_playing:stop_timeline()
	focused_unit=added_units[index]
	_capture_timeline_origin()
	preview_note.text="Focused %s · timeline applies here · [ / ] changes unit"%focused_unit.name
	selection_status.text="Focused "+str(focused_unit.name)
	_update_unit_focus_rings()

func _pick_editor_unit(screen_position:Vector2) -> CharacterBody3D:
	var camera:Camera3D=field.camera
	var origin:=camera.project_ray_origin(screen_position)
	var ray_end:=origin+camera.project_ray_normal(screen_position)*200.0
	var closest:CharacterBody3D
	var distance:=INF
	for unit in added_units:
		if not is_instance_valid(unit) or camera.is_position_behind(unit.global_position):continue
		var points:=Geometry3D.get_closest_points_between_segments(origin,ray_end,unit.global_position+Vector3.UP*0.3,unit.global_position+Vector3.UP*1.55)
		if points[0].distance_to(points[1])>0.4:continue
		var depth:=origin.distance_to(points[0])
		if depth<distance:closest=unit;distance=depth
	return closest

func _update_unit_focus_rings() -> void:
	for unit in added_units:
		if not is_instance_valid(unit):continue
		var ring:MeshInstance3D=unit.get_node("UnitFocusRing")
		ring.visible=unit==focused_unit or unit==hovered_unit
		ring.material_override.albedo_color=Color("e9bf54") if unit==focused_unit else Color("80d8ff")

func _update_timeline_ruler() -> void:
	if not is_instance_valid(timeline_scrubber):return
	var width:=maxi(1,roundi(timeline_duration*TIMELINE_PIXELS_PER_SECOND))
	timeline_scrubber.custom_minimum_size.x=width
	timeline_scrubber.queue_redraw()

func _on_clip_gui_input(event:InputEvent,clip_id:int) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
		remove_timeline_clip(clip_id)

func can_add_unit_animation() -> bool:
	return is_instance_valid(focused_unit) and focused_unit in added_units and focused_unit.is_visible_in_tree()

func show_unit_selection_warning() -> void:
	if not is_instance_valid(unit_selection_warning):
		unit_selection_warning=AcceptDialog.new()
		unit_selection_warning.name="SelectBotWarning"
		unit_selection_warning.title="Select a bot first"
		unit_selection_warning.dialog_text="Add a bot through Simulations → Units, then click the bot to select it.\nYou can then add animations to its timeline."
		unit_selection_warning.theme=_book_theme()
		unit_selection_warning.add_theme_stylebox_override("panel",_book_box(BOOK_PAPER,BOOK_BORDER))
		add_child(unit_selection_warning)
	if not unit_selection_warning.visible:unit_selection_warning.call_deferred("popup_centered")

func add_timeline_clip(entry:Dictionary,track:String,time:float) -> void:
	if not can_add_unit_animation():
		show_unit_selection_warning()
		return
	_ensure_animation_source(entry)
	_capture_timeline_origin()
	_record_timeline_undo()
	timeline_serial+=1
	var clip:=entry.duplicate(true)
	clip["id"]=timeline_serial
	clip["track"]=track
	var default_duration:=_animation_timeline_duration(entry)
	clip["source_length"]=default_duration
	clip["start"]=0.0
	clip["duration"]=minf(default_duration,timeline_duration-float(clip.start))
	clip["priority"]=3
	var motion_type:=_timeline_motion_type(clip)
	if not motion_type.is_empty():
		clip["effort"]=_timeline_default_effort(motion_type)
	timeline_clips.append(clip)
	_rebuild_timeline_tracks()
	select_timeline_clip(timeline_serial)
	save_timeline()

func _record_timeline_undo() -> void:
	timeline_redo_history.clear()
	var snapshot:Dictionary={"clips":timeline_clips.duplicate(true),"duration":timeline_duration,"selected":timeline_selected_id,"playhead":timeline_playhead}
	if not timeline_undo_history.is_empty() and timeline_undo_history.back()==snapshot:return
	timeline_undo_history.append(snapshot)
	if timeline_undo_history.size()>100:timeline_undo_history.pop_front()

func undo_timeline_edit() -> void:
	while not timeline_undo_history.is_empty():
		var snapshot:Dictionary=timeline_undo_history.pop_back()
		if snapshot.clips==timeline_clips and is_equal_approx(float(snapshot.duration),timeline_duration):continue
		timeline_redo_history.append({"clips":timeline_clips.duplicate(true),"duration":timeline_duration,"selected":timeline_selected_id,"playhead":timeline_playhead})
		stop_timeline()
		timeline_clips.assign(snapshot.clips.duplicate(true))
		timeline_duration=float(snapshot.duration)
		timeline_selected_id=int(snapshot.selected)
		timeline_playhead=clampf(float(snapshot.playhead),0.0,timeline_duration)
		timeline_length_input.set_value_no_signal(timeline_duration)
		_rebuild_timeline_tracks()
		_update_timeline_ruler()
		if timeline_selected_id>=0:select_timeline_clip(timeline_selected_id)
		save_timeline()
		selection_status.text="Undid timeline edit"
		return
	selection_status.text="Nothing to undo"

func redo_timeline_edit() -> void:
	if timeline_redo_history.is_empty():return
	var snapshot:Dictionary=timeline_redo_history.pop_back()
	timeline_undo_history.append({"clips":timeline_clips.duplicate(true),"duration":timeline_duration,"selected":timeline_selected_id,"playhead":timeline_playhead})
	stop_timeline()
	timeline_clips.assign(snapshot.clips.duplicate(true))
	timeline_duration=float(snapshot.duration)
	timeline_selected_id=int(snapshot.selected)
	timeline_playhead=clampf(float(snapshot.playhead),0.0,timeline_duration)
	timeline_length_input.set_value_no_signal(timeline_duration)
	_rebuild_timeline_tracks()
	_update_timeline_ruler()
	if timeline_selected_id>=0:select_timeline_clip(timeline_selected_id)
	save_timeline()
	selection_status.text="Redid timeline edit"

func copy_timeline_clip() -> void:
	for clip in timeline_clips:
		if int(clip.id)==timeline_selected_id:
			timeline_clip_clipboard=clip.duplicate(true)
			selection_status.text="Copied "+str(clip.title)
			return
	selection_status.text="Select a timeline clip to copy"

func paste_timeline_clip() -> void:
	if not can_add_unit_animation():
		show_unit_selection_warning()
		return
	if timeline_clip_clipboard.is_empty():
		selection_status.text="Copy a timeline clip first"
		return
	_record_timeline_undo()
	stop_timeline()
	var clip:Dictionary=timeline_clip_clipboard.duplicate(true)
	timeline_serial+=1
	clip.id=timeline_serial
	clip.start=timeline_playhead
	timeline_clips.append(clip)
	timeline_duration=maxf(timeline_duration,float(clip.start)+float(clip.duration))
	timeline_length_input.set_value_no_signal(timeline_duration)
	_rebuild_timeline_tracks()
	select_timeline_clip(timeline_serial)
	save_timeline()
	selection_status.text="Pasted "+str(clip.title)

func _animation_timeline_duration(entry:Dictionary) -> float:
	if entry.has("duration"):
		return maxf(0.1,float(entry.duration))
	if str(entry.get("step",""))=="Jump":return SourcePose.duration(actor,"Jump",str(entry.get("clip","duel/air")))
	var clip_name:=str(entry.get("clip",""))
	if is_instance_valid(actor) and is_instance_valid(actor.player) and actor.player.has_animation(clip_name):
		return maxf(0.1,actor.player.get_animation(clip_name).length)
	return TIMELINE_DEFAULT_CLIP_DURATION

func edit_timeline_clip_edge(id:int,edge:String,delta_seconds:float,stretch:bool=false) -> void:
	_record_timeline_undo()
	stop_timeline()
	for clip in timeline_clips:
		if int(clip.id)!=id:continue
		var start:=float(clip.start)
		var duration:=float(clip.duration)
		var rate:=float(clip.get("speed",1.0))
		var source_in:=float(clip.get("source_in",0.0))
		var source_length:=float(clip.get("source_length",_animation_timeline_duration(clip)))
		# Native source length is independent of the edited timeline duration.
		var name_:=str(clip.get("clip",""))
		if not clip.has("source_length") and str(clip.get("step",""))!="Jump" and actor.player.has_animation(name_):source_length=actor.player.get_animation(name_).length
		if edge=="left":
			var change:=clampf(delta_seconds,-start,duration-0.05)
			if not stretch:change=maxf(change,-source_in/rate)
			clip.start=start+change
			clip.duration=duration-change
			if stretch:clip.speed=rate*duration/float(clip.duration)
			else:clip.source_in=maxf(0.0,source_in+change*rate)
		else:
			var new_duration:=maxf(0.05,duration+delta_seconds)
			if not stretch:new_duration=minf(new_duration,maxf(0.05,(source_length-source_in)/rate))
			clip.duration=new_duration
			if stretch:clip.speed=rate*duration/new_duration
		if stretch and _timeline_motion_type(clip)=="Jump":
			var flight:=maxf(0.0,float(clip.duration)-0.14-0.24)
			var needed:=float(actor.GRAVITY)*flight*flight/(8.0*0.035)
			clip.effort=clampf(maxf(float(clip.get("effort",18.0)),needed),0.0,100.0)
		if stretch and float(clip.start)+float(clip.duration)>timeline_duration:
			timeline_duration=float(clip.start)+float(clip.duration)
			timeline_length_input.set_value_no_signal(timeline_duration)
		break
	_rebuild_timeline_tracks()
	save_timeline()

func split_selected_timeline_clip() -> void:
	stop_timeline()
	for clip in timeline_clips:
		if int(clip.id)!=timeline_selected_id:continue
		var left_duration:=timeline_playhead-float(clip.start)
		if left_duration<0.05 or float(clip.duration)-left_duration<0.05:
			selection_status.text="Place the playhead inside the selected clip to split"
			return
		var right:Dictionary=clip.duplicate(true)
		_record_timeline_undo()
		timeline_serial+=1
		right.id=timeline_serial
		right.start=timeline_playhead
		right.duration=float(clip.duration)-left_duration
		right.source_in=float(clip.get("source_in",0.0))+left_duration*float(clip.get("speed",1.0))
		clip.duration=left_duration
		timeline_clips.append(right)
		_rebuild_timeline_tracks()
		save_timeline()
		return

func remove_timeline_clip(id:int) -> void:
	_record_timeline_undo()
	for i in range(timeline_clips.size()-1,-1,-1):
		if int(timeline_clips[i].id)==id:timeline_clips.remove_at(i)
	_rebuild_timeline_tracks()
	save_timeline()

func select_timeline_clip(id:int) -> void:
	for clip in timeline_clips:
		if int(clip.id)==id:
			timeline_selected_id=id
			timeline_priority.select(clampi(int(clip.get("priority",3))-1,0,4))
			preview_heading.text=str(clip.title)
			preview_note.text="%s track · priority %d"%[clip.track,int(clip.priority)]
			_refresh_timeline_motion_controls(clip)
			if not timeline_playing and not _timeline_motion_type(clip).is_empty():_preview_selected_motion(clip)
			return
	if is_instance_valid(timeline_motion_panel):timeline_motion_panel.hide()

func _timeline_motion_type(clip:Dictionary) -> String:
	var step:=str(clip.get("step",clip.get("category",""))).to_lower()
	if step in ["jump","run","sprint","dash"]:return step.capitalize()
	return ""

func _timeline_default_effort(motion_type:String) -> float:
	match motion_type:
		"Jump":return 18.0
		"Run":return 6.0
		"Sprint":return 10.0
		"Dash":return 12.0
	return 0.0

func _clip_default_effort(clip:Dictionary) -> float:
	var motion:=_timeline_motion_type(clip)
	if not motion.is_empty():return _timeline_default_effort(motion)
	return float({"Idle":1,"Crouch":3,"Block":5,"Brace Block":8,"Knee":13,"Kick":15,"Round Kick":17,"Uppercut":18,"Sweep":17,"Elbow":12,"Cross":11,"Hook":12}.get(str(clip.get("step","")),8))

func _clip_combat_stats(clip:Dictionary) -> Dictionary:
	var idle:=str(clip.get("category",""))=="Idle" or str(clip.get("title","")).to_lower().begins_with("idle")
	var effort:=0.0 if idle else clampf(float(clip.get("effort",_clip_default_effort(clip))),0.0,100.0)
	var native_duration:=maxf(0.1,float(clip.get("source_length",_animation_timeline_duration(clip))))
	var duration:=maxf(0.05,float(clip.get("duration",native_duration)))
	var motion_only:=str(clip.get("group",""))!="Attack" or str(clip.get("step","")) in ["Jump","Run","Sprint","Land","Dash","Crouch","Flip","Twist"]
	var attack:=not motion_only and str(clip.get("category","")) not in ["Block","Dodges"]
	var damage:float=0.1+effort*1.5 if attack else 0.0
	var spell:Dictionary=clip.get("attached_spell",{})
	var spell_multiplier:=pow(2.0,1.0-duration) if not motion_only else 1.0
	var mana:=maxf(0.0,float(spell.get("mana",0.0)))*spell_multiplier
	return {"effort":effort,"duration":duration,"damage_multiplier":1.0,"stamina":effort,"damage":damage,"spell_multiplier":spell_multiplier,"mana":mana}

func animation_info_text(entry:Dictionary) -> String:
	var stats:=_clip_combat_stats(entry)
	if str(entry.get("group",""))!="Attack":
		return "%s\nAnimation time\t%.2f s\nStamina cost\t%.1f"%[entry.get("title","Animation"),stats.duration,stats.stamina]
	return "%s\nAnimation time\t%.2f s\nStamina cost\t%.1f\nDamage\t%.1f\nMana cost multiplier\t×%.6f"%[entry.get("title","Animation"),stats.duration,stats.stamina,stats.damage,stats.spell_multiplier]

func toggle_timeline_spell() -> void:
	for clip in timeline_clips:
		if int(clip.id)!=timeline_selected_id:continue
		_record_timeline_undo()
		if not (clip.get("attached_spell",{}) as Dictionary).is_empty():clip.erase("attached_spell")
		elif is_instance_valid(spell_builder):clip["attached_spell"]=spell_builder.projectile_spec().duplicate(true)
		_rebuild_timeline_tracks()
		_refresh_timeline_motion_controls(clip)
		save_timeline()
		return
	selection_status.text="Select a timeline clip to attach a spell"

func _update_timeline_combat_totals() -> void:
	var damage:=0.0
	var stamina:=0.0
	var mana:=0.0
	for clip in timeline_clips:
		var stats:=_clip_combat_stats(clip)
		clip["stamina_cost"]=stats.stamina
		clip["physical_damage"]=stats.damage
		clip["mana_cost"]=stats.mana
		clip["spell_multiplier"]=stats.spell_multiplier
		damage+=float(stats.damage)
		stamina+=float(stats.stamina)
		mana+=float(stats.mana)
	if is_instance_valid(timeline_damage_label):timeline_damage_label.text="DMG %.1f"%damage
	if is_instance_valid(timeline_stamina_label):timeline_stamina_label.text="Stamina %.1f"%stamina
	if is_instance_valid(timeline_mana_label):timeline_mana_label.text="Mana %.1f"%mana
	for clip in timeline_clips:
		if int(clip.id)==timeline_selected_id:
			_refresh_timeline_motion_controls(clip)
			return
	if is_instance_valid(timeline_spell_label):timeline_spell_label.text="Select a clip · Spell multiplier applies only with an attached spell"
	if is_instance_valid(timeline_spell_button):timeline_spell_button.text="Attach spell"

func _refresh_timeline_spell_controls(clip:Dictionary) -> void:
	if not is_instance_valid(timeline_spell_label):return
	var spell:Dictionary=clip.get("attached_spell",{})
	var stats:=_clip_combat_stats(clip)
	timeline_spell_button.text="Detach spell" if not spell.is_empty() else "Attach spell"
	timeline_spell_label.text="%s · Spell ×%.2f · Mana %.1f"%[spell.get("name","Spell"),stats.spell_multiplier,stats.mana] if not spell.is_empty() else "No spell attached · Mana 0"
	timeline_spell_label.tooltip_text="Mana = base spell cost ÷ clip duration in seconds. A 0.5 s cast costs 2×; a 2 s cast costs 0.5×."

func _timeline_motion_stats(clip:Dictionary) -> Dictionary:
	var motion_type:=_timeline_motion_type(clip)
	var effort:=clampf(float(clip.get("effort",_timeline_default_effort(motion_type))),0.0,100.0)
	var duration:=maxf(0.1,float(clip.get("duration",1.0)))
	var distance:=0.0
	var height:=0.0
	match motion_type:
		"Jump":
			height=effort*0.035
	var airtime:=sqrt(8.0*height/float(actor.GRAVITY)) if height>0.0 else 0.0
	return {"effort":effort,"distance":distance,"height":height,"airtime":airtime,"jump_duration":0.14+airtime+0.24}

func _refresh_timeline_motion_controls(clip:Dictionary) -> void:
	if not is_instance_valid(timeline_motion_panel):return
	_refresh_timeline_spell_controls(clip)
	var motion_type:=_timeline_motion_type(clip)
	timeline_motion_panel.show()
	var stats:=_timeline_motion_stats(clip)
	var combat:=_clip_combat_stats(clip)
	timeline_motion_name.text=str(clip.get("title",motion_type)).to_upper()
	timeline_motion_effort.set_value_no_signal(float(combat.effort))
	var values:Dictionary={"Effort":combat.effort,"Stamina depletion":combat.stamina,"Damage":combat.damage,"Mana saved":100.0*(1.0-float(combat.spell_multiplier))}
	for key in timeline_linked_bars:
		var slider:HSlider=timeline_linked_bars[key].slider
		slider.get_parent().visible=key=="Stamina depletion" or str(clip.get("group",""))=="Attack"
		slider.set_block_signals(true)
		if key=="Damage":slider.max_value=maxf(200.0,float(combat.damage)*1.25)
		if key=="Mana saved":slider.max_value=maxf(16.0,float(combat.duration))
		slider.value=float(combat.duration) if key=="Mana saved" else float(values[key])
		slider.editable=key!="Damage" or (str(clip.get("group",""))=="Attack" and str(clip.get("category","")) not in ["Block","Dodges"])
		slider.set_block_signals(false)
		(timeline_linked_bars[key].label as Label).text="Mana saved %.2f%% · %.2f s"%[values[key],combat.duration] if key=="Mana saved" else "%s %.1f"%[key,values[key]]
	if motion_type=="Jump":
		var land_at:=float(clip.get("start",0.0))+0.14+float(stats.airtime)
		var used_duration:=minf(float(clip.duration),maxf(0,timeline_duration-float(clip.get("start",0.0))))
		var extra:=maxf(0.0,0.14+float(stats.airtime)-used_duration)
		timeline_motion_output.text="Height %.2f m · Airtime %.2f s · Lands at %.2f s · Air continues +%.2f s after playback"%[float(stats.height),float(stats.airtime),land_at,extra]
	elif not motion_type.is_empty():
		timeline_motion_output.text=""
	else:timeline_motion_output.text=""
	timeline_motion_output.visible=not timeline_motion_output.text.is_empty()

func _linked_stat_changed(key:String,value:float) -> void:
	if key in ["Damage","Mana saved"]:
		for clip in timeline_clips:
			if int(clip.id)==timeline_selected_id and str(clip.get("group",""))!="Attack":return
	if key in ["Effort","Stamina depletion","Damage"]:
		timeline_motion_effort.set_value_no_signal(clampf((value-0.1)/1.5,0.0,100.0) if key=="Damage" else value)
		_timeline_motion_parameters_changed()
		return
	for clip in timeline_clips:
		if int(clip.id)!=timeline_selected_id:continue
		var duration:float
		if key=="Mana saved":duration=value
		edit_timeline_clip_edge(int(clip.id),"right",clampf(duration,0.05,120.0)-float(clip.duration),true)
		_refresh_timeline_motion_controls(clip)
		return

func _timeline_motion_parameters_changed(_value:Variant=0) -> void:
	_record_timeline_undo()
	for clip in timeline_clips:
		if int(clip.get("id",-1))!=timeline_selected_id:continue
		clip["effort"]=timeline_motion_effort.value
		var stats:=_timeline_motion_stats(clip)
		clip["travel_distance"]=stats.distance
		clip["jump_height"]=stats.height
		_refresh_timeline_motion_controls(clip)
		_update_timeline_combat_totals()
		_rebuild_timeline_tracks()
		save_timeline()
		if not timeline_playing and not _timeline_motion_type(clip).is_empty():
			_preview_selected_motion(clip)
		return

func _preview_selected_motion(clip:Dictionary) -> void:
	if not timeline_origin_valid:_capture_timeline_origin()
	var motion_type:=_timeline_motion_type(clip)
	var preview_time:=float(clip.get("start",0.0))+float(clip.get("duration",1.0))*(0.5 if motion_type=="Jump" else 1.0)
	timeline_playhead=clampf(preview_time,0.0,timeline_duration)
	_apply_timeline_at(timeline_playhead,true)
	_update_timeline_ruler()
	if is_instance_valid(timeline_time_label):timeline_time_label.text="%.2f s"%timeline_playhead

func _capture_timeline_origin() -> void:
	if not is_instance_valid(actor):return
	timeline_origin_position=actor.global_position
	timeline_origin_basis=actor.global_basis
	timeline_origin_valid=true
	if is_instance_valid(focused_unit):
		timeline_unit_origin=focused_unit.global_position
		if timeline_clips.any(func(clip):return str(clip.get("step",""))=="Jump"):
			timeline_unit_origin.y=float(focused_unit.get_meta("editor_ground_y",timeline_unit_origin.y))

func _apply_timeline_root_motion(time:float) -> void:
	if not is_instance_valid(actor):return
	if not timeline_origin_valid:_capture_timeline_origin()
	if not timeline_origin_valid:return
	var horizontal:=Vector3.ZERO
	var vertical:=0.0
	var seen_motion:Dictionary={}
	for clip in timeline_clips:
		var motion_type:=_timeline_motion_type(clip)
		if motion_type.is_empty():continue
		var start:=float(clip.get("start",0.0))
		if time<start:continue
		var motion_key:="%s:%d"%[motion_type,roundi(start*20.0)]
		if seen_motion.has(motion_key):continue
		seen_motion[motion_key]=true
		var duration:=maxf(0.1,float(clip.get("duration",1.0)))
		var progress:=clampf((time-start)/duration,0.0,1.0)
		var eased:=progress*progress*(3.0-2.0*progress)
		var stats:=_timeline_motion_stats(clip)
		if motion_type=="Jump":
			progress=clampf((time-start-0.14)/maxf(0.001,float(stats.airtime)),0.0,1.0)
			eased=progress*progress*(3.0-2.0*progress)
		var direction:Vector3=timeline_origin_basis.z.normalized()
		horizontal+=direction*float(stats.distance)*eased
		if motion_type=="Jump" and progress<1.0:
			vertical+=float(stats.height)*4.0*progress*(1.0-progress)
	actor.global_position=timeline_origin_position+horizontal+Vector3.UP*vertical
	if is_instance_valid(focused_unit):focused_unit.global_position=timeline_unit_origin+horizontal+Vector3.UP*vertical

func _timeline_priority_changed(index:int) -> void:
	_record_timeline_undo()
	for clip in timeline_clips:
		if int(clip.id)==timeline_selected_id:
			clip.priority=index+1
			_rebuild_timeline_tracks()
			select_timeline_clip(timeline_selected_id)
			save_timeline()
			return

func move_timeline_clip(id:int,track:String,time:float) -> void:
	_record_timeline_undo()
	for clip in timeline_clips:
		if int(clip.id)==id:
			clip.track=track
			clip.start=clampf(time,0.0,maxf(0.0,timeline_duration-float(clip.duration)))
			_rebuild_timeline_tracks()
			if timeline_selected_id==id:select_timeline_clip(id)
			save_timeline()
			return

func begin_timeline_clip_drag(id:int,track:String) -> void:
	timeline_drag_clip_id=id
	timeline_drag_original_track=track

func finish_timeline_clip_drag(id:int,mouse_global:Vector2,clip_global:Vector2) -> void:
	var destination:=timeline_drag_original_track
	for row in timeline_tracks.get_children():
		if row.get_child_count()<2:continue
		var lane:=row.get_child(1) as Control
		if str(lane.get("track_id"))=="":continue
		var rect:=lane.get_global_rect()
		if mouse_global.y>=rect.position.y and mouse_global.y<=rect.end.y:
			destination=str(lane.get("track_id"))
			break
	var target_lane:=_timeline_lane_for(destination)
	var start_x:=clip_global.x
	if is_instance_valid(target_lane):start_x-=target_lane.global_position.x
	timeline_drag_clip_id=-1
	timeline_drag_original_track=""
	move_timeline_clip(id,destination,start_x/TIMELINE_PIXELS_PER_SECOND)

func _timeline_lane_for(track:String) -> Control:
	for row in timeline_tracks.get_children():
		if row.get_child_count()>1 and str(row.get_child(1).get("track_id"))==track:return row.get_child(1) as Control
	return null

func _on_timeline_scrubbed(value:float) -> void:
	clear_jump_tails(focused_unit)
	timeline_playhead=clampf(value,0.0,timeline_duration)
	if is_instance_valid(timeline_time_label):timeline_time_label.text="%.2f s"%value
	if not timeline_playing:_apply_timeline_at(value,true)
	_update_timeline_ruler()
	_update_timeline_clip_highlights()

func _update_timeline_clip_highlights() -> void:
	if not is_instance_valid(timeline_tracks):return
	var active_ids:Dictionary={}
	for clip in timeline_active.values():active_ids[int(clip.get("id",-1))]=true
	for row in timeline_tracks.get_children():
		if row.get_child_count()<2:continue
		var lane:Control=row.get_child(1)
		for clip_button in lane.get_children():
			if not clip_button is Button or not clip_button.has_meta("timeline_clip_id"):continue
			var is_active:=active_ids.has(int(clip_button.get_meta("timeline_clip_id")))
			clip_button.modulate=Color("ffe07a") if is_active else Color.WHITE

func play_timeline() -> void:
	clear_jump_tails(focused_unit,true)
	if playtest.active:
		var required:=0.0
		for clip in timeline_clips:required+=float(_clip_combat_stats(clip).stamina)
		if focused_unit.stamina+0.001<required:
			_show_library_notice("Not enough stamina · Backspace resets test units")
			return
		playtest.hit_once.clear()
		playtest.previous_points.clear()
		timeline_playhead=0
		repeat_playing=false
		actor.global_basis=focused_unit.global_basis
	row_preview_unit=null
	if selected_group=="Spells":return
	if not is_instance_valid(focused_unit):
		selection_status.text="Add and focus a unit before playing"
		return
	if timeline_playhead>=timeline_duration:timeline_playhead=0.0
	if not timeline_playing:
		var keep_repeating:=repeat_playing
		preserve_camera_on_setup_reset=true
		_reset_animation_state_in_place()
		preserve_camera_on_setup_reset=false
		_capture_timeline_origin()
		repeat_playing=keep_repeating
		_set_button_accent(repeat_play_button,repeat_playing)
		for fighter in field.fighters:fighter.editor_pose_locked=true
		actor.player.stop()
		actor.skeleton.reset_bone_poses()
		preload("res://scripts/editor_rig_pose.gd").idle(actor,idle_preview_elapsed)
	timeline_playing=true
	timeline_active.clear()
	get_tree().paused=false
	_apply_timeline_at(timeline_playhead,true)

func stop_timeline() -> void:
	if timeline_playing:_continue_jump_after_timeline()
	row_preview_unit=null
	timeline_playing=false
	timeline_active.clear()
	for player in actor.story_limb_players.values():player.stop()
	actor.player.stop()
	actor.skeleton.reset_bone_poses()
	preload("res://scripts/editor_rig_pose.gd").idle(actor,idle_preview_elapsed)
	get_tree().paused=false
	_update_timeline_clip_highlights()

func reset_timeline() -> void:
	stop_timeline()
	clear_jump_tails(focused_unit,true)
	timeline_playhead=0.0
	_capture_timeline_origin()
	_update_timeline_ruler()
	_apply_timeline_at(0.0,true)

func toggle_timeline_repeat() -> void:
	var enable_repeat:=not repeat_playing
	if enable_repeat and not timeline_playing:
		play_timeline()
	repeat_playing=enable_repeat
	_set_button_accent(repeat_play_button,repeat_playing)

func _apply_timeline_at(time:float,force:bool=false) -> void:
	var winners:Dictionary={}
	for clip in timeline_clips:
		var start:=float(clip.get("start",0.0))
		if time<start or time>=start+float(clip.get("duration",1.0)):continue
		var track:=str(clip.get("track","BODY"))
		var previous:Dictionary=winners.get(track,{})
		# Jump's height is a physical layer. Other authored poses can play over it.
		var jump_pose:bool=track=="BODY" and str(clip.get("step",""))=="Jump"
		var previous_jump:bool=track=="BODY" and str(previous.get("step",""))=="Jump"
		if jump_pose and not previous.is_empty() and not previous_jump:continue
		if previous.is_empty() or (previous_jump and not jump_pose) or int(clip.get("priority",1))>int(previous.get("priority",1)):winners[track]=clip
	var body_clip:Dictionary=winners.get("BODY",{})
	if body_clip.is_empty():body_clip=_active_jump_pose(time)
	if body_clip.is_empty():preload("res://scripts/editor_rig_pose.gd").idle(actor,idle_preview_elapsed)
	_apply_effective_track("BODY",body_clip,time,force)
	var channel_tracks:Dictionary={"face":"HEAD","torso":"TORSO","arm_l":"LEFT ARM","arm_r":"RIGHT ARM","leg_l":"LEFT LEG","leg_r":"RIGHT LEG"}
	for channel in channel_tracks:
		var limb_track:String=channel_tracks[channel]
		var limb_clip:Dictionary=winners.get(limb_track,{})
		var chosen:Dictionary=limb_clip
		var chosen_track:=limb_track
		var body_priority:=int(body_clip.get("priority",1)) if str(body_clip.get("step",""))!="Jump" else -1
		if not body_clip.is_empty() and (limb_clip.is_empty() or body_priority>int(limb_clip.get("priority",1))):
			chosen=body_clip
			chosen_track="OVERRIDE:"+channel
		if chosen_track.begins_with("OVERRIDE:"):
			_apply_effective_track(limb_track,{},time,force)
			_apply_effective_track(chosen_track,chosen,time,force)
		else:
			timeline_active.erase("OVERRIDE:"+channel)
			_apply_effective_track(limb_track,chosen,time,force)
	for key in timeline_active.keys():
		if str(key) not in TIMELINE_TRACKS and not str(key).begins_with("OVERRIDE:"):timeline_active.erase(key)
	_apply_timeline_root_motion(time)
	if is_instance_valid(focused_unit):
		_set_unit_pose_target(focused_unit)

func _active_jump_pose(time:float) -> Dictionary:
	var chosen:Dictionary={}
	for clip in timeline_clips:
		if _timeline_motion_type(clip)!="Jump":continue
		var elapsed:=time-float(clip.start)
		var stats:=_timeline_motion_stats(clip)
		if elapsed<0 or elapsed>=float(stats.jump_duration):continue
		if chosen.is_empty() or int(clip.get("priority",1))>int(chosen.get("priority",1)):chosen=clip
	return chosen

func _set_unit_pose_target(unit:CharacterBody3D) -> void:
	var poses:Array[Transform3D]=[]
	for bone in mini(unit.skeleton.get_bone_count(),actor.skeleton.get_bone_count()):
		poses.append(actor.skeleton.get_bone_pose(bone))
	unit.set_meta("editor_pose_target",poses)

func clear_jump_tails(unit:CharacterBody3D=null,ground:=false) -> void:
	for index in range(jump_tails.size()-1,-1,-1):
		var state:Dictionary=jump_tails[index]
		if unit!=null and state.unit!=unit:continue
		if is_instance_valid(state.unit):
			if ground:state.unit.global_position.y=float(state.ground)
			state.unit.remove_meta("editor_jump_tail")
		jump_tails.remove_at(index)

func _continue_jump_after_timeline() -> void:
	if not is_instance_valid(focused_unit):return
	for clip in timeline_clips:
		if _timeline_motion_type(clip)!="Jump":continue
		var elapsed:=timeline_playhead-float(clip.start)
		var stats:=_timeline_motion_stats(clip)
		if elapsed<0.14 or elapsed>=0.14+float(stats.airtime):continue
		clear_jump_tails(focused_unit)
		jump_tails.append({"unit":focused_unit,"entry":clip.duplicate(true),"elapsed":elapsed,"height":float(stats.height),"airtime":float(stats.airtime),"ground":float(focused_unit.get_meta("editor_ground_y",0.02))})
		focused_unit.set_meta("editor_jump_tail",true)
		return

func _tick_jump_tails(delta:float) -> void:
	for index in range(jump_tails.size()-1,-1,-1):
		var state:Dictionary=jump_tails[index]
		var unit:CharacterBody3D=state.unit
		if not is_instance_valid(unit):jump_tails.remove_at(index);continue
		state.elapsed=float(state.elapsed)+delta
		var flight:=maxf(0.001,float(state.airtime))
		var progress:=clampf((float(state.elapsed)-0.14)/flight,0,1)
		unit.global_position.y=float(state.ground)+4.0*float(state.height)*progress*(1.0-progress)
		var landed_at:=0.14+flight
		if float(state.elapsed)<landed_at:
			var entry:Dictionary=state.entry
			var source_time:=float(entry.get("source_in",0.0))+minf(float(entry.duration),float(state.elapsed))*float(entry.get("speed",1.0))
			_sample_effort_jump(entry,float(state.elapsed),source_time)
			_set_unit_pose_target(unit)
		else:
			preload("res://scripts/editor_rig_pose.gd").sample(actor,"duel/land",minf(0.24,float(state.elapsed)-landed_at))
			_set_unit_pose_target(unit)
		if float(state.elapsed)>=landed_at+0.24:
			unit.global_position.y=float(state.ground)
			unit.remove_meta("editor_jump_tail")
			_set_unit_idle_target(unit,idle_preview_elapsed)
			jump_tails.remove_at(index)

func _set_unit_idle_target(unit:CharacterBody3D,time:=0.0) -> void:
	var current:Array[Transform3D]=[]
	for bone in unit.skeleton.get_bone_count():current.append(unit.skeleton.get_bone_pose(bone))
	preload("res://scripts/editor_rig_pose.gd").idle(unit,time)
	var target_pose:Array[Transform3D]=[]
	for bone in unit.skeleton.get_bone_count():
		target_pose.append(unit.skeleton.get_bone_pose(bone))
		unit.skeleton.set_bone_pose(bone,current[bone])
	unit.set_meta("editor_pose_target",target_pose)

func _blend_unit_pose_targets(delta:float) -> void:
	var weight:=1.0-exp(-maxf(0.0,delta)/UNIT_POSE_BLEND_SECONDS)
	for unit in added_units:
		if not is_instance_valid(unit) or not unit.has_meta("editor_pose_target"):continue
		var poses:Array=unit.get_meta("editor_pose_target")
		for bone in mini(poses.size(),unit.skeleton.get_bone_count()):
			unit.skeleton.set_bone_pose(bone,unit.skeleton.get_bone_pose(bone).interpolate_with(poses[bone],weight))

func _apply_effective_track(track:String,clip:Dictionary,time:float,force:bool) -> void:
	var previous:Dictionary=timeline_active.get(track,{})
	if clip.is_empty():
		if not previous.is_empty():_stop_track(track)
		timeline_active.erase(track)
		return
	if force or previous.get("id",-1)!=clip.get("id",-2):
		if track.begins_with("OVERRIDE:"):
			var channel:=track.trim_prefix("OVERRIDE:")
			var channel_track:String={"face":"HEAD","torso":"TORSO","arm_l":"LEFT ARM","arm_r":"RIGHT ARM","leg_l":"LEFT LEG","leg_r":"RIGHT LEG"}.get(channel,"")
			_stop_track(channel_track)
	timeline_active[track]=clip
	if not track.begins_with("OVERRIDE:"):
		_start_track(track,clip,time-float(clip.start))

func _start_track(track:String,clip:Dictionary,offset:float) -> void:
	if track!="BODY":
		var previous:Array[Transform3D]=[]
		for bone in actor.skeleton.get_bone_count():previous.append(actor.skeleton.get_bone_pose(bone))
		_start_track("BODY",clip,offset)
		for bone in actor.skeleton.get_bone_count():
			if not _bone_in_timeline_track(actor.skeleton.get_bone_name(bone),track):actor.skeleton.set_bone_pose(bone,previous[bone])
		return
	var name_:String=str(clip.get("clip",""))
	var elapsed:=offset
	offset=float(clip.get("source_in",0.0))+offset*float(clip.get("speed",1.0))
	if str(clip.get("step",""))=="Jump":
		_sample_effort_jump(clip,elapsed,offset)
		return
	if clip.get("frames",[]).size()>=2:
		var source_entry:=clip.duplicate(true)
		source_entry.duration=float(clip.get("source_length",clip.duration))
		_sample_row_animation(source_entry,offset)
		return
	if track=="BODY":
		if actor.player.has_animation(name_):
			actor.skeleton.reset_bone_poses()
			if actor.player.assigned_animation!=name_:actor.player.play(name_)
			actor.player.pause()
			actor.player.seek(offset,true)
			if bool(clip.get("mirrored",false)):
				preload("res://scripts/animation_mirror.gd").apply(actor)
		return
	var channel: String=""
	match track:
		"HEAD":channel="face"
		"LEFT ARM":channel="arm_l"
		"RIGHT ARM":channel="arm_r"
		"LEFT LEG":channel="leg_l"
		"RIGHT LEG":channel="leg_r"
		"TORSO":channel="torso"
	if not channel.is_empty() and actor._play_story_limb_animation(channel,name_):
		var player:AnimationPlayer=actor.story_limb_players[channel]
		player.pause()
		player.seek(offset,true)

func _bone_in_timeline_track(bone:String,track:String) -> bool:
	if track=="HEAD":return bone in ["Head","neck_01","jaw","eye_l","eye_r"]
	if track=="TORSO":return bone in ["spine_01","spine_02","spine_03"]
	var side:="l" if track.begins_with("LEFT") else "r"
	if not bone.ends_with("_"+side):return false
	var prefixes:Array=["clavicle_","upperarm_","lowerarm_","hand_","thumb_","index_","middle_","pinky_","ring_"] if track.ends_with("ARM") else ["thigh_","calf_","foot_","ball_"]
	for prefix in prefixes:
		if bone.begins_with(prefix):return true
	return false

func _sample_effort_jump(entry:Dictionary,elapsed:float,source_time:float) -> void:
	var stats:=_timeline_motion_stats(entry)
	var landing_time:=0.14+float(stats.airtime)
	if elapsed>=landing_time:
		actor.skeleton.reset_bone_poses()
		if elapsed<landing_time+0.24:
			actor.player.play("duel/land")
			actor.player.pause()
			actor.player.seek(elapsed-landing_time,true)
		else:
			actor.player.stop()
			preload("res://scripts/editor_rig_pose.gd").idle(actor)
		return
	_sample_editor_jump(entry,source_time)

func _sample_editor_jump(entry:Dictionary,time:float) -> void:
	var duration:=SourcePose.duration(actor,"Jump","duel/air")
	var source_length:=maxf(0.1,float(entry.get("source_length",entry.get("duration",duration))))
	var progress:=clampf(time/source_length,0.0,1.0)
	var recipe:Dictionary=SourcePose.clip_at(actor,"Jump","duel/air",progress,duration)
	actor.skeleton.reset_bone_poses()
	actor.player.play(str(recipe.name))
	actor.player.pause()
	actor.player.seek(actor.player.get_animation(str(recipe.name)).length*float(recipe.blend),true)
	if entry.has("frames") and entry.frames.size()>=2:
		actor.apply_custom_jump_pose(progress,entry.frames,true)

func _stop_track(track:String) -> void:
	if track=="BODY":actor.player.stop();return
	var channel: String={"HEAD":"face","TORSO":"torso","LEFT ARM":"arm_l","RIGHT ARM":"arm_r","LEFT LEG":"leg_l","RIGHT LEG":"leg_r"}.get(track,"")
	if actor.story_limb_players.has(channel):actor.story_limb_players[channel].stop()

func save_timeline() -> void:
	var name_:=timeline_name.text.strip_edges() if is_instance_valid(timeline_name) else "New animation"
	if name_.is_empty():return
	var snapshot:Dictionary={"name":name_,"duration":timeline_duration,"clips":timeline_clips.duplicate(true)}
	var found_index:=-1
	for i in range(timeline_library.size()):
		if str(timeline_library[i].get("name",""))==name_:found_index=i;break
	if found_index>=0:timeline_library[found_index]=snapshot
	else:timeline_library.append(snapshot)
	if is_instance_valid(timeline_library_menu):
		_rebuild_timeline_library_menu()
		for visible_index in range(timeline_visible_library_indices.size()):
			var library_index:=timeline_visible_library_indices[visible_index]
			if str(timeline_library[library_index].get("name",""))==name_:
				timeline_library_menu.select(visible_index)
				break
	var config:=ConfigFile.new()
	config.set_value("timeline","saved",timeline_library)
	config.set_value("timeline","active",found_index if found_index>=0 else timeline_library.size()-1)
	config.save(TIMELINE_PATH)
	if is_instance_valid(selection_status):selection_status.text="Saved · "+name_

func _rebuild_timeline_library_menu() -> void:
	if not is_instance_valid(timeline_library_menu):return
	timeline_library_menu.clear()
	timeline_visible_library_indices.clear()
	for i in range(timeline_library.size()):
		var name_:=str(timeline_library[i].get("name","Animation %d"%(i+1))).strip_edges()
		if name_.is_empty() or name_.to_lower()=="new animation":continue
		timeline_library_menu.add_item(name_,i)
		timeline_visible_library_indices.append(i)
	timeline_library_menu.visible=not timeline_visible_library_indices.is_empty()
	var selected:=-1
	var current_name:=timeline_name.text.strip_edges() if is_instance_valid(timeline_name) else ""
	for visible_index in range(timeline_visible_library_indices.size()):
		if str(timeline_library[timeline_visible_library_indices[visible_index]].get("name",""))==current_name:
			selected=visible_index
			break
	timeline_library_menu.select(selected)

func _select_saved_timeline(index:int) -> void:
	if index<0 or index>=timeline_visible_library_indices.size():return
	stop_timeline()
	var library_index:=timeline_visible_library_indices[index]
	var snapshot:Dictionary=timeline_library[library_index]
	timeline_name.text=str(snapshot.get("name",""))
	timeline_duration=float(snapshot.get("duration",12.0))
	timeline_clips.clear()
	for clip in snapshot.get("clips",[]):
		if clip is Dictionary:timeline_clips.append(clip.duplicate(true))
	timeline_serial=0
	for clip in timeline_clips:timeline_serial=maxi(timeline_serial,int(clip.get("id",0)))
	timeline_length_input.set_value_no_signal(timeline_duration)
	timeline_playhead=0.0
	_rebuild_timeline_tracks()
	_apply_timeline_at(0.0,true)
	var config:=ConfigFile.new()
	config.set_value("timeline","saved",timeline_library)
	config.set_value("timeline","active",library_index)
	config.save(TIMELINE_PATH)

func new_timeline() -> void:
	timeline_undo_history.clear()
	timeline_redo_history.clear()
	stop_timeline()
	timeline_name.text=""
	timeline_duration=1.0
	timeline_length_input.set_value_no_signal(timeline_duration)
	timeline_playhead=0.0
	timeline_clips.clear()
	timeline_serial=0
	timeline_selected_id=-1
	if is_instance_valid(timeline_library_menu):timeline_library_menu.select(-1)
	_rebuild_timeline_tracks()
	timeline_time_label.text="0.00 s"

func _set_timeline_duration(value:float) -> void:
	_record_timeline_undo()
	stop_timeline()
	timeline_duration=maxf(0.1,value)
	timeline_playhead=minf(timeline_playhead,timeline_duration)
	if is_instance_valid(timeline_time_label):timeline_time_label.text="%.2f s"%timeline_playhead
	_rebuild_timeline_tracks()
	save_timeline()

func fit_timeline_to_clips() -> void:
	var end:=0.1
	for clip in timeline_clips:end=maxf(end,float(clip.start)+float(clip.duration))
	_set_timeline_duration(end)
	timeline_length_input.set_value_no_signal(timeline_duration)
	selection_status.text="Timeline fitted to clips · %.2f s"%timeline_duration

func load_timeline() -> void:
	var config:=ConfigFile.new()
	if config.load(TIMELINE_PATH)!=OK:return
	timeline_library.clear()
	for snapshot in config.get_value("timeline","saved",[]):
		if snapshot is Dictionary:timeline_library.append(snapshot)
	if timeline_library.is_empty() and config.has_section_key("timeline","clips"):
		var legacy:Dictionary={"name":str(config.get_value("timeline","name","New animation")),"duration":float(config.get_value("timeline","duration",12.0)),"clips":config.get_value("timeline","clips",[])}
		timeline_library.append(legacy)
	_rebuild_timeline_library_menu()
	var active_index:=int(config.get_value("timeline","active",timeline_library.size()-1))
	if not timeline_library.is_empty():
		active_index=clampi(active_index,0,timeline_library.size()-1)
		var snapshot:Dictionary=timeline_library[active_index]
		# Old unnamed drafts must not override the default starter animation.
		if str(snapshot.get("name","")).strip_edges().to_lower() in ["","new animation"]:
			timeline_clips.clear()
			timeline_serial=0
			return
		timeline_duration=float(snapshot.get("duration",12.0))
		timeline_clips.clear()
		for clip in snapshot.get("clips",[]):
			if clip is Dictionary:timeline_clips.append(clip.duplicate(true))
		var loaded_name:=str(snapshot.get("name",""))
		if is_instance_valid(timeline_name):timeline_name.text="" if loaded_name.to_lower()=="new animation" else loaded_name
		_rebuild_timeline_library_menu()
	_update_timeline_ruler()
	if is_instance_valid(timeline_length_input):timeline_length_input.set_value_no_signal(timeline_duration)
	for clip in timeline_clips:timeline_serial=maxi(timeline_serial,int(clip.get("id",0)))

func clear_list(container: Node) -> void:
	for node in container.get_children():
		container.remove_child(node)
		node.queue_free()

func stop_animation_preview() -> void:
	stop_repeat_play()
	live_preview_sequence.reset()
	sequence.reset()
	get_tree().paused=true
	if is_instance_valid(result_label):result_label.text="Stopped · Reset to play again"

func update_playback_buttons() -> void:
	var empty:bool=move_menu!=null and moves[move_menu.selected].kind=="sequence" and chain_data.is_empty()
	if is_instance_valid(play_button):play_button.disabled=empty
	if is_instance_valid(repeat_play_button):
		repeat_play_button.disabled=empty
		repeat_play_button.tooltip_text="Stop repeating animation chain" if repeat_playing else "Repeat animation chain"

func update_controls() -> void:
	super.update_controls()
	if is_instance_valid(slow_button):
		slow_button.text="SLOW MO"
		slow_button.tooltip_text="Return to normal speed (T)" if Engine.time_scale<1 else "Slow motion (T)"
		_set_button_accent(slow_button,Engine.time_scale<1)

func select_group(group: String) -> void:
	for tab_group in category_group_tabs:_set_button_accent(category_group_tabs[tab_group],tab_group==group)
	for section in workspace_nav_panels:
		if section=="Store" or section=="Animations" and group in ["Motion","Attack"]:continue
		workspace_nav_panels[section].hide()
	options_panel.hide()
	options_button.set_pressed_no_signal(false)
	if is_instance_valid(spell_builder):
		spell_builder.visible=group=="Spells"
		if group=="Spells":
			timeline_panel.hide()
		else:
			timeline_panel.show()
	if group=="Spells":
		stop_repeat_play()
		for fighter in field.fighters:fighter.editor_pose_locked=false
		selected_group=group
		selected_entry.clear()
		live_preview_sequence.reset()
		sequence.reset()
		super.reset_setup()
		actor.set_editor_animation_profile({},"Idle")
		spell_builder.prepare_preview_targets()
		browser.hide()
		browse_backdrop.hide()
		for tab in group_buttons:_set_button_accent(group_buttons[tab],false)
		title_label.text=""
		selection_status.text="Projectiles · Buffs · Barriers · Debuffs"
		frame_spell_preview(spell_builder.preview_subject())
		get_tree().paused=false
		return
	browse_animations()
	populate_group(group)
	title_label.text=""
	selection_status.text=""

func _unhandled_key_input(event:InputEvent) -> void:
	if selected_group=="Spells":
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and not camera_text_editing():
			return_home()
		return
	super._unhandled_key_input(event)

func camera_text_editing() -> bool:
	if is_instance_valid(category_dialog) and category_dialog.visible:return true
	return super.camera_text_editing()

func frame_spell_preview(subject:Node3D) -> void:
	# Compose once on workspace/target choice, never on parameter changes.
	var center:=subject.global_position+Vector3.UP*1.35
	var back:Vector3=(actor.global_basis.z*0.8+actor.global_basis.x*0.7+Vector3.UP*0.45).normalized()
	var right:=Vector3(back.z,0,-back.x).normalized()
	var distance:=9.0
	if is_instance_valid(practice_ally):
		center=(actor.global_position+target.global_position+practice_ally.global_position)/3.0+Vector3.UP*1.45
		distance=maxf(12.0,actor.position.distance_to(target.position)*2.2)
	var shift:Vector3=-right*distance*tan(deg_to_rad(field.camera.fov*0.5))*get_viewport().get_visible_rect().size.aspect()*0.55
	field.camera.global_position=center+back*distance+shift
	field.camera.look_at(center+shift)
	inspection_camera.capture_view(field.camera,distance)
	camera_initialized=true

func populate_group(group: String,preferred_category: String="",preserve_preview:=false) -> void:
	selected_group=group
	clear_list(category_list)
	category_buttons.clear()
	for tab in group_buttons:
		_set_button_accent(group_buttons[tab],false)
	for category in category_store.names_for(group):
		var row:=HBoxContainer.new()
		row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation",UI_EDGE_GAP)
		category_list.add_child(row)
		var custom:bool=category_store.is_custom(group,category)
		var node:=button(row,category,func():select_category(category))
		node.set_script(preload("res://scripts/animation_category_drop.gd"))
		node.set("editor",self)
		node.set("group",group)
		node.set("category",category)
		node.custom_minimum_size=Vector2(84 if custom else 120,34)
		node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		node.clip_text=true
		node.tooltip_text=category
		category_buttons[category]=node
		if custom:
			var remove:=button(row,"−",func():remove_category(group,category))
			remove.custom_minimum_size=Vector2(30,34)
			remove.tooltip_text="Delete category: "+category
	var initial:String=preferred_category if preferred_category in category_store.names_for(group) else str(Library.GROUPS[group][0])
	select_category(initial,preserve_preview)

func _build_category_dialog() -> void:
	category_dialog=ConfirmationDialog.new()
	category_dialog.title="New category"
	category_dialog.dialog_hide_on_ok=false
	category_dialog.get_ok_button().text="Add"
	add_child(category_dialog)
	var content:=VBoxContainer.new()
	category_dialog.add_child(content)
	category_name_input=LineEdit.new()
	category_name_input.placeholder_text="Category name"
	category_name_input.max_length=48
	category_name_input.custom_minimum_size=Vector2(300,38)
	content.add_child(category_name_input)
	category_error=menu_label(content,"",13)
	category_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	category_dialog.confirmed.connect(_submit_category)
	category_name_input.text_submitted.connect(func(_value:String):_submit_category())

func show_new_category() -> void:
	category_name_input.clear()
	category_error.text=""
	category_dialog.popup_centered(Vector2i(350,150))
	category_name_input.grab_focus()

func _submit_category() -> void:
	var result:Dictionary=category_store.add(selected_group,category_name_input.text)
	if not result.ok:
		category_error.text=result.error
		return
	category_dialog.hide()
	var group:=selected_group
	populate_group(group,str(result.name),true)
	category_buttons[str(result.name)].grab_focus()
	category_scroll.call_deferred("ensure_control_visible",category_buttons[str(result.name)])

func remove_category(group:String,category:String) -> void:
	if not category_store.remove(group,category):return
	var previous:=selected_category
	populate_group(group,previous if previous!=category else "",true)

func select_category(category: String,preserve_preview:=false) -> void:
	selected_category=category
	clear_list(animation_list)
	library_buttons.clear()
	library_add_buttons.clear()
	library_add_entries.clear()
	custom_buttons.clear()
	category_heading.text=category
	for name_ in category_buttons:
		_set_button_accent(category_buttons[name_],name_==category)
	var entries:Array=[]
	var personal:=store_library.entries_for(selected_group,category)
	for entry in Library.entries():
		if entry.group==selected_group and entry.category==category and not personal.any(func(owned:Dictionary):return StoreLibrary.key(owned)==StoreLibrary.key(entry)):entries.append(entry)
	for entry in load_custom_motion(category):entries.append(entry)
	entries.append_array(personal)
	var ordered:=animation_favorites.ordered(entries)
	for entry in ordered:build_animation_row(entry,entry.has("path"))
	refresh_library_add_buttons()
	if ordered.is_empty():menu_label(animation_list,"No matching animations",14)
	if not preserve_preview and not ordered.is_empty():preview_animation(ordered[0])
	call_deferred("_apply_panel_zoom","Animations")
	call_deferred("_apply_panel_zoom","Categories")

func toggle_animation_favorite(entry:Dictionary) -> void:
	animation_favorites.toggle(entry)
	if selected_group!="Spells":select_category(selected_category,true)

func set_animation_sort(index:int) -> void:
	animation_favorites.sort_mode=clampi(index,0,2)
	animation_favorites.save()
	animation_sort_menu.select(animation_favorites.sort_mode)
	if selected_group!="Spells":select_category(selected_category,true)

func animation_icon_button(row:Container,action:String,tooltip:String,callback:Callable) -> Button:
	var node:=button(row,"",callback)
	node.name=action.capitalize()
	node.icon=RowIcons.get_icon(action)
	node.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.custom_minimum_size=Vector2(32,42)
	node.tooltip_text=tooltip
	return node

func build_animation_row(entry:Dictionary,saved:bool) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",UI_EDGE_GAP)
	row.set_meta("animation_title",entry.title)
	var owned:bool=entry.has("store_asset_id")
	row.set_meta("base_animation",not saved and not owned)
	animation_list.add_child(row)
	var key:String=str(entry.path) if saved else str(entry.title)
	var title:=button(row,entry.title,func():preview_animation(entry))
	title.set_script(load("res://scripts/animation_clip_source.gd"))
	title.set("entry",entry.duplicate(true))
	title.set("editor",self)
	title.name="Preview"
	title.custom_minimum_size=Vector2(0,42)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.clip_text=true
	title.alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",13)
	title.tooltip_text=animation_info_text(entry)
	title.mouse_entered.connect(func():preview_animation(entry))
	title.focus_entered.connect(func():preview_animation(entry))
	library_buttons[key]=title
	var preview_play:=animation_icon_button(row,"play","Preview this animation on the focused unit's whole body",func():play_animation_row(entry))
	preview_play.name="PlayPreview"
	var favorite:=animation_icon_button(row,"favorited" if animation_favorites.has(entry) else "favorite","Remove from favorites" if animation_favorites.has(entry) else "Add to favorites",func():toggle_animation_favorite(entry))
	animation_icon_button(row,"rename","Rename this animation",func():open_rename_animation(entry)).name="RenameAnimation"
	if owned:animation_icon_button(row,"folder","Move to another category",func():open_take_animation_dialog(entry)).name="MoveAnimation"
	else:
		var spacer:=Button.new()
		spacer.icon=RowIcons.get_icon("folder")
		spacer.modulate=Color.TRANSPARENT
		spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
		spacer.focus_mode=Control.FOCUS_NONE
		spacer.custom_minimum_size=Vector2(32,42)
		row.add_child(spacer)
	favorite.name="Favorite"
	var clone:=animation_icon_button(row,"clone","Edit or create a new version",func():create_custom_variant(entry) if saved else open_custom_for(entry))
	clone.disabled=not entry.group in ["Motion","Attack"]
	if clone.disabled:clone.tooltip_text="The clone editor is not available for this animation yet."
	custom_buttons[key]=clone
	var remove:=animation_icon_button(row,"delete","Delete from your library" if saved or owned else "Starter animations cannot be deleted",func():delete_custom_motion(entry))
	remove.disabled=not (saved or owned)
	if saved or owned:remove.add_theme_color_override("icon_normal_color",Color("f2a19a"))

func refresh_chain_options() -> void:
	super.refresh_chain_options()
	refresh_library_add_buttons()
	update_chain_highlight()

func update_chain_highlight() -> void:
	var active_index:int=sequence.index if sequence.active else -1
	for i in chain_chips.size():
		var chip:Control=chain_chips[i]
		if chip.get_child_count()==0:continue
		var label:=chip.get_child(0) as Label
		if label==null:continue
		var title:String=str(chain_profiles[i].get("title",chain_data[i])) if i<chain_profiles.size() else chain_data[i]
		var active:=i==active_index
		label.text=("▶  " if active else "")+"%d. %s"%[i+1,title]
		label.add_theme_color_override("font_color",BOOK_GOLD if active else BOOK_INK)
		label.add_theme_font_size_override("font_size",17 if active else 15)

func refresh_library_add_buttons() -> void:
	for step in library_add_buttons:
		var add: Button=library_add_buttons[step]
		var entry:Dictionary=library_add_entries[step]
		var action_step:String=entry.step
		add.disabled=not can_append_animation(action_step)
		add.tooltip_text="Add "+str(entry.title)+" to the chain" if not add.disabled else ("Chain is full" if chain_data.size()>=MAX_CHAIN_STEPS else ("Add Jump first" if action_step in ["Flip","Twist","Land"] else "Add Land before a grounded move"))

func preview_animation(entry: Dictionary) -> void:
	if playtest.active:return
	if is_instance_valid(row_preview_unit):return
	row_preview_unit=null
	selected_entry=entry.duplicate()
	preview_heading.text=entry.title
	preview_note.text="Live arena · hover to preview"
	live_preview_sequence.reset()

func play_animation_row(entry:Dictionary) -> void:
	if playtest.active:playtest.release()
	_ensure_animation_source(entry)
	if not is_instance_valid(focused_unit):
		selection_status.text="Add and focus a unit to preview an animation"
		return
	stop_timeline()
	preview_animation(entry)
	row_preview_unit=focused_unit
	row_preview_remaining=0.25+_animation_timeline_duration(entry)
	row_preview_action_duration=maxf(0.05,_animation_timeline_duration(entry))
	row_preview_stamina_cost=float(_clip_combat_stats(entry).stamina)
	row_preview_elapsed=0.0
	row_preview_origin=focused_unit.global_position
	preview_note.text="%s · whole body preview · timeline unchanged"%focused_unit.name
	selection_status.text="Previewing %s on %s"%[entry.title,focused_unit.name]
	live_preview_sequence.reset()
	actor.editor_pose_locked=true

func _sample_row_animation(entry:Dictionary,time:float) -> void:
	var clip_name:=str(entry.get("clip",""))
	if not actor.player.has_animation(clip_name):return
	var duration:=maxf(0.05,_animation_timeline_duration(entry))
	var progress:=clampf(time/duration,0.0,0.99999)
	var source_time:=time
	if not bool(entry.get("store_raw",false)):
		var source_duration:=float(entry.get("source_duration",SourcePose.duration(actor,str(entry.step),clip_name)))
		var recipe:=SourcePose.clip_at(actor,str(entry.step),clip_name,progress,source_duration)
		clip_name=str(recipe.name)
		source_time=actor.player.get_animation(clip_name).length*float(recipe.blend)
	actor.player.pause()
	preload("res://scripts/editor_rig_pose.gd").sample(actor,clip_name,source_time)
	if bool(entry.get("mirrored",false)):preload("res://scripts/animation_mirror.gd").apply(actor)
	if entry.get("frames",[]).size()>=2:actor.apply_custom_jump_pose(progress,entry.frames,true)

func open_custom_for(entry: Dictionary) -> void:
	if playtest.active:playtest.release()
	_ensure_animation_source(entry)
	custom_provenance=AssetProvenance.source(entry)
	custom_store_source_animation=str(entry.get("source_animation",""))
	if not entry.group in ["Motion","Attack"]:
		selection_status.text="Choose a Motion or Attack animation to customize."
		return
	pose_targets.origin.clear()
	pose_targets.undo_state.clear()
	pose_targets.selected.clear()
	pose_targets.boxing=false
	custom_action_group=entry.group
	custom_action_category=entry.category
	custom_edit_path=str(entry.get("path",""))
	custom_parent_name=str(entry.get("parent_name",""))
	custom_parent_path=str(entry.get("parent_path",""))
	custom_duration=clampf(float(entry.get("duration",CUSTOM_LOOP_DURATION)),0.2,60.0)
	custom_drag_handle=""
	custom_drag_undo.clear()
	custom_record_undo.clear()
	custom_record_samples.clear()
	custom_random_snapshot.clear()
	custom_random_pending.clear()
	custom_source_mirrored=bool(entry.get("mirrored",false))
	custom_source_attack_bone=str(entry.get("attack_bone",""))
	custom_source_step=entry.step
	custom_source_clip=entry.clip
	custom_source_title=entry.get("source_title",entry.title)
	custom_source_timing=str(entry.get("source_timing","legacy" if entry.has("frames") else "native_v1"))
	custom_source_duration=float(entry.get("source_duration",custom_duration if entry.has("frames") else SourcePose.duration(actor,custom_source_step,custom_source_clip)))
	if not entry.has("frames"):custom_duration=custom_source_duration
	custom_collision_alert_time=0.0
	custom_collision_alert.hide()
	custom_frames=_default_jump_frames()
	if entry.has("frames"):custom_frames.assign(entry.frames.duplicate(true))
	for frame in custom_frames:
		for bone in DragSolver.JOINTS:
			if not frame.has(bone):frame[bone]=Vector3.ZERO
	custom_frame_count_input.set_value_no_signal(custom_frames.size())
	sync_custom_range_inputs()
	custom_name.text=entry.title if entry.has("frames") else next_custom_copy_name(custom_source_title)
	custom_heading.text="CREATE CUSTOM %s"%custom_source_title.to_upper()
	if not custom_parent_name.is_empty():custom_heading.text="VARIANT OF %s"%custom_parent_name.to_upper()
	custom_heading.tooltip_text=custom_heading.text
	custom_name.placeholder_text="Name this %s"%custom_source_step
	custom_status.text="Started from %s. Save as-is for a copy, or edit any frame."%custom_source_title
	if not custom_parent_name.is_empty():custom_status.text="Built from %s, including its edits. Save this variant with its own name."%custom_parent_name
	custom_frame_index=0
	if is_instance_valid(actor):
		actor.custom_jump_frames=[]
		actor.custom_idle_frames=[]
		actor.custom_motion_frames=[]
		super.reset_setup()
		actor.global_position.y=0.0
		actor.velocity=Vector3.ZERO
		actor.mode="idle"
		actor.clip=""
		actor.play("duel/air")
		actor.player.advance(0.0)
		actor.editor_pose_locked=true
		actor.show()
		get_tree().paused=true
	custom_preview_elapsed=0.0
	custom_preview_frame=-1
	custom_preview_playing=true
	custom_preview_repeat=true
	custom_range_active=false
	custom_range_first=0
	custom_range_last=custom_frames.size()-1
	custom_preview_reseek=true
	refresh_custom_editor()
	base_ui.hide()
	custom_editor.show()
	update_custom_transport()
	update_custom_record_tools()
	advance_custom_preview(0.0)
	frame_custom_editor_camera()
	custom_undo_history.clear()
	custom_redo_history.clear()
	custom_history_baseline=_custom_history_snapshot()

func next_custom_copy_name(source_title:String) -> String:
	var base:=source_title.get_slice(" · ",0)+" Copy"
	return next_unique_custom_name(base)

func next_unique_custom_name(base:String,reserved:="") -> String:
	var name_:=base
	var suffix:=2
	while name_==reserved or FileAccess.file_exists(CUSTOM_DIR+"/"+name_.to_lower().strip_edges().replace(" ","_").validate_filename()+".json"):
		name_=base+" "+str(suffix)
		suffix+=1
	return name_

func create_custom_variant(entry:Dictionary={}) -> void:
	if custom_recording or custom_randomizing:return
	var parent:Dictionary=entry.duplicate(true)
	if parent.is_empty():
		parent={"group":custom_action_group,"category":custom_action_category,"title":custom_name.text.strip_edges(),"step":custom_source_step,"clip":custom_source_clip,"source_title":custom_source_title,"mirrored":custom_source_mirrored,"attack_bone":custom_source_attack_bone,"source_timing":custom_source_timing,"source_duration":custom_source_duration,"duration":custom_duration,"frames":custom_frames.duplicate(true),"path":custom_edit_path}
		parent["provenance"]=custom_provenance.duplicate(true)
		if not custom_store_source_animation.is_empty():parent["source_animation"]=custom_store_source_animation
	if str(parent.get("title","")).is_empty():parent["title"]=custom_source_title
	var parent_title:String=parent.title
	var suffix:=RegEx.new()
	suffix.compile(" Variant(?: \\d+)?$")
	var stem:=suffix.sub(parent_title,"")+" Variant"
	var variant:Dictionary=parent.duplicate(true)
	variant["parent_name"]=parent_title
	variant["parent_path"]=str(parent.get("path",""))
	variant["title"]=next_unique_custom_name(stem,parent_title)
	variant["path"]=""
	open_custom_for(variant)

func frame_custom_editor_camera() -> void:
	# Compose once when opening; subsequent camera placement stays user controlled.
	var full_jump:=custom_source_step=="Jump" and custom_source_timing=="native_v1"
	var center:Vector3=actor.global_position+Vector3.UP*(2.0 if full_jump else 1.55)
	var back:Vector3=(actor.global_basis.z+actor.global_basis.x*0.28+Vector3.UP*0.25).normalized()
	var right:=Vector3(back.z,0,-back.x).normalized()
	# Keep the partner and its world-space nameplate out of the posing view.
	if is_instance_valid(target):
		target.global_position=actor.global_position-right*7.0-Vector3(back.x,0,back.z).normalized()*4.0
		target.global_position.y=0.0
		target.velocity=Vector3.ZERO
	var distance:=7.6 if full_jump else 6.3
	var aspect:float=get_viewport().get_visible_rect().size.aspect()
	var tangent:=tan(deg_to_rad(field.camera.fov*0.5))
	var shift:Vector3=-right*distance*tangent*aspect*0.61
	field.camera.global_position=center+back*distance+shift
	field.camera.look_at(center+shift)
	field.camera.h_offset=0
	field.camera.v_offset=0
	inspection_camera.capture_view(field.camera,distance)
	camera_initialized=true

func _default_jump_frames(frame_count:=6) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for _i in frame_count:
		var pose: Dictionary={}
		for bone in DragSolver.JOINTS:pose[bone]=Vector3.ZERO
		pose["pelvis_offset"]=Vector3.ZERO
		pose["hands"]=_default_hand_pose()
		result.append(pose)
	return result

func _default_land_frames(frame_count:=6) -> Array[Dictionary]:
	var result:=_default_jump_frames(frame_count)
	for i in result.size():
		var t:=float(i)/float(maxi(1,result.size()-1))
		result[i]["thigh_l"]=Vector3(lerpf(-38.0,0.0,t),0,0)
		result[i]["thigh_r"]=Vector3(lerpf(-38.0,0.0,t),0,0)
		result[i]["calf_l"]=Vector3(lerpf(62.0,0.0,t),0,0)
		result[i]["calf_r"]=Vector3(lerpf(62.0,0.0,t),0,0)
		result[i]["spine_03"]=Vector3(lerpf(20.0,0.0,t),0,0)
		result[i]["upperarm_l"]=Vector3(0,0,lerpf(-35.0,0.0,t))
		result[i]["upperarm_r"]=Vector3(0,0,lerpf(35.0,0.0,t))
	return result

func _default_hand_pose() -> Dictionary:
	var hand: Dictionary={}
	for side in ["l","r"]:
		var fingers: Dictionary={}
		for finger in HAND_FINGERS:fingers[finger]=0.0
		hand[side]=fingers
	return hand

func build_custom_editor() -> void:
	custom_editor=Control.new()
	custom_editor.theme=_book_theme()
	custom_editor.name="DetailedAnimationEditor"
	custom_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_editor.process_mode=Node.PROCESS_MODE_ALWAYS
	custom_editor.mouse_filter=Control.MOUSE_FILTER_STOP
	custom_editor.hide()
	base_ui.get_parent().add_child(custom_editor)
	var shade:=ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(0.025,0.045,0.07,0.12)
	custom_editor.add_child(shade)
	var card:=Panel.new()
	card.anchor_left=0.02
	card.anchor_right=0.60
	card.anchor_top=0.025
	card.anchor_bottom=0.975
	card.clip_contents=true
	var style:=StyleBoxFlat.new()
	style.bg_color=BOOK_PAPER
	style.border_color=BOOK_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel",style)
	custom_editor.add_child(card)
	var column:=VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left=UI_EDGE_GAP
	column.offset_right=-UI_EDGE_GAP
	column.offset_top=UI_EDGE_GAP
	column.offset_bottom=-UI_EDGE_GAP
	column.add_theme_constant_override("separation",UI_EDGE_GAP)
	card.add_child(column)
	var heading:=HBoxContainer.new()
	column.add_child(heading)
	custom_heading=menu_label(heading,"CREATE CUSTOM JUMP",21)
	custom_heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	custom_heading.clip_text=true
	custom_heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	button(heading,"Back",close_custom_editor)
	var instructions:=menu_label(column,"1  Choose a frame    →    2  Adjust the pose    →    3  Preview & save",14)
	instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var camera_help:=menu_label(column,"Camera: WASD to move · middle-drag to look · wheel to zoom",12)
	camera_help.modulate=Color(1,1,1,0.75)
	var frame_count_row:=HBoxContainer.new()
	frame_count_row.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(frame_count_row)
	menu_label(frame_count_row,"Pose frames",14)
	custom_frame_count_input=SpinBox.new()
	custom_frame_count_input.min_value=MIN_CUSTOM_FRAMES
	custom_frame_count_input.max_value=MAX_CUSTOM_FRAMES
	custom_frame_count_input.step=1
	custom_frame_count_input.value=6
	custom_frame_count_input.custom_minimum_size=Vector2(96,34)
	custom_frame_count_input.tooltip_text="How many editable poses make up this animation. Click a numbered frame below to edit that moment."
	frame_count_row.add_child(custom_frame_count_input)
	custom_frame_count_input.value_changed.connect(change_custom_frame_count)
	custom_frame_count_input.tooltip_text="Partition this animation into 2–900 editable poses."
	custom_frame_label=menu_label(frame_count_row,"Frame 1 / 6",14)
	custom_frame_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	custom_frame_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	custom_timeline_scroll=ScrollContainer.new()
	custom_timeline_scroll.custom_minimum_size.y=54
	custom_timeline_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(custom_timeline_scroll)
	custom_frame_tabs=HBoxContainer.new()
	custom_frame_tabs.add_theme_constant_override("separation",UI_EDGE_GAP)
	custom_timeline_scroll.add_child(custom_frame_tabs)
	var transport:=HBoxContainer.new()
	transport.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(transport)
	custom_play_button=button(transport,"Preview",play_custom_preview)
	custom_pause_button=button(transport,"Pause",pause_custom_preview)
	custom_repeat_button=button(transport,"Repeat: On",toggle_custom_repeat)
	var mirror_button:=button(transport,"Mirror L/R",mirror_custom_animation)
	mirror_button.tooltip_text="Reflect the whole animation, including edited poses and hand gestures, to the opposite side."
	var tools_tabs:=TabContainer.new()
	custom_tools_tabs=tools_tabs
	tools_tabs.name="EditorTools"
	tools_tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(tools_tabs)
	var pose_tab:=VBoxContainer.new()
	pose_tab.name="Pose"
	pose_tab.add_theme_constant_override("separation",UI_EDGE_GAP)
	tools_tabs.add_child(pose_tab)
	var pose_hint:=menu_label(pose_tab,"Click a numbered frame to pause there. Drag the character's rings or use the body-part sliders below.",13)
	pose_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pose_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	var advanced_toggle:=CheckButton.new()
	advanced_toggle.name="AdvancedPoseToggle"
	advanced_toggle.text="Advanced: blending & smooth transitions"
	advanced_toggle.focus_mode=Control.FOCUS_ALL
	pose_tab.add_child(advanced_toggle)
	var advanced_tools:=VBoxContainer.new()
	advanced_tools.name="AdvancedPoseTools"
	pose_tab.add_child(advanced_tools)
	advanced_tools.hide()
	advanced_toggle.toggled.connect(func(enabled:bool):advanced_tools.visible=enabled)
	var propagate_actions:=HFlowContainer.new()
	propagate_actions.add_theme_constant_override("separation",UI_EDGE_GAP)
	pose_tab.add_child(propagate_actions)
	pose_tab.move_child(propagate_actions,1)
	menu_label(propagate_actions,"Copy pose",13)
	custom_propagate_group=OptionButton.new()
	custom_propagate_group.alignment=HORIZONTAL_ALIGNMENT_CENTER
	for group in PROPAGATE_GROUPS:custom_propagate_group.add_item(group)
	custom_propagate_group.custom_minimum_size=Vector2(100,34)
	propagate_actions.add_child(custom_propagate_group)
	custom_propagate_group.item_selected.connect(func(_index:int):update_custom_frame_controls())
	button(propagate_actions,"← Previous",func():propagate_custom_frame(1.0,-1))
	custom_copy_next_button=button(propagate_actions,"Next →",func():propagate_custom_frame(1.0,1))
	button(propagate_actions,"All earlier",func():propagate_custom_direction(-1))
	button(propagate_actions,"All later",func():propagate_custom_direction(1))
	var blend_actions:=HFlowContainer.new()
	advanced_tools.add_child(blend_actions)
	button(blend_actions,"Blend to previous (50%)",func():propagate_custom_frame(0.5,-1))
	custom_blend_next_button=button(blend_actions,"Blend to next (50%)",func():propagate_custom_frame(0.5,1))
	var hand_shortcuts:=HFlowContainer.new()
	pose_tab.add_child(hand_shortcuts)
	pose_tab.move_child(hand_shortcuts,2)
	menu_label(hand_shortcuts,"Hands",13)
	for side in ["l","r"]:
		var hand_name:="Left" if side=="l" else "Right"
		button(hand_shortcuts,hand_name+" open",func():set_custom_hand_shape(side,"Straight"))
		button(hand_shortcuts,hand_name+" fist",func():set_custom_hand_shape(side,"Fist"))
	var direct_actions:=HBoxContainer.new()
	direct_actions.add_theme_constant_override("separation",UI_EDGE_GAP)
	pose_tab.add_child(direct_actions)
	custom_direct_toggle=button(direct_actions,"Drag: On",func():toggle_custom_direct_pose())
	custom_direct_toggle.tooltip_text="Drag body rings to pose. Shift-drag moves toward or away from the camera."
	custom_drag_undo_button=button(direct_actions,"Undo Drag",undo_custom_drag)
	button(direct_actions,"Redo",redo_custom_edit).tooltip_text="Redo animation edit (Ctrl+Y)"
	pose_targets.setup(self,advanced_tools)
	var controls_scroll:=ScrollContainer.new()
	controls_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	controls_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	pose_tab.add_child(controls_scroll)
	custom_controls=VBoxContainer.new()
	custom_controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	custom_controls.size_flags_vertical=Control.SIZE_EXPAND_FILL
	custom_controls.add_theme_constant_override("separation",3)
	controls_scroll.add_child(custom_controls)
	build_custom_random_tools(tools_tabs)
	var playback_tab:=VBoxContainer.new()
	playback_tab.name="Playback"
	playback_tab.add_theme_constant_override("separation",UI_EDGE_GAP)
	tools_tabs.add_child(playback_tab)
	var playback_hint:=menu_label(playback_tab,"Preview one frame or a section of the animation.",14)
	playback_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var range_row:=HBoxContainer.new()
	range_row.add_theme_constant_override("separation",6)
	playback_tab.add_child(range_row)
	menu_label(range_row,"From",13)
	custom_range_from=SpinBox.new()
	custom_range_from.min_value=1
	custom_range_from.max_value=maxi(6,custom_frames.size())
	custom_range_from.step=1
	custom_range_from.value=1
	custom_range_from.custom_minimum_size=Vector2(76,32)
	range_row.add_child(custom_range_from)
	menu_label(range_row,"To",13)
	custom_range_to=SpinBox.new()
	custom_range_to.min_value=1
	custom_range_to.max_value=maxi(6,custom_frames.size())
	custom_range_to.step=1
	custom_range_to.value=maxi(6,custom_frames.size())
	custom_range_to.custom_minimum_size=Vector2(76,32)
	range_row.add_child(custom_range_to)
	custom_range_from.value_changed.connect(func(value:float):update_custom_range_input(value,true))
	custom_range_to.value_changed.connect(func(value:float):update_custom_range_input(value,false))
	var playback_actions:=HFlowContainer.new()
	playback_tab.add_child(playback_actions)
	button(playback_actions,"Play section",play_custom_range)
	button(playback_actions,"Play selected frame",play_custom_selected)
	build_custom_record_tools(tools_tabs)
	var save_row:=HBoxContainer.new()
	save_row.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(save_row)
	custom_name=LineEdit.new()
	menu_label(save_row,"Name",14)
	custom_name.alignment=HORIZONTAL_ALIGNMENT_CENTER
	custom_name.placeholder_text="Name this Jump"
	custom_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	save_row.add_child(custom_name)
	animation_icon_button(save_row,"clone","Clone this working animation, including unsaved changes",func():create_custom_variant())
	button(save_row,"Save animation",save_custom_jump)
	custom_status=menu_label(column,"",13)
	custom_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	custom_collision_alert=menu_label(column,"",14)
	custom_collision_alert.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	custom_collision_alert.add_theme_color_override("font_color",Color("9e473d"))
	custom_collision_alert.hide()
	custom_drag_overlay=DragHandles.new()
	custom_drag_overlay.editor=self
	custom_drag_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_drag_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_editor.add_child(custom_drag_overlay)

func build_custom_record_tools(parent:TabContainer) -> void:
	var column:=VBoxContainer.new()
	column.name="Record"
	column.add_theme_constant_override("separation",UI_EDGE_GAP)
	parent.add_child(column)
	var hint:=menu_label(column,"Drag the mannequin's rings to pose it. The head ring turns and tilts the head; hips lower the body. Shift-drag changes depth.",14)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var actions:=HFlowContainer.new()
	actions.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(actions)
	custom_record_button=button(actions,"Record Movement",toggle_custom_recording)
	custom_record_cancel_button=button(actions,"Cancel Take",cancel_custom_recording)
	custom_record_undo_button=button(actions,"Undo Last Take",undo_custom_recording)
	custom_record_label=menu_label(column,"",15)
	custom_record_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var detail:=menu_label(column,"Start from the highlighted frame, record your dragging, then Stop & Build Frames. The take fills your chosen frame count with sampled joint angles, including the starting and finishing poses. A completed take replaces the timeline; Cancel or Undo Last Take restores it.",13)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	update_custom_record_tools()

func update_custom_record_tools() -> void:
	if not is_instance_valid(custom_record_button):return
	for index in custom_tools_tabs.get_tab_count():custom_tools_tabs.set_tab_disabled(index,custom_recording and index!=3)
	custom_record_button.text="Stop & Build Frames" if custom_recording else "Record Movement"
	custom_record_button.disabled=custom_randomizing
	custom_record_cancel_button.disabled=not custom_recording
	custom_record_undo_button.disabled=custom_recording or custom_record_undo.is_empty()
	custom_drag_undo_button.disabled=custom_recording or custom_randomizing or custom_undo_history.is_empty()
	custom_drag_undo_button.text="Undo"
	custom_drag_undo_button.tooltip_text="Undo animation edit (Ctrl+Z). Redo with Ctrl+Y."
	if custom_recording:
		custom_record_label.text="● RECORDING · %.1f / 30 s · drag the body rings"%custom_record_elapsed
		custom_record_label.add_theme_color_override("font_color",Color("9e473d"))
	else:
		custom_record_label.text="Ready · %d frames · %.1f s playback"%[custom_frames.size(),custom_duration]
		custom_record_label.add_theme_color_override("font_color",Color("4e7964"))

func toggle_custom_direct_pose() -> void:
	custom_direct_enabled=not custom_direct_enabled
	custom_direct_toggle.text="Drag: On" if custom_direct_enabled else "Drag: Off"
	custom_drag_hover=""

func direct_pose_handles_visible() -> bool:
	return is_instance_valid(custom_editor) and custom_editor.visible and custom_direct_enabled and not custom_randomizing and custom_tools_tabs.current_tab in [0,3]

func direct_pose_handle_points() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not is_instance_valid(actor):return result
	for definition in DragSolver.HANDLES:
		if not actor.bones.has(definition.bone):continue
		var world:Vector3=DragSolver.point(actor,definition.bone)
		if field.camera.is_position_behind(world):continue
		var screen:Vector2=field.camera.unproject_position(world)
		if screen.x<get_viewport().get_visible_rect().size.x*0.61:continue
		result.append({"bone":definition.bone,"label":definition.label,"world":world,"screen":screen})
	return result

func pick_custom_pose_handle(mouse:Vector2) -> String:
	var closest:=15.0
	var selected:=""
	for handle in direct_pose_handle_points():
		var distance:float=mouse.distance_to(handle.screen)
		if distance<closest:
			selected=handle.bone
			closest=distance
	return selected

func begin_custom_pose_drag(handle:String,mouse:Vector2,depth:=false) -> void:
	if custom_randomizing:return
	custom_preview_playing=false
	custom_range_active=false
	if not custom_recording:
		custom_drag_undo.append({"index":custom_frame_index,"pose":custom_frames[custom_frame_index].duplicate(true)})
		if custom_drag_undo.size()>MAX_DRAG_UNDO:custom_drag_undo.pop_front()
		custom_preview_elapsed=float(custom_frame_index)/float(custom_frames.size())*custom_duration
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)
	actor.skeleton.force_update_all_bone_transforms()
	custom_drag_handle=handle
	custom_drag_hover=handle
	custom_drag_start_world=DragSolver.point(actor,handle)
	custom_drag_target=custom_drag_start_world
	custom_drag_start_mouse=mouse
	custom_drag_depth=depth
	custom_drag_stalled=false
	custom_drag_foot_anchors={"l":DragSolver.point(actor,"foot_l"),"r":DragSolver.point(actor,"foot_r")}
	for side in ["l","r"]:
		custom_drag_foot_anchors["rotation_"+side]=(actor.skeleton.global_basis*actor.skeleton.get_bone_global_pose(actor.bones["foot_"+side]).basis).orthonormalized().get_rotation_quaternion()
	var normal:Vector3=field.camera.global_basis.z
	normal.y=0
	if normal.length()<0.01:normal=field.camera.global_basis.z
	custom_drag_plane=Plane(normal.normalized(),custom_drag_start_world)
	update_custom_transport()
	update_custom_record_tools()

func move_custom_pose_drag(mouse:Vector2) -> void:
	var camera:Camera3D=field.camera
	var goal:Vector3
	if custom_drag_depth:
		var depth:float=camera.global_position.distance_to(custom_drag_start_world)
		var scale_:float=2.0*depth*tan(deg_to_rad(camera.fov*0.5))/get_viewport().get_visible_rect().size.y
		goal=custom_drag_start_world+custom_drag_plane.normal*(custom_drag_start_mouse.y-mouse.y)*scale_
	else:
		var hit=custom_drag_plane.intersects_ray(camera.project_ray_origin(mouse),camera.project_ray_normal(mouse))
		if hit==null:return
		goal=hit
	custom_drag_target=goal
	custom_drag_stalled=false

func apply_custom_pose_drag(goal:Vector3) -> void:
	if custom_drag_handle.is_empty():return
	custom_drag_target=goal
	actor.skeleton.force_update_all_bone_transforms()
	var solved:Dictionary=DragSolver.solve(actor,custom_frames[custom_frame_index],custom_drag_handle,goal,custom_drag_foot_anchors)
	custom_frames[custom_frame_index]=solved.pose
	advance_custom_preview(0.0,false)
	if solved.blocked:
		custom_collision_alert.text="Body contact or joint limits reached. Try another direction."
		custom_collision_alert.show()
		custom_collision_alert_time=1.0
	custom_drag_overlay.queue_redraw()

func undo_custom_drag() -> void:
	undo_custom_edit()
	return

func _custom_history_snapshot() -> Dictionary:
	return {"frames":custom_frames.duplicate(true),"duration":custom_duration,"mirrored":custom_source_mirrored,"timing":custom_source_timing,"source_duration":custom_source_duration,"index":custom_frame_index}

func _capture_custom_history() -> void:
	if custom_history_baseline.is_empty() or custom_recording or custom_randomizing:return
	var current:=_custom_history_snapshot()
	var previous:=custom_history_baseline.duplicate(true)
	# Selecting another frame is navigation, not an animation edit.
	previous.index=current.index
	if previous==current:
		custom_history_baseline.index=current.index
		return
	custom_undo_history.append(custom_history_baseline.duplicate(true))
	if custom_undo_history.size()>100:custom_undo_history.pop_front()
	custom_redo_history.clear()
	custom_history_baseline=current
	update_custom_record_tools()

func _restore_custom_history(state:Dictionary) -> void:
	custom_preview_playing=false
	custom_drag_handle=""
	custom_frames.assign(state.frames.duplicate(true))
	custom_duration=float(state.duration)
	custom_source_mirrored=bool(state.mirrored)
	custom_source_timing=str(state.timing)
	custom_source_duration=float(state.source_duration)
	custom_frame_index=clampi(int(state.index),0,custom_frames.size()-1)
	custom_frame_count_input.set_value_no_signal(custom_frames.size())
	sync_custom_range_inputs()
	refresh_custom_editor()
	select_custom_frame(custom_frame_index)
	custom_history_baseline=_custom_history_snapshot()
	update_custom_record_tools()

func undo_custom_edit() -> void:
	if custom_recording or custom_randomizing:return
	_capture_custom_history()
	if custom_undo_history.is_empty():return
	custom_redo_history.append(_custom_history_snapshot())
	_restore_custom_history(custom_undo_history.pop_back())
	custom_status.text="Undid animation edit · Ctrl+Y to redo"

func redo_custom_edit() -> void:
	if custom_recording or custom_randomizing:return
	_capture_custom_history()
	if custom_redo_history.is_empty():return
	custom_undo_history.append(_custom_history_snapshot())
	_restore_custom_history(custom_redo_history.pop_back())
	custom_status.text="Redid animation edit · Ctrl+Z to undo"

func _legacy_undo_custom_drag() -> void:
	if custom_recording or custom_randomizing:return
	var previous:Dictionary={}
	while not custom_drag_undo.is_empty():
		var candidate:Dictionary=custom_drag_undo.pop_back()
		if candidate.index<custom_frames.size() and candidate.pose!=custom_frames[candidate.index]:
			previous=candidate
			break
	if previous.is_empty():
		update_custom_record_tools()
		return
	var index:int=previous.index
	custom_frames[index]=previous.pose.duplicate(true)
	custom_drag_handle=""
	custom_preview_playing=false
	select_custom_frame(index)
	update_custom_transport()
	update_custom_record_tools()
	custom_status.text="Undid drag on frame %d. %d earlier drag(s) available."%[index+1,custom_drag_undo.size()]

func mirror_custom_animation() -> void:
	if custom_recording or custom_randomizing or custom_frames.is_empty():return
	var elapsed:=custom_preview_elapsed
	var mirrored:Array[Dictionary]=[]
	for i in custom_frames.size():
		custom_preview_elapsed=float(i)/float(custom_frames.size())*custom_duration
		custom_preview_reseek=true
		advance_custom_preview(0.0,false)
		preload("res://scripts/animation_mirror.gd").apply(actor)
		var pose:=capture_custom_local_pose()
		var hands:Dictionary=custom_frames[i].hands
		pose.hands={"l":hands.r.duplicate(true),"r":hands.l.duplicate(true)}
		mirrored.append(pose)
	custom_source_mirrored=not custom_source_mirrored
	custom_source_attack_bone=preload("res://scripts/animation_mirror.gd").opposite(custom_source_attack_bone)
	for i in custom_frames.size():
		apply_custom_source_pose(float(i)/float(custom_frames.size()))
		var pose:Dictionary={"hands":mirrored[i].hands}
		for bone in DragSolver.JOINTS:
			var base:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.bones[bone])
			pose[bone]=(base.inverse()*(mirrored[i].rotations[bone] as Quaternion)).get_euler()*180.0/PI
		pose["pelvis_offset"]=(mirrored[i].pelvis as Vector3)-actor.skeleton.get_bone_pose_position(actor.bones.pelvis)
		custom_frames[i]=pose
	custom_record_undo.clear()
	custom_drag_undo.clear()
	custom_random_snapshot.clear()
	custom_random_pending.clear()
	custom_drag_handle=""
	custom_preview_elapsed=elapsed
	custom_preview_reseek=true
	refresh_custom_editor()
	advance_custom_preview(0.0,false)
	custom_status.text="Mirrored every frame and swapped left/right hand gestures. Mirror again to reverse."

func capture_custom_local_pose() -> Dictionary:
	var pose:Dictionary={"rotations":{},"hands":custom_frames[custom_frame_index]["hands"].duplicate(true)}
	for bone in DragSolver.JOINTS:pose.rotations[bone]=actor.skeleton.get_bone_pose_rotation(actor.bones[bone])
	pose.pelvis=actor.skeleton.get_bone_pose_position(actor.bones["pelvis"])
	return pose

func toggle_custom_recording() -> void:
	if custom_recording:
		finish_custom_recording()
		return
	if custom_randomizing or custom_frames.is_empty():return
	custom_record_undo={"frames":custom_frames.duplicate(true),"duration":custom_duration,"elapsed":custom_preview_elapsed,"repeat":custom_preview_repeat,"random_snapshot":custom_random_snapshot.duplicate(true),"random_pending":custom_random_pending.duplicate(true),"drag_undo":custom_drag_undo.duplicate(true)}
	custom_preview_playing=false
	custom_range_active=false
	custom_preview_elapsed=float(custom_frame_index)/float(custom_frames.size())*custom_duration
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)
	custom_recording=true
	custom_direct_enabled=true
	custom_direct_toggle.text="Drag: On"
	custom_tools_tabs.current_tab=3
	custom_record_elapsed=0
	custom_record_sample_clock=0
	custom_record_samples=[{"time":0.0,"pose":capture_custom_local_pose()}]
	set_custom_editing_enabled(false)
	custom_record_button.disabled=false
	custom_record_cancel_button.disabled=false
	update_custom_transport()
	update_custom_record_tools()
	custom_status.text="Recording your movement. Drag a ring, then Stop & Build Frames."

func tick_custom_recording(delta:float) -> void:
	custom_record_elapsed+=delta
	custom_record_sample_clock+=delta
	if custom_record_sample_clock>=1.0/30.0:
		custom_record_samples.append({"time":custom_record_elapsed,"pose":capture_custom_local_pose()})
		custom_record_sample_clock=0
	update_custom_record_tools()
	if custom_record_elapsed>=30.0:finish_custom_recording()

func sample_custom_recording(time_:float) -> Dictionary:
	var first:Dictionary=custom_record_samples[0]
	var second:Dictionary=custom_record_samples.back()
	for i in range(1,custom_record_samples.size()):
		second=custom_record_samples[i]
		if float(second.time)>=time_:break
		first=second
	var weight:=clampf((time_-float(first.time))/maxf(0.00001,float(second.time)-float(first.time)),0,1)
	var pose:Dictionary={"rotations":{},"pelvis":(first.pose.pelvis as Vector3).lerp(second.pose.pelvis,weight),"hands":_blend_hand_pose(first.pose.hands,second.pose.hands,weight)}
	for bone in DragSolver.JOINTS:pose.rotations[bone]=(first.pose.rotations[bone] as Quaternion).slerp(second.pose.rotations[bone],weight)
	return pose

func finish_custom_recording() -> void:
	if not custom_recording:return
	custom_record_samples.append({"time":custom_record_elapsed,"pose":capture_custom_local_pose()})
	custom_recording=false
	custom_drag_handle=""
	var count:=custom_frames.size()
	var captured:=maxf(0.1,custom_record_elapsed)
	# N samples span N-1 intervals, followed by one frame of endpoint hold.
	custom_duration=maxf(0.2,captured*float(count)/float(count-1))
	custom_frames=_default_jump_frames(count)
	var recovered:Array[Dictionary]=[]
	for i in count:
		var local:=sample_custom_recording(float(i)/float(count-1)*captured)
		custom_preview_elapsed=float(i)/float(count)*custom_duration
		custom_preview_reseek=true
		advance_custom_preview(0.0,false)
		var pose:Dictionary={"hands":local.hands.duplicate(true)}
		for bone in DragSolver.JOINTS:
			var base:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.bones[bone])
			pose[bone]=(base.inverse()*(local.rotations[bone] as Quaternion)).get_euler()*180.0/PI
		pose["pelvis_offset"]=(local.pelvis as Vector3)-actor.skeleton.get_bone_pose_position(actor.bones["pelvis"])
		recovered.append(pose)
	custom_frames=recovered
	custom_preview_elapsed=0
	custom_preview_reseek=true
	custom_preview_playing=false
	custom_preview_repeat=false
	custom_random_snapshot.clear()
	custom_random_pending.clear()
	custom_drag_undo.clear()
	set_custom_editing_enabled(true)
	refresh_custom_editor()
	advance_custom_preview(0.0,false)
	update_custom_transport()
	update_custom_record_tools()
	custom_status.text="Recovered %d frames from %.1f seconds of movement. Play to review; Undo Last Take restores your old animation."%[count,captured]

func cancel_custom_recording() -> void:
	if not custom_recording:return
	custom_recording=false
	set_custom_editing_enabled(true)
	undo_custom_recording()

func undo_custom_recording() -> void:
	if custom_recording or custom_record_undo.is_empty():return
	custom_frames.assign(custom_record_undo.frames.duplicate(true))
	custom_duration=custom_record_undo.duration
	custom_preview_elapsed=custom_record_undo.elapsed
	custom_preview_repeat=custom_record_undo.repeat
	custom_preview_playing=false
	custom_preview_reseek=true
	custom_drag_handle=""
	custom_random_snapshot.assign(custom_record_undo.random_snapshot.duplicate(true))
	custom_random_pending=custom_record_undo.random_pending.duplicate(true)
	custom_drag_undo=custom_record_undo.drag_undo.duplicate(true)
	custom_frame_count_input.set_value_no_signal(custom_frames.size())
	custom_record_undo.clear()
	custom_record_samples.clear()
	sync_custom_range_inputs()
	refresh_custom_editor()
	advance_custom_preview(0.0,false)
	update_custom_transport()
	update_custom_record_tools()
	custom_status.text="Restored the animation from before the take."

func build_custom_random_tools(parent:TabContainer) -> void:
	for joint in JUMP_JOINTS:
		custom_random_parts[joint.bone]=true
		custom_random_part_labels[joint.bone]="Head" if joint.bone=="Head" else str(joint.label).replace(" raise","").replace(" bend","").replace(" swing","").replace(" lean","")
	for finger in HAND_FINGERS:
		for side in ["l","r"]:
			var key: String="hand_%s:%s"%[side,finger]
			custom_random_parts[key]=true
			custom_random_part_labels[key]=("Left " if side=="l" else "Right ")+finger
	var column:=VBoxContainer.new()
	column.name="Randomize"
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",6)
	parent.add_child(column)
	var hint:=menu_label(column,"Checked parts change; unchecked parts keep their pose.",13)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	custom_random_selection_label=menu_label(column,"All body parts selected",13)
	custom_random_selection_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	custom_random_selection_label.add_theme_color_override("font_color",BOOK_GOLD)
	var presets:=HFlowContainer.new()
	column.add_child(presets)
	for group in ["All","None","Arms","Legs","Torso","Hands","Head"]:
		var preset:=button(presets,group,func():select_custom_random_group(group))
		preset.custom_minimum_size=Vector2(64,32)
	var targets:=TabContainer.new()
	targets.name="RandomTargets"
	targets.custom_minimum_size.y=110
	targets.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(targets)
	for group in ["Arms","Legs","Torso","Hands","Head"]:
		var group_scroll:=ScrollContainer.new()
		group_scroll.name=group
		group_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		targets.add_child(group_scroll)
		var grid:=GridContainer.new()
		grid.columns=2
		grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation",16)
		grid.add_theme_constant_override("v_separation",6)
		group_scroll.add_child(grid)
		for key in custom_random_parts:
			if custom_random_part_group(key)!=group:continue
			var part_key:String=key
			var check:=Button.new()
			check.toggle_mode=true
			check.alignment=HORIZONTAL_ALIGNMENT_LEFT
			check.text="✓ "+str(custom_random_part_labels[key])
			check.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			check.custom_minimum_size.y=32
			var normal:=StyleBoxFlat.new()
			normal.bg_color=Color("f0e8d5")
			normal.border_color=BOOK_BORDER
			normal.set_border_width_all(1)
			normal.set_corner_radius_all(5)
			normal.content_margin_left=UI_EDGE_GAP
			normal.content_margin_right=UI_EDGE_GAP
			var pressed:StyleBoxFlat=normal.duplicate()
			pressed.bg_color=Color("d8c7a4")
			pressed.border_color=BOOK_GOLD
			pressed.set_border_width_all(1)
			check.add_theme_stylebox_override("normal",normal)
			check.add_theme_stylebox_override("pressed",pressed)
			check.add_theme_stylebox_override("hover_pressed",pressed)
			check.add_theme_color_override("font_pressed_color",BOOK_INK)
			check.set_pressed_no_signal(true)
			check.toggled.connect(func(selected:bool):set_custom_random_part(part_key,selected))
			grid.add_child(check)
			custom_random_checkboxes[key]=check
	var generate:=HFlowContainer.new()
	generate.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(generate)
	custom_random_frame_button=button(generate,"Randomize Frame",randomize_custom_frame)
	custom_random_all_button=button(generate,"Randomize All Frames",randomize_all_custom_frames)
	column.add_child(HSeparator.new())
	var restore_hint:=menu_label(column,"Restore checked parts from before your last randomization.",12)
	restore_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var restore:=HFlowContainer.new()
	restore.add_theme_constant_override("separation",UI_EDGE_GAP)
	column.add_child(restore)
	custom_restore_scope=OptionButton.new()
	custom_restore_scope.alignment=HORIZONTAL_ALIGNMENT_CENTER
	custom_restore_scope.add_item("Current frame")
	custom_restore_scope.add_item("All affected frames")
	custom_restore_scope.custom_minimum_size=Vector2(150,34)
	restore.add_child(custom_restore_scope)
	custom_restore_scope.item_selected.connect(func(_index:int):update_custom_random_tools())
	custom_restore_selected_button=button(restore,"Restore Selected Parts",func():restore_custom_randomization(false))
	custom_undo_random_button=button(restore,"Undo Last Randomize",func():restore_custom_randomization(true))
	custom_undo_random_button.tooltip_text="Restore every remaining part changed by the last randomization."
	update_custom_random_tools()

func custom_random_part_group(key:String) -> String:
	if key=="Head":return "Head"
	if key.begins_with("hand_"):return "Hands"
	if key.begins_with("upperarm") or key.begins_with("lowerarm"):return "Arms"
	if key.begins_with("thigh") or key.begins_with("calf"):return "Legs"
	return "Torso"

func set_custom_random_part(key:String,selected:bool) -> void:
	if custom_randomizing:return
	custom_random_parts[key]=selected
	update_custom_random_tools()

func select_custom_random_group(group:String) -> void:
	if custom_randomizing:return
	for key in custom_random_parts:
		custom_random_parts[key]=group=="All" or custom_random_part_group(key)==group
		(custom_random_checkboxes[key] as Button).set_pressed_no_signal(custom_random_parts[key])
	update_custom_random_tools()

func selected_custom_random_parts() -> Array[String]:
	var selected:Array[String]=[]
	for key in custom_random_parts:
		if custom_random_parts[key]:selected.append(key)
	return selected

func update_custom_random_tools() -> void:
	if not is_instance_valid(custom_random_selection_label):return
	var selected:=selected_custom_random_parts()
	for key in custom_random_checkboxes:
		var check:Button=custom_random_checkboxes[key]
		var checked:bool=custom_random_parts[key]
		check.set_pressed_no_signal(checked)
		check.text=("✓ " if checked else "○ ")+str(custom_random_part_labels[key])
	if selected.is_empty():custom_random_selection_label.text="Select at least one body part."
	elif selected.size()==custom_random_parts.size():custom_random_selection_label.text="All body parts selected"
	elif selected.size()<=3:
		var labels:PackedStringArray=[]
		for key in selected:labels.append(custom_random_part_labels[key])
		custom_random_selection_label.text="Selected: "+", ".join(labels)
	else:custom_random_selection_label.text="%d body controls selected"%selected.size()
	custom_random_frame_button.disabled=custom_recording or custom_randomizing or selected.is_empty()
	custom_random_all_button.disabled=custom_recording or custom_randomizing or selected.is_empty()
	var can_restore:=false
	if is_instance_valid(custom_restore_scope):
		for index in custom_random_pending:
			if custom_restore_scope.selected==0 and index!=custom_frame_index:continue
			for key in selected:
				if custom_random_pending[index].has(key):can_restore=true
	custom_restore_selected_button.disabled=custom_recording or custom_randomizing or not can_restore
	custom_undo_random_button.disabled=custom_recording or custom_randomizing or custom_random_pending.is_empty()

func refresh_custom_editor() -> void:
	if not is_instance_valid(custom_frame_tabs):return
	rebuild_custom_source_frames()
	custom_displayed_frame_index=-1
	clear_list(custom_frame_tabs)
	for i in custom_frames.size():
		var index:=i
		var tab:=button(custom_frame_tabs,str(i+1),func():select_custom_frame(index))
		tab.custom_minimum_size=Vector2(42,36)
		tab.tooltip_text="Select frame %d"%(i+1)
		_set_button_accent(tab,i==custom_frame_index)
	clear_list(custom_controls)
	custom_pose_controls.clear()
	var body_tabs:=TabContainer.new()
	body_tabs.name="BodyPose"
	body_tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	custom_controls.add_child(body_tabs)
	var groups:Dictionary={}
	for group in ["Arms","Legs","Torso","Hands","Head"]:
		var group_column:=VBoxContainer.new()
		group_column.name=group
		group_column.add_theme_constant_override("separation",UI_EDGE_GAP)
		body_tabs.add_child(group_column)
		groups[group]=group_column
	for joint in JUMP_JOINTS:
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",UI_EDGE_GAP)
		groups[custom_random_part_group(joint.bone)].add_child(row)
		var label:=menu_label(row,joint.label,14)
		label.custom_minimum_size=Vector2(120,0)
		label.add_theme_font_size_override("font_size",13)
		var slider:=HSlider.new()
		slider.min_value=joint.min
		slider.max_value=joint.max
		slider.step=1
		slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var value: float=custom_pose_angles(custom_frame_index,joint.bone)[joint.axis]
		slider.min_value=minf(slider.min_value,value)
		slider.max_value=maxf(slider.max_value,value)
		slider.value=value
		row.add_child(slider)
		var readout:=menu_label(row,str(int(value))+"°",13)
		readout.custom_minimum_size=Vector2(30,0)
		var bone: String=joint.bone
		var axis: int=joint.axis
		slider.value_changed.connect(func(v: float):set_custom_pose_angle(bone,axis,v))
		custom_pose_controls.append({"slider":slider,"label":readout,"bone":bone,"axis":axis,"min":joint.min,"max":joint.max})
	build_custom_hand_controls(groups["Hands"])
	body_tabs.current_tab=custom_body_tab_index
	body_tabs.tab_changed.connect(func(index:int):custom_body_tab_index=index)
	update_custom_frame_controls()

func build_custom_hand_controls(parent:Control) -> void:
	custom_hand_controls.clear()
	var hand_tabs:=TabContainer.new()
	hand_tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	parent.add_child(hand_tabs)
	for side in ["l","r"]:
		var scroll:=ScrollContainer.new()
		scroll.name="Left hand" if side=="l" else "Right hand"
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		hand_tabs.add_child(scroll)
		var column:=VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",UI_EDGE_GAP)
		scroll.add_child(column)
		var poses:=HFlowContainer.new()
		column.add_child(poses)
		var pose_group:=ButtonGroup.new()
		for pose in ["Original","Fist","Straight","Palm up"]:
			var choice:=CheckBox.new()
			choice.text=pose
			choice.button_group=pose_group
			choice.add_theme_font_size_override("font_size",13)
			poses.add_child(choice)
			choice.pressed.connect(func():set_custom_hand_shape(side,pose))
			custom_hand_controls.append({"kind":"shape","side":side,"shape":pose,"control":choice})
		for finger in HAND_FINGERS:
			var row:=HBoxContainer.new()
			column.add_child(row)
			var label:=menu_label(row,finger.capitalize(),13)
			label.custom_minimum_size.x=85
			var group:=ButtonGroup.new()
			for state in ["Up","Down"]:
				var choice:=CheckBox.new()
				choice.text=state
				choice.button_group=group
				choice.add_theme_font_size_override("font_size",13)
				row.add_child(choice)
				choice.pressed.connect(func():set_custom_finger(side,finger,0.0 if state=="Up" else 100.0))
				custom_hand_controls.append({"kind":"finger","side":side,"finger":finger,"state":state,"control":choice})

func update_custom_frame_controls() -> void:
	if not is_instance_valid(custom_frame_tabs):return
	custom_frame_label.text="Frame %d / %d"%[custom_frame_index+1,custom_frames.size()]
	if custom_displayed_frame_index!=custom_frame_index and custom_frame_index<custom_frame_tabs.get_child_count():
		custom_timeline_scroll.ensure_control_visible(custom_frame_tabs.get_child(custom_frame_index))
		custom_displayed_frame_index=custom_frame_index
	update_custom_random_tools()
	update_custom_record_tools()
	if is_instance_valid(custom_copy_next_button):
		var group:String=PROPAGATE_GROUPS[custom_propagate_group.selected]
		custom_copy_next_button.text="Next →"
		custom_copy_next_button.tooltip_text="Copy %s to the next frame"%group.to_lower()
		custom_blend_next_button.text="Blend to Next (50%)" if group=="All" else "Blend %s (50%%)"%group
		var at_last:=custom_frame_index>=custom_frames.size()-1
		custom_copy_next_button.disabled=at_last or custom_randomizing or custom_recording
		custom_blend_next_button.disabled=at_last or custom_randomizing or custom_recording
		custom_copy_next_button.tooltip_text="Copy %s to the next frame and select it. Pauses playback."%group.to_lower() if not at_last else "Last frame reached. Select an earlier frame to propagate again."
		custom_blend_next_button.tooltip_text="Blend %s halfway into the next frame's existing pose, then select it."%group.to_lower()
	for i in custom_frame_tabs.get_child_count():
		_set_button_accent(custom_frame_tabs.get_child(i) as Button,i==custom_frame_index)
	for control in custom_pose_controls:
		var value: float=custom_pose_angles(custom_frame_index,control.bone)[control.axis]
		var slider:HSlider=control.slider
		slider.set_block_signals(true)
		slider.min_value=minf(float(control.get("min",slider.min_value)),value)
		slider.max_value=maxf(float(control.get("max",slider.max_value)),value)
		slider.set_value_no_signal(value)
		slider.set_block_signals(false)
		(control.label as Label).text=str(int(value))+"°"
		var angles:Vector3=custom_pose_angles(custom_frame_index,control.bone)
		(control.label as Label).tooltip_text="3D angles: X %.1f°, Y %.1f°, Z %.1f°"%[angles.x,angles.y,angles.z]
	for control in custom_hand_controls:
		var hand:Dictionary=custom_frames[custom_frame_index].hands[control.side]
		var selected:=false
		if control.kind=="shape":
			var shape:="Original"
			for finger in HAND_FINGERS:
				if preload("res://scripts/hand_pose.gd").absolute_strength(hand,finger)>0.5:shape="Custom"
			if float(hand.get("absolute",0))>0.5:
				shape="Fist" if hand_gesture_index(hand)==2 else "Straight"
				if float(hand.get("palm_up",0))>0.5:shape="Palm up"
			selected=control.shape==shape
		else:
			var value:float=float(hand.get(control.finger,0))
			selected=(value<50 if control.state=="Up" else value>=50) and preload("res://scripts/hand_pose.gd").absolute_strength(hand,control.finger)>0.5
		(control.control as CheckBox).set_pressed_no_signal(selected)

func hand_gesture_index(hand: Dictionary) -> int:
	var shapes: Array[Dictionary]=[
		{},
		{"thumb":0,"index":0,"middle":0,"ring":0,"pinky":0},
		{"thumb":100,"index":100,"middle":100,"ring":100,"pinky":100},
		{"thumb":55,"index":0,"middle":100,"ring":100,"pinky":100},
		{"thumb":55,"index":0,"middle":0,"ring":100,"pinky":100},
		{"thumb":100,"index":100,"middle":0,"ring":100,"pinky":100},
		{"thumb":100,"index":0,"middle":100,"ring":0,"pinky":100},
		{"thumb":100,"index":100,"middle":100,"ring":100,"pinky":0},
		{"thumb":0,"index":100,"middle":100,"ring":100,"pinky":100}
	]
	for i in range(1,shapes.size()):
		var matches:=true
		for finger in HAND_FINGERS:
			if absf(float(hand.get(finger,0.0))-float(shapes[i].get(finger,0)))>0.1:
				matches=false
				break
		if matches:return i
	return 0

func hand_gesture_pose(index:int) -> Dictionary:
	var pose: Dictionary={"thumb":100.0,"index":100.0,"middle":100.0,"ring":100.0,"pinky":100.0}
	match index:
		1:pose={"thumb":0.0,"index":0.0,"middle":0.0,"ring":0.0,"pinky":0.0}
		2:pass
		3:
			pose["thumb"]=55.0
			pose["index"]=0.0
		4:
			pose["thumb"]=55.0
			pose["index"]=0.0
			pose["middle"]=0.0
		5:pose["middle"]=0.0
		6:
			pose["index"]=0.0
			pose["ring"]=0.0
		7:pose["pinky"]=0.0
		8:pose["thumb"]=0.0
	return pose

func set_custom_hand_shape(side:String,shape:String) -> void:
	if custom_recording or custom_randomizing or custom_frames.is_empty():return
	var hand:=hand_gesture_pose(2 if shape=="Fist" else 1)
	hand["absolute"]=0.0 if shape=="Original" else 1.0
	hand["straight"]=0.0 if shape=="Original" else 1.0
	hand["palm_up"]=1.0 if shape=="Palm up" else 0.0
	custom_frames[custom_frame_index].hands[side]=hand
	update_custom_frame_controls()
	advance_custom_preview(0.0,false)

func apply_hand_gesture(side:String,index:int) -> void:
	if custom_frames.is_empty() or index==0:return
	var hand:=hand_gesture_pose(index)
	hand["absolute"]=1.0
	hand["straight"]=1.0
	custom_frames[custom_frame_index].hands[side]=hand
	update_custom_frame_controls()
	advance_custom_preview(0.0,false)

func set_custom_finger(side:String,finger:String,value:float,readout:Label=null) -> void:
	if custom_recording or custom_randomizing or custom_frames.is_empty():return
	custom_frames[custom_frame_index].hands[side][finger]=value
	custom_frames[custom_frame_index].hands[side]["absolute_"+finger]=1.0
	if readout!=null:readout.text=str(int(value))
	update_custom_frame_controls()
	advance_custom_preview(0.0,false)

func select_custom_frame(index: int) -> void:
	custom_range_active=false
	custom_preview_elapsed=float(index)/float(custom_frames.size())*custom_duration
	custom_preview_reseek=true
	advance_custom_preview(0.0)

func update_custom_range_input(value:float,changed_from:bool) -> void:
	var selected:=clampi(roundi(value),0,custom_frames.size()-1)
	if changed_from:
		if selected>int(custom_range_to.value)-1:
			custom_range_to.set_value_no_signal(selected+1)
	else:
		if selected<int(custom_range_from.value)-1:
			custom_range_from.set_value_no_signal(selected+1)

func sync_custom_range_inputs() -> void:
	if not is_instance_valid(custom_range_from) or not is_instance_valid(custom_range_to):return
	custom_range_from.max_value=custom_frames.size()
	custom_range_to.max_value=custom_frames.size()
	custom_range_from.set_value_no_signal(clampi(int(custom_range_from.value),1,custom_frames.size()))
	custom_range_to.set_value_no_signal(clampi(int(custom_range_to.value),1,custom_frames.size()))
	if custom_range_from.value>custom_range_to.value:
		custom_range_to.set_value_no_signal(custom_range_from.value)

func play_custom_range() -> void:
	play_custom_section(int(custom_range_from.value)-1,int(custom_range_to.value)-1)

func play_custom_selected() -> void:
	play_custom_section(custom_frame_index,custom_frame_index)

func play_custom_section(first:int,last:int) -> void:
	custom_range_first=clampi(first,0,custom_frames.size()-1)
	custom_range_last=clampi(last,custom_range_first,custom_frames.size()-1)
	custom_range_active=true
	custom_preview_elapsed=float(custom_range_first)/float(custom_frames.size())*custom_duration
	custom_preview_reseek=true
	custom_preview_playing=true
	sync_custom_range_inputs()
	update_custom_transport()
	advance_custom_preview(0.0)

func change_custom_frame_count(value: float) -> void:
	var new_count:=clampi(roundi(value),MIN_CUSTOM_FRAMES,MAX_CUSTOM_FRAMES)
	if new_count==custom_frames.size():return
	custom_frame_count_input.set_value_no_signal(new_count)
	custom_random_snapshot.clear()
	custom_random_pending.clear()
	custom_drag_undo.clear()
	var old_frames:=custom_frames.duplicate(true)
	var old_count:=old_frames.size()
	var resized: Array[Dictionary]=[]
	for i in new_count:
		var source_position:=float(i)*float(old_count)/float(new_count)
		var first:=int(floor(source_position))
		var second: int=(first+1)%old_count
		var blend:=source_position-float(first)
		var pose: Dictionary={}
		for bone in DragSolver.JOINTS:
			pose[bone]=blend_custom_angles(old_frames[first][bone],old_frames[second][bone],blend)
		pose["hands"]=_blend_hand_pose(old_frames[first].get("hands",_default_hand_pose()),old_frames[second].get("hands",_default_hand_pose()),blend)
		pose["pelvis_offset"]=(old_frames[first].get("pelvis_offset",Vector3.ZERO) as Vector3).lerp(old_frames[second].get("pelvis_offset",Vector3.ZERO),blend)
		resized.append(pose)
	custom_frames=resized
	custom_frame_index=mini(custom_frame_index,new_count-1)
	custom_range_first=mini(custom_range_first,new_count-1)
	custom_range_last=mini(custom_range_last,new_count-1)
	sync_custom_range_inputs()
	custom_preview_reseek=true
	custom_status.text="Adjusted to %d pose sections; existing poses were resampled across the full %s."%[new_count,custom_action_category.to_lower()]
	refresh_custom_editor()
	advance_custom_preview(0.0)

func blend_custom_angles(a:Vector3,b:Vector3,weight:float) -> Vector3:
	if weight<=0.0:return a
	if weight>=1.0:return b
	return Quaternion.from_euler(a*PI/180.0).slerp(Quaternion.from_euler(b*PI/180.0),weight).get_euler()*180.0/PI

func _blend_hand_pose(a:Dictionary,b:Dictionary,weight:float) -> Dictionary:
	return preload("res://scripts/hand_pose.gd").blend(a,b,weight)

func rebuild_custom_source_frames() -> void:
	custom_source_frames.clear()
	for i in custom_frames.size():
		apply_custom_source_pose(float(i)/float(custom_frames.size()))
		var sample:Dictionary={"rotations":{},"pelvis_position":actor.skeleton.get_bone_pose_position(actor.bones["pelvis"]),"pelvis_rotation":actor.skeleton.get_bone_pose_rotation(actor.bones["pelvis"])}
		for bone in DragSolver.JOINTS:sample.rotations[bone]=actor.skeleton.get_bone_pose_rotation(actor.bones[bone])
		custom_source_frames.append(sample)

func custom_pose_angles(frame_index:int,bone:String) -> Vector3:
	var rest:Quaternion=actor.skeleton.get_bone_rest(actor.bones[bone]).basis.get_rotation_quaternion()
	var base:Quaternion=rest
	if frame_index<custom_source_frames.size():base=custom_source_frames[frame_index].rotations[bone]
	var offset:Vector3=custom_frames[frame_index].get(bone,Vector3.ZERO)
	if bone=="Head":return DragSolver.head_pose_angles(actor,base*Quaternion.from_euler(offset*PI/180.0))
	return (rest.inverse()*base*Quaternion.from_euler(offset*PI/180.0)).get_euler()*180.0/PI

func set_custom_pose_angle(bone:String,axis:int,value:float,notify_collision:=true) -> void:
	if custom_recording or (custom_randomizing and notify_collision):return
	var frame_index:=custom_frame_index
	var original:Vector3=custom_frames[frame_index][bone]
	var current:=Quaternion.from_euler(original*PI/180.0)
	var desired_angles:=custom_pose_angles(frame_index,bone)
	desired_angles[axis]=value
	var rest:Quaternion=actor.skeleton.get_bone_rest(actor.bones[bone]).basis.get_rotation_quaternion()
	var base:Quaternion=custom_source_frames[frame_index].rotations[bone]
	var desired:Quaternion=base.inverse()*rest*Quaternion.from_euler(desired_angles*PI/180.0)
	if bone=="Head":desired=base.inverse()*DragSolver.limit_head_rotation(actor,base*current,DragSolver.head_rotation_from_angles(actor,desired_angles))
	var steps:=maxi(1,ceili(current.angle_to(desired)/deg_to_rad(2.0)))
	var elapsed:=custom_preview_elapsed
	var baseline:=custom_frame_penetrations(frame_index)
	var accepted:=original
	var blocked:=false
	for i in range(1,steps+1):
		var candidate:=current.slerp(desired,float(i)/float(steps)).get_euler()*180.0/PI
		custom_frames[frame_index][bone]=candidate
		var contact:=custom_frame_penetrations(frame_index)
		for pair in contact:
			if float(contact[pair])>maxf(0.005,float(baseline.get(pair,0))+0.00001):
				blocked=true
				break
		if blocked:break
		accepted=candidate
		baseline=contact
	custom_frames[frame_index][bone]=accepted
	custom_preview_elapsed=elapsed
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)
	if blocked and notify_collision:
		custom_collision_alert.text="Can't put body parts clipping through others. Move the limb another way."
		custom_collision_alert.show()
		custom_collision_alert_time=3.0

func set_custom_joint(bone: String,axis: int,value: float,readout: Label=null,notify_collision:=true) -> void:
	if custom_frames.is_empty():return
	var frame_index:=custom_frame_index
	var original:Vector3=custom_frames[frame_index][bone]
	var accepted:=original[axis]
	var elapsed:=custom_preview_elapsed
	var baseline:=custom_frame_penetrations(frame_index)
	var steps:=maxi(1,ceili(absf(value-accepted)/2.0))
	var blocked:=false
	for step in range(1,steps+1):
		var candidate:=original
		candidate[axis]=lerpf(original[axis],value,float(step)/float(steps))
		custom_frames[frame_index][bone]=candidate
		var collisions:=custom_frame_penetrations(frame_index)
		for pair in collisions:
			# Existing contact in the source clip can move apart, but not deepen.
			if float(collisions[pair])>maxf(0.005,float(baseline.get(pair,0.0))+0.00001):
				blocked=true
				break
		if blocked:break
		accepted=candidate[axis]
		baseline=collisions
	var final_pose:=original
	final_pose[axis]=accepted
	custom_frames[frame_index][bone]=final_pose
	custom_preview_elapsed=elapsed
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)
	if is_instance_valid(readout):readout.text=str(int(accepted))+"°"
	if blocked and notify_collision:
		custom_collision_alert.text="Can't put body parts clipping through others. Move the limb another way."
		custom_collision_alert.show()
		custom_collision_alert_time=3.0

func custom_frame_penetrations(frame_index:int) -> Dictionary:
	if not is_instance_valid(actor) or actor.skeleton==null:return {}
	custom_preview_elapsed=float(frame_index)/float(custom_frames.size())*custom_duration
	custom_preview_reseek=true
	custom_collision_probe_active=true
	advance_custom_preview(0.0,false)
	actor.skeleton.force_update_all_bone_transforms()
	var result:=PoseSelfCollision.penetrations(actor.skeleton)
	custom_collision_probe_active=false
	return result

func custom_propagation_bone_group(bone:String) -> String:
	if bone=="Head":return "Head"
	if bone.begins_with("upperarm") or bone.begins_with("lowerarm"):return "Arms"
	if bone.begins_with("thigh") or bone.begins_with("calf") or bone.begins_with("foot"):return "Legs"
	return "Torso"

func propagate_custom_direction(direction:int) -> void:
	if custom_recording or custom_randomizing or custom_frames.is_empty():return
	_capture_custom_history()
	var source:=custom_frame_index
	var targets:=range(source-1,-1,-1) if direction<0 else range(source+1,custom_frames.size())
	for target_index in targets:
		select_custom_frame(source)
		propagate_custom_frame(1.0,target_index-source)
	select_custom_frame(source)
	_capture_custom_history()
	custom_status.text="Copied selected body parts to %s frames. Body-contact checks still apply."%["earlier" if direction<0 else "later"]

func propagate_custom_frame(weight:=1.0,direction:=1) -> void:
	if custom_recording or custom_randomizing or custom_frames.is_empty():return
	var group:String=PROPAGATE_GROUPS[custom_propagate_group.selected]
	var source_index:=custom_frame_index
	var target_index:=source_index+direction
	if target_index<0 or target_index>=custom_frames.size():
		custom_status.text="No frame in that direction. Choose another numbered frame."
		return
	var elapsed:=custom_preview_elapsed
	var original:Dictionary=custom_frames[target_index].duplicate(true)
	var source:Dictionary=custom_frames[source_index].duplicate(true)
	var candidate:Dictionary=original.duplicate(true)
	for bone in DragSolver.JOINTS:
		if group!="All" and custom_propagation_bone_group(bone)!=group:continue
		if custom_source_timing=="native_v1":
			var source_base:Quaternion=custom_source_frames[source_index].rotations[bone]
			var target_base:Quaternion=custom_source_frames[target_index].rotations[bone]
			var from:Quaternion=target_base*Quaternion.from_euler((original.get(bone,Vector3.ZERO) as Vector3)*PI/180.0)
			var to:Quaternion=source_base*Quaternion.from_euler((source.get(bone,Vector3.ZERO) as Vector3)*PI/180.0)
			candidate[bone]=(target_base.inverse()*from.slerp(to,weight)).get_euler()*180.0/PI
		else:candidate[bone]=blend_custom_angles(original.get(bone,Vector3.ZERO),source.get(bone,Vector3.ZERO),weight)
	if group in ["All","Hands"]:candidate["hands"]=_blend_hand_pose(original["hands"],source["hands"],weight)
	if group in ["All","Torso"]:
		candidate["pelvis_offset"]=(original.get("pelvis_offset",Vector3.ZERO) as Vector3).lerp(source.get("pelvis_offset",Vector3.ZERO),weight)
		if custom_source_timing=="native_v1":
			var from:Vector3=custom_source_frames[target_index].pelvis_position+(original.get("pelvis_offset",Vector3.ZERO) as Vector3)
			var to:Vector3=custom_source_frames[source_index].pelvis_position+(source.get("pelvis_offset",Vector3.ZERO) as Vector3)
			candidate["pelvis_offset"]=from.lerp(to,weight)-(custom_source_frames[target_index].pelvis_position as Vector3)
	custom_preview_playing=false
	update_custom_transport()
	var baseline:=custom_frame_penetrations(target_index)
	custom_frames[target_index]=candidate
	var collisions:=custom_frame_penetrations(target_index)
	var blocked:=false
	for pair in collisions:
		if float(collisions[pair])>maxf(0.005,float(baseline.get(pair,0.0))+0.00001):
			blocked=true
			break
	if blocked:
		custom_frames[target_index]=original
		custom_preview_elapsed=elapsed
		custom_collision_alert.text="This pose overlaps the body in the destination frame. Try adjusting it or blending."
		custom_collision_alert.show()
		custom_collision_alert_time=3.0
		custom_status.text="Frame %d kept its original pose. Adjust the pose or try blending."%(target_index+1)
	else:
		custom_range_active=false
		custom_preview_elapsed=float(target_index)/float(custom_frames.size())*custom_duration
		custom_collision_alert_time=0.0
		custom_collision_alert.hide()
		custom_status.text="%s %s from frame %d into frame %d. Tweak it or propagate again."%["Copied" if weight>=1.0 else "Blended","all parts" if group=="All" else group.to_lower(),source_index+1,target_index+1]
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)

func randomize_custom_frame() -> void:
	if custom_frames.is_empty() or custom_randomizing:return
	var index:=custom_frame_index
	if not begin_custom_random_snapshot([index]):return
	var elapsed:=custom_preview_elapsed
	_randomize_custom_pose(index)
	_finish_custom_randomization(elapsed,"Randomized selected parts in frame %d. Clipping checks applied."%(index+1))

func randomize_all_custom_frames() -> void:
	if custom_frames.is_empty() or custom_randomizing:return
	var indices:Array[int]=[]
	for index in custom_frames.size():indices.append(index)
	if not begin_custom_random_snapshot(indices):return
	var elapsed:=custom_preview_elapsed
	custom_randomizing=true
	set_custom_editing_enabled(false)
	for index in custom_frames.size():
		_randomize_custom_pose(index)
		custom_status.text="Randomizing frame %d / %d…"%[index+1,custom_frames.size()]
		if index<custom_frames.size()-1:await get_tree().process_frame
	custom_randomizing=false
	set_custom_editing_enabled(true)
	_finish_custom_randomization(elapsed,"Randomized selected parts across %d frames. Clipping checks applied."%custom_frames.size())
	update_custom_transport()
	update_custom_random_tools()

func begin_custom_random_snapshot(indices:Array[int]) -> bool:
	var selected:=selected_custom_random_parts()
	if selected.is_empty():
		custom_status.text="Choose the body parts you want to randomize first."
		return false
	custom_random_snapshot.assign(custom_frames.duplicate(true))
	custom_random_pending.clear()
	for index in indices:
		var pending:Dictionary={}
		for key in selected:pending[key]=true
		custom_random_pending[index]=pending
	return true

func copy_custom_pose_part(target:Dictionary,source:Dictionary,key:String) -> void:
	if key.begins_with("hand_"):
		var side:=key.get_slice(":",0).trim_prefix("hand_")
		var finger:=key.get_slice(":",1)
		target["hands"][side][finger]=source["hands"][side][finger]
	else:target[key]=source[key]

func restore_custom_randomization(undo_all:=false) -> void:
	if custom_randomizing or custom_random_snapshot.size()!=custom_frames.size() or custom_random_pending.is_empty():return
	var elapsed:=custom_preview_elapsed
	var selected_frame:=custom_frame_index
	var selected:=selected_custom_random_parts()
	var restored:=0
	var blocked:=0
	for index in custom_random_pending.keys():
		if not undo_all and custom_restore_scope.selected==0 and index!=selected_frame:continue
		var keys:Array[String]=[]
		for key in custom_random_pending[index]:
			if undo_all or key in selected:keys.append(key)
		if keys.is_empty():continue
		var original:Dictionary=custom_frames[index].duplicate(true)
		var candidate:Dictionary=original.duplicate(true)
		for key in keys:copy_custom_pose_part(candidate,custom_random_snapshot[index],key)
		var baseline:=custom_frame_penetrations(index)
		# Source-clip contact that was already present before randomizing is allowed.
		custom_frames[index]=custom_random_snapshot[index].duplicate(true)
		var previous_contact:=custom_frame_penetrations(index)
		custom_frames[index]=candidate
		var collisions:=custom_frame_penetrations(index)
		var intersects:=false
		for pair in collisions:
			var allowed:=maxf(0.005,maxf(float(baseline.get(pair,0)),float(previous_contact.get(pair,0))))
			if float(collisions[pair])>allowed+0.00001:
				intersects=true
				break
		if intersects:
			custom_frames[index]=original
			blocked+=1
		else:
			for key in keys:custom_random_pending[index].erase(key)
			restored+=keys.size()
			if custom_random_pending[index].is_empty():custom_random_pending.erase(index)
	custom_preview_elapsed=elapsed
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)
	custom_status.text="Restored %d body controls from before the last randomization."%restored
	if blocked>0:
		custom_collision_alert.text="Can't put body parts clipping through others. %d frame(s) kept their current pose."%blocked
		custom_collision_alert.show()
		custom_collision_alert_time=3.0
	else:
		custom_collision_alert.hide()
		custom_collision_alert_time=0.0
	update_custom_random_tools()

func set_custom_editing_enabled(enabled:bool) -> void:
	for control in custom_editor.find_children("*","Control",true,false):
		if control is BaseButton:control.disabled=not enabled
		elif control is Slider or control is SpinBox or control is LineEdit:control.editable=enabled

func _randomize_custom_pose(index:int) -> void:
	custom_preview_elapsed=float(index)/float(custom_frames.size())*custom_duration
	custom_preview_reseek=true
	advance_custom_preview(0.0,false)
	for joint in JUMP_JOINTS:
		if not custom_random_parts.get(joint.bone,false):continue
		var extent:=100.0
		if str(joint.bone).begins_with("thigh"):extent=55.0
		elif joint.bone=="spine_03":extent=25.0
		var target:=custom_random.randf_range(maxf(float(joint.min),-extent),minf(float(joint.max),extent))
		if joint.bone=="Head":set_custom_pose_angle("Head",joint.axis,roundf(target),false)
		else:set_custom_joint(joint.bone,joint.axis,roundf(target),null,false)
	for side in ["l","r"]:
		var gesture:=custom_random.randi_range(1,HAND_GESTURES.size()-1)
		if gesture==hand_gesture_index(custom_frames[index]["hands"][side]):gesture=gesture%(HAND_GESTURES.size()-1)+1
		var hand:=hand_gesture_pose(gesture)
		for finger in HAND_FINGERS:
			if not custom_random_parts.get("hand_%s:%s"%[side,finger],false):continue
			if is_equal_approx(float(hand[finger]),float(custom_frames[index]["hands"][side][finger])):hand[finger]=roundf(custom_random.randf_range(0.0,100.0))
			custom_frames[index]["hands"][side][finger]=hand[finger]

func _finish_custom_randomization(elapsed:float,message:String) -> void:
	custom_preview_elapsed=elapsed
	custom_preview_reseek=true
	custom_collision_alert_time=0.0
	custom_collision_alert.hide()
	advance_custom_preview(0.0,false)
	custom_status.text=message

func play_custom_preview() -> void:
	if custom_range_active:
		var range_end:float=float(custom_range_last+1)/float(custom_frames.size())*custom_duration
		if custom_preview_elapsed>=range_end-0.001:
			custom_preview_elapsed=float(custom_range_first)/float(custom_frames.size())*custom_duration
			custom_preview_reseek=true
	elif custom_preview_elapsed>=custom_duration:
		custom_preview_elapsed=0.0
		custom_preview_reseek=true
	custom_preview_playing=true
	update_custom_transport()
	advance_custom_preview(0.0)

func pause_custom_preview() -> void:
	custom_preview_playing=false
	update_custom_transport()
	advance_custom_preview(0.0)

func toggle_custom_repeat() -> void:
	custom_preview_repeat=not custom_preview_repeat
	update_custom_transport()

func update_custom_transport() -> void:
	if not is_instance_valid(custom_play_button):return
	custom_play_button.disabled=custom_recording or custom_preview_playing
	custom_pause_button.disabled=custom_recording or not custom_preview_playing
	custom_repeat_button.text="Repeat: On" if custom_preview_repeat else "Repeat: Off"
	_set_button_accent(custom_repeat_button,custom_preview_repeat)

func preview_clip_for_progress(progress: float) -> Dictionary:
	if custom_source_timing=="native_v1":return SourcePose.clip_at(actor,custom_source_step,custom_source_clip,progress,custom_source_duration)
	if custom_source_step!="Jump":return {"name":custom_source_clip,"blend":progress}
	if progress<0.30:return {"name":"ual1/Jump_Start","blend":progress/0.30}
	return {"name":"duel/air","blend":(progress-0.30)/0.70}

func apply_custom_source_pose(progress:float) -> void:
	actor.skeleton.reset_bone_poses()
	var jump_progress:=clampf((progress-0.28)/0.58,0.0,1.0)
	actor.global_position.y=1.25*4.0*jump_progress*(1.0-jump_progress) if custom_source_step=="Jump" else 0.0
	if custom_source_timing=="native_v1" and custom_source_step=="Jump":
		var air_time:=maxf(0.0,progress*custom_source_duration-0.14)
		actor.global_position.y=maxf(0.0,10.8*air_time-0.5*actor.GRAVITY*air_time*air_time)
	if custom_source_step in ["Flip","Twist"]:actor.global_position.y=0.6+0.9*sin(PI*progress)
	actor.model.rotation.y=0.0
	if custom_source_step=="Twist":
		actor.model.rotation.y=TAU*smoothstep(0.0,1.0,clampf((progress*custom_source_duration-actor.TWIST_DELAY)/actor.TWIST_DURATION,0,1)) if custom_source_timing=="native_v1" else TAU*smoothstep(0.15,0.9,progress)
	var base_clip:=preview_clip_for_progress(progress)
	var clip_name:String=base_clip.name
	# Pose sampling must never crossfade: advance(0) cannot finish a fade.
	actor.clip=clip_name
	actor.player.play(clip_name,0.0,1.0)
	var animation:Animation=actor.player.get_animation(clip_name)
	actor.player.seek(animation.length*clampf(float(base_clip.blend),0.0,1.0),true)
	actor.player.advance(0.0)
	preload("res://scripts/editor_rig_pose.gd").sample(actor,clip_name,animation.length*clampf(float(base_clip.blend),0,1))
	if custom_source_mirrored:preload("res://scripts/animation_mirror.gd").apply(actor)
	if custom_source_step in ["Run","Sprint","Dash"] and actor.bones.has("pelvis"):
		var pelvis:int=actor.bones["pelvis"]
		var origin:Vector3=actor.skeleton.get_bone_pose_position(pelvis)
		var rest:Vector3=actor.skeleton.get_bone_rest(pelvis).origin
		origin.x=rest.x
		origin.z=rest.z
		actor.skeleton.set_bone_pose_position(pelvis,origin)

func advance_custom_preview(delta: float,advance_timeline:=true) -> void:
	if not is_instance_valid(actor) or actor.skeleton==null:return
	var timeline_advances:=advance_timeline and custom_preview_playing
	if timeline_advances:
		if custom_range_active:
			var range_start:=float(custom_range_first)/float(custom_frames.size())*custom_duration
			var range_end:=float(custom_range_last+1)/float(custom_frames.size())*custom_duration
			var range_duration:=maxf(0.001,range_end-range_start)
			custom_preview_elapsed+=delta
			if custom_preview_elapsed>=range_end:
				if custom_preview_repeat:
					custom_preview_elapsed=range_start+fposmod(custom_preview_elapsed-range_end,range_duration)
					custom_preview_reseek=true
				else:
					custom_preview_elapsed=maxf(range_start,range_end-0.001)
					custom_preview_playing=false
					update_custom_transport()
		elif custom_preview_repeat:
			custom_preview_elapsed=fposmod(custom_preview_elapsed+delta,custom_duration)
		else:
			custom_preview_elapsed=minf(custom_preview_elapsed+delta,custom_duration)
	var progress:=custom_preview_elapsed/custom_duration
	apply_custom_source_pose(progress)
	var frame_count:=custom_frames.size()
	var scaled:=progress*float(frame_count)
	custom_frame_index=mini(frame_count-1,int(floor(scaled)))
	custom_preview_frame=custom_frame_index
	var next_index: int=(custom_frame_index+1)%frame_count
	if not custom_preview_repeat and custom_frame_index==frame_count-1:next_index=custom_frame_index
	if custom_range_active and custom_frame_index>=custom_range_last:next_index=custom_range_last
	var blend: float=scaled-float(floor(scaled))
	custom_preview_reseek=false
	if not custom_collision_probe_active:update_custom_frame_controls()
	for bone in DragSolver.JOINTS:
		var index: int=actor.bones.get(bone,-1)
		if index<0:continue
		var pose_a: Vector3=custom_frames[custom_frame_index].get(bone,Vector3.ZERO)
		var pose_b: Vector3=custom_frames[next_index].get(bone,Vector3.ZERO)
		var offset:=Quaternion.from_euler(pose_a*PI/180.0).slerp(Quaternion.from_euler(pose_b*PI/180.0),blend)
		var base_pose: Quaternion=actor.skeleton.get_bone_pose_rotation(index)
		actor.skeleton.set_bone_pose_rotation(index,(base_pose*offset).normalized())
	var frame_a: Dictionary=custom_frames[custom_frame_index]
	var frame_b: Dictionary=custom_frames[next_index]
	var pelvis_index:int=actor.bones["pelvis"]
	var pelvis_offset:Vector3=(frame_a.get("pelvis_offset",Vector3.ZERO) as Vector3).lerp(frame_b.get("pelvis_offset",Vector3.ZERO),blend)
	actor.skeleton.set_bone_pose_position(pelvis_index,actor.skeleton.get_bone_pose_position(pelvis_index)+pelvis_offset)
	if not custom_collision_probe_active:_apply_preview_hand_pose(_blend_hand_pose(frame_a.get("hands",_default_hand_pose()),frame_b.get("hands",_default_hand_pose()),blend))
	if not custom_range_active and not custom_preview_repeat and custom_preview_elapsed>=custom_duration:
		custom_preview_playing=false
		update_custom_transport()

func _apply_preview_hand_pose(hands:Dictionary) -> void:
	preload("res://scripts/hand_pose.gd").apply(actor,hands)

func encode_custom_source_frames() -> Array:
	var encoded:Array=[]
	for sample in custom_source_frames:
		var pose:Dictionary={}
		for bone in DragSolver.JOINTS:
			var rest:Quaternion=actor.skeleton.get_bone_rest(actor.bones[bone]).basis.get_rotation_quaternion()
			var angles:Vector3=(rest.inverse()*(sample.rotations[bone] as Quaternion)).get_euler()*180.0/PI
			pose[bone]=[angles.x,angles.y,angles.z]
		var position:Vector3=sample.pelvis_position
		pose["pelvis_position"]=[position.x,position.y,position.z]
		var rotation:Vector3=(sample.pelvis_rotation as Quaternion).get_euler()*180.0/PI
		pose["pelvis_rotation"]=[rotation.x,rotation.y,rotation.z]
		encoded.append(pose)
	return encoded

func save_custom_jump() -> void:
	var name_: String=custom_name.text.strip_edges()
	if name_.is_empty():
		custom_status.text="Add a name before saving this %s."%custom_action_category
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CUSTOM_DIR))
	var slug:=name_.to_lower().strip_edges().replace(" ","_").validate_filename()
	var path:=CUSTOM_DIR+"/"+slug+".json"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		custom_status.text="Could not save this %s on this device."%custom_action_category
		return
	var encoded_frames: Array=[]
	for frame in custom_frames:
		var encoded_pose: Dictionary={}
		for bone in frame:
			if bone=="hands":
				encoded_pose["hands"]=frame["hands"].duplicate(true)
				continue
			var angles: Vector3=frame[bone]
			encoded_pose[bone]=[angles.x,angles.y,angles.z]
		encoded_frames.append(encoded_pose)
	custom_provenance=AssetProvenance.derive([custom_provenance],"animation",name_,AssetProvenance.creator_name(),"modified animation")
	file.store_string(JSON.stringify({"version":2,"name":name_,"group":custom_action_group,"category":custom_action_category,"step":custom_source_step,"clip":custom_source_clip,"source_title":custom_source_title,"mirrored":custom_source_mirrored,"attack_bone":custom_source_attack_bone,"source_timing":custom_source_timing,"source_duration":custom_source_duration,"source_frames":encode_custom_source_frames(),"based_on":{"name":custom_parent_name,"path":custom_parent_path},"provenance":custom_provenance,"source_animation":custom_store_source_animation,"duration":custom_duration,"frame_count":encoded_frames.size(),"frames":encoded_frames},"\t"))
	file.close()
	custom_edit_path=path
	custom_status.text="Saved %s on this device."%name_

func load_custom_motion(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CUSTOM_DIR)):return result
	var dir:=DirAccess.open(CUSTOM_DIR)
	if dir==null:return result
	dir.list_dir_begin()
	var filename:=dir.get_next()
	while not filename.is_empty():
		if filename.ends_with(".json"):
			var file:=FileAccess.open(CUSTOM_DIR+"/"+filename,FileAccess.READ)
			if file!=null:
				var parsed=JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and Library.category_for(str(parsed.get("category","Jump")))==category and parsed.get("frames",[]).size()>=MIN_CUSTOM_FRAMES:
					var decoded_frames: Array[Dictionary]=[]
					for source_pose in parsed.frames:
						var decoded: Dictionary={}
						for bone in DragSolver.JOINTS:
							var raw: Array=source_pose.get(bone,[0.0,0.0,0.0])
							decoded[bone]=Vector3(float(raw[0]),float(raw[1]),float(raw[2]))
						decoded["hands"]=_normalize_hand_pose(source_pose.get("hands",_default_hand_pose()))
						var pelvic:Array=source_pose.get("pelvis_offset",[0,0,0])
						decoded["pelvis_offset"]=Vector3(float(pelvic[0]),float(pelvic[1]),float(pelvic[2]))
						decoded_frames.append(decoded)
					var source:Dictionary={}
					for candidate in Library.entries():
						if (candidate.group=="Motion" or candidate.group=="Attack" and category in ["Punch","Kick","Knee","Elbow","Uppercut","Sweep","Slash","Block","Dodges"]) and candidate.category==category:
							if source.is_empty():source=candidate
							if candidate.step==str(parsed.get("step",category)) and candidate.clip==str(parsed.get("clip",candidate.clip)) and bool(candidate.get("mirrored",false))==bool(parsed.get("mirrored",false)):
								source=candidate
								break
					if source.is_empty() and not str(parsed.get("clip","")).is_empty():
						source=Library.item(str(parsed.get("group","Motion")),category,str(parsed.get("name",filename.get_basename())),str(parsed.get("step","Idle")),str(parsed.clip))
					if not source.is_empty():
						var based_on:Dictionary=parsed.get("based_on",{})
						result.append({"group":source.group,"category":category,"title":str(parsed.get("name",filename.get_basename())),"step":str(parsed.get("step",source.step)),"clip":str(parsed.get("clip",source.clip)),"source_title":str(parsed.get("source_title",source.title)),"mirrored":bool(parsed.get("mirrored",false)),"attack_bone":str(parsed.get("attack_bone",source.get("attack_bone",""))),"source_timing":str(parsed.get("source_timing","legacy")),"source_duration":clampf(float(parsed.get("source_duration",parsed.get("duration",CUSTOM_LOOP_DURATION))),0.1,60.0),"parent_name":str(based_on.get("name","")),"parent_path":str(based_on.get("path","")),"kind":"custom_"+category.to_lower(),"duration":clampf(float(parsed.get("duration",CUSTOM_LOOP_DURATION)),0.2,60.0),"frames":decoded_frames,"frame_count":decoded_frames.size(),"path":CUSTOM_DIR+"/"+filename})
						var loaded_entry:Dictionary=result.back()
						loaded_entry["provenance"]=AssetProvenance.source(parsed)
						if not str(parsed.get("source_animation","")).is_empty():loaded_entry["source_animation"]=str(parsed.source_animation)
		filename=dir.get_next()
	dir.list_dir_end()
	return result

func _normalize_hand_pose(source:Dictionary) -> Dictionary:
	var result:=_default_hand_pose()
	for side in ["l","r"]:
		var source_fingers: Dictionary=source.get(side,{})
		for finger in HAND_FINGERS:
			result[side][finger]=clampf(float(source_fingers.get(finger,0.0)),0.0,100.0)
		for key in ["absolute","straight","palm_up"]:result[side][key]=clampf(float(source_fingers.get(key,0.0)),0,1)
		for finger in HAND_FINGERS:
			if source_fingers.has("absolute_"+finger):result[side]["absolute_"+finger]=clampf(float(source_fingers["absolute_"+finger]),0,1)
	return result

func populate_custom_motion(category: String) -> void:
	for entry in load_custom_motion(category):
		build_animation_row(entry,true)
	refresh_library_add_buttons()

func delete_custom_motion(entry: Dictionary) -> void:
	if entry.has("store_asset_id"):
		if store_library.remove(StoreLibrary.key(entry)):
			select_category(selected_category,true)
			_populate_animation_store()
			_show_library_notice("Removed %s from your library"%entry.title)
		return
	var path:String=str(entry.get("path",""))
	var root:String=ProjectSettings.globalize_path(CUSTOM_DIR).simplify_path().trim_suffix("/")+"/"
	var absolute:String=ProjectSettings.globalize_path(path).simplify_path()
	if not entry.has("frames") or not path.ends_with(".json") or not absolute.to_lower().begins_with(root.to_lower()):
		selection_status.text="Base animations cannot be deleted."
		return
	if FileAccess.file_exists(path):
		var archived:=AnimationTrash.archive(entry,animation_trash_directory)
		if archived.is_empty():
			selection_status.text="Could not delete this animation."
			return
		deleted_animation_records.append(archived)
		update_undo_delete_button()
	if selected_entry.get("path","")==entry.path:selected_entry.clear()
	populate_group(entry.group)
	select_category(entry.category)
	if is_instance_valid(custom_status):custom_status.text="Deleted %s."%entry.title
	selection_status.text="Deleted %s · use the undo icon to restore it."%entry.title

func update_undo_delete_button() -> void:
	if not is_instance_valid(undo_delete_button):return
	undo_delete_button.visible=not deleted_animation_records.is_empty()
	undo_delete_button.disabled=deleted_animation_records.is_empty()
	if not deleted_animation_records.is_empty():undo_delete_button.tooltip_text="Undo delete: "+str(deleted_animation_records.back().get("title","animation"))

func restore_last_deleted_animation() -> void:
	if deleted_animation_records.is_empty():return
	var restored:=AnimationTrash.restore(deleted_animation_records.back())
	if restored.is_empty():
		selection_status.text="Could not restore the deleted animation."
		return
	deleted_animation_records.pop_back()
	update_undo_delete_button()
	var group:String=restored.group
	for candidate in Library.GROUPS:
		if restored.category in Library.GROUPS[candidate]:group=candidate
	populate_group(group)
	select_category(restored.category)
	selection_status.text="Restored "+str(restored.title)

func close_custom_editor() -> void:
	actor.editor_pose_locked=false
	actor.hide()
	if custom_recording:cancel_custom_recording()
	custom_drag_handle=""
	custom_editor.hide()
	base_ui.show()
	get_tree().paused=false
	for f in [actor,target]:
		if is_instance_valid(f):f.skeleton.reset_bone_poses()
	if selected_group!=custom_action_group:populate_group(custom_action_group)
	select_category(custom_action_category)

func add_library_animation(entry: Dictionary) -> void:
	var steps:=chosen_steps()
	if steps.size()>=MAX_CHAIN_STEPS:
		selection_status.text="Chain is full"
		return
	var grounded:=true
	for step in steps:grounded=sequence.state_after(step,grounded)
	if not sequence.allowed_for_state(entry.step,grounded):
		selection_status.text="Add Jump first" if grounded else "Add Land before a grounded move"
		return
	steps.append(entry.step)
	var profiles:Array=chain_profiles.duplicate(true)
	profiles.append(entry.duplicate(true))
	set_chain(steps,profiles)
	selection_status.text="Added: "+entry.title
	reveal_last_chain_step()

func layout_chain(browsing: bool) -> void:
	# The legacy chain widgets remain owned by the parent sandbox but are fully removed from this editor.
	if is_instance_valid(chain_backdrop):chain_backdrop.hide()
	if is_instance_valid(chain_panel):chain_panel.hide()

func run_setup() -> void:
	if is_instance_valid(browser):
		browser.hide()
		browse_backdrop.hide()
		field.show()
		live_preview_sequence.reset()
		layout_chain(false)
	super.run_setup()
	update_chain_highlight()

func browse_animations() -> void:
	stop_repeat_play()
	stop_camera_drag()
	browser.show()
	browse_backdrop.hide()
	field.show()
	layout_chain(true)
	if is_instance_valid(timeline_panel):timeline_panel.show()
	begin_live_preview()

func reset_setup() -> void:
	_reset_animation_state_in_place()
	if not is_instance_valid(browser):return
	if move_menu.selected!=0:
		browser.hide()
		browse_backdrop.hide()
		field.show()
		layout_chain(false)
	elif browser.visible and not selected_entry.is_empty():
		begin_live_preview()

func _reset_animation_state_in_place() -> void:
	var transforms:Array[Transform3D]=[]
	if is_instance_valid(field):
		for fighter in field.fighters:transforms.append(fighter.global_transform)
	super.reset_setup()
	if is_instance_valid(field):
		for index in mini(transforms.size(),field.fighters.size()):
			field.fighters[index].global_transform=transforms[index]

func begin_live_preview(reset_loops: bool=true) -> void:
	if selected_entry.is_empty() or not is_instance_valid(actor):return
	# Reset real fighters/effects without altering the user's composed chain.
	_reset_animation_state_in_place()
	_capture_timeline_origin()
	for fighter in field.fighters:fighter.editor_pose_locked=true
	actor.player.stop()
	actor.skeleton.reset_bone_poses()
	actor.model.rotation=Vector3.ZERO
	actor.clip=""
	actor.twist_age=-1
	actor.set_editor_animation_profile(selected_entry,selected_entry.step)
	preload("res://scripts/editor_rig_pose.gd").idle(actor)
	if field.events.size()>4000:field.events=field.events.slice(-2000)
	live_preview_steps.assign([selected_entry.step])
	if selected_entry.step in ["Flip","Twist"]:
		live_preview_steps.assign(["Jump",selected_entry.step,"Land"])
	elif selected_entry.step=="Land":
		live_preview_steps.assign(["Jump","Land"])
	actor.mana=100 if sequence.needs_mana(live_preview_steps) else 0
	live_preview_sequence.reset()
	live_preview_age=0
	live_preview_started=false
	if reset_loops:live_preview_loops=0
	field.show()
	get_tree().paused=false

func _spend_unit_stamina(unit:CharacterBody3D,amount:float) -> void:
	if not is_instance_valid(unit) or amount<=0.0:return
	unit.stamina=maxf(0.0,float(unit.stamina)-amount)
	var tag:=unit.get_node_or_null("OverheadHealthTag")
	if tag!=null:tag.update_tag()

func _spend_timeline_stamina(from_time:float,to_time:float) -> void:
	if not is_instance_valid(focused_unit):return
	var cost:=0.0
	for clip in timeline_clips:
		var duration:=maxf(0.05,float(clip.duration))
		var overlap:=maxf(0.0,minf(to_time,float(clip.start)+duration)-maxf(from_time,float(clip.start)))
		cost+=float(_clip_combat_stats(clip).stamina)*overlap/duration
	_spend_unit_stamina(focused_unit,cost)

func _physics_process(delta: float) -> void:
	playtest.physics(delta)
	_tick_jump_tails(delta*Engine.time_scale)
	if is_instance_valid(row_preview_unit):
		update_camera(delta)
		return
	if timeline_playing and selected_group!="Spells":
		var previous_time:=timeline_playhead
		timeline_playhead+=delta*Engine.time_scale
		_spend_timeline_stamina(previous_time,minf(timeline_playhead,timeline_duration))
		if timeline_playhead>=timeline_duration:
			if repeat_playing:
				_apply_timeline_at(timeline_duration)
				_capture_timeline_origin()
				timeline_playhead=fposmod(timeline_playhead,timeline_duration)
				_spend_timeline_stamina(0.0,timeline_playhead)
			else:
				timeline_playhead=timeline_duration
				stop_timeline()
		_apply_timeline_at(timeline_playhead)
		_update_timeline_ruler()
		timeline_time_label.text="%.2f s"%timeline_playhead
		for lane_row in timeline_tracks.get_children():
			if lane_row.get_child_count()>1 and str(lane_row.get_child(1).get("track_id"))!="":lane_row.get_child(1).queue_redraw()
		_update_timeline_clip_highlights()
		update_camera(delta)
		return
	if selected_group=="Spells":
		update_camera(delta)
		return
	if playtest.active:return
	if is_instance_valid(browser) and browser.visible:
		update_camera(delta)
		return
	if get_tree().paused:return
	if not is_instance_valid(browser) or not browser.visible:
		super._physics_process(delta)
		update_chain_highlight()
		return
	if selected_entry.is_empty():
		update_camera(delta)
		return
	live_preview_age+=delta
	if not live_preview_started and live_preview_age>=0.25:
		live_preview_started=true
		if partner_jumps():
			target.start_jump("flip")
			target.air_momentum=Vector3.ZERO
			partner_jumping=true
		var profiles:Array=[]
		for step in live_preview_steps:profiles.append(selected_entry.duplicate(true) if step==selected_entry.step else {})
		live_preview_sequence.start(actor,live_preview_steps,dash_direction_menu.selected,profiles)
	elif live_preview_started:
		if not sequence.needs_mana(live_preview_steps):actor.mana=0
		live_preview_sequence.tick(actor,delta)
	if partner_jumping and not partner_air_ready and target.mode=="flip":
		partner_air_ready=true
		target.mode="air"
		target.mode_time=0
		if catalog[0].has("block"):set_shield(target,catalog[0].block,9.0)
	update_camera(delta)
	show_resources()
	result_label.text="LIVE ARENA · %s · Damage %.1f · %s"%[selected_entry.title,target.damage_taken-marks.damage,live_preview_sequence.status]
	var cycle:float={"Run":1.8,"Sprint":1.8,"Dash":1.5,"Crouch":1.8,"Block":2.0,"Brace Block":2.0}.get(selected_entry.step,2.5)
	if live_preview_age>=cycle and not is_instance_valid(row_preview_unit):
		begin_live_preview(false)
		live_preview_loops+=1

func update_camera(delta: float) -> void:
	if camera_initialized:return
	if not is_instance_valid(browser) or not browser.visible:
		super.update_camera(delta)
		return
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	var points: Array[Vector3]=[]
	for f in [actor]:
		for point in [f.focus_position(),f.bone_point("Head")+Vector3.UP*0.2,f.bone_point("foot_l"),f.bone_point("foot_r")]:
			points.append(point)
			low=low.min(point)
			high=high.max(point)
	var center: Vector3=(low+high)*0.5-Vector3.UP*2.0
	var back:=Vector3(0.15,0.36,1).normalized()
	var right:=Vector3(1,0,-0.15).normalized()
	var up:=back.cross(right).normalized()
	var distance:=18.0
	var aspect: float=get_viewport().get_visible_rect().size.aspect()
	var tangent:=tan(deg_to_rad(field.camera.fov*0.5))
	for point in points:
		var offset:=point-center
		var fit:=maxf(absf(offset.dot(right))/(tangent*aspect*0.5),absf(offset.dot(up))/(tangent*0.4))
		distance=maxf(distance,offset.dot(back)+fit+0.6)
	# One initial composition. No tracking, interpolation, or per-cycle zoom.
	var shift: Vector3=right*(-distance*tangent*aspect*0.40)
	field.camera.position=center+back*distance+shift
	field.camera.look_at(center+shift)
	field.camera.h_offset=0
	field.camera.v_offset=0
	inspection_camera.capture_view(field.camera,distance)
	camera_initialized=true

func _process(delta: float) -> void:
	if is_instance_valid(custom_editor) and custom_editor.visible and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):_capture_custom_history()
	if is_instance_valid(field) and is_instance_valid(base_ui):
		var hover_control:=get_viewport().gui_get_hovered_control()
		hovered_unit=_pick_editor_unit(get_viewport().get_mouse_position()) if hover_control==base_ui.get_node_or_null("ArenaUnitDrop") else null
		_update_unit_focus_rings()
	idle_preview_elapsed+=delta
	if custom_collision_alert_time>0.0:
		custom_collision_alert_time=maxf(0.0,custom_collision_alert_time-delta)
		if custom_collision_alert_time<=0.0 and is_instance_valid(custom_collision_alert):custom_collision_alert.hide()
	if is_instance_valid(custom_editor) and custom_editor.visible:
		super._process(delta)
		if not custom_drag_handle.is_empty() and not custom_drag_stalled:
			var before:Vector3=DragSolver.point(actor,custom_drag_handle)
			if before.distance_to(custom_drag_target)>0.003:
				apply_custom_pose_drag(custom_drag_target)
				custom_drag_stalled=before.distance_to(DragSolver.point(actor,custom_drag_handle))<0.0002
		if custom_recording:
			advance_custom_preview(0.0,false)
			tick_custom_recording(delta)
		elif not custom_randomizing:advance_custom_preview(delta,not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		custom_drag_overlay.queue_redraw()
		return
	if not timeline_playing and selected_group!="Spells" and is_instance_valid(field):
		for fighter in field.fighters:
			if fighter.mode in ["idle","review"]:preload("res://scripts/editor_rig_pose.gd").idle(fighter,idle_preview_elapsed)
	for unit in added_units:
		if is_instance_valid(unit) and not unit.has_meta("editor_jump_tail") and unit!=row_preview_unit and not (timeline_playing and unit==focused_unit) and not (playtest.active and unit==focused_unit and (playtest.held.get(KEY_W,false) or playtest.held.get(KEY_A,false) or playtest.held.get(KEY_S,false) or playtest.held.get(KEY_D,false))):_set_unit_idle_target(unit,idle_preview_elapsed)
	super._process(delta)
	if is_instance_valid(row_preview_unit) and is_instance_valid(actor):
		var previous_elapsed:=row_preview_elapsed
		row_preview_elapsed+=delta
		var active_delta:=maxf(0.0,minf(row_preview_elapsed-0.25,row_preview_action_duration)-maxf(previous_elapsed-0.25,0.0))
		_spend_unit_stamina(row_preview_unit,row_preview_stamina_cost*active_delta/row_preview_action_duration)
		_sample_row_animation(selected_entry,clampf(row_preview_elapsed-0.25,0.0,row_preview_action_duration))
		if str(selected_entry.get("step",""))=="Jump":
			var duration:=_animation_timeline_duration(selected_entry)
			var time:=clampf(row_preview_elapsed-0.25,0.0,duration)
			_sample_effort_jump(selected_entry,time,time)
			var stats:=_timeline_motion_stats(selected_entry)
			var progress:=clampf((time-0.14)/maxf(0.001,float(stats.airtime)),0.0,1.0)
			row_preview_unit.global_position=row_preview_origin+Vector3.UP*(4.0*float(stats.height)*progress*(1.0-progress))
		_set_unit_pose_target(row_preview_unit)
		row_preview_remaining-=delta
		if row_preview_remaining<=0.0:
			if str(selected_entry.get("step",""))=="Jump":row_preview_unit.global_position=row_preview_origin
			_set_unit_idle_target(row_preview_unit)
			row_preview_unit=null
			selection_status.text="Preview finished · press the row Play button to play again"
	_blend_unit_pose_targets(delta)
	playtest.contacts()

func _input(event: InputEvent) -> void:
	if playtest.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.alt_pressed and not event.ctrl_pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN] and can_add_unit_animation() and not get_viewport().gui_get_focus_owner() is LineEdit and not (get_viewport().gui_get_focus_owner() is Button and get_viewport().gui_get_focus_owner().has_meta("timeline_clip_id")):
		stop_timeline()
		var direction:Vector3={KEY_LEFT:Vector3.LEFT,KEY_RIGHT:Vector3.RIGHT,KEY_UP:Vector3.FORWARD,KEY_DOWN:Vector3.BACK}[event.keycode]
		move_editor_unit(focused_unit,focused_unit.global_position+direction*0.25)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode==KEY_R and not get_viewport().gui_get_focus_owner() is LineEdit:
		reset_focused_unit_position()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.ctrl_pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		var key:=_zoom_panel_at(event.position)
		if not key.is_empty():
			change_panel_zoom(key,1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode in [KEY_EQUAL,KEY_MINUS,KEY_0] and not get_viewport().gui_get_focus_owner() is LineEdit:
		var key:=_zoom_panel_at(get_viewport().get_mouse_position())
		if not key.is_empty():
			change_panel_zoom(key,-1 if event.keycode==KEY_MINUS else 1,event.keycode==KEY_0)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and not get_viewport().gui_get_focus_owner() is LineEdit and not get_viewport().gui_get_focus_owner() is TextEdit and not (is_instance_valid(custom_editor) and custom_editor.visible):
		match event.keycode:
			KEY_Z:undo_timeline_edit()
			KEY_Y:redo_timeline_edit()
			KEY_C:copy_timeline_clip()
			KEY_P,KEY_V:paste_timeline_clip()
			_:return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode in [KEY_BRACKETLEFT,KEY_BRACKETRIGHT] and not get_viewport().gui_get_focus_owner() is LineEdit and not added_units.is_empty():
		focus_editor_unit(posmod(added_units.find(focused_unit)+(-1 if event.keycode==KEY_BRACKETLEFT else 1),added_units.size()))
		get_viewport().set_input_as_handled()
		return
	release_camera_text_focus(event)
	if is_instance_valid(custom_editor) and custom_editor.visible and pose_targets.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(custom_editor) and custom_editor.visible:
		if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode in [KEY_Z,KEY_Y] and not get_viewport().gui_get_focus_owner() is LineEdit and not get_viewport().gui_get_focus_owner() is TextEdit:
			if event.keycode==KEY_Y:redo_custom_edit()
			else:undo_custom_edit()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			if custom_recording:cancel_custom_recording()
			elif not custom_drag_handle.is_empty():undo_custom_drag()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseMotion and direct_pose_handles_visible():
			if not custom_drag_handle.is_empty():
				move_custom_pose_drag(event.position)
				get_viewport().set_input_as_handled()
				return
			custom_drag_hover=pick_custom_pose_handle(event.position)
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			if not event.pressed and not custom_drag_handle.is_empty():
				pose_targets.update_info()
				custom_drag_handle=""
				get_viewport().set_input_as_handled()
				return
			if event.pressed and direct_pose_handles_visible():
				var handle:=pick_custom_pose_handle(event.position)
				if not handle.is_empty():
					begin_custom_pose_drag(handle,event.position,event.shift_pressed)
					get_viewport().set_input_as_handled()
					return
	if is_instance_valid(custom_editor) and custom_editor.visible and event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				take_camera_control()
				camera_mouse_origin=event.position
				camera_dragging=true
				Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
			else:
				stop_camera_drag()
			get_viewport().set_input_as_handled()
			return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			take_camera_control()
			inspection_camera.zoom(1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1)
			inspection_camera.apply(field.camera)
			get_viewport().set_input_as_handled()
			return
	if not custom_recording:super._input(event)

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
