extends PanelContainer
## Projectile and summon workspaces share casting, size and potency controls.
const TYPES=["Projectiles","Buffs","Barriers","Debuffs","Summons","Teleports","Arena Settings"]
const Projectile=preload("res://scripts/basic_projectile.gd")
const CastPose=preload("res://scripts/spell_cast_motion.gd")
const RigPose=preload("res://scripts/editor_rig_pose.gd")
const Provenance=preload("res://scripts/asset_provenance.gd")
const Allocation=preload("res://scripts/projectile_allocation.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
var spell_provenance:Dictionary={}
var spell_provenance_signature:=""
var editor:Node
var manual_aim:=false
var spell_focus_target:CharacterBody3D
var manual_aim_point:=Vector3.ZERO
var manual_aim_valid:=false
var preview_hitboxes:=false
var projectile_hitbox_button:Button
var third_person_ready:=false
var third_person_orbiting:=false
var third_person_mouse_origin:=Vector2.ZERO
var third_person_crosshair:Control
const ThirdPersonCamera=preload("res://scripts/third_person_camera.gd")
const CombatAim=preload("res://scripts/combat_aim.gd")
const Movement=preload("res://scripts/character_movement.gd")
var draft_path:="user://projectile_spell_draft.cfg"
var category:="Projectiles"
var spell_kind:="Projectiles"
var casting_animation:Dictionary={}
var preview_preferences_path:="user://spell_preview_preferences.cfg"
var demo_source_ready:=false
var demo_button:Button
var demo_dialog:ConfirmationDialog
var demo_search:LineEdit
var demo_list:ItemList
var demo_entries:Array[Dictionary]=[]
var demo_visible_entries:Array[Dictionary]=[]
var demo_only_stage:=true
var demo_choices:Dictionary={}
const DEMO_ANIMATIONS:={"cross":{"title":"Left cross","source":"Left cross"},"hook":{"title":"Melee hook","source":"Melee Hook"},"knee":{"title":"Left knee","source":"Left knee"},"block":{"title":"Block stand","source":"block stand"},"mend":{"title":"Self mend","source":"self mend"}}
var demo_duration:=1.0
var limiter_enabled:=true
var limiter_toggle:CheckButton
var limiter_notice:Label
var limiter_warning:AcceptDialog
var test_overrides=preload("res://scripts/spell_test_overrides.gd").new()
var test_inputs:Dictionary={}
var test_extra_rows:Array[Control]=[]
var duration_endpoints:HBoxContainer
var power_balance_label:Label
var demo_duration_slider:HSlider
var demo_duration_label:Label
var demo_mana_cost_label:Label
var demo_mana_base_label:Label
var demo_amplifier_label:Label
var demo_size_bonus_label:Label
var demo_speed_bonus_label:Label
var demo_burn_label:Label
var projectile_allocations:Dictionary={}
var allocation_sliders:Dictionary={}
var allocation_labels:Dictionary={}
var allocation_rows:Dictionary={}
var projectile_scroll:ScrollContainer
var demo_stamina_label:Label
var demo_damage_label:Label
var demo_damage_breakdown:Label
var demo_stamina_note:Label
var demo_amp_breakdown:Label
const PROJECTILE_EFFECTS:=["None","Fire","Ice","Lightning","Wind","Water","Earth"]
var preview_effect:="None"
var projectile_effect_confirmed:=false
var effect_choices:Dictionary={}
var effect_confirm_button:Button
var spell_playback_panel:PanelContainer
var demo_timing_panel:PanelContainer
var demo_enter_pose:Array[Transform3D]=[]
var demo_exit_pose:Array[Transform3D]=[]
var demo_exit_elapsed:=0.0
const DEMO_TRANSITION_SECONDS:=0.18
var demo_confirm_button:Button
const DELIVERY_TYPES:=["Projectile","Targeted","Touch","Barrier"]
var delivery_type:=""
var creation_step:="demo"
var demo_screen:VBoxContainer
var delivery_screen:VBoxContainer
var delivery_choices:Dictionary={}
var delivery_back_button:Button
var delivery_demo_label:Label
var projectile_screen:VBoxContainer
var projectile_name_label:Label
var projectile_preview_button:Button
var projectile_repeat_button:Button
var projectile_slow_button:Button
var reset_scene_button:Button
var preview_repeating:=false
var preview_slow:=false
var preview_original_time_scale:=1.0
var projectile_back_button:Button
var projectile_initialized:=false
const MIN_RELEASE_FRACTION:=0.05
const MAX_RELEASE_FRACTION:=0.55
const MAX_RELEASE_BONUS:=0.25
var release_fraction:=MIN_RELEASE_FRACTION
var release_slider:HSlider
var playing:=false
var released:=false
var elapsed:=0.0
var idle_elapsed:=0.0
var categories:Dictionary={}
var content:VBoxContainer
var controls:VBoxContainer
var empty_label:Label
var element:="None"
var projectile_velocity:=14.0
var velocity_row:HBoxContainer
var velocity_slider:HSlider
var velocity_input:SpinBox
var potency:=1.0
var potency_slider:HSlider
var potency_label:Label
var projectile_size:=0.20
var starting_distance:=5.0
var element_buttons:Dictionary={}
var size_slider:HSlider
var size_label:Label
var mana_label:Label
var effect_label:Label
var distance_input:SpinBox
var distance_slider:HSlider
var current_distance:Label
var shots:Array[Dictionary]=[]
var repeat_wait:=0.0
const MAX_RADIUS:=2.0
const REPEAT_DELAY:=0.55
var size_input:SpinBox
var element_heading:Label
var elements:HFlowContainer
var preview_label:Label
var summon_button:Button
var summon_label:Label
var arena_settings:VBoxContainer
var potency_input:SpinBox
var budget_label:Label
var testing_sizes:=false
var testing_toggle:CheckButton
var radius_warning:Label
var appearances:Dictionary={}
var appearance_controls:VBoxContainer
var trail_texture_input:OptionButton
var texture_input:OptionButton
var preset_input:OptionButton
var orbit_input:CheckButton
var trail_input:OptionButton
var shape_input:OptionButton
var color_input:ColorPickerButton
var accent_input:ColorPickerButton
var appearance_sliders:Dictionary={}
var budget_meter:ProgressBar
var resizing:=false
var resize_edges:=Vector2.ZERO
var resize_origin:=Rect2()
var resize_grips:Array[Control]=[]
var movement_keys:Dictionary={}
var caster_moving:=false
var caster_move_axes:=Vector2.ZERO
var caster_sprinting:=false
var dummy_god_mode:=true
var character_god_modes:Dictionary={}
var dummy_god_button:Button
var dummy_total_damage:=0.0
var dummy_last_damage:=0.0
var dummy_damage_mark:=0.0
var dummy_hit_text:Label3D
var dummy_hit_age:=0.0
var practice_human:CharacterBody3D

func setup(owner_editor:Node) -> void:
 editor=owner_editor
 set_process(true)
 set_process_input(true)
 # Keep the old self/barrier draft untouched; this is a separate projectile draft.
 if not draft_path.is_empty() and draft_path=="user://spell_draft.cfg":draft_path="user://projectile_spell_draft.cfg"
 var style=StyleBoxFlat.new()
 style.bg_color=Color("e8ddc4")
 style.border_color=Color("b5a27f")
 style.set_border_width_all(1)
 style.set_corner_radius_all(0)
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,12)
 add_theme_stylebox_override("panel",style)
 var layout=HBoxContainer.new()
 layout.add_theme_constant_override("separation",12)
 add_child(layout)
 var sidebar=VBoxContainer.new()
 sidebar.custom_minimum_size.x=130
 layout.add_child(sidebar)
 for type in TYPES:
  var node:Button=editor.button(sidebar,type,func():select_category(type))
  node.add_theme_font_size_override("font_size",15)
  categories[type]=node
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 layout.add_child(scroll)
 content=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",10)
 scroll.add_child(content)
 editor.menu_label(content,"SPELLS",24)
 editor.menu_label(content,"1. Demo animation",17)
 demo_button=editor.button(content,"Choose demo animation",open_demo_animation_picker)
 demo_button.name="DemoAnimationPicker"
 demo_button.clip_text=true
 var demo_help=editor.menu_label(content,"For previewing while you build. This animation is not attached to your spell.",13)
 demo_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 empty_label=editor.menu_label(content,"",16)
 empty_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 controls=VBoxContainer.new()
 controls.add_theme_constant_override("separation",8)
 content.add_child(controls)
 editor.menu_label(controls,"2. Build your spell",17)
 preview_label=editor.menu_label(controls,"Projectile preview loops automatically",14)
 summon_label=editor.menu_label(controls,"Earth Wall",20)
 summon_button=editor.button(controls,"Cast Earth Wall",play_cast_preview)
 summon_button.tooltip_text=preload("res://scripts/element_interactions.gd").tooltip("Earth")
 element_heading=editor.menu_label(controls,"Element",17)
 elements=HFlowContainer.new()
 controls.add_child(elements)
 for value in Projectile.ELEMENTS:
  var choice:Button=editor.button(elements,value,func():set_element(value))
  choice.tooltip_text=preload("res://scripts/element_interactions.gd").tooltip(value)
  choice.custom_minimum_size=Vector2(90,34)
  elements.add_theme_constant_override("separation",6)
  element_buttons[value]=choice
 effect_label=editor.menu_label(controls,"",13)
 effect_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var size_row=HBoxContainer.new()
 size_row.add_theme_constant_override("separation",10)
 controls.add_child(size_row)
 size_label=editor.menu_label(size_row,"Radius",16)
 size_label.custom_minimum_size.x=95
 size_slider=HSlider.new()
 size_slider.min_value=0.1
 size_slider.max_value=MAX_RADIUS
 size_slider.step=0.01
 size_slider.exp_edit=true
 size_slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 size_slider.value_changed.connect(set_projectile_size)
 size_row.add_child(size_slider)
 size_input=SpinBox.new()
 size_input.min_value=0.1
 size_input.max_value=MAX_RADIUS
 size_input.step=0.01
 size_input.suffix=" m"
 size_input.custom_minimum_size.x=108
 size_input.value_changed.connect(set_projectile_size)
 size_row.add_child(size_input)
 var potency_row=HBoxContainer.new()
 potency_row.add_theme_constant_override("separation",10)
 controls.add_child(potency_row)
 potency_label=editor.menu_label(potency_row,"Potency",16)
 potency_label.custom_minimum_size.x=95
 potency_slider=HSlider.new()
 potency_slider.min_value=0.25
 potency_slider.max_value=4.0
 potency_slider.step=0.001
 potency_slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 potency_slider.value_changed.connect(set_potency)
 potency_row.add_child(potency_slider)
 potency_input=SpinBox.new()
 potency_input.min_value=0.25
 potency_input.max_value=4.0
 potency_input.step=0.001
 potency_input.suffix=" x"
 potency_input.custom_minimum_size.x=108
 potency_input.value_changed.connect(set_potency)
 potency_row.add_child(potency_input)
 velocity_row=HBoxContainer.new()
 velocity_row.add_theme_constant_override("separation",10)
 controls.add_child(velocity_row)
 var velocity_label=editor.menu_label(velocity_row,"Velocity",16)
 velocity_label.custom_minimum_size.x=95
 velocity_slider=HSlider.new()
 velocity_slider.min_value=Projectile.MIN_VELOCITY
 velocity_slider.max_value=Projectile.MAX_VELOCITY
 velocity_slider.step=0.01
 velocity_slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 velocity_slider.value_changed.connect(set_velocity)
 velocity_row.add_child(velocity_slider)
 velocity_input=SpinBox.new()
 velocity_input.min_value=Projectile.MIN_VELOCITY
 velocity_input.max_value=Projectile.MAX_VELOCITY
 velocity_input.step=0.01
 velocity_input.suffix=" m/s"
 velocity_input.custom_minimum_size.x=108
 velocity_input.value_changed.connect(set_velocity)
 velocity_row.add_child(velocity_input)
 budget_label=editor.menu_label(controls,"",13)
 budget_meter=ProgressBar.new()
 budget_meter.custom_minimum_size.y=8
 budget_meter.show_percentage=false
 controls.add_child(budget_meter)
 var budget_help=editor.menu_label(controls,"Shared power cap: radius, potency and velocity compete for the same output.",12)
 budget_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 mana_label=editor.menu_label(controls,"",20)
 mana_label.add_theme_color_override("font_color",Color("486d85"))
 editor.button(controls,"Spell credits",func():editor.inspect_asset_metadata({"title":element+" spell","provenance":spell_provenance,"spec":projectile_spec()}))
 radius_warning=editor.menu_label(controls,"TESTING ONLY · oversized spell",14)
 radius_warning.add_theme_color_override("font_color",Color("98703d"))
 appearance_controls=VBoxContainer.new()
 appearance_controls.add_theme_constant_override("separation",8)
 controls.add_child(appearance_controls)
 editor.menu_label(appearance_controls,"SPELL APPEARANCE",17)
 var preset_row=HBoxContainer.new()
 appearance_controls.add_child(preset_row)
 var preset_label=editor.menu_label(preset_row,"Preset",15)
 preset_label.custom_minimum_size.x=95
 preset_input=OptionButton.new()
 preset_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for name_ in ["Custom / element default","Fireball","Torch flame","Embers","Cold fire"]:preset_input.add_item(name_)
 preset_input.item_selected.connect(apply_visual_preset)
 preset_row.add_child(preset_input)
 var shape_row=HBoxContainer.new()
 appearance_controls.add_child(shape_row)
 var shape_label=editor.menu_label(shape_row,"Shape",15)
 shape_label.custom_minimum_size.x=95
 shape_input=OptionButton.new()
 shape_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for shape in preload("res://scripts/spell_appearance.gd").SHAPES:shape_input.add_item(shape)
 shape_input.item_selected.connect(func(index:int):
  if shape_input.get_item_text(index)=="Drawn":open_drawing(true)
  else:set_appearance("shape",shape_input.get_item_text(index)))
 shape_row.add_child(shape_input)
 var draw_row=HBoxContainer.new()
 appearance_controls.add_child(draw_row)
 editor.button(draw_row,"Draw shape",func():open_drawing(true))
 editor.button(draw_row,"Draw trail",func():open_drawing(false))
 var texture_row=HBoxContainer.new()
 appearance_controls.add_child(texture_row)
 var texture_label=editor.menu_label(texture_row,"Texture",15)
 texture_label.custom_minimum_size.x=95
 texture_input=OptionButton.new()
 texture_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 texture_input.add_item("Element style")
 for name_ in preload("res://scripts/spell_textures.gd").NAMES+preload("res://scripts/spell_textures.gd").user_names():
  var source:Texture2D=preload("res://scripts/spell_textures.gd").texture(name_)
  var icon_image:Image=source.get_image()
  icon_image.resize(24,24,Image.INTERPOLATE_LANCZOS)
  texture_input.add_icon_item(ImageTexture.create_from_image(icon_image),name_)
 texture_input.item_selected.connect(func(index:int):set_appearance("texture",texture_input.get_item_text(index)))
 texture_row.add_child(texture_input)
 editor.button(texture_row,"Import PNG",open_texture_import)
 var trail_texture_row=HBoxContainer.new()
 appearance_controls.add_child(trail_texture_row)
 var trail_texture_label=editor.menu_label(trail_texture_row,"Trail mask",15)
 trail_texture_label.custom_minimum_size.x=95
 trail_texture_input=OptionButton.new()
 trail_texture_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 trail_texture_input.add_item("Element style")
 for i in range(1,texture_input.item_count):trail_texture_input.add_icon_item(texture_input.get_item_icon(i),texture_input.get_item_text(i))
 trail_texture_input.item_selected.connect(func(index:int):set_appearance("trail_texture",trail_texture_input.get_item_text(index)))
 trail_texture_row.add_child(trail_texture_input)
 var color_row=HBoxContainer.new()
 appearance_controls.add_child(color_row)
 var color_label=editor.menu_label(color_row,"Colours",15)
 color_label.custom_minimum_size.x=95
 color_input=ColorPickerButton.new()
 color_input.custom_minimum_size=Vector2(80,30)
 color_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 color_input.color_changed.connect(func(value:Color):set_appearance("color",value))
 color_input.tooltip_text="Primary colour"
 color_row.add_child(color_input)
 accent_input=ColorPickerButton.new()
 accent_input.custom_minimum_size=Vector2(80,30)
 accent_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 accent_input.color_changed.connect(func(value:Color):set_appearance("accent",value))
 accent_input.tooltip_text="Highlight and ring colour"
 color_row.add_child(accent_input)
 var trail_row=HBoxContainer.new()
 appearance_controls.add_child(trail_row)
 var trail_label=editor.menu_label(trail_row,"Trail style",15)
 trail_label.custom_minimum_size.x=95
 trail_input=OptionButton.new()
 trail_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for style_name in ["Element style","Sparks","Smoke","Wisps","None","Drawn"]:trail_input.add_item(style_name)
 trail_input.item_selected.connect(func(index:int):
  if trail_input.get_item_text(index)=="Drawn":open_drawing(false)
  else:set_appearance("trail_style",trail_input.get_item_text(index)))
 trail_row.add_child(trail_input)
 orbit_input=CheckButton.new()
 orbit_input.text="Orbit rings"
 orbit_input.toggled.connect(func(value:bool):set_appearance("orbits",value))
 appearance_controls.add_child(orbit_input)
 appearance_row("Glow","glow",0,3,0.05)
 appearance_row("Opacity","opacity",0.1,1,0.05)
 appearance_row("Trail","trail",0,1,0.05)
 appearance_row("Pulse","pulse",0,1,0.05)
 appearance_row("Swirl","spin",0,4,0.1)
 editor.button(appearance_controls,"Reset element appearance",reset_appearance)
 arena_settings=VBoxContainer.new()
 arena_settings.add_theme_constant_override("separation",12)
 content.add_child(arena_settings)
 editor.menu_label(arena_settings,"ARENA SETTINGS",20)
 testing_toggle=CheckButton.new()
 testing_toggle.text="Testing: allow radius above 2 m (up to 30 m)"
 testing_toggle.toggled.connect(set_testing_sizes)
 arena_settings.add_child(testing_toggle)
 var distance_row=HBoxContainer.new()
 distance_row.add_theme_constant_override("separation",10)
 arena_settings.add_child(distance_row)
 var distance_label=editor.menu_label(distance_row,"Starting distance",15)
 distance_label.custom_minimum_size.x=130
 distance_slider=HSlider.new()
 distance_slider.min_value=0.5
 distance_slider.max_value=20
 distance_slider.step=0.5
 distance_slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 distance_slider.value_changed.connect(set_distance)
 distance_row.add_child(distance_slider)
 distance_input=SpinBox.new()
 distance_input.min_value=0.5
 distance_input.max_value=20
 distance_input.step=0.5
 distance_input.suffix=" m"
 distance_input.custom_minimum_size.x=108
 distance_input.value_changed.connect(set_distance)
 distance_row.add_child(distance_input)
 editor.button(arena_settings,"Reset Field - Apply distance",reset_field)
 current_distance=editor.menu_label(arena_settings,"",13)
 choose_default(false)
 load_draft()
 load_demo_preferences()
 refresh()
 # Keep the established spell builder available underneath this first step.
 # The visible first step uses the user's collection clips and timing.
 layout.hide()
 demo_screen=VBoxContainer.new()
 demo_screen.name="DemoAnimationChoices"
 demo_screen.add_theme_constant_override("separation",8)
 add_child(demo_screen)
 var demo_columns:=HBoxContainer.new()
 demo_columns.add_theme_constant_override("separation",16)
 demo_screen.add_child(demo_columns)
 var choices_column:=VBoxContainer.new()
 choices_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 demo_columns.add_child(choices_column)
 editor.menu_label(choices_column,"Choose a demo animation",20)
 for choice_key in DEMO_ANIMATIONS:
  var choice:String=choice_key
  var node:Button=editor.button(choices_column,str(DEMO_ANIMATIONS[choice].title),func():select_demo_choice(choice))
  node.name="Demo"+choice.capitalize()
  node.custom_minimum_size.y=40
  demo_choices[choice]=node
 var help:Label=editor.menu_label(choices_column,"Preview only. You can change this anytime.",14)
 help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 demo_confirm_button=editor.button(choices_column,"Confirm",confirm_demo_choice)
 demo_confirm_button.name="ConfirmDemoAnimation"
 var timing_column:=VBoxContainer.new()
 timing_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 timing_column.add_theme_constant_override("separation",6)
 demo_timing_panel=PanelContainer.new()
 demo_timing_panel.name="SpellDemoTiming"
 demo_timing_panel.add_theme_stylebox_override("panel",style.duplicate())
 editor.base_ui.add_child(demo_timing_panel)
 demo_timing_panel.anchor_left=0.74
 demo_timing_panel.anchor_right=1.0
 demo_timing_panel.anchor_bottom=1.0
 demo_timing_panel.offset_top=54
 demo_timing_panel.offset_right=0
 demo_timing_panel.offset_bottom=-60
 var timing_scroll:=ScrollContainer.new()
 timing_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 demo_timing_panel.add_child(timing_scroll)
 timing_scroll.add_child(timing_column)
 limiter_toggle=CheckButton.new()
 limiter_toggle.name="SpellLimiter"
 limiter_toggle.text="Limiter"
 limiter_toggle.button_pressed=true
 limiter_toggle.focus_mode=Control.FOCUS_ALL
 limiter_toggle.toggled.connect(set_limiter_enabled)
 timing_column.add_child(limiter_toggle)
 limiter_notice=editor.menu_label(timing_column,"TESTING ONLY · Saving disabled",14)
 limiter_notice.add_theme_color_override("font_color",Color("bb443d"))
 limiter_notice.hide()
 demo_mana_cost_label=editor.menu_label(timing_column,"",21)
 demo_mana_cost_label.add_theme_color_override("font_color",Color("328fc4"))
 demo_mana_base_label=editor.menu_label(timing_column,"",14)
 demo_mana_base_label.add_theme_color_override("font_color",Color("328fc4"))
 editor.menu_label(timing_column,"Animation duration",18)
 demo_duration_label=editor.menu_label(timing_column,"",30)
 demo_duration_slider=HSlider.new()
 demo_duration_slider.name="DemoDuration"
 demo_duration_slider.min_value=0.1
 demo_duration_slider.max_value=60.0
 demo_duration_slider.step=0.1
 demo_duration_slider.exp_edit=true
 demo_duration_slider.custom_minimum_size=Vector2(230,36)
 demo_duration_slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 demo_duration_slider.value_changed.connect(set_demo_duration)
 timing_column.add_child(demo_duration_slider)
 var endpoints:=HBoxContainer.new()
 duration_endpoints=endpoints
 timing_column.add_child(endpoints)
 var start:Label=editor.menu_label(endpoints,"0.1 s",13)
 var endpoint_space:=Control.new()
 endpoint_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 endpoints.add_child(endpoint_space)
 editor.menu_label(endpoints,"60 s",13)
 editor.menu_label(timing_column,"Spell timing",18)
 release_slider=HSlider.new()
 release_slider.name="ProjectileReleaseTiming"
 release_slider.min_value=MIN_RELEASE_FRACTION*100.0
 release_slider.max_value=MAX_RELEASE_FRACTION*100.0
 release_slider.step=1
 release_slider.custom_minimum_size=Vector2(230,28)
 release_slider.focus_mode=Control.FOCUS_ALL
 release_slider.value_changed.connect(func(value:float):set_release_fraction(value/100.0))
 timing_column.add_child(release_slider)
 release_slider.tooltip_text="Early cast → apex. Casting near the apex gives full Spell amp."
 power_balance_label=editor.menu_label(timing_column,"Power balance",18)
 for allocation_key in ["size","speed","effect"]:
  var key:String=allocation_key
  var row:=HBoxContainer.new()
  row.add_theme_constant_override("separation",6)
  timing_column.add_child(row)
  allocation_rows[key]=row
  allocation_labels[key]=editor.menu_label(row,"",15)
  allocation_labels[key].custom_minimum_size.x=100
  var slider:=HSlider.new()
  slider.name="ProjectileBalance"+key.capitalize()
  slider.min_value=0
  slider.max_value=100
  slider.step=0.1
  slider.custom_minimum_size=Vector2(0,24)
  slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  slider.focus_mode=Control.FOCUS_ALL
  slider.tooltip_text="Shares one budget. Raising this reduces the other sliders."
  slider.value_changed.connect(func(value:float):set_projectile_allocation(key,value/100.0))
  row.add_child(slider)
  allocation_sliders[key]=slider
 demo_stamina_label=editor.menu_label(timing_column,"",19)
 demo_stamina_label.add_theme_color_override("font_color",Color("388753"))
 demo_stamina_note=editor.menu_label(timing_column,"",13)
 demo_stamina_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 demo_damage_label=editor.menu_label(timing_column,"",19)
 demo_damage_label.add_theme_color_override("font_color",Color("bb443d"))
 demo_damage_label.tooltip_text="Physical impact scales with projectile speed. 14 m/s = ×1 damage. Burn is separate."
 demo_damage_breakdown=editor.menu_label(timing_column,"",13)
 demo_damage_breakdown.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 demo_amplifier_label=editor.menu_label(timing_column,"",19)
 demo_amplifier_label.add_theme_color_override("font_color",Color("8154a5"))
 demo_amplifier_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 demo_amp_breakdown=editor.menu_label(timing_column,"",13)
 demo_amp_breakdown.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 demo_size_bonus_label=editor.menu_label(timing_column,"",17)
 demo_size_bonus_label.add_theme_color_override("font_color",Color("8154a5"))
 demo_speed_bonus_label=editor.menu_label(timing_column,"",17)
 demo_speed_bonus_label.add_theme_color_override("font_color",Color("8154a5"))
 demo_burn_label=editor.menu_label(timing_column,"",17)
 demo_burn_label.add_theme_color_override("font_color",Color("bb6937"))
 add_test_input("duration",demo_duration_slider," s")
 add_test_input("release",release_slider," %")
 for key in allocation_sliders:add_test_input(key,allocation_sliders[key]," %")
 for key in ["mana","stamina","damage"]:
  var row:=HBoxContainer.new()
  timing_column.add_child(row)
  timing_column.move_child(row,demo_stamina_label.get_index())
  var caption:Label=editor.menu_label(row,{"mana":"Mana cost","stamina":"Stamina depletion","damage":"Physical damage"}[key],15)
  caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  caption.add_theme_color_override("font_color",{"mana":Color("328fc4"),"stamina":Color("388753"),"damage":Color("bb443d")}[key])
  add_test_input(key,row,"")
  test_extra_rows.append(row)
  row.hide()
 refresh_projectile_allocation()
 refresh_demo_timing()
 delivery_screen=VBoxContainer.new()
 delivery_screen.name="SpellDeliveryChoices"
 delivery_screen.add_theme_constant_override("separation",8)
 add_child(delivery_screen)
 editor.menu_label(delivery_screen,"Choose spell type",20)
 for type in DELIVERY_TYPES:
  var node:Button=editor.button(delivery_screen,type,func():choose_delivery_type(type))
  node.name="SpellType"+type
  node.custom_minimum_size.y=40
  node.disabled=type!="Projectile"
  if node.disabled:node.tooltip_text="Not available yet"
  delivery_choices[type]=node
 delivery_demo_label=editor.menu_label(delivery_screen,"",13)
 delivery_demo_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 delivery_back_button=editor.button(delivery_screen,"← Back",func():show_creation_step("demo"))
 delivery_back_button.tooltip_text="Back to demo animation choices"
 projectile_screen=VBoxContainer.new()
 projectile_screen.name="ProjectileWorkspace"
 projectile_screen.add_theme_constant_override("separation",8)
 projectile_scroll=ScrollContainer.new()
 projectile_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 add_child(projectile_scroll)
 projectile_screen.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 projectile_scroll.add_child(projectile_screen)
 editor.menu_label(projectile_screen,"Projectile",20)
 projectile_name_label=editor.menu_label(projectile_screen,"Elementless projectile",24)
 projectile_name_label.add_theme_color_override("font_color",Color("bb6937"))
 editor.menu_label(projectile_screen,"Choose an effect",20)
 var effects:=GridContainer.new()
 effects.columns=2
 effects.add_theme_constant_override("h_separation",6)
 effects.add_theme_constant_override("v_separation",6)
 projectile_screen.add_child(effects)
 for effect in PROJECTILE_EFFECTS:
  var choice:Button=editor.button(effects,"No effect" if effect=="None" else effect,func():preview_projectile_effect(effect))
  choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  choice.focus_mode=Control.FOCUS_ALL
  choice.disabled=effect not in ["None","Fire"]
  if choice.disabled:choice.tooltip_text="Not available yet"
  effect_choices[effect]=choice
 effect_confirm_button=editor.button(projectile_screen,"Confirm",confirm_projectile_effect)
 effect_confirm_button.focus_mode=Control.FOCUS_ALL
 spell_playback_panel=PanelContainer.new()
 spell_playback_panel.name="SpellPlayback"
 spell_playback_panel.add_theme_stylebox_override("panel",style.duplicate())
 editor.base_ui.add_child(spell_playback_panel)
 spell_playback_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 spell_playback_panel.offset_top=-60
 spell_playback_panel.offset_bottom=0
 var playback_row:=HBoxContainer.new()
 playback_row.alignment=BoxContainer.ALIGNMENT_CENTER
 playback_row.add_theme_constant_override("separation",6)
 spell_playback_panel.add_child(playback_row)
 projectile_preview_button=editor.button(playback_row,"Play [1]",play_projectile_once)
 projectile_preview_button.name="PreviewProjectile"
 projectile_preview_button.tooltip_text="Play once · 1"
 projectile_repeat_button=editor.button(playback_row,"Repeat",func():pass)
 projectile_repeat_button.name="RepeatSpellPreview"
 projectile_repeat_button.toggle_mode=true
 projectile_repeat_button.toggled.connect(set_preview_repeat)
 projectile_repeat_button.tooltip_text="Keep casting until Repeat is switched off"
 projectile_slow_button=editor.button(playback_row,"Slow mo",func():pass)
 projectile_slow_button.name="SlowSpellPreview"
 projectile_slow_button.toggle_mode=true
 projectile_slow_button.toggled.connect(set_preview_slow)
 projectile_slow_button.tooltip_text="Preview at quarter speed"
 projectile_hitbox_button=editor.button(playback_row,"Hitboxes [2]",func():pass)
 projectile_hitbox_button.name="SpellHitboxes"
 projectile_hitbox_button.toggle_mode=true
 projectile_hitbox_button.set_pressed_no_signal(preview_hitboxes)
 projectile_hitbox_button.toggled.connect(set_preview_hitboxes)
 projectile_hitbox_button.tooltip_text="Show actual spell collision spheres · 2"
 for node in [projectile_preview_button,projectile_repeat_button,projectile_slow_button,projectile_hitbox_button]:
  node.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  node.custom_minimum_size.x=140
  node.focus_mode=Control.FOCUS_ALL
 reset_scene_button=editor.button(playback_row,"Reset scene",reset_practice_scene)
 reset_scene_button.name="ResetSpellPracticeScene"
 reset_scene_button.custom_minimum_size.x=140
 reset_scene_button.focus_mode=Control.FOCUS_ALL
 reset_scene_button.tooltip_text="Heal and restore the practice scene; keep your spell settings."
 var movement_hint:Label=editor.menu_label(playback_row,"WASD · Move   F · Focus",14)
 movement_hint.tooltip_text="W forward · A/D strafe · S backpedal · Combine keys for diagonals · Shift runs · F focuses the camera."
 projectile_back_button=editor.button(projectile_screen,"← Back",func():show_creation_step("delivery"))
 projectile_back_button.tooltip_text="Back to spell types"
 editor.menu_label(projectile_screen,"Selected character",18)
 dummy_god_button=editor.button(projectile_screen,"God mode: On",func():pass)
 dummy_god_button.name="MannequinGodMode"
 dummy_god_button.toggle_mode=true
 dummy_god_button.focus_mode=Control.FOCUS_ALL
 dummy_god_button.toggled.connect(set_selected_god_mode)
 dummy_god_button.tooltip_text="Click a character, including yourself, then toggle unlimited health, stamina and mana. Hits and reactions still apply."
 var dummy_reset_button:Button=editor.button(projectile_screen,"Reset mannequin",reset_training_dummy)
 dummy_reset_button.name="ResetPracticeMannequin"
 dummy_reset_button.focus_mode=Control.FOCUS_ALL
 refresh_dummy_controls()
 show_creation_step("demo")
 refresh_demo_choices()
 visibility_changed.connect(workspace_visibility_changed)

