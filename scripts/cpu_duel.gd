extends "res://scripts/combat_world.gd"
## Match orchestration and spectator UI. Combat is entirely CombatWorld/Runtime.
const Brain=preload("res://scripts/cpu_duel_brain.gd")
const Focus=preload("res://scripts/focus_visuals.gd")
const CameraControls=preload("res://scripts/third_person_camera.gd")
var brains:Array=[]
var ready_for_match:=false
var countdown:=2.0
var paused:=false
var match_seed:=0
var match_winner:=-2
var finished_at:=0.0
var pause_button:Button
var report_dialog:AcceptDialog
var report_text:Label
var camera_zoom:=1.0
var camera_orbit_yaw:=0.35
var camera_orbit_pitch:=0.38
var camera_dragging:=false
var selected:CharacterBody3D
var hovered:CharacterBody3D
var focus_marker:Label3D
var hud:Control
var learning_store:RefCounted
var learning_enabled:=true
var learning_updates:=true
var exploration:=0.06
var policy_overrides:Array=[]
var policy_training_flags:Array=[]
var self_play:=false
var self_play_button:Button
var intermission_left:=2.0
var training_view:=false
var learning_save_ok:=true
func _ready()->void:
 super._ready()
 training_view=bool(get_tree().get_meta("cpu_training_view",false))
 learning_enabled=bool(get_tree().get_meta("ai_learning_enabled",true))
 if learning_enabled:
  learning_store=preload("res://scripts/ai/self_play_store.gd").new()
  learning_store.path=str(get_tree().get_meta("ai_learning_path","user://ai/self_play.json"))
  if not learning_store.load_data():learning_enabled=false;push_warning(learning_store.error)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var pit=preload("res://scenes/maps/gladiatorial_pit.tscn").instantiate();add_child(pit);use_level(pit)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("9cb4b9")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("fff1d5");environment.environment.ambient_light_energy=0.7;add_child(environment)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_energy=1.3;sun.shadow_enabled=true;add_child(sun)
 camera=Camera3D.new();camera.fov=58;add_child(camera);camera.current=true;vfx.camera=camera
 for team in 2:
  var profile:Dictionary=preload("res://scripts/creation_bot_outfit.gd").profile(team)
  profile["shirt_color"]=Color("913f39") if team==0 else Color("416b91")
  var actor=spawn_combatant(team,surface_placement(level_point(Vector3(-4 if team==0 else 4,0,0))),profile)
  actor.brain_enabled=false
  Focus.ensure_ring(actor)
  preload("res://scripts/fighter_overhead_tag.gd").attach(actor,"CPU "+str(team+1))
 focus_marker=Focus.create_marker(self)
 if not training_view:build_ui()
 else:set_process(false)
 ready_for_match=true
 rematch()
 update_camera(1.0)
func rematch(seed_:int=0)->void:
 paused=false
 if is_instance_valid(pause_button):pause_button.text="Pause"
 if not training_view:Engine.time_scale=1.0
 set_physics_process(true)
 match_seed=seed_ if seed_!=0 else int(Time.get_ticks_usec())
 var random:=RandomNumberGenerator.new();random.seed=match_seed
 round_active=false;clear_battle_effects();events.clear();casts.clear();hits.clear();elapsed=0;projectile_clash_count=0
 spell_environment.reset_environment()
 combat().cast_attempts.clear();combat().cast_recoveries.clear();combat().touch_casts.clear()
 brains.clear();match_winner=-2;finished_at=0;countdown=0.1 if training_view else 2.0;intermission_left=2.0
 selected=null;camera_focus_target=null
 var names:Array=["Aster","Rook","Vale","Cinder","Flint","Ash","Wren","Slate"]
 var offset:=random.randi_range(0,names.size()-1)
 for team in 2:
  var actor:CharacterBody3D=fighters[team]
  actor.practice_spell_animation={};actor.practice_projectile_spec={}
  actor.reset_fighter(surface_placement(level_point(Vector3(-4 if team==0 else 4,0,0))))
  actor.brain_enabled=false;actor.practice_god_mode=false;actor.practice_immortal=false
  actor.damage_dealt=0;actor.damage_taken=0;actor.mana_spent=0;actor.stamina_spent=0
  actor.minimum_mana=actor.MAX_MANA;actor.minimum_stamina=actor.MAX_STAMINA;actor.actions.clear()
  actor.blocks=0;actor.guard_breaks=0;actor.melee_hits=0;actor.melee_damage=0;actor.melee_attempts=0
  actor.rival=fighters[1-team];actor.rotation.y=PI/2 if team==0 else -PI/2
  actor.get_node("OverheadHealthTag").name_label.text=names[(offset+team)%names.size()]
  actor.story_profile["name"]=names[(offset+team)%names.size()]
  var brain=Brain.new();brain.setup(actor,self,match_seed+team*7919,random.randf_range(0.35,0.80));brains.append(brain)
  if learning_enabled:
   var table:Dictionary=policy_overrides[team] if policy_overrides.size()==2 else learning_store.data.learner
   brain.policy=preload("res://scripts/ai/adaptive_policy.gd").new()
   var train:bool=learning_updates and (bool(policy_training_flags[team]) if policy_training_flags.size()==2 else true)
   brain.policy.configure(table,match_seed+team*179,train,exploration)
