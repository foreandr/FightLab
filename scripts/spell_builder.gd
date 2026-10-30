extends PanelContainer
## Projectile and summon workspaces share casting, size and potency controls.
const TYPES=["Projectiles","Buffs","Barriers","Debuffs","Summons","Teleports","Arena Settings"]
const Projectile=preload("res://scripts/basic_projectile.gd")
const CastPose=preload("res://scripts/spell_cast_motion.gd")
const RigPose=preload("res://scripts/editor_rig_pose.gd")
const Provenance=preload("res://scripts/asset_provenance.gd")
var spell_provenance:Dictionary={}
var spell_provenance_signature:=""
var editor:Node
var draft_path:="user://projectile_spell_draft.cfg"
var category:="Projectiles"
var spell_kind:="Projectiles"
var casting_animation:Dictionary={}
var release_fraction:=0.35
var playing:=false
var released:=false
var elapsed:=0.0
var idle_elapsed:=0.0
var categories:Dictionary={}
var content:VBoxContainer
var controls:VBoxContainer
var empty_label:Label
var element:="Fire"
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

func setup(owner_editor:Node) -> void:
 editor=owner_editor
 # Keep the old self/barrier draft untouched; this is a separate projectile draft.
 if not draft_path.is_empty() and draft_path=="user://spell_draft.cfg":draft_path="user://projectile_spell_draft.cfg"
 var style=StyleBoxFlat.new()
 style.bg_color=Color("e8ddc4")
 style.border_color=Color("b5a27f")
 style.set_border_width_all(1)
 style.set_corner_radius_all(6)
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
 empty_label=editor.menu_label(content,"",16)
 empty_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 controls=VBoxContainer.new()
 controls.add_theme_constant_override("separation",8)
 content.add_child(controls)
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
 refresh()
 visibility_changed.connect(workspace_visibility_changed)

func choose_default(save:=true) -> void:
 for entry in preload("res://scripts/animation_catalog.gd").entries():
  if entry.title=="Default Spell Cast":casting_animation=entry.duplicate(true)
 playing=false
 repeat_wait=0
 reset_caster_pose()
 refresh()
 if save:save_draft()

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
 effect_label.text={"Fire":"Potency increases burn damage. Scorches the ground.","Ice":"Potency freezes legs faster and longer. Creates slippery ground.","Lightning":"Electrifies water for 6 seconds per potency. Stuns everyone in it, including allies and caster.","Wind":"Potency increases knockback and upward lift. Throws nearby debris.","Water":"Water collects beneath the person hit, spreads from that spot, and accumulates. Reset Field drains it.","Earth":"Rock projectile. To raise an Earth Wall, choose Summons."}[element]
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
 reset_caster_pose()

func projectile_spec() -> Dictionary:
 var spec:Dictionary=Projectile.spec(element,projectile_size,potency,testing_sizes,projectile_velocity)
 if spell_kind=="Summons":
  spec={"id":"earth_wall","name":"Earth Wall","effect":"summon_earth","animation":"palm_fireball","hand":"hand_r","release":0.25,"summon_radius":projectile_size,"potency":potency,"mana_percent":Projectile.mana_percent(projectile_size,potency),"mana":Projectile.mana_cost(projectile_size,potency),"damage":0.0}
 spec["appearance"]=appearances.get(element,{}).duplicate(true)
 spec["testing_only"]=testing_sizes and projectile_size>MAX_RADIUS
 var limb:String=str(casting_animation.get("attack_bone","hand_r"))
 spec.hand="Head" if limb in ["mouth","head"] else limb
 spec["provenance"]=spell_provenance.duplicate(true)
 return spec

func cast_duration() -> float:
 if casting_animation.has("duration"):return float(casting_animation.duration)
 if not is_instance_valid(editor.actor):return 0.64
 return CastPose.Source.duration(editor.actor,casting_animation.step,casting_animation.clip)

