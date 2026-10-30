extends "res://scripts/battle_arena.gd"
## Story's first encounter: the newly created character must survive a duel.
const DEFAULT_SPELL_AIM_LIFT := PI / 6.0
var survive_label: Label
var main_menu_button: Button
var punch_aim_button: Button
var punch_aim_overlay: Control
var punch_aim_panel: PanelContainer
var punch_aim_status: Label
var punch_calibration_done_button: Button
var punch_capture_hint: Label
var punch_capture_center: Label
var punch_capture_shade: ColorRect
var punch_capture_cursor_marker: MeshInstance3D
var facing_direction_line: MeshInstance3D
var facing_direction_line_visible:=false
var punch_capture_side := ""
var punch_capture_recording := false
var calibration_aim_guide_visible := false
var punch_capture_index := 0
var punch_capture_clock := 0.0
var punch_capture_repeat := 0
var punch_capture_samples: Dictionary = {"left":[],"right":[]}
var punch_capture_working_samples: Array = []
var punch_capture_saved_round_active := false
var punch_capture_brain_states: Array[bool] = []
var calibration_mode := false
var direct_calibration_mode := false
var calibration_request: Dictionary = {}
var calibration_spell_previews: Array[Dictionary] = []
const PUNCH_AIM_DIRECTIONS: Array[Dictionary] = [
	{"name":"TOP LEFT","yaw":-0.44,"pitch":0.20},
	{"name":"TOP","yaw":0.0,"pitch":0.28},
	{"name":"TOP RIGHT","yaw":0.44,"pitch":0.20},
	{"name":"LEFT","yaw":-0.62,"pitch":0.0},
	{"name":"CENTER","yaw":0.0,"pitch":0.0},
	{"name":"RIGHT","yaw":0.62,"pitch":0.0},
	{"name":"BOTTOM LEFT","yaw":-0.44,"pitch":-0.20},
	{"name":"BOTTOM","yaw":0.0,"pitch":-0.28},
	{"name":"BOTTOM RIGHT","yaw":0.44,"pitch":-0.20}
]
var return_button: Button
var chat_panel: PanelContainer
var chat_entry: LineEdit
var profanity_filter := RegEx.new()
var last_forward_press := -10.0
var mouse_left_down := false
var mouse_right_down := false
var mouse_middle_down := false
var mouse_block_active := false
var pending_mouse_punch := ""
var mouse_punch_token := 0
var mouse_down_position := Vector2.ZERO
var camera_drag_active := false
var mouse_press_times := {"left":0.0,"right":0.0}
var held_story_key_inputs:Dictionary={}
var held_story_mouse_inputs:Dictionary={}
var held_charge_inputs: Dictionary = {}
var charge_hint: Label
var charge_ring: MeshInstance3D
var rival_charge_rings: Array[MeshInstance3D] = []
var charge_elapsed_total := 0.0
var charge_ring_last_signature := ""
var post_fight_slowmo := false
var post_fight_timer := 0.0
var post_fight_freeplay := false
var replay_mode := false
var replay_data: Dictionary = {}
var replay_elapsed := 0.0
var replay_sample_clock := 0.0
var replay_samples: Array[Dictionary] = []
var replay_save_button: Button
var replay_play_button: Button
var replay_seek: HSlider
var replay_duration := 0.0
var replay_playing := true
var replay_sample_period := 0.10
var fight_won := false
var training_mode := false
var training_complete := false
var training_lesson := 1
var tutorial_phase := 0
var tutorial_phase_hits := 0
var tutorial_phase_hit_start := 0
var calibration_zone_index := 0
var calibration_zone_targets: Dictionary = {}
var calibration_zone_observations: Array[Dictionary] = []
var calibration_zone_angles: Dictionary = {}

func is_post_fight_freeplay() -> bool:
	return post_fight_freeplay
var calibration_dummy_roots: Array[Node3D] = []
var calibration_punch_repeat_timer := 0.0
const CALIBRATION_ZONES := ["head", "body", "leg"]
const CALIBRATION_DUMMY_ORDER := [1, 2, 3]
const CALIBRATION_DUMMY_NAMES := ["LEFT DUMMY", "CENTER DUMMY", "RIGHT DUMMY"]
const CALIBRATION_PUNCH_REPEAT_INTERVAL := 0.62
var tutorial_focus_target: CharacterBody3D
var target_marker: Label3D
var hovered_fighter: CharacterBody3D
var selected_fighter: CharacterBody3D
var fighter_selection_rings: Dictionary = {}
var mouse_cursor: Control
var keyboard_aim_enabled := false
var keyboard_aim_position := Vector2.ZERO

func _aim_screen_position() -> Vector2:
	return keyboard_aim_position if keyboard_aim_enabled else get_viewport().get_mouse_position()

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	# The custom, high-contrast cursor is rendered over the 3D fight view.
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:
		set_process(false)
		set_physics_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/story_character_creator.tscn")
		return
	var saved_profile: Variant = config.get_value("character", "profile", {})
	if not saved_profile is Dictionary or saved_profile.is_empty():
		set_process(false)
		set_physics_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/story_character_creator.tscn")
		return
	story_mode = true
	training_mode = bool(get_tree().get_meta("story_punch_tutorial", false))
	training_lesson = clampi(int(get_tree().get_meta("story_tutorial_lesson", 1)), 1, 2)
	direct_calibration_mode=OS.get_cmdline_user_args().has("--calibration-grid")
	calibration_aim_guide_visible=direct_calibration_mode
	if get_tree().has_meta("story_punch_tutorial"):
		get_tree().remove_meta("story_punch_tutorial")
	if get_tree().has_meta("story_tutorial_lesson"):
		get_tree().remove_meta("story_tutorial_lesson")
	if get_tree().has_meta("story_calibration_request"):
		var request_value:Variant=get_tree().get_meta("story_calibration_request",{})
		calibration_request=request_value.duplicate(true) if request_value is Dictionary else {}
		get_tree().remove_meta("story_calibration_request")
		calibration_mode=not calibration_request.is_empty()
	replay_mode = get_tree().has_meta("story_replay_data")
	if replay_mode:
		var stored: Variant = get_tree().get_meta("story_replay_data", {})
		replay_data = stored.duplicate(true) if stored is Dictionary else {}
		get_tree().remove_meta("story_replay_data")
		replay_duration = float(replay_data.get("duration", 0.0))
		story_stage = clampi(int(replay_data.get("fight", 1)), 1, 5)
	story_profile = saved_profile.duplicate(true)
	if direct_calibration_mode and not calibration_mode:
		_ensure_standalone_calibration_gear()
		calibration_request=_standalone_calibration_request()
		calibration_mode=not calibration_request.is_empty()
	if direct_calibration_mode and calibration_mode:
		calibration_request["return_scene"]=""
	if training_mode:
		story_profile["wardrobe_hat"] = "None"
		story_profile["wardrobe_mask"] = "None"
		story_profile["wardrobe_back"] = "None"
	story_stage = 1 if training_mode else clampi(int(get_tree().get_meta("story_fight_stage", story_profile.get("story_stage", 1))), 1, 5)
	if replay_mode: story_stage = clampi(int(replay_data.get("fight", story_stage)), 1, 5)
	if get_tree().has_meta("story_fight_stage"):
		get_tree().remove_meta("story_fight_stage")
	story_profile["story_stage"] = story_stage
	if story_mode and not training_mode and not replay_mode and not calibration_mode and not _profile_has_equipped_spell(story_profile):
		get_tree().set_meta("story_selected_chapter", story_stage)
		GameDiagnostics.log_event("story_fight_blocked_no_equipped_spell", {"fighter":story_profile.get("name", ""), "fight":story_stage})
		get_tree().call_deferred("change_scene_to_file", "res://scenes/story_opponents.tscn")
		return
	GameDiagnostics.log_event("punch_tutorial_start", {"fighter":story_profile.get("name", "")}) if training_mode else GameDiagnostics.log_event("story_fight_start", {"fighter":story_profile.get("name", ""), "fight":story_stage, "opponent":StoryRivals.name_for_stage(story_stage), "abilities":story_profile.get("combat_abilities", []), "hotkeys":story_profile.get("combat_hotkeys", {})})
	profanity_filter.compile("(?i)\\b(fuck\\w*|shit\\w*|bitch\\w*|asshole\\w*|cunt\\w*|dick\\w*|piss\\w*|damn\\w*|bastard\\w*|hell)\\b")
	super._ready()
	_build_target_marker()
	_build_fighter_selection_rings()
	_build_mouse_cursor()
	_build_calibration_cursor_marker()

	if training_mode and fighters.size() > 1:
		var receiver=fighters[1]
		receiver.brain_enabled = false
		receiver.player_controlled = false
		receiver.practice_immortal = true
		receiver.story_profile["name"] = "Trainer"
		receiver.story_profile["combat_abilities"] = []
		receiver.set_meta("hide_overhead_tag",false)
		var receiver_model:Variant=receiver.get("model")
		if receiver_model is Node3D:receiver_model.visible=true
		_disable_training_hurtboxes(receiver)
		_build_training_dummy(2,receiver)
		_show_trainer_prompt(receiver)
		fighters[0].story_torso_calibration_yaw = 0.0
		fighters[0].story_torso_calibration_pitch = 0.0
		camera_focus_target = null
		tutorial_focus_target = receiver
		tutorial_phase = 0 if training_lesson == 1 else 1
		_build_calibration_cursor_marker()
	if calibration_mode:
		_prepare_calibration_arena()
		call_deferred("_start_direct_aim_preview")
	if replay_mode:
		warmup = 0.0
		round_active = false
		for fighter in fighters:
			fighter.brain_enabled = false
			fighter.player_controlled = false
			fighter.editor_pose_locked = true
		GameDiagnostics.log_event("replay_viewer_open", {"fight":story_stage,"frames":replay_data.get("samples",[]).size()})

func _profile_has_equipped_spell(profile:Dictionary) -> bool:
	var equipped:Dictionary=profile.get("story_part_gear",{})
	var gear_items:Array=profile.get("gear_inventory",[])
	for part_id in equipped:
		var gear_id:=str(equipped[part_id])
		for item in gear_items:
			if not item is Dictionary or str(item.get("id", ""))!=gear_id:continue
			if str(part_id)=="left_arm" and item.get("native_animations", []).has("punch_left"):return true
			for pair in item.get("animation_slots",[]):
				if not pair is Dictionary or str(pair.get("animation", "")).is_empty():continue
				if str(part_id)=="left_arm" and str(pair.get("animation", ""))=="punch_left":return true
				var spell_ids:Variant=pair.get("spell_ids",[])
				if _contains_spell_id(spell_ids):return true
				if not str(pair.get("spell_id", "")).is_empty():return true
			for linked in item.get("crystal_links", {}).values():
				if _contains_spell_id(linked):return true
	return false

func _contains_spell_id(value:Variant) -> bool:
	if value is Array:return not value.is_empty()
	if value is Dictionary:return _contains_spell_id(value.get("spell_ids", []))
	return not str(value).is_empty()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_target_marker() -> void:
	target_marker=Label3D.new()
	target_marker.name="FocusedTargetDiamond"
	target_marker.text="◆"
	target_marker.font_size=32
	target_marker.pixel_size=0.010
	target_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	target_marker.no_depth_test=true
	target_marker.modulate=Color("ffd166")
	target_marker.outline_size=7
	target_marker.outline_modulate=Color("20202a")
	target_marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	target_marker.visible=false
	add_child(target_marker)

func _update_target_marker() -> void:
	if not is_instance_valid(target_marker):return
	if not is_instance_valid(camera_focus_target) or camera_focus_target.health<=0:
		target_marker.visible=false
		return
	var anchor:Vector3=camera_focus_target.global_position+Vector3.UP*2.2
	if camera_focus_target.has_method("overhead_tag_position"):
		anchor=camera_focus_target.overhead_tag_position()
	target_marker.global_position=anchor+Vector3.UP*0.48
	target_marker.visible=true

func _process(delta:float) -> void:
	if not punch_capture_side.is_empty():
		punch_capture_clock-=delta
		if punch_capture_clock<=0.0:
			punch_capture_repeat+=1
			punch_capture_clock=0.82
			_play_punch_calibration_preview()
			_update_punch_capture_hint()
	_advance_calibration_spell_previews(delta)
	_update_calibration_cursor_marker()
	_update_facing_direction_line()
	if is_instance_valid(mouse_cursor):mouse_cursor.position=_aim_screen_position()
	var pointed:=_fighter_under_mouse()
	if pointed!=hovered_fighter:
		hovered_fighter=pointed
		GameDiagnostics.log_event("fighter_hover",{"fighter":hovered_fighter.story_profile.get("name","") if is_instance_valid(hovered_fighter) else ""})
	_refresh_fighter_selection_rings()

func _build_fighter_selection_rings() -> void:
	fighter_selection_rings.clear()
	for fighter in fighters:
		var ring:=MeshInstance3D.new()
		var torus:=TorusMesh.new()
		torus.inner_radius=0.53
		torus.outer_radius=0.64
		torus.rings=8
		torus.ring_segments=32
		ring.mesh=torus
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled=true
		material.emission_energy_multiplier=1.35
		material.no_depth_test=true
		material.albedo_color=Color(0.40,0.83,1.0,0.72)
		material.emission=Color("55cfff")
		ring.material_override=material
		ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.name="FighterSelectionAura_%d" % fighter.team
		ring.visible=false
		add_child(ring)
		fighter_selection_rings[fighter]=ring

func _refresh_fighter_selection_rings() -> void:
	for fighter in fighter_selection_rings:
		var ring:MeshInstance3D=fighter_selection_rings[fighter]
		if not is_instance_valid(fighter) or not is_instance_valid(ring):continue
		var is_selected:bool=fighter==selected_fighter
		var is_hovered:bool=fighter==hovered_fighter
		ring.visible=(is_selected or is_hovered) and fighter.health>0
		if not ring.visible:continue
		ring.global_position=fighter.global_position+Vector3.UP*0.055
		var material:=ring.material_override as StandardMaterial3D
		var color:=Color("ffd166") if is_selected else Color("70dfff")
		material.albedo_color=Color(color.r,color.g,color.b,0.86 if is_selected else 0.68)
		material.emission=color