func choose_default(save:=true) -> void:
 select_demo_choice("cross",save)

func confirm_demo_choice() -> void:
 if DEMO_ANIMATIONS.has(str(casting_animation.get("demo_choice",""))):show_creation_step("delivery")

func show_creation_step(step:String) -> void:
 if creation_step=="projectile" and step!="projectile":
  stop_preview_controls()
  playing=false
  begin_demo_exit()
  clear_shots()
 creation_step=step if step in ["demo","delivery","projectile"] else "demo"
 if not is_instance_valid(demo_screen) or not is_instance_valid(delivery_screen):return
 demo_screen.visible=creation_step=="demo"
 delivery_screen.visible=creation_step=="delivery"
 if is_instance_valid(projectile_screen):projectile_screen.visible=creation_step=="projectile"
 if is_instance_valid(projectile_scroll):projectile_scroll.visible=creation_step=="projectile"
 if is_instance_valid(spell_playback_panel):spell_playback_panel.visible=is_visible_in_tree() and creation_step=="projectile"
 layout_connected_panels()
 if is_instance_valid(demo_timing_panel):
  demo_timing_panel.visible=is_visible_in_tree()
  demo_timing_panel.anchor_left=0.74
  demo_timing_panel.anchor_right=1.0
  demo_timing_panel.offset_left=0
  demo_timing_panel.offset_right=0
  anchor_left=0.0
  anchor_right=0.32
  offset_left=0
  offset_right=0
 delivery_demo_label.text="Demo: %s · preview only"%str(casting_animation.get("title","Left cross"))
 refresh_delivery_choices()

