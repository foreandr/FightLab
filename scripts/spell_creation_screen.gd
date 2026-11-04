extends Control
const CyberStyle=preload("res://scripts/ui_design.gd")
## Standalone spell authoring host. It owns no timeline or custom pose editor.
const Focus=preload("res://scripts/focus_visuals.gd")
const Library=preload("res://scripts/animation_catalog.gd")
var field:Node3D
var actor:CharacterBody3D
var target:CharacterBody3D
var focused_unit:CharacterBody3D
var hovered_unit:CharacterBody3D
var focus_marker:Label3D
var camera_focus_active:=false
var base_ui:Control
var spell_builder:PanelContainer
var arena_area:Control
var title_label:Label
var distance_input:SpinBox
var inspection_camera=preload("res://scripts/sandbox_camera.gd").new()
var category_store=preload("res://scripts/animation_category_store.gd").new()
var store_library=preload("res://scripts/animation_store_library.gd").new()
var recipes:Array[Dictionary]=[]
var workspace_ready:=false
var zoom_dragging:=false
var zoom_remainder:=0.0
var zoom:=1.0
func _ready()->void:
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 category_store.load_state();store_library.load_state()
 var titles:Array=[]
 for choice in preload("res://scripts/spell_builder.gd").DEMO_ANIMATIONS.values():titles.append(choice.source)
 recipes=preload("res://scripts/animation_recipe_library.gd").load_custom_motion("",titles)
 _build_world()
 _build_ui()
 spell_builder.hide();spell_builder.setup(self)
 spell_builder.show()
 spell_builder.prepare_preview_targets()
 frame_spell_preview(actor)
 select_editor_unit(actor)
 workspace_ready=true
 GameDiagnostics.log_event("standalone_spell_creation_ready",{"actors":field.fighters.size(),"demo_sources":spell_builder.demo_source_cache.size(),"animation_editor_loaded":false})
func _build_world()->void:
 field=preload("res://scripts/spell_creation_world.gd").new();field.name="SpellCreationWorld";add_child(field)
 var level=preload("res://scenes/maps/gladiatorial_pit.tscn").instantiate();field.add_child(level);field.use_level(level)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("9cb4b9")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("fff1d5");env.environment.ambient_light_energy=0.7;field.add_child(env)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-48,-35,0);light.light_energy=1.3;light.shadow_enabled=true;field.add_child(light)
 field.camera=Camera3D.new();field.add_child(field.camera);field.camera.current=true;field.vfx.camera=field.camera
 for i in 3:
  var unit=field.spawn_combatant(i,Vector3(i*3,0,0),preload("res://scripts/creation_bot_outfit.gd").profile(i))
  unit.brain_enabled=false;unit.mode="review"
  preload("res://scripts/fighter_overhead_tag.gd").attach(unit,["Animation Bot","Combat dummy","Human target"][i])
 actor=field.fighters[0];target=field.fighters[1];field.editor_animation_only=true;field.round_active=true
 actor.editor_pose_locked=true
func _book_theme()->Theme:
 var book:Theme=preload("res://scripts/game_settings_access.gd").service().dialog.theme.duplicate(true)
 book.default_font_size=14
 var box:=StyleBoxFlat.new();box.bg_color=CyberStyle.PANEL;box.border_color=CyberStyle.LINE;box.set_border_width_all(1)
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:box.set_content_margin(side,6)
 book.set_stylebox("panel","PanelContainer",box)
 return book
func _build_ui()->void:
 base_ui=self;theme=_book_theme()
 var top:=PanelContainer.new();top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_bottom=54;add_child(top)
 var row:=HBoxContainer.new();top.add_child(row)
 var home:=button(row,"",return_to_main_menu);home.name="MainMenu";home.icon=preload("res://scripts/animation_row_icons.gd").get_icon("home");home.tooltip_text="Main Menu";home.custom_minimum_size=Vector2(38,38)
 title_label=menu_label(row,"Spell creation",20)
 distance_input=SpinBox.new();distance_input.hide();add_child(distance_input)
 arena_area=Control.new();arena_area.name="ArenaUnitDrop";arena_area.mouse_filter=Control.MOUSE_FILTER_PASS;add_child(arena_area)
 spell_builder=preload("res://scripts/spell_builder.gd").new();spell_builder.name="SpellBuilder";spell_builder.allow_panel_resize=false;add_child(spell_builder)
func button(parent:Container,title:String,callback:Callable)->Button:
 var node:=Button.new();node.text=title;node.focus_mode=Control.FOCUS_ALL;node.custom_minimum_size.y=34;node.pressed.connect(callback);parent.add_child(node);return node