func _select_fighter_from_mouse() -> void:
	var pointed:=_fighter_under_mouse()
	if not is_instance_valid(pointed):return
	selected_fighter=pointed
	GameDiagnostics.log_event("fighter_selected",{"fighter":pointed.story_profile.get("name",""),"focused":pointed==camera_focus_target})
	_refresh_fighter_selection_rings()

func _build_mouse_cursor() -> void:
	var cursor_layer:=CanvasLayer.new()
	cursor_layer.layer=120
	add_child(cursor_layer)
	mouse_cursor=preload("res://scripts/fight_cursor.gd").new()
	mouse_cursor.name="FightMouseCursor"
	mouse_cursor.size=Vector2(24,32)
	mouse_cursor.z_index=1000
	cursor_layer.add_child(mouse_cursor)

func build_fight_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	survive_label = Label.new()
	survive_label.text = ("TASK 1  ·  HIT TRAINER  ·  0 / 5\nLEFT MOUSE: JAB  ·  WASD: MOVE" if training_lesson == 1 else "TASK 2  ·  TARGET TRAINER, THEN HIT  ·  0 / 5\nCLICK TRAINER, PRESS F, THEN LEFT MOUSE") if training_mode else "Goal: Survive"
	if training_mode:
		survive_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		survive_label.offset_left=24
		survive_label.offset_top=118
		survive_label.offset_right=500
		survive_label.offset_bottom=190
		survive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		survive_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		survive_label.offset_top = 22
		survive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	survive_label.add_theme_font_size_override("font_size", 20 if training_mode else 30)
	survive_label.add_theme_color_override("font_color", Color("f1f3f4"))
	survive_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	survive_label.add_theme_constant_override("shadow_offset_x", 2)
	survive_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(survive_label)
	survive_label.visible=not calibration_mode
	charge_hint=Label.new()
	charge_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	charge_hint.offset_left=-270
	charge_hint.offset_right=270
	charge_hint.offset_top=-144
	charge_hint.offset_bottom=-84
	charge_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	charge_hint.add_theme_font_size_override("font_size",16)
	charge_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	charge_hint.visible=false
	root.add_child(charge_hint)
	charge_ring=MeshInstance3D.new()
	charge_ring.name="ChargeTimingRing"
	var ring_material:=StandardMaterial3D.new()
	ring_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.vertex_color_use_as_albedo=true
	ring_material.no_depth_test=true
	charge_ring.material_override=ring_material
	charge_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(charge_ring)
	charge_ring.visible=false
	_update_charge_ring(0.0,Color("aab2bb"))
	rival_charge_rings.clear()
	for fighter_index in range(1,fighters.size()):
		var rival_ring:=MeshInstance3D.new()
		rival_ring.name="RivalChargeTimingRing_%d" % fighter_index
		rival_ring.material_override=ring_material.duplicate()
		rival_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rival_ring.visible=false
		rival_ring.set_meta("ring_signature","")
		add_child(rival_ring)
		rival_charge_rings.append(rival_ring)
	main_menu_button=Button.new()
	main_menu_button.text="MAIN MENU"
	main_menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main_menu_button.offset_left=26
	main_menu_button.offset_top=24
	main_menu_button.offset_right=196
	main_menu_button.offset_bottom=72
	main_menu_button.focus_mode=Control.FOCUS_NONE
	main_menu_button.pressed.connect(_go_to_main_menu)
	main_menu_button.visible=not calibration_mode
	root.add_child(main_menu_button)
	if calibration_mode:_build_punch_aim_calibration(root)
	_build_chat_input(root)
	return_button = Button.new()
	return_button.text = "READY FOR YOUR FIRST FIGHT" if training_mode else "Back to fight board"
	return_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	return_button.offset_left = -150
	return_button.offset_right = 150
	return_button.offset_top = -158
	return_button.offset_bottom = -98
	return_button.visible = false
	return_button.pressed.connect(_leave_result)
	root.add_child(return_button)
	if replay_mode:
		_build_replay_controls(root)
	else:
		replay_save_button = Button.new()
		replay_save_button.text = "SAVE REPLAY"
		replay_save_button.custom_minimum_size = Vector2(170, 48)
		replay_save_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		replay_save_button.offset_left = -88
		replay_save_button.offset_right = 88
		replay_save_button.offset_top = -222
		replay_save_button.offset_bottom = -168
		replay_save_button.visible = false
		replay_save_button.pressed.connect(_save_replay)
		root.add_child(replay_save_button)
	if is_instance_valid(punch_aim_overlay):punch_aim_overlay.move_to_front()

func _go_to_main_menu() -> void:
	GameDiagnostics.log_event("fight_quit_to_main_menu", {"training":training_mode,"replay":replay_mode,"fight":story_stage})
	get_tree().paused=false
	Engine.time_scale=1.0
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func _build_punch_aim_calibration(root:Control)->void:
	punch_aim_overlay=Control.new()
	punch_aim_overlay.name="PunchAimCalibration"
	punch_aim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	punch_aim_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	punch_aim_overlay.visible=calibration_mode
	root.add_child(punch_aim_overlay)
	punch_capture_shade=ColorRect.new()
	punch_capture_shade.color=Color(0.015,0.025,0.04,0.0)
	punch_capture_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	punch_capture_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	punch_aim_overlay.add_child(punch_capture_shade)
	punch_capture_hint=Label.new()
	punch_capture_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	punch_capture_hint.offset_left=-420
	punch_capture_hint.offset_right=420
	punch_capture_hint.offset_top=62
	punch_capture_hint.offset_bottom=116
	punch_capture_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	punch_capture_hint.add_theme_font_size_override("font_size",22)
	punch_capture_hint.add_theme_color_override("font_color",Color("fff0c4"))
	punch_capture_hint.text="AIM CALIBRATION  ·  Move your cursor over the arena. The gold circle marks the ground point."
	punch_capture_hint.visible=direct_calibration_mode
	punch_aim_overlay.add_child(punch_capture_hint)
	punch_capture_center=Label.new()
	punch_capture_center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	punch_capture_center.offset_left=-28
	punch_capture_center.offset_right=28
	punch_capture_center.offset_top=-28
	punch_capture_center.offset_bottom=28
	punch_capture_center.text="⊕"
	punch_capture_center.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	punch_capture_center.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	punch_capture_center.add_theme_font_size_override("font_size",38)
	punch_capture_center.add_theme_color_override("font_color",Color("fff0c4"))
	punch_capture_center.add_theme_color_override("font_shadow_color",Color(0,0,0,0.9))
	punch_capture_center.add_theme_constant_override("shadow_offset_x",2)
	punch_capture_center.add_theme_constant_override("shadow_offset_y",2)
	punch_capture_center.mouse_filter=Control.MOUSE_FILTER_IGNORE
	punch_capture_center.visible=false
	punch_aim_overlay.add_child(punch_capture_center)
	punch_aim_panel=PanelContainer.new()
	punch_aim_panel.custom_minimum_size=Vector2(540,0)
	punch_aim_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	punch_aim_panel.offset_left=-270
	punch_aim_panel.offset_right=270
	punch_aim_panel.offset_top=-190
	punch_aim_panel.offset_bottom=190
	var panel_style:=StyleBoxFlat.new()
	panel_style.bg_color=Color("111c29")
	panel_style.border_color=Color("617a90")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	punch_aim_panel.add_theme_stylebox_override("panel",panel_style)
	punch_aim_panel.visible=not direct_calibration_mode
	punch_aim_overlay.add_child(punch_aim_panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,22)
	punch_aim_panel.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	margin.add_child(column)
	var title:=Label.new()
	title.text="CALIBRATE ACTION"
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("e9c982"))
	column.add_child(title)
	var instruction:=Label.new()
	var linked_names:=_calibration_spell_names()
	var action_summary:="%s  ·  %s"%[_animation_display_name(str(calibration_request.get("animation","Action"))),_calibration_input_name(str(calibration_request.get("input","")))]
	if not linked_names.is_empty():action_summary+="  ·  "+", ".join(linked_names)
	instruction.text="%s\nThe animation repeats in nine directions. Click where its contact should land; linked spells follow the same aim map."%action_summary
	instruction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_font_size_override("font_size",17)
	instruction.add_theme_color_override("font_color",Color("b8c8d5"))
	column.add_child(instruction)
	punch_aim_status=Label.new()
	punch_aim_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	punch_aim_status.add_theme_font_size_override("font_size",15)
	punch_aim_status.add_theme_color_override("font_color",Color("9ed9ff"))
	column.add_child(punch_aim_status)
	_update_punch_aim_status()
	var footer:=HBoxContainer.new()
	footer.add_theme_constant_override("separation",10)
	column.add_child(footer)
	var start:=Button.new()
	start.text="START CALIBRATION"
	start.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	start.custom_minimum_size.y=48
	start.pressed.connect(_arm_punch_contact_capture)
	footer.add_child(start)
	punch_calibration_done_button=Button.new()
	punch_calibration_done_button.text="DONE  ·  RETURN"
	punch_calibration_done_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	punch_calibration_done_button.disabled=_stored_calibration_samples().size()!=PUNCH_AIM_DIRECTIONS.size()
	punch_calibration_done_button.pressed.connect(_close_punch_aim_calibration)
	footer.add_child(punch_calibration_done_button)

func _load_punch_aim_settings()->void:
	# Aim maps live on their gear's animation slot and travel with the character profile.
	punch_capture_samples["active"]=_stored_calibration_samples()

func _stored_calibration_samples()->Array:
	var gear_id:=str(calibration_request.get("gear_id",""))
	var slot_index:=int(calibration_request.get("slot_index",-1))
	for item in story_profile.get("gear_inventory",[]):
		if not item is Dictionary or str(item.get("id",""))!=gear_id:continue
		var slots:Array=item.get("animation_slots",[])
		if slot_index>=0 and slot_index<slots.size():return slots[slot_index].get("aim_samples",[]).duplicate(true)
	return calibration_request.get("aim_samples",[]).duplicate(true)

func _save_punch_aim_settings()->void:
	var gear_id:=str(calibration_request.get("gear_id",""))
	var slot_index:=int(calibration_request.get("slot_index",-1))
	var inventory:Array=story_profile.get("gear_inventory",[])
	for item_index in range(inventory.size()):
		if not inventory[item_index] is Dictionary or str(inventory[item_index].get("id",""))!=gear_id:continue
		var item:Dictionary=inventory[item_index]
		var slots:Array=item.get("animation_slots",[])
		if slot_index<0 or slot_index>=slots.size():break
		var animation_slot:Dictionary=slots[slot_index]
		animation_slot["aim_samples"]=punch_capture_working_samples.duplicate(true)
		slots[slot_index]=animation_slot
		item["animation_slots"]=slots
		inventory[item_index]=item
		story_profile["gear_inventory"]=inventory
		var config:=ConfigFile.new()
		if config.load("user://story_character.cfg")!=OK:break
		config.set_value("character","profile",story_profile)
		var result:=config.save("user://story_character.cfg")
		if result!=OK:push_warning("Could not save action calibration: %s"%error_string(result))
		var roster:=ConfigFile.new()
		if roster.load("user://story_characters.cfg")==OK:
			var characters:Array=roster.get_value("roster","characters",[])
			for index in range(characters.size()):
				if characters[index] is Dictionary and str(characters[index].get("character_id",""))==str(story_profile.get("character_id","")):
					characters[index]=story_profile.duplicate(true)
					break
			roster.set_value("roster","characters",characters)
			roster.save("user://story_characters.cfg")
		return
	push_warning("Could not find equipped gear slot to save action calibration.")

func _animation_display_name(animation_id:String)->String:
	return {"punch_left":"Left punch","punch_right":"Right punch","front_kick":"Front kick","block":"Block","dash":"Dash"}.get(animation_id,animation_id.replace("_"," ").capitalize())

func _calibration_input_name(input_id:String)->String:
	if input_id.begins_with("mouse_"):return input_id.trim_prefix("mouse_").replace("_"," ").to_upper()+" CLICK"
	if input_id.begins_with("key_"):return input_id.trim_prefix("key_").replace("_"," ").to_upper()
	return "ACTION INPUT"

func _calibration_emitter(animation_id:String)->String:
	return {"punch_left":"hand_l","punch_right":"hand_r","front_kick":"foot_r","block":"both","dash":"hand_r"}.get(animation_id,"hand_r")

func _calibration_spell_names()->Array[String]:
	var names:Array[String]=[]
	var ids:Array=calibration_request.get("spell_ids",[])
	var spells:Array=story_profile.get("spell_inventory",story_profile.get("crystal_inventory",[]))
	for id in ids:
		for spell in spells:
			if spell is Dictionary and str(spell.get("id",""))==str(id):
				names.append(str(spell.get("spell",spell.get("name","Spell"))))
	return names

func _tutorial_left_punch_calibration_request()->Dictionary:
	var equipped:Dictionary=story_profile.get("story_part_gear",{})
	var gear_id:=str(equipped.get("left_arm",""))
	for item in story_profile.get("gear_inventory",[]):
		if not item is Dictionary or str(item.get("id",""))!=gear_id:continue
		var slots:Array=item.get("animation_slots",[])
		for index in range(slots.size()):
			var animation_slot:Dictionary=slots[index]
			if str(animation_slot.get("animation",""))=="punch_left":
				return {"gear_id":gear_id,"part":"left_arm","slot_index":index,"animation":"punch_left","spell_ids":animation_slot.get("spell_ids",[]),"input":animation_slot.get("input","mouse_left"),"return_scene":"","character_id":str(story_profile.get("character_id","")),"aim_samples":animation_slot.get("aim_samples",[])}
	return {"gear_id":gear_id,"part":"left_arm","slot_index":-1,"animation":"punch_left","spell_ids":[],"input":"mouse_left","return_scene":"","character_id":str(story_profile.get("character_id","")),"aim_samples":[]}