func layout_connected_panels() -> void:
 var bottom:= -60.0 if creation_step=="projectile" else 0.0
 anchor_top=0.0
 anchor_bottom=1.0
 offset_top=54
 offset_bottom=bottom
 if is_instance_valid(demo_timing_panel):
  demo_timing_panel.anchor_top=0.0
  demo_timing_panel.anchor_bottom=1.0
  demo_timing_panel.offset_top=54
  demo_timing_panel.offset_bottom=bottom

func choose_delivery_type(value:String) -> void:
 if value!="Projectile":return
 delivery_type=value
 refresh_delivery_choices()
 if value=="Projectile":open_projectile_workspace()
 else:save_draft()
 GameDiagnostics.log_event("spell_delivery_selected",{"delivery_type":delivery_type,"demo":casting_animation.get("demo_choice","")})

func open_projectile_workspace() -> void:
 category="Projectiles"
 spell_kind="Projectiles"
 delivery_type="Projectile"
 if not projectile_initialized:
  projectile_initialized=true
  element="None"
  projectile_size=0.2
  potency=1.0
  projectile_velocity=Projectile.DEFAULT_VELOCITY
  testing_sizes=false
 if not projectile_effect_confirmed:element="None"
 if element not in ["None","Fire"]:
  element="None"
  projectile_effect_confirmed=false
 preview_effect=element
 refresh()
 refresh_effect_choices()
 refresh_demo_timing()
 show_creation_step("projectile")
 save_draft()
 play_demo_preview()

func preview_projectile_effect(value:String) -> void:
 if value not in ["None","Fire"]:return
 preview_effect=value
 refresh_effect_choices()
 refresh_demo_timing()
 play_demo_preview()

func confirm_projectile_effect() -> void:
 if preview_effect not in ["None","Fire"]:return
 element=preview_effect
 projectile_effect_confirmed=true
 refresh()
 refresh_effect_choices()
 save_draft()

func refresh_effect_choices() -> void:
 projectile_name_label.text="Elementless projectile" if preview_effect=="None" else preview_effect+" projectile"
 for effect in effect_choices:
  effect_choices[effect].add_theme_color_override("font_color",Color("98703d") if effect==preview_effect else Color("382c1c"))
 effect_confirm_button.text="Confirmed" if projectile_effect_confirmed and element==preview_effect else "Confirm"
 effect_confirm_button.disabled=projectile_effect_confirmed and element==preview_effect
 refresh_projectile_allocation()

func allocation_for(effect:String) -> Dictionary:
 var raw:Dictionary=projectile_allocations.get(effect,{})
 var result:=Allocation.normalize(raw,effect!="None")
 projectile_allocations[effect]=result
 return result

func set_projectile_allocation(key:String,value:float) -> void:
 if not limiter_enabled:
  set_test_value(key,value*100.0)
  return
 if preview_effect not in ["None","Fire"]:return
 if key=="effect" and preview_effect=="None":return
 projectile_allocations[preview_effect]=Allocation.change(allocation_for(preview_effect),key,value,preview_effect!="None")
 refresh_projectile_allocation()
 refresh_demo_timing()
 save_draft()
 if is_visible_in_tree() and creation_step=="projectile":
  play_demo_preview()

func refresh_projectile_allocation() -> void:
 if allocation_sliders.is_empty():return
 var shares:=allocation_for(preview_effect)
 for key in allocation_sliders:
  var active:=shares.has(key)
  allocation_rows[key].visible=active
  if not active:continue
  var percent:float=float(shares[key])*100.0 if limiter_enabled else float(test_overrides.values.get(key,0.0))
  allocation_sliders[key].set_value_no_signal(percent)
  var title:String="Burn" if key=="effect" else str(key).capitalize()
  allocation_labels[key].text="%s: %.1f%%"%[title,percent] if limiter_enabled else title

func play_projectile_once() -> void:
 set_preview_repeat(false)
 play_demo_preview()

func set_preview_hitboxes(enabled:bool) -> void:
 preview_hitboxes=enabled
 if is_instance_valid(projectile_hitbox_button):projectile_hitbox_button.set_pressed_no_signal(enabled)
 if is_instance_valid(editor.field):editor.field.set_projectile_hitboxes(enabled)
 save_demo_preferences()

func set_preview_repeat(enabled:bool) -> void:
 preview_repeating=enabled and creation_step=="projectile" and is_visible_in_tree()
 if is_instance_valid(projectile_repeat_button):projectile_repeat_button.set_pressed_no_signal(preview_repeating)
 repeat_wait=REPEAT_DELAY
 if preview_repeating and not playing:play_demo_preview()
 GameDiagnostics.log_event("spell_preview_repeat",{"enabled":preview_repeating})

func set_preview_slow(enabled:bool) -> void:
 if enabled==preview_slow:return
 if enabled:
  preview_original_time_scale=Engine.time_scale
  Engine.time_scale=0.25
 else:Engine.time_scale=preview_original_time_scale
 preview_slow=enabled
 if is_instance_valid(projectile_slow_button):projectile_slow_button.set_pressed_no_signal(preview_slow)
 GameDiagnostics.log_event("spell_preview_slow_motion",{"enabled":preview_slow,"time_scale":Engine.time_scale})

func stop_preview_controls() -> void:
 if preview_repeating:set_preview_repeat(false)
 if preview_slow:set_preview_slow(false)

func refresh_delivery_choices() -> void:
 for type in delivery_choices:
  delivery_choices[type].add_theme_color_override("font_color",Color("98703d") if type==delivery_type else Color("382c1c"))