func _physics_process(delta:float)->void:
 if not ready_for_match or paused:return
 if match_winner!=-2 and self_play:
  intermission_left-=delta
  if intermission_left<=0:rematch();return
 if countdown>0:
  countdown=maxf(0.0,countdown-delta)
  if countdown<=0:round_active=true;elapsed=0.0
 else:
  # Alternate evaluation order: neither team always gets the first decision.
  var order:=[0,1] if Engine.get_physics_frames()%2==0 else [1,0]
  for i in order:brains[i].step(delta)
 tick_combat(delta)
 if round_active:
  var dead0:bool=fighters[0].health<=0;var dead1:bool=fighters[1].health<=0
  if dead0 or dead1:finish_round(-1 if dead0 and dead1 else (1 if dead0 else 0))
func projectile_aim_target(actor:CharacterBody3D,spec:Dictionary,origin:Vector3,speed:float)->Vector3:
 var target:=combat_target(actor)
 if not is_instance_valid(target):return super.projectile_aim_target(actor,spec,origin,speed)
 var chest:Vector3=target.bone_point("spine_03")
 var lead:float=minf(0.45,origin.distance_to(chest)/maxf(1.0,speed))
 return chest+Vector3(target.velocity.x,0,target.velocity.z)*lead*0.65
func finish_round(winner:int)->void:
 if match_winner!=-2:return
 match_winner=winner;finished_at=elapsed;super.finish_round(winner)
 for actor in fighters:
  combat().discard_cast_attempt(actor)
 if learning_enabled:
  var updates:=0
  for brain in brains:
   brain.policy.finish(brain.actor,winner,finished_at);updates+=int(brain.policy.updates)
  if learning_updates:
   learning_save_ok=learning_store.completed(updates,winner,finished_at)
   if not learning_save_ok:push_warning("Could not save AI learning profile: "+str(learning_store.last_save_error))
 if winner>=0:
  fighters[winner].get_node("OverheadHealthTag").name_label.text=str(fighters[winner].story_profile.name)+" · Winner"
 var record:Dictionary={"seed":match_seed,"winner":winner,"seconds":elapsed,"fighters":[],"events":events}
 for i in fighters.size():
  var actor:CharacterBody3D=fighters[i]
  record.fighters.append({"name":actor.story_profile.name,"health":actor.health,"damage_dealt":actor.damage_dealt,"stamina_spent":actor.stamina_spent,"mana_spent":actor.mana_spent,"decisions":brains[i].counts})
 var file:=FileAccess.open("user://logs/cpu_demo_last_match.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(record,"  "))
 GameDiagnostics.log_event("cpu_demo_finished",{"seed":match_seed,"winner":winner,"seconds":elapsed})
func button(parent:Container,text_:String,callback:Callable)->Button:
 var node:=Button.new();node.text=text_;node.custom_minimum_size=Vector2(112,38);node.focus_mode=Control.FOCUS_ALL;node.pressed.connect(callback);parent.add_child(node);return node
func label(parent:Container,text_:String,size_:int=16)->Label:
 var node:=Label.new();node.text=text_;node.add_theme_font_size_override("font_size",size_);parent.add_child(node);return node
func build_ui()->void:
 var layer:=CanvasLayer.new();add_child(layer)
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
 hud.theme=preload("res://scripts/game_settings_access.gd").service().dialog.theme.duplicate(true)
 var paper:=StyleBoxFlat.new();paper.bg_color=Color("e8ddc4");paper.border_color=Color("b5a27f");paper.set_border_width_all(1)
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:paper.set_content_margin(side,6)
 hud.theme.set_stylebox("panel","PanelContainer",paper)
 var bottom:=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_top=-54;hud.add_child(bottom)
 var buttons:=HBoxContainer.new();buttons.alignment=BoxContainer.ALIGNMENT_CENTER;bottom.add_child(buttons)
 button(buttons,"Main menu",go_home)
 pause_button=button(buttons,"Pause",toggle_pause);pause_button.tooltip_text="Space"
 button(buttons,"Rematch",func():rematch());button(buttons,"Slow mo",toggle_slow)
 button(buttons,"Hitboxes [2]",func():set_combat_hitboxes(not projectile_hitboxes_visible))
 button(buttons,"Numbers [3]",func():set_combat_numbers(not combat_numbers_visible))
 button(buttons,"Match report",show_report)
 self_play_button=button(buttons,"Self-play [T]",toggle_self_play);self_play_button.toggle_mode=true
 self_play_button.tooltip_text="Keep running matches and saving AI learning"
func toggle_pause()->void:
 paused=not paused;set_physics_process(not paused)
 if is_instance_valid(pause_button):pause_button.text="Resume" if paused else "Pause"
func toggle_self_play()->void:
 self_play=not self_play
 if is_instance_valid(self_play_button):self_play_button.set_pressed_no_signal(self_play)
func toggle_slow()->void:Engine.time_scale=1.0 if Engine.time_scale<1.0 else 0.35
func show_report()->void:
 if not is_instance_valid(report_dialog):
  report_dialog=AcceptDialog.new();report_dialog.title="Match report";report_dialog.theme=hud.theme;add_child(report_dialog)
  var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(540,360);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;report_dialog.add_child(scroll)
  report_text=Label.new();report_text.custom_minimum_size.x=520;report_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;report_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;scroll.add_child(report_text)
 var text_:="Seed: %d\nElapsed: %.1f seconds\nSame loadouts; different decisions.\n"%[match_seed,finished_at if match_winner!=-2 else elapsed]
 text_+="Winner: "+("In progress" if match_winner==-2 else ("Draw" if match_winner<0 else str(fighters[match_winner].story_profile.name)))+"\n"
 if learning_store!=null and not learning_enabled:text_+="Learning unavailable: "+str(learning_store.error)+"\n"
 if learning_enabled:text_+="Learning: %d completed matches · %d updates · champion generation %d\n"%[learning_store.data.matches,learning_store.data.updates,learning_store.data.generation]
 if not learning_save_ok:text_+="Learning was not saved: "+str(learning_store.last_save_error)+"\n"
 for i in fighters.size():
  var actor:CharacterBody3D=fighters[i]
  text_+="\n%s\nDamage %.1f · Mana spent %.1f · Stamina spent %.1f\n"%[actor.story_profile.name,actor.damage_dealt,actor.mana_spent,actor.stamina_spent]
  text_+="Decisions:\n"
  for action in brains[i].counts:text_+="%s: %d\n"%[action,brains[i].counts[action]]
 report_text.text=text_;report_dialog.popup_centered(Vector2i(620,500))
func update_camera(delta:float)->void:
 if fighters.size()!=2:return
 var middle:Vector3=(fighters[0].global_position+fighters[1].global_position)*0.5+Vector3.UP*1.3
 if is_instance_valid(camera_focus_target):middle=middle.lerp(camera_focus_target.focus_position(),0.4)
 var separation:float=fighters[0].global_position.distance_to(fighters[1].global_position)
 var distance:float=preload("res://scripts/game_settings_access.gd").service().clamp_camera_distance(maxf(8.0,separation*1.2+5.0)*camera_zoom)
 var backward:=Vector3(sin(camera_orbit_yaw)*cos(camera_orbit_pitch),sin(camera_orbit_pitch),cos(camera_orbit_yaw)*cos(camera_orbit_pitch))
 camera.global_position=camera.global_position.lerp(middle+backward*distance,1.0-exp(-5.0*delta));camera.look_at(middle)
func _process(delta:float)->void:
 if not ready_for_match:return
 update_camera(delta)
 hovered=Focus.pick(camera,fighters,get_viewport().get_mouse_position()) if get_viewport().gui_get_hovered_control()==null else null
 for actor in fighters:Focus.update_ring(Focus.ensure_ring(actor),actor==selected,actor==hovered,actor.health>0)
 Focus.update_marker(focus_marker,camera_focus_target)
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_SPACE:toggle_pause()
   KEY_R:rematch()
   KEY_T:toggle_self_play()
   KEY_ESCAPE:go_home()
   KEY_2:set_combat_hitboxes(not projectile_hitboxes_visible)
   KEY_3:set_combat_numbers(not combat_numbers_visible)
   KEY_F:camera_focus_target=null if camera_focus_target==selected else selected
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:selected=hovered
  if event.button_index==MOUSE_BUTTON_MIDDLE:camera_dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:CameraControls.zoom(self,event.button_index==MOUSE_BUTTON_WHEEL_UP)
 elif event is InputEventMouseMotion and camera_dragging:CameraControls.orbit(self,event.relative)
func go_home()->void:
 Engine.time_scale=1.0;get_tree().set_meta("home_page","Fight");get_tree().change_scene_to_file("res://scenes/home.tscn")
func _exit_tree()->void:Engine.time_scale=1.0