func _standalone_calibration_request()->Dictionary:
	var left_punch:=_tutorial_left_punch_calibration_request()
	if int(left_punch.get("slot_index",-1))>=0:return left_punch
	var equipped:Dictionary=story_profile.get("story_part_gear",{})
	for part_id in equipped:
		var gear_id:=str(equipped[part_id])
		for item in story_profile.get("gear_inventory",[]):
			if not item is Dictionary or str(item.get("id",""))!=gear_id:continue
			var slots:Array=item.get("animation_slots",[])
			for index in range(slots.size()):
				var pair:Dictionary=slots[index]
				var animation_id:=str(pair.get("animation",""))
				if animation_id.is_empty():continue
				return {"gear_id":gear_id,"part":str(part_id),"slot_index":index,"animation":animation_id,"spell_ids":pair.get("spell_ids",[]),"input":pair.get("input",_default_calibration_input(animation_id)),"return_scene":"","character_id":str(story_profile.get("character_id","")),"aim_samples":pair.get("aim_samples",[])}
	return left_punch

func _ensure_standalone_calibration_gear()->void:
	var equipped:Dictionary=story_profile.get("story_part_gear",{}).duplicate(true)
	var inventory:Array=story_profile.get("gear_inventory",[]).duplicate(true)
	for gear_id_value in equipped.values():
		for item in inventory:
			if not item is Dictionary or str(item.get("id",""))!=str(gear_id_value):continue
			for pair in item.get("animation_slots",[]):
				if str(pair.get("animation",""))=="punch_left":return
	var starter_id:="starter_left_arm"
	var starter_index:=-1
	for index in range(inventory.size()):
		if inventory[index] is Dictionary and str(inventory[index].get("id",""))==starter_id:
			starter_index=index
			break
	var starter:Dictionary={"id":starter_id,"name":"Equipped left arm","part":"left_arm","slot":"Left arm","rarity":1,"appearance":{},"native_animations":["punch_left"],"crystal_links":{},"animation_slots":[{"animation":"punch_left","spell_ids":[],"spell_id":"","input":"mouse_left","aim_samples":[]}]}
	if starter_index<0:inventory.append(starter)
	else:inventory[starter_index]=starter
	equipped["left_arm"]=starter_id
	story_profile["story_part_gear"]=equipped
	story_profile["gear_inventory"]=inventory
	var config:=ConfigFile.new()
	if config.load("user://story_character.cfg")==OK:
		config.set_value("character","profile",story_profile)
		config.save("user://story_character.cfg")
	GameDiagnostics.log_event("calibration_starter_gear_ready",{"gear":starter_id,"animation":"punch_left"})

func _default_calibration_input(animation_id:String)->String:
	return {"punch_left":"mouse_left","punch_right":"mouse_right","block":"mouse_both","front_kick":"key_1","dash":"key_2"}.get(animation_id,"key_1")

func _hide_calibration_opponent(actor:CharacterBody3D)->void:
	if not actor.has_meta("calibration_collision_layer"):actor.set_meta("calibration_collision_layer",actor.collision_layer)
	if not actor.has_meta("calibration_collision_mask"):actor.set_meta("calibration_collision_mask",actor.collision_mask)
	actor.visible=false
	actor.collision_layer=0
	actor.collision_mask=0
	actor.brain_enabled=false
	for child in actor.get_children():
		if child is Label3D:child.visible=false

func _prepare_calibration_arena()->void:
	round_active=false
	warmup=0
	intermission=0
	for index in range(1,fighters.size()):_hide_calibration_opponent(fighters[index])
	if is_instance_valid(main_menu_button):main_menu_button.visible=false
	if is_instance_valid(return_button):return_button.visible=false
	if is_instance_valid(punch_aim_overlay):punch_aim_overlay.visible=true
	_build_calibration_cursor_marker()
	camera_zoom=0.92
	GameDiagnostics.log_event("action_calibration_arena_ready",{"animation":calibration_request.get("animation",""),"gear":calibration_request.get("gear_id",""),"spells":calibration_request.get("spell_ids",[])})

func _start_direct_aim_preview()->void:
	if fighters.is_empty() or not calibration_mode:return
	punch_capture_side=str(calibration_request.get("animation","punch_left"))
	punch_capture_clock=0.82
	punch_capture_hint.visible=true
	punch_capture_hint.text="LIVE AIM PREVIEW  ·  DEFAULT PUNCH ANIMATION  ·  F1 TOGGLE FACING LINE\nMove the cursor to aim spells; middle-drag orbits; wheel zooms." if direct_calibration_mode else "LIVE AIM PREVIEW  ·  DEFAULT PUNCH ANIMATION  ·  F1 TOGGLE FACING LINE\nMove the cursor to aim spells; ESC returns to loadout."
	punch_capture_cursor_marker.visible=calibration_aim_guide_visible
	punch_aim_panel.visible=false
	punch_aim_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(mouse_cursor):mouse_cursor.visible=false
	_play_punch_calibration_preview()
	GameDiagnostics.log_event("action_aim_preview_started",{"animation":punch_capture_side,"recording":false,"guide_visible":calibration_aim_guide_visible})

func _arm_punch_contact_capture()->void:
	if fighters.is_empty() or not calibration_mode:return
	punch_capture_recording=true
	punch_capture_side=str(calibration_request.get("animation","action"))
	punch_capture_index=0
	punch_capture_repeat=0
	punch_capture_clock=0.0
	punch_capture_working_samples=_stored_calibration_samples()
	if punch_capture_working_samples.size()<PUNCH_AIM_DIRECTIONS.size():punch_capture_working_samples.resize(PUNCH_AIM_DIRECTIONS.size())
	punch_capture_saved_round_active=round_active
	round_active=false
	punch_capture_brain_states.clear()
	for fighter in fighters:
		punch_capture_brain_states.append(fighter.brain_enabled)
		fighter.brain_enabled=false
		fighter.velocity=Vector3.ZERO
		fighter.drive_velocity=Vector3.ZERO
	punch_aim_panel.visible=false
	punch_capture_shade.color=Color(0,0,0,0)
	punch_capture_cursor_marker.visible=true
	punch_capture_hint.visible=true
	punch_capture_center.visible=false
	punch_aim_overlay.visible=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(mouse_cursor):mouse_cursor.visible=false
	_play_punch_calibration_preview()
	_update_punch_capture_hint()
	GameDiagnostics.log_event("action_direction_sequence_started",{"animation":punch_capture_side,"directions":PUNCH_AIM_DIRECTIONS.size()})

func _play_punch_calibration_preview()->void:
	if punch_capture_side.is_empty() or fighters.is_empty():return
	var actor=fighters[0]
	var emitter:=_calibration_emitter(punch_capture_side)
	if emitter=="both":emitter="hand_l"
	var aim:Vector3=punch_capture_cursor_marker.global_position-fighter_hand(actor,emitter) if is_instance_valid(punch_capture_cursor_marker) else actor.global_basis.z
	var local_aim:Vector3=(actor.global_basis.inverse()*aim.normalized()).normalized()
	var yaw:=atan2(local_aim.x,local_aim.z)
	var pitch:=atan2(local_aim.y,sqrt(local_aim.x*local_aim.x+local_aim.z*local_aim.z))
	if punch_capture_side in ["punch_left","punch_right"]:
		actor.preview_story_animation(punch_capture_side,0.0,0.0)
	else:
		actor.preview_story_animation(punch_capture_side,yaw,pitch)
	_spawn_calibration_spell_preview(yaw,pitch)

func _update_punch_capture_hint()->void:
	if punch_capture_side.is_empty() or not is_instance_valid(punch_capture_hint):return
	if not punch_capture_recording:
		var controls_hint:=" Middle-drag orbits; wheel zooms." if direct_calibration_mode else " ESC returns to loadout."
		punch_capture_hint.text="LIVE AIM PREVIEW  ·  DEFAULT PUNCH ANIMATION  ·  F1 TOGGLE FACING LINE\nMove the cursor to aim spells; target stays in front.%s"%controls_hint
		return
	punch_capture_hint.text="%s  ·  AIM POINT %d / %d  ·  LOOP %d\nMove the gold ring to the intended contact point. Click to save  ·  ESC cancels"%[_animation_display_name(punch_capture_side).to_upper(),punch_capture_index+1,PUNCH_AIM_DIRECTIONS.size(),punch_capture_repeat+1]

func _spawn_calibration_spell_preview(yaw:float,pitch:float)->void:
	if fighters.is_empty():return
	var ids:Array=calibration_request.get("spell_ids",[])
	if ids.is_empty():return
	var local_direction:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	var world_direction:Vector3=(fighters[0].global_basis*local_direction).normalized()
	var inventory:Array=story_profile.get("spell_inventory",story_profile.get("crystal_inventory",[]))
	for spell_id in ids:
		for spell in inventory:
			if not spell is Dictionary or str(spell.get("id",""))!=str(spell_id):continue
			var node:=MeshInstance3D.new()
			var orb:=SphereMesh.new()
			orb.radius=0.15
			orb.height=0.30
			orb.radial_segments=14
			orb.rings=8
			node.mesh=orb
			var material:=StandardMaterial3D.new()
			material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			material.emission_enabled=true
			var spell_color:Color=spell.get("color",Color("ff774c"))
			material.albedo_color=spell_color
			material.emission=spell_color
			material.emission_energy_multiplier=2.0
			node.material_override=material
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(node)
			var hand:=str(spell.get("hand",""))
			if hand not in ["hand_l","hand_r","foot_l","foot_r"]:hand=_calibration_emitter(punch_capture_side)
			node.global_position=fighter_hand(fighters[0],hand)+world_direction*0.22
			calibration_spell_previews.append({"node":node,"direction":world_direction,"age":0.0,"spell":spell_id})

func _advance_calibration_spell_previews(delta:float)->void:
	for index in range(calibration_spell_previews.size()-1,-1,-1):
		var preview:Dictionary=calibration_spell_previews[index]
		var node:MeshInstance3D=preview.get("node")
		if not is_instance_valid(node):calibration_spell_previews.remove_at(index);continue
		preview.age=float(preview.age)+delta
		node.global_position+=Vector3(preview.direction)*delta*8.0
		node.scale=Vector3.ONE*(1.0+float(preview.age)*0.3)
		if float(preview.age)>=0.9:
			node.queue_free()
			calibration_spell_previews.remove_at(index)
		else:calibration_spell_previews[index]=preview

func _restore_after_punch_calibration()->void:
	punch_capture_side=""
	punch_capture_recording=false
	punch_capture_working_samples.clear()
	if not fighters.is_empty():
		fighters[0].set_story_calibration_aim(Vector3.ZERO,false)
		fighters[0].clear_story_animation_preview()
	for spell_preview in calibration_spell_previews:
		var preview_node:MeshInstance3D=spell_preview.get("node")
		if is_instance_valid(preview_node):preview_node.queue_free()
	calibration_spell_previews.clear()
	round_active=punch_capture_saved_round_active
	for index in range(mini(fighters.size(),punch_capture_brain_states.size())):
		fighters[index].brain_enabled=punch_capture_brain_states[index]
	punch_capture_brain_states.clear()
	punch_capture_cursor_marker.visible=direct_calibration_mode
	punch_capture_hint.visible=direct_calibration_mode
	punch_capture_center.visible=false
	punch_capture_shade.color=Color(0,0,0,0)
	punch_aim_panel.visible=not direct_calibration_mode
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(mouse_cursor):mouse_cursor.visible=false

func _cancel_punch_contact_capture()->void:
	var cancelled_animation:=punch_capture_side
	_restore_after_punch_calibration()
	_update_punch_aim_status("Calibration cancelled; saved map was kept.")
	if direct_calibration_mode:
		punch_capture_hint.text="CALIBRATION CANCELLED  ·  SAVED MAP KEPT\nMove the gold floor circle and click anywhere to try again"
	GameDiagnostics.log_event("action_direction_sequence_cancelled",{"animation":cancelled_animation})

func _update_punch_aim_status(message:String="")->void:
	if not is_instance_valid(punch_aim_status):return
	var count:=_stored_calibration_samples().size()
	var summary:="Saved map  %d / %d directions"%[count,PUNCH_AIM_DIRECTIONS.size()]
	var linked_names:=_calibration_spell_names()
	if not linked_names.is_empty():summary+="  ·  Linked: "+", ".join(linked_names)
	punch_aim_status.text=(message+"\n" if not message.is_empty() else "")+summary

func _build_calibration_cursor_marker()->void:
	if is_instance_valid(punch_capture_cursor_marker):return
	punch_capture_cursor_marker=MeshInstance3D.new()
	punch_capture_cursor_marker.name="CalibrationGroundCursor"
	var ring:=TorusMesh.new()
	ring.inner_radius=0.24
	ring.outer_radius=0.32
	ring.rings=12
	ring.ring_segments=40
	punch_capture_cursor_marker.mesh=ring
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=Color(1.0,0.77,0.25,0.92)
	material.emission_enabled=true
	material.emission=Color("ffd166")
	material.emission_energy_multiplier=1.6
	punch_capture_cursor_marker.material_override=material
	punch_capture_cursor_marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	punch_capture_cursor_marker.visible=false
	add_child(punch_capture_cursor_marker)
	var center:=MeshInstance3D.new()
	var dot:=SphereMesh.new()
	dot.radius=0.045
	dot.height=0.09
	dot.radial_segments=10
	dot.rings=6
	center.mesh=dot
	center.position.y=0.035
	center.material_override=material
	center.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	punch_capture_cursor_marker.add_child(center)