func select_demo_choice(choice:String,save:=true) -> void:
 if not DEMO_ANIMATIONS.has(choice):return
 var source_name:String=str(DEMO_ANIMATIONS[choice].source).to_lower()
 var candidates:Array[Dictionary]=[]
 for owned in editor.store_library.taken.values():
  var owned_profile:Dictionary=owned.duplicate(true)
  owned_profile["store_raw"]=true
  candidates.append(owned_profile)
 for group in ["Motion","Attack"]:
  for folder in editor.category_store.names_for(group):candidates.append_array(editor.load_custom_motion(folder))
 candidates.append_array(preload("res://scripts/animation_catalog.gd").entries())
 for entry in candidates:
  if str(entry.get("title","")).to_lower()==source_name:
   var profile:Dictionary=entry.duplicate(true)
   profile.title=str(DEMO_ANIMATIONS[choice].title)
   profile["demo_choice"]=choice
   profile["duration"]=demo_duration
   if choose_demo_animation(profile,save) and is_visible_in_tree():play_demo_preview()
   return
 GameDiagnostics.log_event("spell_demo_source_missing",{"choice":choice,"requested_source":source_name})
 editor._show_library_notice("Demo animation not found in your folders: "+str(DEMO_ANIMATIONS[choice].source))

func add_test_input(key:String,control:Control,suffix:String) -> void:
 var row:HBoxContainer
 if control is HSlider:
  if control.get_parent() is HBoxContainer:row=control.get_parent()
  else:
   var parent:=control.get_parent()
   var index:=control.get_index()
   row=HBoxContainer.new()
   parent.remove_child(control)
   parent.add_child(row)
   parent.move_child(row,index)
   row.add_child(control)
  control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 else:row=control
 var input:=SpinBox.new()
 input.name="Unrestricted"+key.capitalize()
 input.min_value=0.0
 input.max_value=100.0
 input.allow_greater=true
 input.step=0.001 if key=="duration" else 0.1
 input.suffix=suffix
 input.custom_minimum_size.x=145
 input.size_flags_horizontal=Control.SIZE_SHRINK_END
 input.focus_mode=Control.FOCUS_ALL
 input.value_changed.connect(func(value:float):set_test_value(key,value))
 row.add_child(input)
 input.hide()
 test_inputs[key]=input
 if key in ["size","speed","effect"]:input.tooltip_text="100% = normal maximum. Independent final value; changing this does not change the other values."

func set_limiter_enabled(enabled:bool) -> void:
 if enabled==limiter_enabled:return
 stop_preview_controls()
 playing=false
 if not enabled:test_overrides.seed(demo_preview_spec(),demo_duration,release_fraction)
 limiter_enabled=enabled
 limiter_toggle.set_pressed_no_signal(enabled)
 limiter_notice.visible=not enabled
 duration_endpoints.visible=enabled
 power_balance_label.text="Power balance" if enabled else "Independent values"
 demo_duration_slider.exp_edit=enabled
 for key in test_inputs:test_inputs[key].visible=not enabled
 for row in test_extra_rows:row.visible=not enabled
 for slider in [demo_duration_slider,release_slider]:
  slider.set_block_signals(true)
  slider.allow_greater=not enabled
  slider.min_value=(0.1 if slider==demo_duration_slider else MIN_RELEASE_FRACTION*100.0) if enabled else 0.0
  slider.max_value=60.0 if slider==demo_duration_slider else (MAX_RELEASE_FRACTION*100.0 if enabled else 100.0)
  slider.set_block_signals(false)
 for key in allocation_sliders:
  allocation_sliders[key].set_block_signals(true)
  allocation_sliders[key].allow_greater=not enabled
  allocation_sliders[key].set_block_signals(false)
 for label in [demo_mana_base_label,demo_stamina_label,demo_damage_label,demo_stamina_note,demo_damage_breakdown,demo_amplifier_label,demo_amp_breakdown]:label.visible=enabled
 refresh_projectile_allocation()
 refresh_demo_timing()
 if not enabled:
  if not is_instance_valid(limiter_warning):
   limiter_warning=AcceptDialog.new()
   limiter_warning.title="Limiter off · Testing only"
   limiter_warning.dialog_text="Values are independent and spells cannot be saved.\nExtreme settings may freeze the game.\nExperiment at your own discretion."
   limiter_warning.ok_button_text="Understood"
   limiter_warning.get_label().add_theme_color_override("font_color",Color("fff3db"))
   add_child(limiter_warning)
  limiter_warning.popup_centered()

func set_test_value(key:String,value:float) -> void:
 if limiter_enabled:return
 test_overrides.set_value(key,value)
 refresh_projectile_allocation()
 refresh_test_controls()

func refresh_test_controls() -> void:
 var values:Dictionary=test_overrides.values
 for key in test_inputs:test_inputs[key].set_value_no_signal(float(values[key]))
 demo_duration_slider.set_value_no_signal(float(values.duration))
 release_slider.set_value_no_signal(float(values.release))
 demo_duration_label.text="%.3f s"%float(values.duration)
 demo_mana_cost_label.text="Mana cost: %.1f"%float(values.mana)
 demo_stamina_label.text="Stamina depletion: %.1f"%float(values.stamina)
 demo_damage_label.text="Physical damage: %.1f"%float(values.damage)
 var spec:Dictionary=test_overrides.apply(projectile_effect_spec(preview_effect))
 demo_size_bonus_label.text="Diameter: %.2f m"%(float(spec.projectile_radius)*2.0)
 demo_speed_bonus_label.text="Speed: %.1f m/s"%float(spec.projectile_velocity)
 demo_burn_label.visible=preview_effect=="Fire"
 demo_burn_label.text="Burn: %.1f/s"%(3.0*float(spec.potency))

func set_demo_duration(value:float) -> void:
 if not limiter_enabled:
  set_test_value("duration",value)
  return
 demo_duration=clampf(value,0.1,60.0)
 casting_animation["duration"]=demo_duration
 # Reprice the whole preview instead of changing the cost midway through a cast.
 if is_visible_in_tree():play_demo_preview()
 refresh_demo_timing()
 save_demo_preferences()

func demo_mana_stats() -> Dictionary:
 return preload("res://scripts/animation_mana_scaling.gd").stats(demo_duration)

func release_timing_stats() -> Dictionary:
 # The spell peaks near the motion's apex, before the recovery half.
 var bonus:=clampf((release_fraction-MIN_RELEASE_FRACTION)/(MAX_RELEASE_FRACTION-MIN_RELEASE_FRACTION),0.0,1.0)
 return {"fraction":release_fraction,"seconds":demo_duration*release_fraction,"bonus_percent":bonus*MAX_RELEASE_BONUS*100.0,"multiplier":1.0+bonus*MAX_RELEASE_BONUS}

func set_release_fraction(value:float) -> void:
 if not limiter_enabled:
  set_test_value("release",value*100.0)
  return
 release_fraction=clampf(value,MIN_RELEASE_FRACTION,MAX_RELEASE_FRACTION)
 refresh_demo_timing()
 save_draft()
 if creation_step=="projectile" and is_visible_in_tree():
  play_demo_preview()

func demo_physical_stats() -> Dictionary:
 if not limiter_enabled:return {"duration":test_overrides.values.duration,"stamina":test_overrides.values.stamina,"damage":test_overrides.values.damage,"effort":test_overrides.values.stamina}
 var choice:=str(casting_animation.get("demo_choice","cross"))
 var offensive:=choice in ["cross","hook","knee"]
 # One second is neutral. Faster buys delivery, slower buys power.
 # Keep the full cost visible, including casts exceeding the stamina budget.
 var seconds:=maxf(0.1,demo_duration)
 var stamina:=10.0*maxf(seconds,1.0/seconds) if offensive else 0.0
 var damage:=10.0*seconds if offensive else 0.0
 return {"duration":seconds,"stamina":stamina,"damage":damage,"effort":stamina}

func demo_projectile_stats() -> Dictionary:
 var effect:=preview_effect if creation_step=="projectile" else element
 var base:=projectile_effect_spec(effect)
 var timing:=demo_mana_stats()
 var amp:float=float(timing.amplifier)*float(release_timing_stats().multiplier)
 var base_radius:float=float(base.get("projectile_radius",projectile_size))*Projectile.CAST_RADIUS_SCALE
 var base_velocity:float=float(base.get("projectile_velocity",projectile_velocity))
 var speed_damage_multiplier:=base_velocity*amp/Projectile.DEFAULT_VELOCITY
 var impact_damage:float=float(demo_physical_stats().damage)*speed_damage_multiplier
 return {"base_mana":float(base.mana),"mana":float(base.mana)*float(timing.multiplier),"cost_percent":float(timing.cost_percent),"amplifier":amp,"base_radius":base_radius,"base_velocity":base_velocity,"radius":base_radius*amp,"velocity":base_velocity*amp,"speed_damage_multiplier":speed_damage_multiplier,"physical_damage":impact_damage,"burn_dps":3.0*float(base.get("potency",0.0))*amp if effect=="Fire" else 0.0,"effect":effect}

func refresh_demo_timing() -> void:
 if not is_instance_valid(demo_duration_slider):return
 if not limiter_enabled:
  refresh_test_controls()
  return
 demo_duration_slider.set_value_no_signal(demo_duration)
 demo_duration_label.text="%.1f s"%demo_duration
 var physical:=demo_physical_stats()
 demo_stamina_label.text="Stamina depletion: %.1f"%float(physical.stamina)
 demo_stamina_note.text="1 s = 10 stamina / 10 base damage"
 var max_stamina:float=float(editor.actor.MAX_STAMINA) if is_instance_valid(editor.actor) else 100.0
 if float(physical.stamina)>max_stamina:
  demo_stamina_note.text="Needs %.1f stamina · maximum %.0f"%[float(physical.stamina),max_stamina]
 var stats:=demo_projectile_stats()
 demo_damage_label.text="Physical damage: %.1f"%float(stats.physical_damage)
 demo_damage_breakdown.text="%.1f base × %.2f speed × %.2f amp"%[float(physical.damage),float(stats.base_velocity)/Projectile.DEFAULT_VELOCITY,float(stats.amplifier)]
 demo_mana_cost_label.text="Mana cost: %.1f"%float(stats.mana)
 demo_mana_base_label.text="%.1f base × %.1f%%"%[float(stats.base_mana),float(stats.cost_percent)]
 demo_amplifier_label.text="Spell amp: +%.1f%%"%((float(stats.amplifier)-1.0)*100.0)
 demo_amp_breakdown.text="×%.2f duration × %.2f timing"%[float(demo_mana_stats().amplifier),float(release_timing_stats().multiplier)]
 demo_size_bonus_label.text="Diameter: %.2f → %.2f m"%[float(stats.base_radius)*2.0,float(stats.radius)*2.0]
 demo_speed_bonus_label.text="Speed: %.1f → %.1f m/s"%[float(stats.base_velocity),float(stats.velocity)]
 demo_burn_label.visible=str(stats.effect)=="Fire"
 demo_burn_label.text="Burn: %.1f/s · %.1f total / 4 s"%[float(stats.burn_dps),float(stats.burn_dps)*4.0]
 if is_instance_valid(release_slider):
  release_slider.set_value_no_signal(release_fraction*100.0)

func refresh_demo_choices() -> void:
 for choice in demo_choices:
  var selected:bool=str(casting_animation.get("demo_choice","cross"))==choice
  demo_choices[choice].add_theme_color_override("font_color",Color("98703d") if selected else Color("382c1c"))

func play_demo_preview() -> void:
 if not is_instance_valid(editor.actor) or casting_animation.is_empty():return
 var stamina_cost:=float(demo_physical_stats().stamina)
 if not editor.actor.practice_god_mode and stamina_cost>float(editor.actor.stamina)+0.0001:
  playing=false
  if not preview_repeating:editor._show_library_notice("Needs %.1f stamina · available %.1f"%[stamina_cost,float(editor.actor.stamina)])
  return
 if not demo_source_ready:
  if not editor._ensure_animation_source(casting_animation):return
  demo_source_ready=true
 demo_enter_pose=capture_demo_pose()
 demo_exit_pose.clear()
 editor.actor.set_editor_animation_profile({},"")
 editor.actor.mode="review"
 editor.actor.player.pause()
 blend_demo_pose(demo_enter_pose,0.0)
 elapsed=0
 playing=true
 released=false

 if not limiter_enabled and cast_duration()<=0.0:
  if creation_step=="projectile":launch_projectile()
  released=true
  playing=false
  begin_demo_exit()

func process_demo_preview(delta:float) -> void:
 idle_elapsed+=delta
 if not playing:
  editor.actor.mana_delay=maxf(0.0,editor.actor.mana_delay-delta)
  if editor.actor.mana_delay<=0.0:editor.actor.mana=minf(editor.actor.MAX_MANA,editor.actor.mana+editor.actor.RESOURCE_RECOVERY_RATE*delta)
  editor.actor.stamina_delay=maxf(0.0,editor.actor.stamina_delay-delta)
  if editor.actor.stamina_delay<=0.0:editor.actor.stamina=minf(editor.actor.MAX_STAMINA,editor.actor.stamina+editor.actor.RESOURCE_RECOVERY_RATE*delta)
  editor.actor.recover_guard(delta)
  if caster_moving:
   Locomotion.pose(editor.actor,caster_move_axes,idle_elapsed,caster_sprinting)
  else:RigPose.idle(editor.actor,idle_elapsed)
  if not demo_exit_pose.is_empty():
   demo_exit_elapsed+=delta
   var weight:=smoothstep(0.0,DEMO_TRANSITION_SECONDS,demo_exit_elapsed)
   blend_demo_pose(demo_exit_pose,weight)
   if demo_exit_elapsed>=DEMO_TRANSITION_SECONDS:demo_exit_pose.clear()
  if creation_step=="projectile" and preview_repeating:
   repeat_wait=maxf(0.0,repeat_wait-delta)
   if repeat_wait<=0.0 and demo_exit_pose.is_empty():play_demo_preview()
  return
 elapsed+=delta
 var progress:=clampf(elapsed/maxf(0.001,cast_duration()),0.0,1.0)
 CastPose.pose(editor.actor,casting_animation,minf(0.9999,progress),cast_pose_aim(progress))
 if not demo_enter_pose.is_empty():
  var fade:=minf(DEMO_TRANSITION_SECONDS,cast_duration()*0.25)
  blend_demo_pose(demo_enter_pose,smoothstep(0.0,fade,elapsed))
  if elapsed>=fade:demo_enter_pose.clear()
 if creation_step=="projectile" and not released and progress>=(release_fraction if limiter_enabled else float(test_overrides.values.release)/100.0):
  launch_projectile()
  released=true
 if progress>=1.0:
  playing=false
  repeat_wait=REPEAT_DELAY
  begin_demo_exit()