func play_cast_preview() -> void:
 if category not in ["Projectiles","Summons"] or casting_animation.is_empty() or not is_instance_valid(editor.actor):return
 reset_caster_pose()
 elapsed=0
 playing=true
 released=false
 if release_fraction==0:
  CastPose.pose(editor.actor,casting_animation,0)
  launch_projectile()
  released=true

func launch_projectile() -> void:
 var actor=editor.actor
 var spec:Dictionary=projectile_spec()
 if not actor.can_cast_with(spec,casting_animation):return
 if spec.effect=="summon_earth":editor.field.summon_earth(actor,spec)
 else:editor.field.spawn_projectile(actor,spec,editor.field.fighter_hand(actor,spec.hand)+actor.global_basis.z*0.12)

func _process(delta:float) -> void:
 if not is_visible_in_tree() or not is_instance_valid(editor.actor):return
 if not editor.actor.can_cast_with(projectile_spec(),casting_animation):
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

func workspace_visibility_changed() -> void:
 playing=false
 repeat_wait=0
 clear_shots()
 if is_instance_valid(editor.actor):
  for fighter in editor.field.fighters:
   fighter.editor_pose_locked=is_visible_in_tree() and fighter==editor.actor
   fighter.practice_immortal=is_visible_in_tree()
   fighter.practice_return_enabled=is_visible_in_tree() and fighter!=editor.actor
  reset_caster_pose()
 if is_visible_in_tree():refresh()

func reset_caster_pose() -> void:
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
 var positions:=positions_for_fighters()
 for i in editor.field.fighters.size():
  var fighter=editor.field.fighters[i]
  fighter.practice_return_enabled=fighter!=editor.actor
  fighter.practice_home=positions[i]
  fighter.position=positions[i]
  fighter.velocity=Vector3.ZERO
  fighter.editor_pose_locked=fighter==editor.actor
  fighter.practice_immortal=true
  fighter.brain_enabled=false
  fighter.mode="review"
  var toward:Vector3=(editor.target.position if fighter==editor.actor else editor.actor.position)-fighter.position
  fighter.rotation.y=atan2(toward.x,toward.z)
  RigPose.idle(fighter)
 editor.actor.rival=editor.target
 var forward:Vector3=editor.target.position-editor.actor.position
 editor.actor.rotation.y=atan2(forward.x,forward.z)

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
 if draft_path.is_empty():return
 var cfg=ConfigFile.new()
 var signature: String=JSON.stringify({"kind":spell_kind,"element":element,"size":projectile_size,"potency":potency,"velocity":projectile_velocity,"appearance":appearances,"casting":casting_animation.get("clip",""),"casting_revision":Provenance.source(casting_animation).get("head","") if not casting_animation.is_empty() else ""},"",true).sha256_text()
 if signature!=spell_provenance_signature:
  var parents:Array=[]
  parents.append(spell_provenance if not spell_provenance.is_empty() else Provenance.source({"id":"fightlab_spell_"+element.to_lower(),"title":element+" spell"},"spell"))
  if not casting_animation.is_empty():parents.append(Provenance.source(casting_animation))
  spell_provenance=Provenance.derive(parents,"spell",element+" "+spell_kind,Provenance.creator_name(),"modified spell")
  spell_provenance_signature=signature
 cfg.set_value("credits","provenance",spell_provenance)
 cfg.set_value("credits","signature",spell_provenance_signature)
 cfg.set_value("testing","oversized",testing_sizes)
 cfg.set_value("appearance","elements",appearances)
 cfg.set_value("workspace","category",category)
 cfg.set_value("workspace","spell_kind",spell_kind)
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
 testing_sizes=bool(cfg.get_value("testing","oversized",false))
 appearances=cfg.get_value("appearance","elements",{})
 element=str(cfg.get_value("projectile","element","Fire"))
 if element not in Projectile.ELEMENTS:element="Fire"
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