func _build_facing_direction_line()->void:
	if is_instance_valid(facing_direction_line):return
	facing_direction_line=MeshInstance3D.new()
	facing_direction_line.name="FacingDirectionGuide"
	var beam:=CylinderMesh.new()
	beam.top_radius=0.035
	beam.bottom_radius=0.035
	beam.height=1.0
	beam.radial_segments=10
	facing_direction_line.mesh=beam
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test=true
	material.emission_enabled=true
	material.albedo_color=Color("ff293f")
	material.emission=Color("ff102d")
	material.emission_energy_multiplier=2.4
	facing_direction_line.material_override=material
	facing_direction_line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	facing_direction_line.visible=false
	add_child(facing_direction_line)

func _update_facing_direction_line()->void:
	if not facing_direction_line_visible or not is_instance_valid(facing_direction_line) or fighters.is_empty():return
	var actor:CharacterBody3D=fighters[0]
	var direction:=actor.global_basis.z.normalized()
	var origin:Vector3=actor.bone_point("Head")+direction*0.12+Vector3.UP*0.045
	var line_length:=5.0
	facing_direction_line.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,direction)),origin+direction*line_length*0.5)
	facing_direction_line.scale=Vector3(1.0,line_length,1.0)
	facing_direction_line.visible=true

func _update_calibration_cursor_marker()->void:
	if replay_mode or fighters.is_empty():return
	var active_camera:=get_viewport().get_camera_3d()
	if active_camera==null:return
	var actor:CharacterBody3D=fighters[0]
	var pointer:=_punch_aim_pointer(actor,_aim_screen_position())
	var cursor_aim_point:=_cursor_aim_point(actor,pointer)
	var torso_origin:Vector3=actor.bone_point("spine_03")
	var local_aim:=actor.global_basis.inverse()*(cursor_aim_point-torso_origin)
	var horizontal_length:=Vector2(local_aim.x,local_aim.z).length()
	actor.story_torso_calibration_yaw=clampf(atan2(local_aim.x,local_aim.z),-deg_to_rad(89),deg_to_rad(89))
	actor.story_torso_calibration_pitch=clampf(-atan2(local_aim.y,maxf(0.001,horizontal_length)),-deg_to_rad(80),deg_to_rad(80))
	actor.set_story_calibration_aim(cursor_aim_point,true)
	if not is_instance_valid(punch_capture_cursor_marker):return
	var offset:Vector3=cursor_aim_point-actor.global_position
	var flat_offset:=Vector3(offset.x,0.0,offset.z)
	var forward:=actor.global_basis.z;forward.y=0.0;forward=forward.normalized()
	var right:=actor.global_basis.x;right.y=0.0;right=right.normalized()
	var forward_distance:=flat_offset.dot(forward)
	if forward_distance<0.60:flat_offset=forward*0.60+right*flat_offset.dot(right)
	if flat_offset.length()>18.0:flat_offset=flat_offset.normalized()*18.0
	punch_capture_cursor_marker.global_position=actor.global_position+flat_offset+Vector3.UP*0.045
	punch_capture_cursor_marker.visible=calibration_aim_guide_visible

func _cursor_aim_point(actor:CharacterBody3D,pointer:Vector2)->Vector3:
	var active_camera:=get_viewport().get_camera_3d()
	var facing:=actor.global_basis.z.normalized()
	var aim_plane_center:=actor.global_position+facing*1.8+Vector3.UP*1.25
	if active_camera!=null:
		var origin:=active_camera.project_ray_origin(pointer)
		var ray_direction:=active_camera.project_ray_normal(pointer).normalized()
		var denominator:=ray_direction.dot(facing)
		if denominator>0.025:
			var distance:float=(aim_plane_center-origin).dot(facing)/denominator
			if distance>0.0:
				var point:=origin+ray_direction*distance
				var local_aim:Vector3=actor.global_basis.inverse()*(point-actor.bone_point("spine_03"))
				var yaw:=clampf(atan2(local_aim.x,local_aim.z),-deg_to_rad(89),deg_to_rad(89))
				var pitch:=clampf(atan2(local_aim.y,maxf(0.001,Vector2(local_aim.x,local_aim.z).length())),-deg_to_rad(80),deg_to_rad(80))
				return actor.bone_point("spine_03")+actor.global_basis*(Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*4.0)
	return aim_plane_center

func _finish_action_calibration()->void:
	_save_punch_aim_settings()
	var animation_id:=punch_capture_side
	_restore_after_punch_calibration()
	_update_punch_aim_status("%s aim map saved."%_animation_display_name(animation_id))
	GameDiagnostics.log_event("action_calibration_saved",{"animation":animation_id,"gear":calibration_request.get("gear_id",""),"directions":PUNCH_AIM_DIRECTIONS.size(),"spells":calibration_request.get("spell_ids",[])})
	if direct_calibration_mode:
		punch_capture_hint.visible=true
		punch_capture_hint.text="AIM MAP SAVED  ·  9 / 9\nClick anywhere to calibrate again"
		punch_capture_cursor_marker.visible=true
	else:
		if is_instance_valid(punch_calibration_done_button):punch_calibration_done_button.disabled=false

func _close_punch_aim_calibration()->void:
	if not punch_capture_side.is_empty():_restore_after_punch_calibration()
	var destination:=str(calibration_request.get("return_scene","res://scenes/story_loadout.tscn"))
	if destination.is_empty():return
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(destination)

func _build_replay_controls(root: Control) -> void:
	var controls := PanelContainer.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 24
	controls.offset_right = -24
	controls.offset_top = -82
	controls.offset_bottom = -16
	root.add_child(controls)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	controls.add_child(row)
	replay_play_button = Button.new()
	replay_play_button.text = "PAUSE"
	replay_play_button.pressed.connect(func():
		replay_playing = not replay_playing
		replay_play_button.text = "PAUSE" if replay_playing else "PLAY"
	)
	row.add_child(replay_play_button)
	replay_seek = HSlider.new()
	replay_seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_seek.min_value = 0.0
	replay_seek.max_value = maxf(0.1, replay_duration)
	replay_seek.value_changed.connect(func(value: float): replay_elapsed = value)
	row.add_child(replay_seek)
	var camera_hint := Label.new()
	camera_hint.text = "DRAG TO ORBIT  ·  WHEEL TO ZOOM"
	row.add_child(camera_hint)

func _build_chat_input(root: Control) -> void:
	chat_panel=PanelContainer.new()
	chat_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	chat_panel.offset_left=-250
	chat_panel.offset_right=250
	chat_panel.offset_top=-74
	chat_panel.offset_bottom=-24
	chat_panel.visible=false
	var panel_style:=StyleBoxFlat.new()
	panel_style.bg_color=Color("172331",0.96)
	panel_style.border_color=Color("7893a7")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	chat_panel.add_theme_stylebox_override("panel",panel_style)
	root.add_child(chat_panel)
	chat_entry=LineEdit.new()
	chat_entry.placeholder_text="Type a message, then press Enter"
	chat_entry.max_length=90
	chat_entry.focus_mode=Control.FOCUS_ALL
	chat_entry.add_theme_font_size_override("font_size",18)
	chat_panel.add_child(chat_entry)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:keyboard_aim_enabled=false
	if event is InputEventKey and event.pressed and not get_viewport().gui_get_focus_owner() is LineEdit:
		if event.keycode in [KEY_KP_2,KEY_KP_4,KEY_KP_6,KEY_KP_8]:
			if not keyboard_aim_enabled:keyboard_aim_position=get_viewport().get_visible_rect().size/2
			keyboard_aim_enabled=true
			var step := 3.0 if event.shift_pressed else 18.0
			keyboard_aim_position+=Vector2(-step if event.keycode==KEY_KP_4 else (step if event.keycode==KEY_KP_6 else 0),-step if event.keycode==KEY_KP_8 else (step if event.keycode==KEY_KP_2 else 0))
			keyboard_aim_position=keyboard_aim_position.clamp(Vector2.ZERO,get_viewport().get_visible_rect().size)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN] and not fighters.is_empty():
			var selected_index := fighters.find(selected_fighter)
			selected_fighter=fighters[posmod(selected_index+(-1 if event.keycode==KEY_PAGEUP else 1),fighters.size())]
			_refresh_fighter_selection_rings()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F1:
		calibration_aim_guide_visible=not calibration_aim_guide_visible
		facing_direction_line_visible=calibration_aim_guide_visible
		if facing_direction_line_visible:_build_facing_direction_line()
		if is_instance_valid(facing_direction_line):facing_direction_line.visible=facing_direction_line_visible
		if calibration_aim_guide_visible:_build_calibration_cursor_marker()
		if is_instance_valid(punch_capture_cursor_marker):punch_capture_cursor_marker.visible=calibration_aim_guide_visible
		if is_instance_valid(punch_capture_hint):
			punch_capture_hint.text="FOREHEAD FACING LINE %s  ·  F1 TOGGLES"%["ON" if facing_direction_line_visible else "OFF"]
		GameDiagnostics.log_event("aim_guide_toggled",{"visible":calibration_aim_guide_visible,"facing_line":facing_direction_line_visible,"key":"F1"})
		get_viewport().set_input_as_handled()
		return
	if calibration_mode and event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			adjust_camera_zoom(event.button_index==MOUSE_BUTTON_WHEEL_UP)
			get_viewport().set_input_as_handled()
			return
		if event.button_index==MOUSE_BUTTON_MIDDLE:
			mouse_middle_down=event.pressed
			camera_drag_active=event.pressed
			mouse_down_position=event.position
			if not event.pressed:log_camera_orbit()
			get_viewport().set_input_as_handled()
			return
	if calibration_mode and event is InputEventMouseMotion and mouse_middle_down:
		rotate_camera_orbit(event.relative)
		get_viewport().set_input_as_handled()
		return
	if punch_capture_recording:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
			_cancel_punch_contact_capture()
			get_viewport().set_input_as_handled()
			return
		if (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and event.keycode==KEY_KP_ENTER):
			var viewport_size:=get_viewport().get_visible_rect().size
			var pointer_position:Vector2=event.position if event is InputEventMouseButton else _aim_screen_position()
			var pointer_sample:Vector2=(pointer_position-viewport_size*0.5)/viewport_size
			var actor=fighters[0]
			var emitter:=_calibration_emitter(punch_capture_side)
			if emitter=="both":emitter="hand_l"
			var target_point:Vector3=punch_capture_cursor_marker.global_position if is_instance_valid(punch_capture_cursor_marker) else actor.global_position+actor.global_basis.z
			var aim:Vector3=(target_point-fighter_hand(actor,emitter)).normalized()
			var local_aim:Vector3=(actor.global_basis.inverse()*aim).normalized()
			var yaw:=atan2(local_aim.x,local_aim.z)
			var pitch:=atan2(local_aim.y,sqrt(local_aim.x*local_aim.x+local_aim.z*local_aim.z))
			var sample:Dictionary={"cursor":pointer_sample,"yaw":yaw,"pitch":pitch,"direction":"aim_%d"%(punch_capture_index+1)}
			punch_capture_working_samples[punch_capture_index]=sample
			GameDiagnostics.log_event("action_direction_sample_saved",{"animation":punch_capture_side,"direction":sample.direction,"cursor":pointer_sample,"aim_yaw":yaw,"aim_pitch":pitch,"target":target_point,"sample":punch_capture_index+1})
			punch_capture_index+=1
			punch_capture_repeat=0
			punch_capture_clock=0.0
			if punch_capture_index>=PUNCH_AIM_DIRECTIONS.size():
				_finish_action_calibration()
			else:
				_play_punch_calibration_preview()
				_update_punch_capture_hint()
			get_viewport().set_input_as_handled()
			return
		get_viewport().set_input_as_handled()
		return
	if chat_panel==null or not chat_panel.visible or not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
		_submit_chat_message()
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_ESCAPE:
		_close_chat()
		get_viewport().set_input_as_handled()

func _open_chat() -> void:
	if not is_instance_valid(chat_panel):return
	chat_entry.clear()
	chat_panel.visible=true
	chat_entry.grab_focus()
	GameDiagnostics.log_event("chat_open", {"fighter":story_profile.get("name", "")})

func _close_chat() -> void:
	if not is_instance_valid(chat_panel):return
	chat_panel.visible=false
	chat_entry.release_focus()
	get_viewport().gui_release_focus()

func _submit_chat_message(_submitted: String="") -> void:
	if not is_instance_valid(chat_entry) or not chat_panel.visible:return
	var message: String=" ".join(chat_entry.text.strip_edges().split(" ",false))
	if message.is_empty():
		_close_chat()
		return
	var filtered:=profanity_filter.sub(message,"***",true)
	if not fighters.is_empty():
		var tag=fighters[0].get_node_or_null("OverheadHealthTag")
		if is_instance_valid(tag) and tag.has_method("show_chat_bubble"):
			tag.show_chat_bubble(filtered,4.0)
	GameDiagnostics.log_event("chat_message", {"fighter":story_profile.get("name", ""), "characters":filtered.length(), "filtered":filtered!=message})
	_close_chat()

func update_fight_ui() -> void:
	# The Story encounter deliberately keeps the screen clear: its only prompt is
	# the survival objective at the top of the screen. Each fighter carries their own resource bars.
	if is_instance_valid(survive_label):
		if training_mode:
			if tutorial_phase == 0:
				survive_label.text = "TASK 1  ·  HIT THE TRAINER  ·  %d / 5\nLEFT MOUSE: LEFT JAB  ·  WASD: MOVE" % tutorial_phase_hits
			elif tutorial_phase == 1:
				survive_label.text = "TASK 2  ·  TARGET THE TRAINER, THEN HIT  ·  %d / 5\nCLICK THE TRAINER, PRESS F, THEN LEFT MOUSE" % tutorial_phase_hits
			else:
				survive_label.text = "TUTORIAL COMPLETE  ·  READY FOR YOUR FIRST FIGHT"
		else:
			survive_label.text = "Goal: Survive"