func capture_demo_pose() -> Array[Transform3D]:
 var result:Array[Transform3D]=[]
 if not is_instance_valid(editor.actor):return result
 for bone in editor.actor.skeleton.get_bone_count():result.append(editor.actor.skeleton.get_bone_pose(bone))
 return result

func cast_pose_aim(progress:float) -> Dictionary:
 if creation_step!="projectile":return {}
 if str(casting_animation.get("demo_choice","cross")) not in ["cross","hook","knee"]:return {}
 var target:Vector3
 if is_instance_valid(spell_focus_target):target=CombatAim.focused_chest(spell_focus_target)
 elif manual_aim_valid:target=manual_aim_point
 else:return {}
 var weight:=smoothstep(0.0,0.12,progress)*(1.0-smoothstep(0.75,1.0,progress))
 return {"target":target,"emitter":CombatAim.emitter(casting_animation),"weight":weight}

func blend_demo_pose(from:Array[Transform3D],weight:float) -> void:
 var rig:Skeleton3D=editor.actor.skeleton
 for bone in mini(from.size(),rig.get_bone_count()):rig.set_bone_pose(bone,from[bone].interpolate_with(rig.get_bone_pose(bone),weight))
 rig.force_update_all_bone_transforms()

func begin_demo_exit() -> void:
 demo_exit_pose=capture_demo_pose()
 demo_exit_elapsed=0.0
 demo_enter_pose.clear()

func choose_demo_animation(entry:Dictionary,save:=true) -> bool:
 if str(entry.get("clip","")).is_empty():return false
 var before:=capture_demo_pose()
 if is_instance_valid(editor.actor) and not editor._ensure_animation_source(entry):return false
 if not before.is_empty():blend_demo_pose(before,0.0)
 casting_animation=entry.duplicate(true)
 if entry.has("animation_resource") or entry.has("bvh_source") or entry.has("source_animation"):casting_animation["store_raw"]=true
 demo_source_ready=is_instance_valid(editor.actor)
 demo_button.text=str(entry.get("title","Demo animation"))+"  ▾"
 restart_preview()
 refresh()
 refresh_demo_choices()
 refresh_demo_timing()
 if save:save_demo_preferences()
 GameDiagnostics.log_event("spell_demo_selected",{"title":entry.get("title",""),"clip":entry.get("clip",""),"preview_only":true})
 return true

func save_demo_preferences() -> void:
 if preview_preferences_path.is_empty():return
 var cfg:=ConfigFile.new()
 cfg.set_value("preview","choice",str(casting_animation.get("demo_choice","cross")))
 cfg.set_value("preview","duration",demo_duration)
 cfg.set_value("practice","dummy_god_mode",dummy_god_mode)
 cfg.set_value("practice","character_god_modes",character_god_modes)
 cfg.set_value("preview","hitboxes",preview_hitboxes)
 cfg.save(preview_preferences_path)

func load_demo_preferences() -> void:
 if preview_preferences_path.is_empty():return
 var cfg:=ConfigFile.new()
 if cfg.load(preview_preferences_path)!=OK:return
 demo_duration=clampf(float(cfg.get_value("preview","duration",1.0)),0.1,60.0)
 dummy_god_mode=bool(cfg.get_value("practice","dummy_god_mode",true))
 character_god_modes=cfg.get_value("practice","character_god_modes",{})
 preview_hitboxes=bool(cfg.get_value("preview","hitboxes",false))
 refresh_dummy_controls()
 var saved:String=str(cfg.get_value("preview","choice","cross"))
 saved=str({"straight":"cross","up":"mend","sky":"mend","down":"knee","stomp":"knee"}.get(saved,saved))
 select_demo_choice(saved if DEMO_ANIMATIONS.has(saved) else "cross",false)
 refresh_demo_timing()

func open_demo_animation_picker() -> void:
 if is_instance_valid(demo_dialog):demo_dialog.popup_centered();return
 demo_entries.clear()
 demo_entries.append_array(preload("res://scripts/animation_catalog.gd").entries())
 for group in ["Motion","Attack"]:
  for folder in editor.category_store.names_for(group):demo_entries.append_array(editor.load_custom_motion(folder))
 for entry in editor.store_library.taken.values():demo_entries.append(entry.duplicate(true))
 demo_entries.sort_custom(func(a:Dictionary,b:Dictionary):return str(a.get("title","")).naturalnocasecmp_to(str(b.get("title","")))<0)
 demo_dialog=ConfirmationDialog.new()
 demo_dialog.title="Choose a demo animation"
 demo_dialog.name="SpellDemoAnimationDialog"
 demo_dialog.theme=editor._book_theme()
 demo_dialog.unresizable=false
 demo_dialog.min_size=Vector2i(340,300)
 demo_dialog.get_ok_button().text="Use for demo"
 var layout:=VBoxContainer.new()
 layout.add_theme_constant_override("separation",6)
 demo_dialog.add_child(layout)
 demo_search=LineEdit.new()
 demo_search.placeholder_text="Search your animations…"
 demo_search.text_changed.connect(func(_text:String):populate_demo_animations())
 layout.add_child(demo_search)
 demo_list=ItemList.new()
 demo_list.custom_minimum_size=Vector2(320,250)
 demo_list.size_flags_vertical=Control.SIZE_EXPAND_FILL
 demo_list.item_selected.connect(func(_index:int):demo_dialog.get_ok_button().disabled=false)
 demo_list.item_activated.connect(func(_index:int):confirm_demo_animation())
 layout.add_child(demo_list)
 var help:Label=editor.menu_label(layout,"Choose from Motion, Attack and Downloaded. Enter selects; double-click uses the animation.",13)
 help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 demo_dialog.confirmed.connect(confirm_demo_animation)
 demo_dialog.visibility_changed.connect(func():
  if demo_dialog.visible:return
  demo_dialog.queue_free())
 add_child(demo_dialog)
 populate_demo_animations()
 demo_dialog.popup_centered(Vector2i(540,440))
 demo_search.grab_focus()

func populate_demo_animations() -> void:
 demo_list.clear()
 demo_visible_entries.clear()
 var query:=demo_search.text.strip_edges().to_lower()
 var seen:Dictionary={}
 for entry in demo_entries:
  var key:=str(entry.get("clip",""))+"|"+str(entry.get("path",""))+"|"+str(entry.get("title",""))
  if seen.has(key):continue
  seen[key]=true
  var text:="%s  ·  %s / %s"%[entry.get("title","Animation"),entry.get("group","Motion"),entry.get("category","")]
  if not query.is_empty() and not text.to_lower().contains(query):continue
  demo_visible_entries.append(entry)
  demo_list.add_item(text)
 demo_dialog.get_ok_button().disabled=demo_visible_entries.is_empty()
 if not demo_visible_entries.is_empty():demo_list.select(0)

func confirm_demo_animation() -> void:
 var selected:=demo_list.get_selected_items()
 if selected.is_empty():return
 if choose_demo_animation(demo_visible_entries[selected[0]]):demo_dialog.hide()

func select_category(value:String) -> void:
 if value not in TYPES:return
 category=value
 if value in ["Projectiles","Summons"]:
  spell_kind=value
  apply_budget("radius")
 playing=false
 repeat_wait=0
 clear_shots()
 reset_caster_pose()
 refresh()
 save_draft()

func refresh() -> void:
 if not is_instance_valid(controls):return
 for type in categories:
  categories[type].modulate=Color.WHITE
  categories[type].add_theme_color_override("font_color",Color("98703d") if type==category else Color("382c1c"))
 controls.visible=category in ["Projectiles","Summons"]
 arena_settings.visible=category=="Arena Settings"
 empty_label.visible=not controls.visible and not arena_settings.visible
 preview_label.visible=category=="Projectiles"
 element_heading.visible=category=="Projectiles"
 elements.visible=category=="Projectiles"
 summon_button.visible=category=="Summons"
 summon_label.visible=category=="Summons"
 empty_label.text=category+"\nNothing created here yet."
 for value in element_buttons:
  element_buttons[value].modulate=Color.WHITE
  element_buttons[value].add_theme_color_override("font_color",Color("98703d") if value==element else Color("382c1c"))
 size_slider.max_value=radius_limit()
 size_input.max_value=radius_limit()
 testing_toggle.set_pressed_no_signal(testing_sizes)
 radius_warning.visible=projectile_size>MAX_RADIUS
 appearance_controls.visible=category=="Projectiles"
 refresh_appearance()
 size_slider.set_value_no_signal(projectile_size)
 size_input.set_value_no_signal(projectile_size)
 size_label.text="Radius"
 potency_slider.set_value_no_signal(potency)
 potency_input.set_value_no_signal(potency)
 potency_label.text="Potency"
 velocity_row.visible=category=="Projectiles"
 velocity_slider.set_value_no_signal(projectile_velocity)
 velocity_input.set_value_no_signal(projectile_velocity)
 var speed:float=projectile_velocity if spell_kind=="Projectiles" else Projectile.MIN_VELOCITY
 var used:float=Projectile.budget_used(projectile_size,potency,speed)*100.0
 budget_label.text="Power budget: %.1f%% / 100%%"%used
 budget_meter.value=used
 mana_label.text="Mana cost: %.1f%% of maximum mana"%Projectile.mana_percent(projectile_size,potency,speed)
 effect_label.text={"Fire":"Potency increases burn damage. Scorches the ground.","Ice":"Potency freezes legs faster and longer. Creates slippery ground.","Lightning":"Electrifies water for 6 seconds per potency. Stuns everyone in it, including allies and caster.","Wind":"Potency increases knockback and upward lift. Throws nearby debris.","Water":"Water collects beneath the person hit, spreads from that spot, and accumulates. Reset Field drains it.","Earth":"Rock projectile. To raise an Earth Wall, choose Summons."}.get(element,"Elementless projectile.")
 if category=="Summons":
  effect_label.text="Summons a wall directly between the caster and target. Size grows it; potency strengthens it. Break it to make wind-movable debris."
 distance_input.set_value_no_signal(starting_distance)
 distance_slider.set_value_no_signal(starting_distance)

func set_element(value:String) -> void:
 if value not in Projectile.ELEMENTS:return
 element=value
 restart_preview()
 refresh()
 save_draft()

func set_projectile_size(value:float) -> void:
 projectile_size=clampf(value,0.1,radius_limit())
 apply_budget("radius")
 restart_preview()
 refresh()
 save_draft()

func set_potency(value:float) -> void:
 potency=clampf(value,0.25,4.0)
 apply_budget("potency")
 restart_preview()
 refresh()
 save_draft()

func set_distance(value:float) -> void:
 starting_distance=clampf(value,0.5,20)
 refresh()
 save_draft()

func restart_preview() -> void:
 playing=false
 repeat_wait=0
 clear_shots()
 if demo_only_stage and is_instance_valid(editor.actor):begin_demo_exit()
 else:reset_caster_pose()

func projectile_spec() -> Dictionary:
 return projectile_effect_spec(element)

func projectile_effect_spec(effect:String) -> Dictionary:
 var spec:Dictionary=Projectile.spec(effect,projectile_size,potency,testing_sizes,projectile_velocity)
 if demo_only_stage and spell_kind=="Projectiles":
  var shares:=allocation_for(effect)
  spec["projectile_radius"]=Projectile.MIN_RADIUS*pow(Projectile.MAX_RADIUS/Projectile.MIN_RADIUS,float(shares["size"]))
  spec["projectile_velocity"]=lerpf(Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY,float(shares.speed))
  spec["potency"]=4.0*float(shares.get("effect",0.0))
  spec["power_allocation"]=shares.duplicate()
 if effect=="None":
  spec["name"]="Elementless projectile"
  spec["mana"]=10.0
  spec["mana_percent"]=10.0
 elif effect=="Fire":spec["name"]="Fireball"
 if spell_kind=="Summons":
  spec={"id":"earth_wall","name":"Earth Wall","effect":"summon_earth","animation":"palm_fireball","hand":"hand_r","release":0.25,"summon_radius":projectile_size,"potency":potency,"mana_percent":Projectile.mana_percent(projectile_size,potency),"mana":Projectile.mana_cost(projectile_size,potency),"damage":0.0}
 spec["appearance"]=appearances.get(effect,{}).duplicate(true)
 spec["testing_only"]=testing_sizes and projectile_size>MAX_RADIUS
 spec["provenance"]=spell_provenance.duplicate(true)
 spec["release"]=release_fraction
 spec["release_timing_multiplier"]=float(release_timing_stats().multiplier)
 if not delivery_type.is_empty():spec["delivery_type"]=delivery_type
 return spec