func menu_label(parent:Container,title:String,font_size:int)->Label:
 var label:=Label.new();label.text=title;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label
func load_custom_motion(category:String)->Array[Dictionary]:return recipes.filter(func(entry):return entry.category==category)
func _ensure_animation_source(entry:Dictionary)->bool:return preload("res://scripts/animation_store_backend.gd")._ensure_animation_source(self,entry)
func _log_store_action(action:String,entry:Dictionary,details:Dictionary={})->void:GameDiagnostics.log_event("spell_animation_"+action,{"title":entry.get("title",""),"details":details})
func _show_library_notice(message:String)->void:
 title_label.text=message
func inspect_asset_metadata(entry:Dictionary)->void:
 var dialog:=AcceptDialog.new();dialog.title=str(entry.get("title","Metadata"));dialog.dialog_text=JSON.stringify(entry.get("provenance",{}),"  ");dialog.theme=theme;add_child(dialog);dialog.popup_centered()
func camera_text_editing()->bool:
 var focused:=get_viewport().gui_get_focus_owner()
 return focused is LineEdit or focused is TextEdit or preload("res://scripts/combat_pointer.gd").dialog_open(get_viewport())
func frame_spell_preview(subject:Node3D)->void:
 spell_builder.third_person_ready=false
 preload("res://scripts/spell_workspace_camera.gd").frame(field.camera,subject,spell_builder.practice_human,inspection_camera)
func reset_setup()->void:
 for fighter in field.fighters:fighter.reset_fighter(fighter.position)
 spell_builder.prepare_preview_targets()
func select_editor_unit(unit:CharacterBody3D)->void:
 if is_instance_valid(unit) and unit.is_visible_in_tree():focused_unit=unit
func _process(_delta:float)->void:
 if not workspace_ready:return
 arena_area.position=Vector2(spell_builder.get_global_rect().end.x,54)
 var right:float=spell_builder.demo_timing_panel.get_global_rect().position.x if spell_builder.demo_timing_panel.visible else size.x
 arena_area.size=Vector2(maxf(0,right-arena_area.position.x),maxf(0,size.y-114))
 var pointer:=get_viewport().get_mouse_position()
 hovered_unit=Focus.pick(field.camera,field.fighters,pointer) if arena_area.get_global_rect().has_point(pointer) and get_viewport().gui_get_hovered_control()==arena_area else null
 for unit in field.fighters:
  var ring:=Focus.ensure_ring(unit);Focus.update_ring(ring,unit==focused_unit,unit==hovered_unit,unit.visible)
 if not is_instance_valid(focus_marker):focus_marker=Focus.create_marker(field)
 Focus.update_marker(focus_marker,field.camera_focus_target if is_instance_valid(field.camera_focus_target) else focused_unit)
func _input(event:InputEvent)->void:
 if not workspace_ready or camera_text_editing():return
 if spell_builder.handle_third_person_input(event):get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_F:spell_builder.toggle_third_person_focus(focused_unit);get_viewport().set_input_as_handled()
  elif event.keycode==KEY_ESCAPE:return_to_main_menu()
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT and event.pressed and arena_area.get_global_rect().has_point(event.position):
   focused_unit=Focus.pick(field.camera,field.fighters,event.position)
  if event.button_index==MOUSE_BUTTON_MIDDLE and event.ctrl_pressed:
   zoom_dragging=event.pressed;zoom_remainder=0
  if event.pressed and event.ctrl_pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   _zoom(1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1);get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and zoom_dragging:
  zoom_remainder-=event.relative.y/40.0
  while absf(zoom_remainder)>=1:
   var step:=1 if zoom_remainder>0 else -1
   zoom_remainder-=step;_zoom(step)
func _zoom(step:int)->void:
 zoom=clampf(zoom+step*0.1,0.6,1.8)
 for root in [spell_builder,spell_builder.demo_timing_panel,spell_builder.spell_playback_panel]:_scale_controls(root)
func _scale_controls(node:Node)->void:
 if node is Label or node is Button or node is LineEdit:
  if not node.has_meta("original_font_size"):node.set_meta("original_font_size",node.get_theme_font_size("font_size"))
  node.add_theme_font_size_override("font_size",roundi(float(node.get_meta("original_font_size"))*zoom))
 for child in node.get_children():_scale_controls(child)
func return_to_main_menu()->void:
 spell_builder.save_draft();spell_builder.stop_preview_controls(true)
 Engine.time_scale=1;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;get_tree().paused=false
 get_tree().change_scene_to_file("res://scenes/home.tscn")