func finish_round(winner: int) -> void:
	if training_mode:
		return
	if not round_active or replay_mode:
		return
	_capture_replay_frame()
	var alive := []
	for fighter in fighters:
		if fighter.health > 0:
			alive.append(fighter)
	if alive.size() > 1:
		return
	var won: bool = winner == 0 and not fighters.is_empty() and fighters[0].health > 0
	fight_won = won
	_record_story_result(won)
	GameDiagnostics.log_event("story_fight_end", {"fight":story_stage, "winner":winner, "player_health":fighters[0].health if not fighters.is_empty() else 0.0, "rival_health":fighters[1].health if fighters.size() > 1 else 0.0})
	if not fighters.is_empty():
		fighters[0].prepare_post_fight_freeplay()
	round_active = false
	intermission = 0
	post_fight_slowmo = true
	post_fight_freeplay = true
	post_fight_timer = 0.85
	Engine.time_scale = 0.28
	for fighter in fighters:
		fighter.brain_enabled = false
		fighter.story_block_held = false
	if winner >= 0 and winner < wins.size():
		wins[winner] += 1
	status = ""
	if survive_label != null:
		survive_label.text = "Goal: Survive"
	if is_instance_valid(return_button):
		return_button.text = "Victory  ·  Review loot" if won else "Defeated  ·  Return to fight board"
		return_button.visible = false
	if is_instance_valid(replay_save_button): replay_save_button.visible = false
	events.append({"time": elapsed, "event": "round_end", "winner": winner, "round": round_number})
	GameDiagnostics.log_event("fight_slowmo_start", {"duration_scaled_seconds":post_fight_timer,"winner":winner})

func _record_story_result(won: bool) -> void:
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:
		return
	var profile: Dictionary = config.get_value("character", "profile", {}).duplicate(true)
	var history: Array = profile.get("story_history", [])
	var gear: Array = _opponent_gear(story_stage) if won else []
	var drop_snapshot: Array = _opponent_loot(story_stage) if won else []
	var spell_drops: Array[String] = _spells_from_loot(drop_snapshot)
	history.append({"fight":story_stage, "opponent":StoryRivals.name_for_stage(story_stage), "won":won, "opponent_gear":gear, "opponent_loot":drop_snapshot, "opponent_spells":spell_drops, "time":elapsed})
	profile["story_history"] = history
	if won:
		profile["story_stage"] = maxi(int(profile.get("story_stage", 1)), mini(5, story_stage + 1))
		profile["story_location"] = "Colosseum"
		var loot: Array = profile.get("story_loot", [])
		var last_loot: Array = []
		var seen_loot: Array = profile.get("seen_loot_ids", [])
		var unseen_value: Variant = profile.get("unseen_loadout_ids", [])
		var unseen_loadout: Array = unseen_value.duplicate() if unseen_value is Array else []
		for owned_item in loot:
			if owned_item is Dictionary and not seen_loot.has(str(owned_item.get("id", ""))):seen_loot.append(str(owned_item.get("id", "")))
		for item in _opponent_loot(story_stage):
			var seen_before := seen_loot.has(str(item.get("id", "")))
			var drop_for_review: Dictionary = item.duplicate(true)
			drop_for_review["is_new"] = not seen_before
			last_loot.append(drop_for_review)
			if not seen_before:
				var item_id := str(item.get("id", ""))
				seen_loot.append(item_id)
				if not unseen_loadout.has(item_id): unseen_loadout.append(item_id)
			var already_owned := false
			for owned_index in range(loot.size()):
				var owned:Dictionary=loot[owned_index] if loot[owned_index] is Dictionary else {}
				if owned is Dictionary and str(owned.get("id", "")) == str(item.get("id", "")):
					owned.merge(item,true)
					loot[owned_index]=owned
					already_owned = true
					break
			if not already_owned:
				loot.append(item)
		profile["story_loot"] = loot
		profile["seen_loot_ids"] = seen_loot
		profile["unseen_loadout_ids"] = unseen_loadout
		profile["last_fight_loot"] = last_loot
		profile["last_fight_spells"] = []
		if story_stage == 3:
			var spells: Array = profile.get("spell_inventory", profile.get("crystal_inventory", []))
			var seen_spells: Array = profile.get("seen_spell_ids", [])
			for owned_spell in spells:
				if owned_spell is Dictionary and not seen_spells.has(str(owned_spell.get("id", ""))):seen_spells.append(str(owned_spell.get("id", "")))
			var fireball_crystal := {"id":"crystal_fire", "name":"Fire crystal", "spell":"Fireball", "element":"Fire", "color":Color("ff774c")}
			var owns_fireball := false
			for spell in spells:
				if spell is Dictionary and str(spell.get("id", "")) == "crystal_fire":
					owns_fireball = true
					break
			if not owns_fireball:
				spells.append(fireball_crystal)
			var spell_is_new := not seen_spells.has("crystal_fire")
			profile["last_fight_spells"] = [fireball_crystal.duplicate(true)] if spell_is_new else []
			if spell_is_new:
				seen_spells.append("crystal_fire")
				if not unseen_loadout.has("crystal_fire"): unseen_loadout.append("crystal_fire")
			profile["seen_spell_ids"] = seen_spells
			profile["unseen_loadout_ids"] = unseen_loadout
			profile["spell_inventory"] = spells
			profile["crystal_inventory"] = spells.duplicate(true)
			profile["spell_catalog"] = spells.duplicate(true)
	else:
		profile["last_fight_loot"] = []
		profile["last_fight_spells"] = []
	config.set_value("character", "profile", profile)
	if config.save("user://story_character.cfg") == OK:
		var roster := ConfigFile.new()
		if roster.load("user://story_characters.cfg") == OK:
			var characters: Array = roster.get_value("roster", "characters", [])
			for index in range(characters.size()):
				if characters[index] is Dictionary and str(characters[index].get("character_id", "")) == str(profile.get("character_id", "")):
					characters[index] = profile
					break
			roster.set_value("roster", "characters", characters)
			roster.save("user://story_characters.cfg")

func _opponent_gear(fight: int) -> Array:
	var gear := ["Peasant chest", "Peasant left trouser leg", "Peasant right trouser leg", "Leather belt", "Peasant left arm wraps", "Peasant right arm wraps", "Peasant left boot", "Peasant right boot"]
	if fight >= 3:
		gear.append("Block chest wraps")
	if fight >= 2:
		gear.append("Left fingerless glove")
		gear.append("Right fingerless glove")
	if fight >= 3:
		gear.append("Left front-kick greave")
		gear.append("Right front-kick greave")
	if fight >= 4:
		gear.append("Left reinforced front-kick greave")
		gear.append("Right reinforced front-kick greave")
	if fight >= 5:
		gear.append("Left dash boot")
		gear.append("Right dash boot")
	return gear

func _spells_from_loot(loot: Array) -> Array[String]:
	var spells: Array[String] = []
	for item in loot:
		if not item is Dictionary:
			continue
		var spell_name := str(item.get("spell", ""))
		if not spell_name.is_empty() and not spells.has(spell_name):
			spells.append(spell_name)
		for spell in item.get("spells", []):
			var name := str(spell.get("spell", spell.get("name", "Spell"))) if spell is Dictionary else str(spell)
			if not name.is_empty() and not spells.has(name):
				spells.append(name)
	return spells

func _opponent_loot(fight: int) -> Array:
	var loot := [
		{"name":"Peasant chest", "slot":"Chest"},
		{"name":"Peasant left trouser leg", "slot":"Left leg", "part":"left_leg"},
		{"name":"Peasant right trouser leg", "slot":"Right leg", "part":"right_leg"},
		{"name":"Leather belt", "slot":"Belt"},
		{"name":"Peasant left arm wraps", "slot":"Left arm", "part":"left_arm", "ability":"punch_left"},
		{"name":"Peasant left boot", "slot":"Left boot", "part":"left_boot"}
	]
	if fight >= 3:
		loot[0]["name"] = "Guarded chest wraps"
		loot[0]["ability"] = "block"
		loot[0]["spell"] = "Fireball"
	if fight >= 2:
		loot.append({"name":"Left fingerless glove", "slot":"Left hand", "part":"left_hand"})
		loot.append({"name":"Right fingerless glove", "slot":"Right hand", "part":"right_hand"})
	if fight >= 3:
		loot.append({"name":"Worn hood", "slot":"Head"})
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
	loot.append({"id":"fight-%d-right-arm"%fight,"name":"Peasant right arm wraps","slot":"Right arm","ability":"punch_right"})
	loot.append({"id":"fight-%d-right-leg"%fight,"name":"Peasant right trouser leg","slot":"Right leg","part":"right_leg"})
	loot.append({"id":"fight-%d-right-boot"%fight,"name":"Peasant right boot","slot":"Right boot","part":"right_boot"})
	return loot

func _physics_process(delta: float) -> void:
	_update_charge_inputs(delta)
	if replay_mode:
		if replay_playing:
			replay_elapsed = minf(replay_duration, replay_elapsed + delta)
			if is_instance_valid(replay_seek): replay_seek.set_value_no_signal(replay_elapsed)
		super._physics_process(delta)
		_apply_replay_frame(delta)
		return
	# Unlike the sparring study, this story encounter is a single fight.
	if post_fight_slowmo:
		post_fight_timer -= delta
		if post_fight_timer <= 0:
			post_fight_slowmo = false
			Engine.time_scale = 1.0
			if is_instance_valid(return_button): return_button.visible = true
			if is_instance_valid(replay_save_button): replay_save_button.visible = replay_samples.size() > 2
			GameDiagnostics.log_event("fight_slowmo_end", {"samples":replay_samples.size()})
	if round_active:
		replay_sample_clock += delta
		if replay_sample_clock >= replay_sample_period:
			replay_sample_clock = 0.0
			_capture_replay_frame()
	if story_mode and intermission > 0:
		intermission = 0
	super._physics_process(delta)
	_update_rival_charge_rings()
	if training_mode and round_active and mouse_left_down and not training_complete:
		calibration_punch_repeat_timer-=delta
		if calibration_punch_repeat_timer<=0.0:
			_player_punch("left")
			calibration_punch_repeat_timer=CALIBRATION_PUNCH_REPEAT_INTERVAL
			GameDiagnostics.log_event("punch_tutorial_repeat",{"phase":tutorial_phase+1,"hits":tutorial_phase_hits})
	_update_target_marker()
	update_fight_ui()

func record_training_calibration_hit(dummy_team:int, _zone:String)->void:
	if not training_mode or training_complete or dummy_team<=0:return
	if tutorial_phase == 0 and is_instance_valid(camera_focus_target):return
	if tutorial_phase == 1 and camera_focus_target != tutorial_focus_target:return
	tutorial_phase_hits+=1
	GameDiagnostics.log_event("punch_tutorial_hit",{"phase":tutorial_phase+1,"count":tutorial_phase_hits,"targeted":is_instance_valid(camera_focus_target)})
	if tutorial_phase_hits<5:return
	_complete_punch_tutorial()

func _save_punch_torso_calibration()->void:
	var config:=ConfigFile.new()
	if config.load("user://story_character.cfg")!=OK:return
	var profile:Dictionary=config.get_value("character","profile",{}).duplicate(true)
	var saved:Dictionary=profile.get("punch_torso_calibration",{}).duplicate(true)
	saved.merge(calibration_zone_angles,true)
	profile["punch_torso_calibration"]=saved
	config.set_value("character","profile",profile)
	var result:=config.save("user://story_character.cfg")
	GameDiagnostics.log_event("punch_calibration_saved",{"zones":calibration_zone_angles.keys(),"success":result==OK})

func _reset_tutorial_arena() -> void:
	tutorial_phase=1
	tutorial_phase_hits=0
	camera_focus_target=null
	selected_fighter=null
	camera_zoom=1.0
	camera_orbit_yaw=0.0
	camera_orbit_pitch=0.18
	begin_round()
	for trainer_hitboxes in calibration_dummy_roots:
		if is_instance_valid(trainer_hitboxes):trainer_hitboxes.global_position=fighters[1].global_position
	_show_trainer_prompt(fighters[1])
	tutorial_phase_hit_start=fighters[0].melee_hits
	GameDiagnostics.log_event("punch_tutorial_arena_reset", {"phase":2,"focused":false,"selected":false,"player_position":fighters[0].global_position,"dummy_position":fighters[1].global_position})

func _complete_punch_tutorial() -> void:
	training_complete = true
	tutorial_phase = 3
	if is_instance_valid(return_button):
		return_button.text = "RETURN TO BOOK"
		return_button.visible = true
	GameDiagnostics.log_event("punch_tutorial_complete", {"fighter":story_profile.get("name", ""), "lesson":training_lesson,"hits":fighters[0].melee_hits})

func _disable_training_hurtboxes(node:Node)->void:
	for child in node.get_children():
		if child is Area3D:
			child.collision_layer=0
			child.monitorable=false
		_disable_training_hurtboxes(child)

func _build_training_dummy(dummy_index:int,receiver:CharacterBody3D)->void:
	var target := Node3D.new()
	target.name = "TutorialTrainerHitZones_%d" % dummy_index
	add_child(target)
	target.global_position=receiver.global_position
	calibration_dummy_roots.append(target)
	_add_dummy_hurtbox(target,receiver,dummy_index,"head",Vector3(0,1.64,0),0.25,"Head")
	_add_dummy_hurtbox(target,receiver,dummy_index,"chest",Vector3(0,1.08,0),0.24,"spine_03")
	_add_dummy_hurtbox(target,receiver,dummy_index,"pelvis",Vector3(0,0.69,0),0.18,"pelvis")
	_add_dummy_hurtbox(target,receiver,dummy_index,"leg_l",Vector3(0,0.34,-0.13),0.16,"thigh_l")
	_add_dummy_hurtbox(target,receiver,dummy_index,"leg_r",Vector3(0,0.34,0.13),0.16,"thigh_r")