func demo_preview_spec() -> Dictionary:
 var spec:=projectile_effect_spec(preview_effect) if creation_step=="projectile" else projectile_spec()
 spec["stamina_cost"]=float(demo_physical_stats().stamina)
 spec.hand=CombatAim.emitter(casting_animation)
 var timing:=demo_mana_stats()
 spec["mana"]=float(spec.get("mana",0.0))*float(timing.multiplier)
 spec["mana_percent"]=float(spec.get("mana_percent",0.0))*float(timing.multiplier)
 spec["damage"]=float(demo_physical_stats().damage)
 spec["physical_damage"]=spec.damage
 spec["damage"]=float(spec.damage)*float(timing.amplifier)*float(release_timing_stats().multiplier)
 spec["potency"]=float(spec.get("potency",1.0))*float(timing.amplifier)*float(release_timing_stats().multiplier)
 if spec.has("projectile_radius"):
  var stats:=demo_projectile_stats()
  spec["base_projectile_radius"]=stats.base_radius
  spec["projectile_radius_scale"]=Projectile.CAST_RADIUS_SCALE
  spec["base_projectile_velocity"]=stats.base_velocity
  spec["spell_amplifier"]=stats.amplifier
  spec["projectile_radius"]=stats.radius
  spec["projectile_velocity"]=stats.velocity
  spec["motion_damage"]=float(demo_physical_stats().damage)
  spec["speed_damage_multiplier"]=stats.speed_damage_multiplier
  spec["physical_damage"]=stats.physical_damage
  spec["damage"]=stats.physical_damage
 return spec if limiter_enabled else test_overrides.apply(spec)

func cast_duration() -> float:
 if not limiter_enabled:return float(test_overrides.values.duration)
 if casting_animation.has("duration"):return float(casting_animation.duration)
 if not is_instance_valid(editor.actor):return 0.64
 if casting_animation.get("store_raw",false) and editor.actor.player.has_animation(str(casting_animation.clip)):return editor.actor.player.get_animation(str(casting_animation.clip)).length
 return CastPose.Source.duration(editor.actor,casting_animation.step,casting_animation.clip)

func play_cast_preview() -> void:
 if category not in ["Projectiles","Summons"] or casting_animation.is_empty() or not is_instance_valid(editor.actor):return
 if not demo_source_ready:
  if not editor._ensure_animation_source(casting_animation):return
  demo_source_ready=true
 reset_caster_pose()
 elapsed=0
 playing=true
 released=false
 if release_fraction==0:
  CastPose.pose(editor.actor,casting_animation,0)
  launch_projectile()
  released=true

func projectile_preview_launch() -> Dictionary:
 var actor=editor.actor
 var spec:Dictionary=demo_preview_spec()
 var origin:Vector3=editor.field.fighter_hand(actor,spec.hand)+actor.global_basis.z*0.12
 if demo_only_stage and creation_step=="projectile":
  spec["aim_direction"]=actor.global_basis.z.normalized()
  if manual_aim:
   if manual_aim_valid:spec["aim_direction"]=(manual_aim_point-origin).normalized()
  else:
   var subject:CharacterBody3D=spell_focus_target if is_instance_valid(spell_focus_target) else editor.target
   if is_instance_valid(subject) and subject.visible and subject.health>0.0:
    spec["aim_direction"]=(CombatAim.focused_chest(subject)-origin).normalized()
 return {"spec":spec,"origin":origin}

func launch_projectile() -> void:
 var actor=editor.actor
 var launch:=projectile_preview_launch()
 var spec:Dictionary=launch.spec
 var origin:Vector3=launch.origin
 if not actor.can_cast_with(spec,casting_animation):return
 var mana_cost:=maxf(0.0,float(spec.get("mana",0.0)))
 if not actor.spend_cast_resources(float(spec.stamina_cost),mana_cost):
  GameDiagnostics.log_event("spell_preview_insufficient_resources",{"mana_required":mana_cost,"mana_available":actor.mana,"stamina_required":spec.stamina_cost,"stamina_available":actor.stamina})
  return
 if spec.effect=="summon_earth":editor.field.summon_earth(actor,spec)
 else:editor.field.spawn_projectile(actor,spec,origin)
 GameDiagnostics.log_event("spell_preview_fired",{"name":spec.get("name",""),"element":spec.get("projectile_element",""),"duration":demo_duration,"mana":spec.get("mana",0),"potency":spec.get("potency",1),"damage":spec.get("damage",0)})

func _process(delta:float) -> void:
 _update_resize_grips()
 _process_resize_cursor()
 if not is_visible_in_tree() or not is_instance_valid(editor.actor):return
 update_training_dummy(delta)
 if demo_only_stage:
  update_third_person_view(delta)
  process_demo_preview(delta)
  return
 if not editor.actor.can_cast_with(demo_preview_spec(),casting_animation):
  playing=false
  repeat_wait=REPEAT_DELAY
  return
 idle_elapsed+=delta
 if not playing and category=="Projectiles":
  repeat_wait=maxf(0,repeat_wait-delta)
  if repeat_wait==0:play_cast_preview()
 for fighter in editor.field.fighters:
  if (fighter!=editor.actor or not playing) and fighter.mode in ["review","idle"]:
   fighter.capture_ice_pose()
   RigPose.idle(fighter,idle_elapsed)
   fighter.restore_ice_pose()
 if playing:
  elapsed+=delta
  var progress:=clampf(elapsed/maxf(0.001,cast_duration()),0,1)
  CastPose.pose(editor.actor,casting_animation,minf(0.9999,progress))
  if not released and progress>=release_fraction:
   launch_projectile()
   released=true
  if progress>=1:
   playing=false
   repeat_wait=REPEAT_DELAY
   reset_caster_pose()
 current_distance.text="Current separation: %.2f m | Water: %.2f m deep"%[editor.actor.global_position.distance_to(editor.target.global_position),editor.field.spell_environment.flood_depth]

func begin_border_resize(edges:Vector2) -> void:
 _detach_anchors()
 resizing=true
 resize_edges=edges
 resize_origin=get_global_rect()

func resize_window_by(amount:Vector2) -> void:
 _detach_anchors()
 resize_origin=get_global_rect()
 resize_edges=Vector2.ONE
 _resize_to(resize_origin.end+amount)
 resize_edges=Vector2.ZERO

func _ensure_resize_grips() -> void:
 if not resize_grips.is_empty():return
 if get_parent()==null:return
 for edges in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
  var grip:=Control.new()
  grip.set_script(preload("res://scripts/workspace_window_resize_grip.gd"))
  grip.set("window",self)
  grip.set("edges",edges)
  get_parent().add_child(grip)
  resize_grips.append(grip)

func _update_resize_grips() -> void:
 _ensure_resize_grips()
 if get_parent()==null:return
 var rect:=get_global_rect()
 for grip in resize_grips:
  grip.visible=is_visible_in_tree()
  if not grip.visible:continue
  var edges:Vector2=grip.get("edges")
  grip.size=Vector2(16.0 if edges.x!=0 else maxf(16.0,size.x-16.0),16.0 if edges.y!=0 else maxf(16.0,size.y-16.0))
  grip.global_position=rect.position+Vector2(-8 if edges.x<0 else (size.x-8 if edges.x>0 else 8),-8 if edges.y<0 else (size.y-8 if edges.y>0 else 8))
  if get_index()>grip.get_index():get_parent().move_child(grip,get_parent().get_child_count()-1)

func _edges_at(point:Vector2) -> Vector2:
 var rect:=get_global_rect()
 if not rect.grow(10.0).has_point(point):return Vector2.ZERO
 var local:=point-rect.position
 return Vector2(-1 if local.x<8 else (1 if local.x>size.x-8 else 0),-1 if local.y<8 else (1 if local.y>size.y-8 else 0))

func _process_resize_cursor() -> void:
 if not is_visible_in_tree():return
 var edges:=resize_edges if resizing else _edges_at(get_global_mouse_position())
 if edges.x!=0 and edges.y!=0:mouse_default_cursor_shape=Control.CURSOR_FDIAGSIZE if edges.x==edges.y else Control.CURSOR_BDIAGSIZE
 elif edges.x!=0:mouse_default_cursor_shape=Control.CURSOR_HSIZE
 elif edges.y!=0:mouse_default_cursor_shape=Control.CURSOR_VSIZE
 else:mouse_default_cursor_shape=Control.CURSOR_ARROW

func _detach_anchors() -> void:
 var position_before:=global_position
 var size_before:=size
 set_anchors_preset(Control.PRESET_TOP_LEFT,true)
 global_position=position_before
 size=size_before

func _resize_to(point:Vector2) -> void:
 var minimum:=get_combined_minimum_size().max(Vector2(320,220))
 var viewport_size:=get_viewport_rect().size
 var start:=resize_origin.position
 var finish:=resize_origin.end
 if resize_edges.x<0:start.x=clampf(point.x,0.0,maxf(0.0,finish.x-minimum.x))
 elif resize_edges.x>0:finish.x=clampf(point.x,start.x+minimum.x,maxf(start.x+minimum.x,viewport_size.x))
 if resize_edges.y<0:start.y=clampf(point.y,0.0,maxf(0.0,finish.y-minimum.y))
 elif resize_edges.y>0:finish.y=clampf(point.y,start.y+minimum.y,maxf(start.y+minimum.y,viewport_size.y))
 global_position=start
 size=finish-start

func release_target_focus() -> void:
 set_third_person_focus(null)

func focus_spell_target(unit:CharacterBody3D) -> void:
 set_third_person_focus(unit if unit!=editor.actor else null)

func ensure_third_person_camera() -> void:
 if third_person_ready:return
 ThirdPersonCamera.adopt(editor.field,editor.actor)
 third_person_ready=true

func set_third_person_focus(unit:CharacterBody3D) -> void:
 ensure_third_person_camera()
 ThirdPersonCamera.set_focus(editor.field,editor.actor,unit)
 spell_focus_target=editor.field.camera_focus_target
 manual_aim=not is_instance_valid(spell_focus_target)
 manual_aim_valid=false
 editor.camera_focus_active=not manual_aim

func toggle_third_person_focus(selected:CharacterBody3D) -> void:
 var next:CharacterBody3D=ThirdPersonCamera.next_target(editor.field.camera_focus_target,selected,editor.actor)
 set_third_person_focus(next)

func handle_third_person_input(event:InputEvent) -> bool:
 if not is_visible_in_tree() or not demo_only_stage:return false
 var area:Control=editor.base_ui.get_node_or_null("ArenaUnitDrop")
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_MIDDLE and not event.ctrl_pressed:
   if event.pressed and is_instance_valid(area) and area.get_global_rect().has_point(event.position):
    ensure_third_person_camera()
    third_person_orbiting=true
    third_person_mouse_origin=event.position
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
    return true
   if not event.pressed and third_person_orbiting:
    third_person_orbiting=false
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    get_viewport().warp_mouse(third_person_mouse_origin)
    return true
  if event.pressed and not event.ctrl_pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and is_instance_valid(area) and area.get_global_rect().has_point(event.position):
   ensure_third_person_camera()
   editor.field.adjust_camera_zoom(event.button_index==MOUSE_BUTTON_WHEEL_UP)
   return true
 if event is InputEventMouseMotion and third_person_orbiting:
  editor.field.rotate_camera_orbit(event.relative)
  return true
 return false

func update_third_person_view(delta:float) -> void:
 ensure_third_person_camera()
 var field=editor.field
 var locked:CharacterBody3D=field.camera_focus_target
 if is_instance_valid(locked) and (not locked.is_visible_in_tree() or locked.health<=0.0):
  set_third_person_focus(null)
  locked=null
 manual_aim=not is_instance_valid(locked)
 spell_focus_target=locked
 var yaw:=ThirdPersonCamera.world_yaw(field,editor.actor)
 ThirdPersonCamera.update(field.camera,editor.actor,locked,yaw,field.camera_orbit_pitch,ThirdPersonCamera.BASE_DISTANCE*field.camera_zoom,delta)
 editor.inspection_camera.capture_view(field.camera,ThirdPersonCamera.BASE_DISTANCE*field.camera_zoom)
 if not is_instance_valid(third_person_crosshair):
  third_person_crosshair=preload("res://scripts/third_person_crosshair.gd").new()
  third_person_crosshair.name="SpellCrosshair"
  editor.base_ui.add_child(third_person_crosshair)
 var area:Control=editor.base_ui.get_node("ArenaUnitDrop")
 var pointer:Vector2=get_viewport().get_mouse_position()
 var in_arena:=area.get_global_rect().has_point(pointer)
 third_person_crosshair.place(pointer,in_arena)
 if not third_person_orbiting and get_window().has_focus():Input.mouse_mode=Input.MOUSE_MODE_HIDDEN if in_arena else Input.MOUSE_MODE_VISIBLE
 # Moving onto a UI button preserves the last arena aim.
 if manual_aim and in_arena:aim_at_screen(pointer)

func aim_at_screen(pointer:Vector2) -> void:
 if not manual_aim:return
 var motion:Dictionary=Projectile.resolved_motion(demo_preview_spec())
 manual_aim_point=CombatAim.ray_point(editor.field.camera,editor.actor,pointer,editor.field.fighters,float(motion.radius))
 manual_aim_valid=true

func _input(event:InputEvent) -> void:
 if not is_visible_in_tree():return
 if event is InputEventKey and not editor.camera_text_editing():
  var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
  if key in [KEY_1,KEY_KP_1] and event.pressed and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and creation_step=="projectile":
   play_projectile_once()
   get_viewport().set_input_as_handled()
   return
  if key in [KEY_2,KEY_KP_2] and event.pressed and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and creation_step=="projectile":
   set_preview_hitboxes(not preview_hitboxes)
   get_viewport().set_input_as_handled()
   return
  if key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SHIFT]:
   movement_keys[key]=event.pressed
   get_viewport().set_input_as_handled()
   return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:
   var edges:=_edges_at(event.position)
   if edges==Vector2.ZERO:return
   _detach_anchors()
   resizing=true
   resize_edges=edges
   resize_origin=get_global_rect()
  elif resizing:
   resizing=false
   resize_edges=Vector2.ZERO
  else:return
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and resizing:
  _resize_to(event.position)
  get_viewport().set_input_as_handled()

func workspace_visibility_changed() -> void:
 third_person_ready=false
 if not is_visible_in_tree():
  if third_person_orbiting or Input.mouse_mode==Input.MOUSE_MODE_HIDDEN:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  third_person_orbiting=false
  if is_instance_valid(third_person_crosshair):third_person_crosshair.hide()
  if is_instance_valid(editor.field):editor.field.camera_focus_target=null
 if is_instance_valid(editor.field):editor.field.set_projectile_hitboxes(preview_hitboxes and is_visible_in_tree())
 movement_keys.clear()
 caster_moving=false
 caster_move_axes=Vector2.ZERO
 caster_sprinting=false
 if not is_visible_in_tree() and is_instance_valid(editor.target):
  if is_instance_valid(editor.target.practice_dummy_visual):editor.target.practice_dummy_visual.set_enabled(false)
  editor.target.practice_damageable_dummy=false
  editor.target.practice_god_mode=false
  editor.target.remove_meta("practice_damage_readout")
  editor.target.collision_layer=0
  for item in editor.target.targets:item[0].collision_layer=0
  for item in editor.target.limb_targets:item[0].collision_layer=0
  editor.actor.collision_layer=0
  if is_instance_valid(dummy_hit_text):dummy_hit_text.hide()
 if not is_visible_in_tree() and is_instance_valid(practice_human):
  practice_human.practice_damageable_dummy=false
  practice_human.practice_god_mode=false
  practice_human.collision_layer=0
  for item in practice_human.targets:item[0].collision_layer=0
  for item in practice_human.limb_targets:item[0].collision_layer=0
 if is_instance_valid(spell_playback_panel):spell_playback_panel.visible=is_visible_in_tree() and creation_step=="projectile"
 if not is_visible_in_tree():stop_preview_controls()
 if is_instance_valid(demo_timing_panel):demo_timing_panel.visible=is_visible_in_tree()
 playing=false
 repeat_wait=0
 clear_shots()
 if is_instance_valid(editor.actor):
  for fighter in editor.field.fighters:
   fighter.editor_pose_locked=is_visible_in_tree() and fighter==editor.actor
   fighter.practice_immortal=is_visible_in_tree()
   fighter.practice_return_enabled=is_visible_in_tree() and fighter!=editor.actor
  reset_caster_pose()
 if is_visible_in_tree():
  refresh()
  if demo_only_stage:
   show_creation_step("demo")
   play_demo_preview()

func _exit_tree() -> void:
 stop_preview_controls()
 if is_instance_valid(demo_timing_panel):demo_timing_panel.queue_free()
 if is_instance_valid(spell_playback_panel):spell_playback_panel.queue_free()

func reset_caster_pose() -> void:
 demo_enter_pose.clear()
 demo_exit_pose.clear()
 if not is_instance_valid(editor) or not is_instance_valid(editor.actor):return
 var actor=editor.actor
 actor.capture_ice_pose()
 actor.set_editor_animation_profile({},"")
 actor.mode="review"
 actor.player.stop()
 RigPose.idle(actor,idle_elapsed)
 actor.restore_ice_pose()

func clear_shots() -> void:
 if is_instance_valid(editor) and is_instance_valid(editor.field):editor.field.clear_battle_effects()
 shots.clear()

func positions_for_fighters() -> Array[Vector3]:
 var out:Array[Vector3]=[]
 for fighter in editor.field.fighters:
  out.append(Vector3(-starting_distance/2,0.02,-starting_distance*sqrt(3.0)/6) if fighter==editor.actor else (Vector3(starting_distance/2,0.02,-starting_distance*sqrt(3.0)/6) if fighter==editor.target else Vector3(0,0.02,starting_distance*sqrt(3.0)/3)))
 return out

func prepare_preview_targets() -> void:
 practice_human=null
 if demo_only_stage:
  for fighter in editor.field.fighters:
   if fighter!=editor.actor and fighter!=editor.target:
    practice_human=fighter
    break
 var positions:=positions_for_fighters()
 for i in editor.field.fighters.size():
  var fighter=editor.field.fighters[i]
  fighter.visible=not demo_only_stage or fighter==editor.actor or fighter==editor.target or fighter==practice_human
  if not fighter.visible:
   fighter.collision_layer=0
   for item in fighter.targets:item[0].collision_layer=0
   for item in fighter.limb_targets:item[0].collision_layer=0
  var tag:Node3D=fighter.get_node_or_null("OverheadHealthTag")
  if tag!=null:tag.visible=fighter.visible
  fighter.practice_return_enabled=fighter!=editor.actor
  fighter.practice_home=positions[i]
  fighter.position=positions[i]
  if demo_only_stage and fighter==editor.actor:fighter.position=Vector3(0,0.02,0)
  fighter.velocity=Vector3.ZERO
  fighter.editor_pose_locked=fighter==editor.actor
  fighter.practice_god_mode=bool(character_god_modes.get(god_mode_key(fighter),dummy_god_mode if fighter==editor.target else false))
  fighter.practice_immortal=fighter.practice_god_mode
  fighter.practice_damageable_dummy=true
  if fighter.practice_god_mode:fighter.restore_god_resources()
  fighter.brain_enabled=false
  fighter.mode="review"
  var toward:Vector3=(editor.target.position if fighter==editor.actor else editor.actor.position)-fighter.position
  fighter.rotation.y=atan2(toward.x,toward.z)
  RigPose.idle(fighter)
 editor.actor.rival=editor.target
 var forward:Vector3=editor.target.position-editor.actor.position
 editor.actor.rotation.y=atan2(forward.x,forward.z)
 if demo_only_stage:
  var dummy=editor.target
  dummy.practice_damageable_dummy=true
  dummy.practice_god_mode=dummy_god_mode
  dummy.practice_immortal=dummy_god_mode
  dummy.collision_layer=128<<dummy.team
  for item in dummy.targets:item[0].collision_layer=8<<dummy.team
  for item in dummy.limb_targets:item[0].collision_layer=8<<dummy.team
  editor.actor.collision_layer=128<<editor.actor.team
  dummy.practice_home=editor.actor.position+editor.actor.global_basis.z*3.5
  dummy.position=dummy.practice_home
  dummy.rotation.y=editor.actor.rotation.y+PI
  dummy.health=dummy.MAX_HEALTH
  dummy.guard_energy=0.0
  dummy_damage_mark=dummy.damage_taken
  dummy_total_damage=0.0
  dummy_last_damage=0.0
  editor.field.round_active=true
  var tag=dummy.get_node_or_null("OverheadHealthTag")
  if tag!=null:tag.name_label.text="Combat dummy"
  if not is_instance_valid(dummy.practice_dummy_visual):
   var visual:=preload("res://scripts/practice_dummy_visual.gd").new()
   visual.name="PracticeDummyVisual"
   visual.fighter=dummy
   dummy.add_child(visual)
   dummy.practice_dummy_visual=visual
  dummy.practice_dummy_visual.set_enabled(true)
  if is_instance_valid(practice_human):
   practice_human.set_editor_animation_profile({},"")
   practice_human.story_profile["idle_animation"]="Idle cannon"
   practice_human.clip=""
   practice_human.play("ual1/Idle")
   practice_human.practice_damageable_dummy=true
   practice_human.practice_god_mode=bool(character_god_modes.get("human",false))
   practice_human.practice_immortal=practice_human.practice_god_mode
   practice_human.practice_home=dummy.practice_home+dummy.global_basis.x*3.0
   practice_human.position=practice_human.practice_home
   practice_human.rotation.y=dummy.rotation.y
   practice_human.health=practice_human.MAX_HEALTH
   practice_human.collision_layer=128<<practice_human.team
   for item in practice_human.targets:item[0].collision_layer=8<<practice_human.team
   for item in practice_human.limb_targets:item[0].collision_layer=8<<practice_human.team
   var human_tag=practice_human.get_node_or_null("OverheadHealthTag")
   if human_tag!=null:human_tag.name_label.text="Human target"
  if not is_instance_valid(dummy_hit_text):
   dummy_hit_text=Label3D.new()
   dummy_hit_text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
   dummy_hit_text.no_depth_test=true
   dummy_hit_text.font_size=28
   dummy_hit_text.pixel_size=0.009
   dummy_hit_text.modulate=Color("ff6759")
   dummy_hit_text.outline_size=6
   editor.field.add_child(dummy_hit_text)
  dummy_hit_text.hide()
  if editor.focused_unit not in [editor.actor,editor.target,practice_human]:editor.select_editor_unit(editor.actor)

func _physics_process(delta:float) -> void:
 if not is_visible_in_tree() or not demo_only_stage or not is_instance_valid(editor.actor):return
 if not get_window().has_focus() or editor.camera_text_editing():
  movement_keys.clear()
  caster_moving=false
  caster_move_axes=Vector2.ZERO
  caster_sprinting=false
  return
 var axes:=Locomotion.axes(movement_keys)
 var sprinting:bool=movement_keys.get(KEY_SHIFT,false)
 if (not axes.is_equal_approx(caster_move_axes) or sprinting!=caster_sprinting) and not playing:begin_demo_exit()
 caster_move_axes=axes
 caster_sprinting=sprinting
 var caster=editor.actor
 var direction:=Movement.camera_direction(axes,editor.field.camera,caster.global_basis.z)
 caster_moving=not direction.is_zero_approx()
 if caster_moving:
  var speed:=7.0 if movement_keys.get(KEY_SHIFT,false) else 4.0
  caster.velocity=direction*speed
  caster.move_and_slide()
  var flat:=Vector2(caster.position.x,caster.position.z).limit_length(float(editor.field.Boundary.RADIUS)-1.0)
  caster.position.x=flat.x
  caster.position.z=flat.y
 else:caster.velocity=Vector3.ZERO
 # Face from the resolved position, including near-target collision/sprint steps.
 if not playing or is_instance_valid(spell_focus_target):
  Movement.turn(caster,Movement.facing(caster,editor.field.camera,spell_focus_target),delta)

func update_training_dummy(delta:float) -> void:
 refresh_dummy_controls()
 if not demo_only_stage or not is_instance_valid(editor.target) or not editor.target.practice_damageable_dummy:return
 var dummy=editor.target
 if dummy.damage_taken>dummy_damage_mark:
  var amount:float=dummy.damage_taken-dummy_damage_mark
  dummy_damage_mark=dummy.damage_taken
  dummy_total_damage+=amount
  dummy_last_damage=amount
  dummy_hit_age=0.0
  if is_instance_valid(dummy_hit_text):
   dummy_hit_text.text="−%.1f"%amount
   dummy_hit_text.show()
 if is_instance_valid(dummy_hit_text) and dummy_hit_text.visible:
  dummy_hit_age+=delta
  dummy_hit_text.global_position=dummy.global_position+Vector3.UP*(2.8+dummy_hit_age*0.5)
  if dummy_hit_age>1.3:dummy_hit_text.hide()
 dummy.set_meta("practice_damage_readout","Last spell damage: %.1f"%dummy_last_damage)

func refresh_dummy_controls() -> void:
 if not is_instance_valid(dummy_god_button):return
 var unit=editor.focused_unit
 var valid:bool=is_instance_valid(unit) and unit.is_visible_in_tree()
 dummy_god_button.disabled=not valid
 if not valid:
  dummy_god_button.text="Select a character · God mode"
  dummy_god_button.set_pressed_no_signal(false)
  return
 var label:String="You" if unit==editor.actor else ("Combat dummy" if unit==editor.target else ("Human target" if unit==practice_human else str(unit.name)))
 dummy_god_button.text="%s · God mode: %s"%[label,"On" if unit.practice_god_mode else "Off"]
 dummy_god_button.set_pressed_no_signal(unit.practice_god_mode)

func god_mode_key(unit:Node) -> String:
 if unit==editor.actor:return "caster"
 if unit==editor.target:return "dummy"
 if unit==practice_human:return "human"
 return str(unit.name)

func set_selected_god_mode(enabled:bool) -> void:
 var unit=editor.focused_unit
 if not is_instance_valid(unit) or not unit.is_visible_in_tree():
  refresh_dummy_controls()
  return
 set_character_god_mode(unit,enabled)

func set_character_god_mode(unit:CharacterBody3D,enabled:bool) -> void:
 if not is_instance_valid(unit):return
 character_god_modes[god_mode_key(unit)]=enabled
 if unit==editor.target:dummy_god_mode=enabled
 if enabled and unit.health<=0.0:unit.reset_fighter(unit.position)
 unit.practice_god_mode=enabled
 unit.practice_immortal=enabled
 unit.practice_damageable_dummy=true
 if enabled:unit.restore_god_resources()
 refresh_dummy_controls()
 save_demo_preferences()