func _show_trainer_prompt(receiver:CharacterBody3D)->void:
	var tag:=receiver.get_node_or_null("OverheadHealthTag")
	if tag==null:return
	var name_label:=tag.get_node_or_null("FighterName") as Label3D
	if name_label!=null:name_label.text="Trainer"
	if tag.has_method("show_chat_bubble"):tag.show_chat_bubble("Come hit me!",999.0)

func _add_dummy_hurtbox(parent:Node3D,receiver:CharacterBody3D,dummy_index:int,zone:String,position_:Vector3,radius:float,bone:String)->void:
	var area:=Area3D.new()
	area.name="Dummy_%d_%s_Hurtbox" % [dummy_index,zone]
	area.collision_layer=8<<receiver.team
	area.collision_mask=0
	area.set_meta("fighter",receiver)
	area.set_meta("zone",zone)
	area.set_meta("bone",bone)
	area.set_meta("calibration_dummy_index",dummy_index)
	var shape:=CollisionShape3D.new()
	var sphere:=SphereShape3D.new()
	sphere.radius=radius
	shape.shape=sphere
	shape.position=position_
	area.add_child(shape)
	parent.add_child(area)

func _add_dummy_mesh(parent: Node3D, mesh: PrimitiveMesh, material: Material, position_: Vector3, rotation_: Vector3, scale_: Vector3) -> void:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = material
	piece.position = position_
	piece.rotation = rotation_
	piece.scale = scale_
	parent.add_child(piece)

func _capture_replay_frame() -> void:
	var frame := {"t":round_time,"fighters":[]}
	for fighter in fighters:
		frame.fighters.append({"p":[fighter.global_position.x,fighter.global_position.y,fighter.global_position.z],"yaw":fighter.rotation.y,"health":fighter.health,"mode":fighter.mode,"clip":fighter.clip})
	replay_samples.append(frame)

func _save_replay() -> void:
	if replay_samples.size() < 2:return
	var folder := "user://story_replays"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var path := "%s/fight_%d_%s.json" % [folder, story_stage, stamp]
	var payload := {"fight":story_stage,"opponent":StoryRivals.name_for_stage(story_stage),"player":story_profile.get("name","Fighter"),"duration":float(replay_samples.back().get("t",0.0)),"samples":replay_samples}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		GameDiagnostics.log_event("replay_save_failed", {"path":path,"error":FileAccess.get_open_error()})
		return
	file.store_string(JSON.stringify(payload))
	file.close()
	GameDiagnostics.log_event("replay_saved", {"path":path,"frames":replay_samples.size()})
	replay_save_button.text = "REPLAY SAVED"
	replay_save_button.disabled = true

func _apply_replay_frame(delta: float) -> void:
	var samples: Array = replay_data.get("samples", [])
	if samples.is_empty() or fighters.is_empty():return
	var target_index := 0
	while target_index < samples.size() - 1 and float(samples[target_index + 1].get("t", 0.0)) < replay_elapsed:
		target_index += 1
	var next_index := mini(target_index + 1, samples.size() - 1)
	var a: Dictionary = samples[target_index]
	var b: Dictionary = samples[next_index]
	var span := maxf(0.0001, float(b.get("t", 0.0)) - float(a.get("t", 0.0)))
	var blend := clampf((replay_elapsed - float(a.get("t", 0.0))) / span, 0.0, 1.0)
	var af: Array = a.get("fighters", [])
	var bf: Array = b.get("fighters", [])
	for index in mini(fighters.size(), mini(af.size(), bf.size())):
		var fighter = fighters[index]
		var first: Dictionary = af[index]
		var second: Dictionary = bf[index]
		var p: Array = first.get("p", [0,0,0])
		var q: Array = second.get("p", p)
		fighter.global_position = Vector3(float(p[0]),float(p[1]),float(p[2])).lerp(Vector3(float(q[0]),float(q[1]),float(q[2])),blend)
		fighter.rotation.y = lerp_angle(float(first.get("yaw",0.0)),float(second.get("yaw",first.get("yaw",0.0))),blend)
		fighter.health = lerpf(float(first.get("health",100.0)),float(second.get("health",first.get("health",100.0))),blend)
		fighter.mode = str(first.get("mode","idle"))
		var clip_name := str(first.get("clip",""))
		if not clip_name.is_empty() and fighter.clip != clip_name:fighter.play(clip_name)
		fighter.advance_animation(delta)
	if replay_elapsed >= replay_duration:
		replay_playing = false
		if is_instance_valid(replay_play_button): replay_play_button.text = "PLAY"

func _leave_result() -> void:
	if training_mode:
		_save_tutorial_complete()
		get_tree().change_scene_to_file("res://scenes/story_opponents.tscn")
		return
	get_tree().change_scene_to_file("res://scenes/story_loot_review.tscn" if fight_won else "res://scenes/story_opponents.tscn")

func _save_tutorial_complete() -> void:
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:
		return
	var profile: Dictionary = config.get_value("character", "profile", {}).duplicate(true)
	profile["punch_tutorial_%d_complete" % training_lesson] = true
	profile["punch_tutorial_complete"] = bool(profile.get("punch_tutorial_1_complete", false)) and bool(profile.get("punch_tutorial_2_complete", false))
	config.set_value("character", "profile", profile)
	var result := config.save("user://story_character.cfg")
	if result == OK:
		var roster := ConfigFile.new()
		if roster.load("user://story_characters.cfg") == OK:
			var characters: Array = roster.get_value("roster", "characters", [])
			for index in range(characters.size()):
				if characters[index] is Dictionary and str(characters[index].get("character_id", "")) == str(profile.get("character_id", "")):
					characters[index] = profile
					break
			roster.set_value("roster", "characters", characters)
			roster.save("user://story_characters.cfg")
		GameDiagnostics.log_event("punch_tutorial_saved", {"character_id":profile.get("character_id", ""),"lesson":training_lesson,"complete":profile.get("punch_tutorial_complete",false)})

func _fighter_under_mouse() -> CharacterBody3D:
	var active_camera:=get_viewport().get_camera_3d()
	if active_camera==null:return null
	var ray_start:=active_camera.project_ray_origin(_aim_screen_position())
	var ray_end:=ray_start+active_camera.project_ray_normal(_aim_screen_position())*100.0
	var query:=PhysicsRayQueryParameters3D.create(ray_start,ray_end)
	query.collision_mask=8|16|32|128|256|512
	query.collide_with_areas=true
	query.collide_with_bodies=true
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return null
	var collider: Object=hit.get("collider")
	if collider is CharacterBody3D and fighters.has(collider):return collider
	if collider is Area3D:
		var fighter: Variant=collider.get_meta("fighter",null)
		if fighter is CharacterBody3D and fighters.has(fighter):return fighter
	return null

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_inside_tree():return
	if not event is InputEventKey or event.echo:
		return
	if punch_capture_recording:
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(punch_aim_overlay) and punch_aim_overlay.visible and event.pressed and event.keycode==KEY_ESCAPE:
		_close_punch_aim_calibration()
		get_viewport().set_input_as_handled()
		return
	if chat_panel!=null and chat_panel.visible:
		if event.pressed and event.keycode==KEY_ESCAPE:
			_close_chat()
		elif event.pressed and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
			_submit_chat_message()
		get_viewport().set_input_as_handled()
		return
	if event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/story_replays.tscn" if replay_mode else ("res://scenes/story_opponents.tscn" if training_mode else "res://scenes/home.tscn"))
		get_viewport().set_input_as_handled()
		return
	if fighters.is_empty() or (not round_active and not post_fight_slowmo and not post_fight_freeplay):
		return
	if replay_mode:return
	if event.pressed and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
		_open_chat()
		get_viewport().set_input_as_handled()
		return
	var player = fighters[0]
	if event.keycode in [KEY_KP_7,KEY_KP_9,KEY_KP_0]:
		var binding := "mouse_left" if event.keycode==KEY_KP_7 else ("mouse_right" if event.keycode==KEY_KP_9 else "mouse_both")
		var ability := _story_ability_for_input(binding)
		if ability.is_empty():ability="punch_left" if event.keycode==KEY_KP_7 else ("punch_right" if event.keycode==KEY_KP_9 else "block")
		if event.pressed:_begin_bound_ability(binding,ability)
		else:_finish_bound_ability(binding,ability)
		get_viewport().set_input_as_handled()
		return
	var key_name:=OS.get_keycode_string(event.keycode if event.keycode!=0 else event.physical_keycode).to_lower().replace(" ","_")
	var key_identity:="key_"+key_name
	var input_id:=_key_binding_from_event(event)
	var assigned := _story_ability_for_input(input_id)
	if not event.pressed:
		var released_binding:=input_id
		var had_held_binding:=held_story_key_inputs.has(key_identity)
		if held_story_key_inputs.has(key_identity):
			released_binding=str(held_story_key_inputs[key_identity])
			assigned=_story_ability_for_input(released_binding)
			held_story_key_inputs.erase(key_identity)
		if had_held_binding:_finish_bound_ability(released_binding,assigned)
		elif assigned=="block":_set_story_block(false)
		get_viewport().set_input_as_handled()
		return
	if not assigned.is_empty():
		held_story_key_inputs[key_identity]=input_id
		_begin_bound_ability(input_id,assigned)
		get_viewport().set_input_as_handled()
		return
	var has_modifiers:bool=event.shift_pressed or event.ctrl_pressed or event.alt_pressed
	if has_modifiers:
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F:
		if is_instance_valid(camera_focus_target):
			focus_camera_on(null)
		elif is_instance_valid(selected_fighter):
			focus_camera_on(selected_fighter)
		else:
			GameDiagnostics.log_event("camera_focus_miss", {"reason":"no_gold_selected_fighter"})
		get_viewport().set_input_as_handled()
	elif training_mode:
		# Keep the tutorial's input lesson strictly to movement, target focus and
		# the left mouse jab; the movement controller reads held WASD directly.
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_J:
		_player_punch("left")
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_H:
		_player_punch("right")
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_W and story_stage >= 5 and player.has_story_ability("dash"):
		var now := Time.get_ticks_msec() / 1000.0
		if now - last_forward_press <= 0.32 and player.mode in ["idle", "run"]:
			player.start_motion_dash(0)
			last_forward_press = -10.0
			get_viewport().set_input_as_handled()
		else:
			last_forward_press = now
	else:
		var hotkeys: Dictionary = player.story_profile.get("combat_hotkeys", {})
		for ability in hotkeys:
			if int(hotkeys[ability]) == event.keycode:
				_use_story_ability(str(ability))
				get_viewport().set_input_as_handled()
				return
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not fighters.is_empty() and event.button_index==MOUSE_BUTTON_MIDDLE and (round_active or replay_mode or story_mode):
		var was_camera_dragging:=camera_drag_active
		mouse_middle_down=event.pressed
		camera_drag_active=event.pressed
		if event.pressed:
			mouse_down_position=event.position
			GameDiagnostics.log_event("camera_orbit_start", {"fighter":story_profile.get("name", ""),"button":"middle"})
		elif was_camera_dragging:
			log_camera_orbit()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		adjust_camera_zoom(event.button_index==MOUSE_BUTTON_WHEEL_UP)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and not fighters.is_empty() and (round_active or post_fight_freeplay) and not replay_mode:
		if training_mode:
			get_viewport().set_input_as_handled()
			return
		var binding:="joy_left" if event.button_index==JOY_BUTTON_LEFT_STICK else ("joy_right" if event.button_index==JOY_BUTTON_RIGHT_STICK else "")
		if not binding.is_empty():
			var ability:=_story_ability_for_input("mouse_left" if binding=="joy_left" else "mouse_right")
			if event.pressed:_begin_bound_ability(binding,ability)
			else:_finish_bound_ability(binding,ability)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and not fighters.is_empty() and mouse_middle_down:
		if camera_drag_active:
			rotate_camera_orbit(event.relative)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and not fighters.is_empty() and (round_active or replay_mode or story_mode):
		if replay_mode or (not round_active and not post_fight_freeplay):
			if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
				if event.pressed: mouse_down_position = event.position
				else: camera_drag_active = false
				mouse_left_down = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
				mouse_right_down = event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				adjust_camera_zoom(event.button_index == MOUSE_BUTTON_WHEEL_UP)
			get_viewport().set_input_as_handled()
			return
		if story_mode and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if training_mode:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.pressed:
						_select_fighter_from_mouse()
						mouse_left_down = true
						mouse_down_position = event.position
						calibration_punch_repeat_timer=CALIBRATION_PUNCH_REPEAT_INTERVAL
						if round_active and not training_complete:
							_player_punch("left")
							var zone:String=CALIBRATION_ZONES[calibration_zone_index] if calibration_zone_index<CALIBRATION_ZONES.size() else "complete"
							GameDiagnostics.log_event("punch_calibration_jab",{"zone":zone,"hits":tutorial_phase_hits})
					else:
						mouse_left_down = false
						calibration_punch_repeat_timer=0.0
						camera_drag_active = false
					get_viewport().set_input_as_handled()
					return
				if event.button_index == MOUSE_BUTTON_RIGHT:
					get_viewport().set_input_as_handled()
					return
				get_viewport().set_input_as_handled()
				return
			if training_mode and event.button_index == MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				return
			_handle_story_mouse_button(event)
			get_viewport().set_input_as_handled()