func set_dummy_god_mode(enabled:bool) -> void:
 set_character_god_mode(editor.target,enabled)

func reset_training_dummy(clear_stats:=true) -> void:
 if not is_instance_valid(editor.target):return
 var dummy=editor.target
 dummy.reset_fighter(dummy.practice_home)
 dummy.practice_immortal=dummy_god_mode
 dummy.practice_god_mode=dummy_god_mode
 dummy.practice_damageable_dummy=true
 dummy.practice_return_enabled=true
 dummy.brain_enabled=false
 dummy.mode="review"
 dummy.guard_energy=0.0
 dummy_damage_mark=dummy.damage_taken
 if is_instance_valid(dummy.practice_dummy_visual):dummy.practice_dummy_visual.set_enabled(true)
 if clear_stats:
  dummy_total_damage=0.0
  dummy_last_damage=0.0
 if is_instance_valid(dummy_hit_text):dummy_hit_text.hide()

func reset_practice_scene() -> void:
 stop_preview_controls()
 playing=false
 released=false
 elapsed=0.0
 repeat_wait=0.0
 movement_keys.clear()
 caster_moving=false
 caster_move_axes=Vector2.ZERO
 caster_sprinting=false
 clear_shots()
 editor.field.spell_environment.reset_environment()
 for fighter in editor.field.fighters:
  fighter.reset_fighter(fighter.position)
  fighter.damage_taken=0.0
  fighter.damage_dealt=0.0
 editor.field.ending=false
 editor.field.intermission=0.0
 editor.field.warmup=0.0
 editor.field.round_time=0.0
 editor.field.round_active=true
 prepare_preview_targets()
 reset_caster_pose()
 update_training_dummy(0.0)
 editor.frame_spell_preview(editor.actor)
 refresh_demo_timing()
 GameDiagnostics.log_event("spell_practice_scene_reset",{"god_mode":dummy_god_mode,"spell_settings_preserved":true})

func reset_field() -> void:
 clear_shots()
 editor.field.spell_environment.reset_environment()
 playing=false
 repeat_wait=0
 editor.distance_input.set_value_no_signal(starting_distance)
 editor.reset_setup()
 prepare_preview_targets()
 editor.get_tree().paused=false
 editor.title_label.text="CREATE  -  SPELLS"
 editor.frame_spell_preview(editor.actor)

func save_draft() -> void:
 if not limiter_enabled:return
 if draft_path.is_empty():return
 var cfg=ConfigFile.new()
 var signature: String=JSON.stringify({"kind":spell_kind,"delivery_type":delivery_type,"element":element,"size":projectile_size,"potency":potency,"velocity":projectile_velocity,"release":release_fraction,"allocation":projectile_allocations,"appearance":appearances},"",true).sha256_text()
 if signature!=spell_provenance_signature:
  var parents:Array=[]
  parents.append(spell_provenance if not spell_provenance.is_empty() else Provenance.source({"id":"fightlab_spell_"+element.to_lower(),"title":element+" spell"},"spell"))
  spell_provenance=Provenance.derive(parents,"spell",element+" "+spell_kind,Provenance.creator_name(),"modified spell")
  spell_provenance_signature=signature
 cfg.set_value("credits","provenance",spell_provenance)
 cfg.set_value("credits","signature",spell_provenance_signature)
 cfg.set_value("testing","oversized",testing_sizes)
 cfg.set_value("appearance","elements",appearances)
 cfg.set_value("workspace","category",category)
 cfg.set_value("workspace","spell_kind",spell_kind)
 cfg.set_value("spell","delivery_type",delivery_type)
 cfg.set_value("spell","projectile_initialized",projectile_initialized)
 cfg.set_value("spell","projectile_effect_confirmed",projectile_effect_confirmed)
 cfg.set_value("spell","release_fraction",release_fraction)
 cfg.set_value("spell","power_allocations",projectile_allocations)
 cfg.set_value("projectile","element",element)
 cfg.set_value("projectile","size",projectile_size)
 cfg.set_value("projectile","potency",potency)
 cfg.set_value("projectile","velocity",projectile_velocity)
 cfg.set_value("practice","distance",starting_distance)
 cfg.save(draft_path)

func load_draft() -> void:
 if draft_path.is_empty():return
 var cfg=ConfigFile.new()
 if cfg.load(draft_path)!=OK:return
 spell_provenance=cfg.get_value("credits","provenance",{}).duplicate(true)
 spell_provenance_signature=str(cfg.get_value("credits","signature",""))
 delivery_type=str(cfg.get_value("spell","delivery_type",""))
 projectile_initialized=bool(cfg.get_value("spell","projectile_initialized",false))
 projectile_effect_confirmed=bool(cfg.get_value("spell","projectile_effect_confirmed",false))
 release_fraction=clampf(float(cfg.get_value("spell","release_fraction",MIN_RELEASE_FRACTION)),MIN_RELEASE_FRACTION,MAX_RELEASE_FRACTION)
 projectile_allocations=cfg.get_value("spell","power_allocations",{}).duplicate(true)
 if delivery_type not in DELIVERY_TYPES:delivery_type=""
 testing_sizes=bool(cfg.get_value("testing","oversized",false))
 appearances=cfg.get_value("appearance","elements",{})
 element=str(cfg.get_value("projectile","element","None"))
 if element not in PROJECTILE_EFFECTS:element="None"
 category=str(cfg.get_value("workspace","category","Summons" if element=="Earth" else "Projectiles"))
 if category not in TYPES:category="Projectiles"
 spell_kind=str(cfg.get_value("workspace","spell_kind",category if category in ["Projectiles","Summons"] else "Projectiles"))
 if spell_kind not in ["Projectiles","Summons"]:spell_kind="Projectiles"
 potency=clampf(float(cfg.get_value("projectile","potency",1.0)),0.25,4.0)
 projectile_size=clampf(float(cfg.get_value("projectile","size",0.2)),0.1,radius_limit())
 projectile_velocity=clampf(float(cfg.get_value("projectile","velocity",Projectile.DEFAULT_VELOCITY)),Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY)
 apply_budget("radius")
 starting_distance=clampf(float(cfg.get_value("practice","distance",5.0)),0.5,20)

func preview_subject() -> Node3D:return editor.actor



func radius_limit() -> float:return Projectile.TEST_RADIUS if testing_sizes else MAX_RADIUS

func set_testing_sizes(value:bool) -> void:
 testing_sizes=value
 set_projectile_size(minf(projectile_size,radius_limit()))

func appearance_row(title:String,key:String,minimum:float,maximum:float,increment:float) -> void:
 var row=HBoxContainer.new()
 row.add_theme_constant_override("separation",10)
 appearance_controls.add_child(row)
 var label=editor.menu_label(row,title,15)
 label.custom_minimum_size.x=95
 var slider=HSlider.new()
 slider.min_value=minimum
 slider.max_value=maximum
 slider.step=increment
 slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 slider.value_changed.connect(func(value:float):set_appearance(key,value))
 row.add_child(slider)
 var value_label=editor.menu_label(row,"",13)
 value_label.custom_minimum_size.x=52
 appearance_sliders[key]={"slider":slider,"label":value_label}

func refresh_appearance() -> void:
 if not is_instance_valid(shape_input):return
 var custom:Dictionary=appearances.get(element,{})
 var look:Dictionary=preload("res://scripts/spell_appearance.gd").settings(element,custom)
 for i in texture_input.item_count:
  if texture_input.get_item_text(i)==str(look.texture):texture_input.select(i)
 for i in trail_texture_input.item_count:
  if trail_texture_input.get_item_text(i)==str(look.trail_texture):trail_texture_input.select(i)
 preset_input.select(clampi(int(custom.get("preset",0)),0,4))
 var shape:String=str(custom.get("shape","Element style"))
 shape_input.select(maxi(0,preload("res://scripts/spell_appearance.gd").SHAPES.find(shape)))
 var styles:Array=["Element style","Sparks","Smoke","Wisps","None","Drawn"]
 trail_input.select(maxi(0,styles.find(look.trail_style)))
 orbit_input.set_pressed_no_signal(bool(look.orbits))
 color_input.color=look.color
 accent_input.color=look.accent
 for key in appearance_sliders:
  appearance_sliders[key].slider.set_value_no_signal(float(look[key]))
  appearance_sliders[key].label.text="%.2f"%float(look[key])

func set_appearance(key:String,value:Variant) -> void:
 if not appearances.has(element):appearances[element]={}
 appearances[element].erase("preset")
 appearances[element][key]=value
 restart_preview()
 refresh_appearance()
 save_draft()

func reset_appearance() -> void:
 appearances.erase(element)
 restart_preview()
 refresh_appearance()
 save_draft()

func apply_visual_preset(index:int) -> void:
 if index==0:return
 var presets:Array=[
  {"shape":"Flame","texture":"fire_02","color":Color("ff641b"),"accent":Color("fff3b0"),"trail_style":"Wisps","trail":0.65,"glow":1.8,"opacity":0.9,"orbits":false},
  {"shape":"Flame","texture":"flame_05","color":Color("ff751f"),"accent":Color("ffe68c"),"trail_style":"Smoke","trail":0.4,"glow":1.2,"opacity":0.9,"orbits":false},
  {"shape":"Flame","texture":"fire_01","color":Color("ff480b"),"accent":Color("ffcc61"),"trail_style":"Sparks","trail":0.8,"glow":2.0,"opacity":0.8,"orbits":false},
  {"shape":"Flame","texture":"flame_02","color":Color("148dff"),"accent":Color("d1fcff"),"trail_style":"Sparks","trail":0.7,"glow":1.8,"opacity":0.85,"orbits":false}]
 appearances[element]=presets[index-1].duplicate(true)
 appearances[element]["preset"]=index
 restart_preview()
 refresh_appearance()
 save_draft()

func open_drawing(outline:bool) -> void:
 var dialog:=ConfirmationDialog.new()
 dialog.title="Draw spell silhouette" if outline else "Draw trail pattern"
 dialog.ok_button_text="Use drawing"
 add_child(dialog)
 var box:=VBoxContainer.new()
 dialog.add_child(box)
 var help=editor.menu_label(box,"Draw a closed silhouette; it becomes a shallow 3D shape." if outline else "Draw one continuous stroke; it becomes a repeating trail stamp.",14)
 help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var canvas=preload("res://scripts/spell_drawing.gd").new()
 canvas.outline=outline
 canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(canvas)
 var custom:Dictionary=appearances.get(element,{})
 canvas.points=custom.get("drawn_outline" if outline else "drawn_trail",PackedVector2Array())
 var status=editor.menu_label(box,"",13)
 editor.button(box,"Clear",canvas.clear)
 var validate=func():
  dialog.get_ok_button().disabled=not canvas.valid()
  status.text="Ready to use" if canvas.valid() else "Draw at least three points. Shape outlines must not cross themselves."
 canvas.changed.connect(validate)
 validate.call()
 dialog.confirmed.connect(func():
  var settings_:Dictionary=appearances.get(element,{}).duplicate(true)
  settings_.erase("preset")
  settings_["drawn_outline" if outline else "drawn_trail"]=canvas.points.duplicate()
  settings_["shape" if outline else "trail_style"]="Drawn"
  appearances[element]=settings_
  restart_preview()
  refresh_appearance()
  save_draft()
  dialog.queue_free())
 dialog.canceled.connect(func():refresh_appearance();dialog.queue_free())
 dialog.popup_centered(Vector2i(600,460))

func open_texture_import() -> void:
 var dialog:=FileDialog.new()
 dialog.access=FileDialog.ACCESS_FILESYSTEM
 dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
 dialog.filters=PackedStringArray(["*.png ; PNG texture"])
 dialog.title="Import a spell texture"
 add_child(dialog)
 dialog.file_selected.connect(func(path:String):import_texture(path);dialog.queue_free())
 dialog.canceled.connect(dialog.queue_free)
 dialog.popup_centered(Vector2i(800,550))

func import_texture(path:String) -> bool:
 var image:=Image.load_from_file(path)
 if image==null or image.is_empty():return false
 if maxi(image.get_width(),image.get_height())>2048:image.resize(maxi(1,roundi(2048.0*image.get_width()/maxi(image.get_width(),image.get_height()))),maxi(1,roundi(2048.0*image.get_height()/maxi(image.get_width(),image.get_height()))),Image.INTERPOLATE_LANCZOS)
 DirAccess.make_dir_recursive_absolute("user://spell_textures")
 var name_:String="user://spell_textures/"+path.get_file().get_basename().validate_filename()+"_"+str(hash(image.get_data()))+".png"
 if image.save_png(name_)!=OK:return false
 var already:=false
 for i in texture_input.item_count:
  if texture_input.get_item_text(i)==name_:already=true
 if not already:
  image.resize(24,24,Image.INTERPOLATE_LANCZOS)
  var icon:=ImageTexture.create_from_image(image)
  texture_input.add_icon_item(icon,name_)
  trail_texture_input.add_icon_item(icon,name_)
 set_appearance("texture",name_)
 return true

func apply_budget(edited:String) -> void:
 var allocation:Dictionary=Projectile.allocate(projectile_size,potency,projectile_velocity,edited,spell_kind=="Projectiles")
 projectile_size=allocation.radius
 potency=allocation.potency
 projectile_velocity=allocation.velocity

func set_velocity(value:float) -> void:
 projectile_velocity=clampf(value,Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY)
 apply_budget("velocity")
 restart_preview()
 refresh()
 save_draft()