func _handle_story_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:_select_fighter_from_mouse()
	var has_modifiers:=event.shift_pressed or event.ctrl_pressed or event.alt_pressed
	var middle_has_binding:=event.button_index==MOUSE_BUTTON_MIDDLE and not _story_ability_for_input("mouse_middle").is_empty()
	if has_modifiers or held_story_mouse_inputs.has(event.button_index) or middle_has_binding:
		var binding:=_mouse_binding_from_event(event)
		if not event.pressed and held_story_mouse_inputs.has(event.button_index):
			binding=str(held_story_mouse_inputs[event.button_index])
			held_story_mouse_inputs.erase(event.button_index)
		var assigned:=_story_ability_for_input(binding)
		if event.pressed:
			held_story_mouse_inputs[event.button_index]=binding
			if not assigned.is_empty():_begin_bound_ability(binding, assigned)
		else:
			_finish_bound_ability(binding, assigned)
		get_viewport().set_input_as_handled()
		return
	if event.button_index==MOUSE_BUTTON_MIDDLE:
		_set_story_block(event.pressed)
		get_viewport().set_input_as_handled()
		return
	if event.pressed:
		mouse_down_position=event.position
	if event.button_index == MOUSE_BUTTON_LEFT:
		mouse_left_down = event.pressed
	else:
		mouse_right_down = event.pressed
	if mouse_left_down and mouse_right_down:
		_cancel_charge("mouse_left")
		_cancel_charge("mouse_right")
		pending_mouse_punch = ""
		mouse_punch_token += 1
		if _story_ability_for_input("mouse_both") == "block":
			_set_story_block(true)
		return
	if not event.pressed:
		if not mouse_left_down and not mouse_right_down and camera_drag_active:
			camera_drag_active=false
			log_camera_orbit()
		if mouse_block_active:
			_set_story_block(false)
		var side := "left" if event.button_index == MOUSE_BUTTON_LEFT else "right"
		if pending_mouse_punch == side:
			pending_mouse_punch = ""
			mouse_punch_token += 1
			if not camera_drag_active:
				var binding:="mouse_left" if side=="left" else "mouse_right"
				_finish_bound_ability(binding,_story_ability_for_input(binding))
		return
	var pressed_side := "left" if event.button_index == MOUSE_BUTTON_LEFT else "right"
	mouse_press_times[pressed_side]=Time.get_ticks_msec()/1000.0
	var binding:="mouse_left" if pressed_side=="left" else "mouse_right"
	var ability:=_story_ability_for_input(binding)
	if ability in ["punch_left","punch_right","front_kick"]:
		_begin_bound_ability(binding,ability)
	pending_mouse_punch = pressed_side
	_mouse_chord_delay(pressed_side)

func _mouse_chord_delay(side: String) -> void:
	mouse_punch_token += 1
	var token := mouse_punch_token
	await get_tree().create_timer(0.12).timeout
	# Keep the click pending until release so a held punch can charge and a
	# simultaneous left+right press can still become a block.
	if token != mouse_punch_token or pending_mouse_punch != side or (mouse_left_down and mouse_right_down):return

func _story_ability_for_input(input_id: String) -> String:
	if fighters.is_empty():
		return ""
	var story_profile:Dictionary=fighters[0].story_profile
	var equipped:Dictionary=story_profile.get("story_part_gear",{})
	var inventory:Array=story_profile.get("gear_inventory",[])
	for part_id in equipped:
		var gear_id:=str(equipped[part_id])
		for item in inventory:
			if not item is Dictionary or str(item.get("id",""))!=gear_id:continue
			for animation_slot in item.get("animation_slots",[]):
				if str(animation_slot.get("input",""))==input_id and not str(animation_slot.get("animation","")).is_empty():
					return str(animation_slot.get("animation",""))
	var bindings: Dictionary = story_profile.get("gear_slots", {})
	if bindings.is_empty():
		return {"mouse_left":"punch_left", "mouse_right":"punch_right", "mouse_both":"block"}.get(input_id, "")
	for part_id in bindings:
		var slot: Variant = bindings[part_id]
		if slot is Dictionary and str(slot.get("input", "")) == input_id:
			var ability := str(slot.get("ability", ""))
			if not ability.is_empty():
				return ability
	return ""

func _key_binding_from_event(event:InputEventKey) -> String:
	var modifiers:=""
	if event.ctrl_pressed:modifiers+="ctrl+"
	if event.alt_pressed:modifiers+="alt+"
	if event.shift_pressed:modifiers+="shift+"
	var key_name:=OS.get_keycode_string(event.keycode if event.keycode!=0 else event.physical_keycode).to_lower().replace(" ","_")
	return modifiers+"key_"+key_name

func _mouse_binding_from_event(event:InputEventMouseButton) -> String:
	var modifiers:=""
	if event.ctrl_pressed:modifiers+="ctrl+"
	if event.alt_pressed:modifiers+="alt+"
	if event.shift_pressed:modifiers+="shift+"
	var mouse_name:="mouse_left" if event.button_index==MOUSE_BUTTON_LEFT else ("mouse_right" if event.button_index==MOUSE_BUTTON_RIGHT else "mouse_middle")
	return modifiers+mouse_name

func _dispatch_story_ability(ability: String) -> void:
	match ability:
		"punch_left": _player_punch("left")
		"punch_right": _player_punch("right")
		"block": _set_story_block(true)
		"front_kick", "dash":
			_use_story_ability(ability)

func _begin_bound_ability(binding: String, ability: String) -> void:
	if ability == "block":
		_set_story_block(true)
		return
	if training_mode or (not round_active and not post_fight_freeplay) or ability not in ["punch_left", "punch_right", "front_kick"]:
		_dispatch_story_ability(ability)
		return
	if held_charge_inputs.has(binding):return
	var limb:="arm_l" if ability=="punch_left" else ("arm_r" if ability=="punch_right" else "leg_r")
	var player=fighters[0]
	if player.story_limb_busy("left_arm" if limb=="arm_l" else ("right_arm" if limb=="arm_r" else "right_leg")):
		GameDiagnostics.log_event("charge_start_blocked",{"input":binding,"ability":ability,"reason":"limb_busy","mode":player.mode})
		return
	player.story_limb_reservations[limb]=INF
	held_charge_inputs[binding]={"ability":ability,"limb":limb,"elapsed":0.0,"resource":0.0,"tier":"NORMAL","unstable_damage":0.0,"unstable_crit":false}
	charge_elapsed_total=0.0
	charge_ring_last_signature=""
	_update_charge_ui()
	GameDiagnostics.log_event("charge_started",{"input":binding,"ability":ability,"locomotion_mode":player.mode})

func _finish_bound_ability(binding: String, ability: String) -> void:
	if ability=="block":
		_set_story_block(false)
		return
	if held_charge_inputs.has(binding):
		var state:Dictionary=held_charge_inputs[binding]
		held_charge_inputs.erase(binding)
		if fighters.size()>0: fighters[0].story_limb_reservations.erase(str(state.limb))
		var profile:=_charge_profile(state,true)
		_execute_charged_ability(str(state.ability),profile)
		GameDiagnostics.log_event("charge_released",{"input":binding,"ability":state.ability,"elapsed":state.elapsed,"tier":profile.tier,"damage_multiplier":profile.damage_multiplier,"crit_chance":profile.crit_chance,"critical":profile.critical,"unstable":profile.unstable})
		_update_charge_ui()

func _cancel_charge(binding: String) -> void:
	if not held_charge_inputs.has(binding):return
	var state:Dictionary=held_charge_inputs[ binding ]
	if fighters.size()>0: fighters[0].story_limb_reservations.erase(str(state.limb))
	held_charge_inputs.erase(binding)
	_update_charge_ui()

func _charge_tier(seconds: float) -> Dictionary:
	if seconds<0.50:return {"tier":"NORMAL","damage":1.0,"crit":0.0,"color":Color("aab2bb")}
	if seconds<0.75:return {"tier":"GREY","damage":1.25,"crit":0.10,"color":Color("aab2bb")}
	if seconds<0.875:return {"tier":"GREEN","damage":1.5,"crit":0.25,"color":Color("58d68d")}
	if seconds<0.935:return {"tier":"BLUE","damage":1.75,"crit":0.50,"color":Color("58a6ff")}
	if seconds<0.975:return {"tier":"PURPLE","damage":2.0,"crit":0.75,"color":Color("bd7bff")}
	if seconds<0.995:return {"tier":"LEGENDARY","damage":5.0,"crit":1.0,"color":Color("ffd54a")}
	if seconds<1.0:return {"tier":"MYTHIC","damage":10.0,"crit":1.0,"color":Color("ff8b35")}
	return {"tier":"UNSTABLE","damage":1.0,"crit":0.01,"color":Color("ff3d3d")}

func _charge_profile(state: Dictionary, roll_critical:bool=false) -> Dictionary:
	var tier:=_charge_tier(float(state.elapsed))
	var unstable:=float(state.elapsed)>=1.0
	var damage:=float(state.unstable_damage) if unstable else float(tier.damage)
	var crit:=0.01 if unstable else float(tier.crit)
	return {"tier":"UNSTABLE" if unstable else str(tier.tier),"damage_multiplier":damage,"crit_chance":crit,"critical":roll_critical and randf()<crit,"unstable":unstable,"elapsed":float(state.elapsed)}

func _execute_charged_ability(ability: String, profile: Dictionary) -> void:
	match ability:
		"punch_left":_player_punch("left",0.0,profile)
		"punch_right":_player_punch("right",0.0,profile)
		"front_kick":
			if fighters.is_empty():return
			var before:int=fighters[0].story_strikes.size()
			var aim_result:=_story_action_aim(ability,fighters[0])
			fighters[0].start_story_front_kick(profile,aim_result.direction,float(aim_result.pitch))
			if fighters[0].story_strikes.size()>before:_cast_linked_spell(ability,profile,aim_result.direction)

func _update_charge_inputs(delta: float) -> void:
	if held_charge_inputs.is_empty():return
	if (not round_active and not post_fight_freeplay) or fighters.is_empty():
		for binding in held_charge_inputs.keys():
			var pending:Dictionary=held_charge_inputs[binding]
			fighters[0].story_limb_reservations.erase(str(pending.limb))
		held_charge_inputs.clear()
		_update_charge_ui()
		return
	var changed:=false
	for binding in held_charge_inputs.keys():
		var state:Dictionary=held_charge_inputs[binding]
		state.elapsed=float(state.elapsed)+delta
		if float(state.elapsed)>=1.0 and str(state.tier)!="UNSTABLE":
			state.tier="UNSTABLE"
			state.unstable_damage=randf_range(1.0,5.0)
			GameDiagnostics.log_event("charge_unstable",{"input":binding,"damage_multiplier":state.unstable_damage,"crit_chance":0.01})
		var drain:=8.0*delta
		var player=fighters[0] if not fighters.is_empty() else null
		var mana_drain:=0.0
		if player!=null:
			var anim:="punch_left" if str(state.ability)=="punch_left" else ("punch_right" if str(state.ability)=="punch_right" else str(state.ability))
			if not player.story_spells_for_animation(anim).is_empty():mana_drain=5.0*delta
		if player==null or player.stamina<drain or player.mana<mana_drain or not player.spend_stamina(drain):
			_finish_bound_ability(str(binding),str(state.ability))
			continue
		if mana_drain>0 and not player.spend_mana(mana_drain):
			_finish_bound_ability(str(binding),str(state.ability))
			continue
		state.resource=float(state.resource)+drain
		held_charge_inputs[binding]=state
		changed=true
	if changed and not held_charge_inputs.is_empty():_update_charge_ui()

func _update_charge_ui() -> void:
	var active:Dictionary={}
	for binding in held_charge_inputs:
		active=held_charge_inputs[binding]
		break
	if is_instance_valid(charge_hint):
		charge_hint.visible=not active.is_empty()
		if not active.is_empty():
			var profile:=_charge_profile(active)
			charge_hint.text="%s  ·  %.2f×  ·  %.0f%% CRIT  ·  %.2fs\nGREY .50  ·  GREEN .75  ·  BLUE .875  ·  PURPLE .935  ·  LEGENDARY .975  ·  MYTHIC .995" % [profile.tier,profile.damage_multiplier,profile.crit_chance*100.0,float(active.elapsed)]
			charge_hint.add_theme_color_override("font_color",_charge_tier(float(active.elapsed)).color)
	if is_instance_valid(charge_ring):
		charge_ring.visible=not active.is_empty()
		if not active.is_empty() and fighters.size()>0:
			charge_ring.global_position=fighters[0].global_position+Vector3.UP*0.035
			var color:Color=_charge_tier(float(active.elapsed)).color
			_update_charge_ring(clampf(float(active.elapsed)/1.0,0.0,1.0),color)

func _update_charge_ring(amount:float,color:Color) -> void:
	if not is_instance_valid(charge_ring):return
	var signature:="%d:%.3f:%.3f:%.3f" % [int(amount*64.0),color.r,color.g,color.b]
	if signature==charge_ring_last_signature:return
	charge_ring_last_signature=signature
	_set_charge_ring_mesh(charge_ring,amount,color,signature)

func _update_rival_charge_rings() -> void:
	for ring_index in rival_charge_rings.size():
		var fighter_index:=ring_index+1
		if fighter_index>=fighters.size():continue
		var rival=fighters[fighter_index]
		var elapsed:=-1.0
		var progress:=0.0
		if bool(rival.get("story_enemy_charge_active")):
			elapsed=float(rival.get("story_enemy_charge_elapsed"))
			progress=clampf(elapsed,0.0,1.0)
		elif rival.mode=="melee_charge":
			var duration:=float(rival.editor_uppercut_charge_duration()) if rival.has_method("editor_uppercut_charge_duration") else 1.0
			elapsed=clampf(float(rival.mode_time)/maxf(0.01,duration),0.0,1.0)
			progress=elapsed
		elif rival.mode=="cast" and float(rival.charge_goal)>0.0 and not rival.did_release and str(rival.cast_phase)=="hold":
			elapsed=clampf(float(rival.charge_value),0.0,1.0)
			progress=elapsed
		var ring:MeshInstance3D=rival_charge_rings[ring_index]
		ring.visible=elapsed>=0.0 and round_active and rival.health>0
		if ring.visible:
			ring.global_position=rival.global_position+Vector3.UP*0.035
			var color:Color=_charge_tier(elapsed).color
			var signature:="%d:%.3f:%.3f:%.3f" % [int(progress*64.0),color.r,color.g,color.b]
			_set_charge_ring_mesh(ring,progress,color,signature)

func _set_charge_ring_mesh(ring:MeshInstance3D,amount:float,color:Color,signature:String) -> void:
	if str(ring.get_meta("ring_signature",""))==signature:return
	ring.set_meta("ring_signature",signature)
	var mesh:=ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,ring.material_override as Material)
	var inner:=0.40
	var outer:=0.47
	for segment in range(64):
		var a0:=TAU*float(segment)/64.0-PI/2.0
		var a1:=TAU*float(segment+1)/64.0-PI/2.0
		var c:=Color("29323d",0.82)
		if float(segment)/64.0<amount:c=color
		var i0:=Vector3(cos(a0)*inner,0,sin(a0)*inner)
		var o0:=Vector3(cos(a0)*outer,0,sin(a0)*outer)
		var i1:=Vector3(cos(a1)*inner,0,sin(a1)*inner)
		var o1:=Vector3(cos(a1)*outer,0,sin(a1)*outer)
		mesh.surface_set_color(c);mesh.surface_add_vertex(i0)
		mesh.surface_set_color(c);mesh.surface_add_vertex(o0)
		mesh.surface_set_color(c);mesh.surface_add_vertex(o1)
		mesh.surface_set_color(c);mesh.surface_add_vertex(i0)
		mesh.surface_set_color(c);mesh.surface_add_vertex(o1)
		mesh.surface_set_color(c);mesh.surface_add_vertex(i1)
	mesh.surface_end()
	ring.mesh=mesh

func _set_story_block(held: bool) -> void:
	if fighters.is_empty():
		return
	var player = fighters[0]
	var newly_held: bool = held and not player.story_block_held
	mouse_block_active = held if mouse_left_down or mouse_right_down else false
	GameDiagnostics.log_event("block_input", {"device":"gear_binding", "held":held})
	if held:
		if not newly_held:return
		if not player.start_story_block():
			GameDiagnostics.log_event("block_input_blocked", {"reason":"arms_busy_or_low_stamina"})
		else:
			player.story_block_held=true
	else:
		player.story_block_held=false
		player.story_block_time=0.0
		for limb_player:AnimationPlayer in player.story_limb_players.values():limb_player.stop()
	if newly_held:
		var aim_result:=_story_action_aim("block",player)
		_cast_linked_spell("block",{},aim_result.direction)

func _player_punch(side: String, charge: float=0.0, charge_profile:Dictionary={}) -> void:
	if fighters.is_empty() or (not round_active and not post_fight_freeplay):
		return
	var player = fighters[0]
	var strikes_before:int=player.story_strikes.size()
	GameDiagnostics.log_event("combat_action", {"fighter":"player", "action":"%s_punch" % side})
	var animation_id:="punch_left" if side=="left" else "punch_right"
	var aim_result:=_story_action_aim(animation_id,player)
	# Without a focus target, a jab follows the fighter's facing. Focused attacks
	# use the target's chest point for their forward contact test.
	var facing_direction:Vector3=player.global_basis.z.normalized()
	if is_instance_valid(camera_focus_target) and camera_focus_target!=player and camera_focus_target.health>0:
		facing_direction=aim_result.direction
	player.start_story_punch(side,charge,charge_profile,facing_direction,0.0)
	if player.story_strikes.size()>strikes_before:
		_cast_linked_spell(animation_id,charge_profile,aim_result.direction)

func _mouse_aim_direction(player:CharacterBody3D,pointer:Vector2) -> Vector3:
	var active_camera:=get_viewport().get_camera_3d()
	if active_camera==null:return player.global_basis.z
	var origin:=active_camera.project_ray_origin(pointer)
	var direction:=active_camera.project_ray_normal(pointer)
	var target_point:Variant=Plane(Vector3.UP,player.global_position.y+0.9).intersects_ray(origin,direction)
	if target_point is Vector3:
		var flat:Vector3=target_point-player.global_position
		flat.y=0
		if not flat.is_zero_approx():return _constrain_aim_to_front(player,flat.normalized())
	return _constrain_aim_to_front(player,Vector3(-direction.x,0,-direction.z).normalized())

func _constrain_aim_to_front(player:CharacterBody3D,aim:Vector3)->Vector3:
	var forward:=player.global_basis.z
	forward.y=0.0
	if forward.is_zero_approx():return aim.normalized()
	forward=forward.normalized()
	var direction:=aim.normalized()
	var horizontal:=Vector3(direction.x,0.0,direction.z)
	if horizontal.is_zero_approx():return direction
	if horizontal.dot(forward)<0.0:
		var side:=player.global_basis.x
		side.y=0.0
		side=side.normalized()
		var side_sign:=1.0 if horizontal.dot(side)>=0.0 else -1.0
		horizontal=(forward*0.015+side*side_sign).normalized()
		var horizontal_scale:=sqrt(maxf(0.0,1.0-direction.y*direction.y))
		return (horizontal*horizontal_scale+Vector3.UP*direction.y).normalized()
	return direction

func _punch_aim_pointer(player:CharacterBody3D,cursor:Vector2)->Vector2:
	if is_instance_valid(camera_focus_target) and camera_focus_target!=player and camera_focus_target.health>0:
		var active_camera:=get_viewport().get_camera_3d()
		if active_camera!=null:
			var target_point:=_focused_target_chest_point(camera_focus_target)
			if active_camera.is_position_behind(target_point):return get_viewport().get_visible_rect().size*0.5
			return active_camera.unproject_position(target_point)
	return cursor

func _focused_target_chest_point(target:CharacterBody3D)->Vector3:
	if is_instance_valid(target) and target.has_method("bone_point"):
		# Use the actual chest joint so close-range aim doesn't drift up toward
		# the head when the target's height or pose differs from the player.
		return target.bone_point("spine_02")+Vector3.UP*0.04
	return target.global_position+Vector3.UP*1.0 if is_instance_valid(target) else Vector3.ZERO

func _punch_angles_for_pointer(animation_id:String,pointer:Vector2)->Dictionary:
	var samples:=_equipped_calibration_samples(animation_id)
	if samples.size()!=PUNCH_AIM_DIRECTIONS.size():return {}
	var viewport_size:=get_viewport().get_visible_rect().size
	if viewport_size.x<=0 or viewport_size.y<=0:return {}
	var normalized:Vector2=(pointer-viewport_size*0.5)/viewport_size
	var weighted_yaw:=0.0
	var weighted_pitch:=0.0
	var total_weight:=0.0
	for sample_value in samples:
		if not sample_value is Dictionary or not sample_value.has("cursor"):continue
		var sample:Dictionary=sample_value
		var sample_cursor:Vector2=sample.cursor
		var distance:=normalized.distance_to(sample_cursor)
		if distance<0.012:return {"yaw":float(sample.get("yaw",0.0)),"pitch":float(sample.get("pitch",0.0))}
		var weight:=1.0/pow(distance,3.0)
		weighted_yaw+=float(sample.get("yaw",0.0))*weight
		weighted_pitch+=float(sample.get("pitch",0.0))*weight
		total_weight+=weight
	if total_weight<=0:return {}
	return {"yaw":weighted_yaw/total_weight,"pitch":weighted_pitch/total_weight}

func _equipped_calibration_samples(animation_id:String)->Array:
	var equipped:Dictionary=story_profile.get("story_part_gear",{})
	var inventory:Array=story_profile.get("gear_inventory",[])
	for gear_id in equipped.values():
		for item in inventory:
			if not item is Dictionary or str(item.get("id",""))!=str(gear_id):continue
			for slot in item.get("animation_slots",[]):
				if slot is Dictionary and str(slot.get("animation",""))==animation_id:
					var value:Variant=slot.get("aim_samples",[])
					return value.duplicate(true) if value is Array else []
	return []

func _story_action_aim(animation_id:String,player:CharacterBody3D)->Dictionary:
	var pointer:=_punch_aim_pointer(player,_aim_screen_position())
	var aim_point:=_focused_target_chest_point(camera_focus_target) if is_instance_valid(camera_focus_target) and camera_focus_target!=player and camera_focus_target.health>0 else _cursor_aim_point(player,pointer)
	player.set_story_calibration_aim(aim_point,true)
	var emitter:=_calibration_emitter(animation_id)
	var origin:Vector3=player.bone_point("spine_03")
	if emitter in ["hand_l","hand_r"]:origin=player.bone_point("hand_%s"%emitter.right(1))
	var world_aim:Vector3=(aim_point-origin).normalized()
	if world_aim.is_zero_approx():world_aim=_mouse_aim_direction(player,pointer)
	var local_direction:=player.global_basis.inverse()*world_aim.normalized()
	var yaw:=atan2(local_direction.x,local_direction.z)
	var pitch:=clampf(atan2(local_direction.y,maxf(0.001,Vector2(local_direction.x,local_direction.z).length())),-deg_to_rad(80),deg_to_rad(80))
	return {"direction":world_aim,"pitch":pitch,"yaw":yaw}

func _focused_target_direction(player:CharacterBody3D) -> Vector3:
	if is_instance_valid(camera_focus_target) and camera_focus_target!=player and camera_focus_target.health>0:
		return (_focused_target_chest_point(camera_focus_target)-player.global_position).normalized()
	return Vector3.ZERO

func _cast_linked_spell(animation_id: String, charge_profile:Dictionary={},aim_direction:Vector3=Vector3.ZERO) -> void:
	if training_mode or fighters.is_empty() or not round_active:return
	var player = fighters[0]
	if aim_direction.is_zero_approx():aim_direction=_story_action_aim(animation_id,player).direction
	for spell in player.story_spells_for_animation(animation_id):
		_cast_linked_spell_item(animation_id,player,spell,charge_profile,aim_direction)

func _cast_linked_spell_item(animation_id:String,player,spell:Dictionary,charge_profile:Dictionary={},aim_direction:Vector3=Vector3.ZERO) -> void:
	if spell.is_empty():return
	var spell_name := str(spell.get("spell", spell.get("name", ""))).to_lower()
	if spell_name.contains("barrier") or str(spell.get("effect", "")).to_lower()=="barrier":
		GameDiagnostics.log_event("story_barrier_linked", {"animation":animation_id,"spell":spell.get("id","")})
		return
	var is_heal:=str(spell.get("effect","")).to_lower()=="heal" or spell_name.contains("heal") or spell_name.contains("mend") or spell_name.contains("restore")
	if not spell_name.contains("fireball") and not is_heal:
		GameDiagnostics.log_event("story_spell_link_unsupported", {"animation":animation_id,"spell":spell.get("id","")})
		return
	var spec:Dictionary
	if is_heal:
		spec={"id":str(spell.get("id","ally_mend")),"name":str(spell.get("spell",spell.get("name","Mend"))),"effect":"heal","hand":"both","heal_amount":float(spell.get("heal_amount",22.0)),"mana":float(spell.get("mana",18.0))}
	else:
		spec=profile_spells(0)[0].duplicate(true)
		spec["projectile_element"]="Fire"
	spec["hand"]="both" if is_heal else _calibration_emitter(animation_id)
	spec["cast_limb"]=spec["hand"]
	if not aim_direction.is_zero_approx():
		spec["aim_direction"]=_raise_spell_aim(player,aim_direction,DEFAULT_SPELL_AIM_LIFT) if not is_heal else aim_direction.normalized()
	spec["charge"]=0.0
	var damage_scale:=float(charge_profile.get("damage_multiplier",1.0))*(2.0 if bool(charge_profile.get("critical",false)) else 1.0)
	if damage_scale>1.0:spec["damage"]=damage_for(spec)*damage_scale
	spec["charge_tier"]=str(charge_profile.get("tier","NORMAL"))
	spec["critical"]=bool(charge_profile.get("critical",false))
	var cost:=mana_cost(spec)
	if player.mana<cost:
		GameDiagnostics.log_event("story_spell_cast_blocked", {"animation":animation_id,"spell":spell.get("id",""),"reason":"insufficient_mana","mana":player.mana,"cost":cost})
		return
	if not player.can_cast_with(spec):
		GameDiagnostics.log_event("story_spell_cast_blocked", {"animation":animation_id,"spell":spell.get("id",""),"reason":"cast_limb_restrained"})
		return
	player.story_spell_dispatching=true
	cast_magic(player,spec,false)
	player.story_spell_dispatching=false
	GameDiagnostics.log_event("story_spell_cast", {"animation":animation_id,"spell":spell.get("id",""),"element":spell.get("element","Nature" if is_heal else "Fire"),"target":camera_focus_target.story_profile.get("name","") if is_heal and is_instance_valid(camera_focus_target) and camera_focus_target.team==player.team else player.story_profile.get("name",""),"mana_remaining":player.mana})

func _raise_spell_aim(player:CharacterBody3D,direction:Vector3,lift:float)->Vector3:
	var safe_direction:=_constrain_aim_to_front(player,direction.normalized())
	var horizontal:=Vector3(safe_direction.x,0.0,safe_direction.z)
	if horizontal.is_zero_approx():return safe_direction
	var pitch:=atan2(safe_direction.y,horizontal.length())
	var raised_pitch:=clampf(pitch+lift,-0.05,deg_to_rad(82.0))
	return (horizontal.normalized()*cos(raised_pitch)+Vector3.UP*sin(raised_pitch)).normalized()

func _use_story_ability(ability: String) -> void:
	if fighters.is_empty() or (not round_active and not post_fight_freeplay):
		return
	var player = fighters[0]
	if ability == "front_kick" and story_stage < 4:
		return
	if ability == "dash" and story_stage < 5:
		return
	if player.has_story_ability(ability) and (player.player_controlled or player.mode in ["idle", "run"]):
		if ability == "front_kick":
			GameDiagnostics.log_event("combat_action", {"fighter":"player", "action":ability, "fight":story_stage})
			var before:int=player.story_strikes.size()
			var aim_result:=_story_action_aim(ability,player)
			player.start_story_front_kick({},aim_result.direction,float(aim_result.pitch))
			if player.story_strikes.size()>before:_cast_linked_spell(ability,{},aim_result.direction)
