extends "res://scripts/combat_world.gd"
## Match orchestration and spectator UI. Combat is entirely CombatWorld/Runtime.
const Brain=preload("res://scripts/cpu_duel_brain.gd")
const Focus=preload("res://scripts/focus_visuals.gd")
const CameraControls=preload("res://scripts/third_person_camera.gd")
var brains:Array=[]
var ready_for_match:=false
var countdown:=3.0
var begin_flash:=0.0
var finish_slowmo_left:=0.0
var countdown_label:Label
var paused:=false
var match_seed:=0
var match_winner:=-2
var finished_at:=0.0
var match_duration:=120.0
var finish_reason:=""
var timer_label:Label
var hitboxes_button:Button
var numbers_button:Button
var pause_button:Button
var report_dialog:AcceptDialog
var report_text:Label
var camera_zoom:=1.0
var camera_orbit_yaw:=0.35
var camera_orbit_pitch:=0.38
var camera_dragging:=false
var camera_follow_point:=Vector3.ZERO
var camera_follow_ready:=false
var result_camera_frame:Dictionary={}
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
var spell_names_button:Button
var spell_names_visible:=false
var last_spell_labels:Dictionary={}
var last_spell_until:Dictionary={}
var self_play_button:Button
var intermission_left:=2.0
var training_view:=false
var learning_save_ok:=true
var model_dialog:AcceptDialog
var model_match_labels:Array[String]=[]
var model_match_paths:Array[String]=[]
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
 if not training_view:
  build_ui()
  if learning_enabled and not learning_store.has_snapshots():
   if learning_store.save_snapshot("First archived model").is_empty():push_warning(learning_store.snapshot_error)
 else:set_process(false)
 ready_for_match=true
 rematch()
 update_camera(1.0)
func rematch(seed_:int=0)->void:
 paused=false
 finish_slowmo_left=0.0
 result_camera_frame.clear();camera_follow_ready=false
 if is_instance_valid(pause_button):pause_button.text="Pause"
 if not training_view:Engine.time_scale=1.0
 set_physics_process(true)
 match_seed=seed_ if seed_!=0 else int(Time.get_ticks_usec())
 var random:=RandomNumberGenerator.new();random.seed=match_seed
 round_active=false;clear_battle_effects();events.clear();casts.clear();hits.clear();elapsed=0;projectile_clash_count=0
 spell_environment.reset_environment()
 combat().cast_attempts.clear();combat().cast_recoveries.clear();combat().touch_casts.clear()
 brains.clear();match_winner=-2;finished_at=0;finish_reason="";countdown=0.1 if training_view else 3.0;begin_flash=0.0;intermission_left=2.0
 for spell_label in last_spell_labels.values():spell_label.text="";spell_label.visible=false
 last_spell_until.clear()
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
  if model_match_labels.size()==2:
   actor.story_profile.name+=" · "+model_match_labels[team]
   actor.get_node("OverheadHealthTag").name_label.text=actor.story_profile.name
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
  var countdown_delta:=delta if training_view else delta/maxf(0.001,Engine.time_scale)
  countdown=maxf(0.0,countdown-countdown_delta)
  if countdown<0.00001:countdown=0.0
  combat().step_actors(delta)
  elapsed=0.0
  if countdown<=0:
   round_active=true;begin_flash=0.55
   events.append({"time":0.0,"event":"round_start","seed":match_seed})
  return
 else:
  begin_flash=maxf(0.0,begin_flash-delta/maxf(0.001,Engine.time_scale))
  # Alternate evaluation order: neither team always gets the first decision.
  var order:=[0,1] if Engine.get_physics_frames()%2==0 else [1,0]
  for i in order:brains[i].step(delta)
 var combat_delta:=minf(delta,maxf(0.0,match_duration-elapsed)) if round_active else delta
 tick_combat(combat_delta)
 if round_active:
  var dead0:bool=fighters[0].health<=0;var dead1:bool=fighters[1].health<=0
  if dead0 or dead1:finish_round(-1 if dead0 and dead1 else (1 if dead0 else 0))
  elif elapsed>=match_duration-0.00001:
   elapsed=match_duration
   finish_reason="timeout"
   var difference:float=fighters[0].health-fighters[1].health
   finish_round(-1 if absf(difference)<0.001 else (0 if difference>0 else 1))
func time_remaining()->float:
 return maxf(0.0,match_duration-(finished_at if match_winner!=-2 else (0.0 if countdown>0 else elapsed)))
func projectile_aim_target(actor:CharacterBody3D,spec:Dictionary,origin:Vector3,speed:float)->Vector3:
 var target:=combat_target(actor)
 if not is_instance_valid(target):return super.projectile_aim_target(actor,spec,origin,speed)
 var chest:Vector3=target.bone_point("spine_03")
 var lead:float=minf(0.45,origin.distance_to(chest)/maxf(1.0,speed))
 return chest+Vector3(target.velocity.x,0,target.velocity.z)*lead*0.65
func finish_round(winner:int)->void:
 if match_winner!=-2:return
 if finish_reason.is_empty():finish_reason="knockout" if fighters.any(func(a):return a.health<=0) else "manual"
 # Result framing must not track settling corpses or residual actor movement.
 # Keep orbit, zoom and changing focus available after the fight.
 result_camera_frame={"middle":(fighters[0].global_position+fighters[1].global_position)*0.5+Vector3.UP*1.3,"separation":fighters[0].global_position.distance_to(fighters[1].global_position),"focus":{}}
 for actor in fighters:result_camera_frame.focus[actor.get_instance_id()]=actor.focus_position()
 match_winner=winner;finished_at=elapsed;super.finish_round(winner)
 if not training_view:
  finish_slowmo_left=1.1;Engine.time_scale=0.2
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
 var record:Dictionary={"seed":match_seed,"winner":winner,"seconds":elapsed,"fighters":[],"events":events,"model_paths":model_match_paths.duplicate(),"learning":learning_updates,"finish_reason":finish_reason,"duration_limit":match_duration}
 for i in fighters.size():
  var actor:CharacterBody3D=fighters[i]
  record.fighters.append({"name":actor.story_profile.name,"health":actor.health,"damage_dealt":actor.damage_dealt,"stamina_spent":actor.stamina_spent,"mana_spent":actor.mana_spent,"decisions":brains[i].counts})
 var file:=FileAccess.open("user://logs/cpu_demo_last_match.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(record,"  "))
 GameDiagnostics.log_event("cpu_demo_finished",{"seed":match_seed,"winner":winner,"seconds":elapsed})
func button(parent:Container,text_:String,callback:Callable)->Button:
 var node:=Button.new();node.text=text_;node.custom_minimum_size=Vector2(90,32);node.add_theme_font_size_override("font_size",14);node.focus_mode=Control.FOCUS_ALL;node.pressed.connect(callback);parent.add_child(node);return node
func label(parent:Container,text_:String,size_:int=16)->Label:
 var node:=Label.new();node.text=text_;node.add_theme_font_size_override("font_size",size_);parent.add_child(node);return node
func build_ui()->void:
 var layer:=CanvasLayer.new();add_child(layer)
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
 hud.theme=preload("res://scripts/game_settings_access.gd").service().dialog.theme.duplicate(true)
 var paper:=StyleBoxFlat.new();paper.bg_color=Color("e8ddc4");paper.border_color=Color("b5a27f");paper.set_border_width_all(1)
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:paper.set_content_margin(side,6)
 hud.theme.set_stylebox("panel","PanelContainer",paper)
 var clock:=PanelContainer.new();clock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);clock.offset_left=-54;clock.offset_right=54;clock.offset_top=6;clock.offset_bottom=44;clock.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(clock)
 timer_label=label(clock,"2:00",24);timer_label.name="MatchTimer";timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 countdown_label=preload("res://scripts/round_countdown_label.gd").new();hud.add_child(countdown_label)
 var bottom:=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_top=-46;bottom.grow_vertical=Control.GROW_DIRECTION_BEGIN;hud.add_child(bottom)
 var buttons:=HFlowContainer.new();buttons.alignment=FlowContainer.ALIGNMENT_CENTER;buttons.add_theme_constant_override("h_separation",6);buttons.add_theme_constant_override("v_separation",6);bottom.add_child(buttons)
 button(buttons,"Main menu",go_home)
 pause_button=button(buttons,"Pause",toggle_pause);pause_button.tooltip_text="Space"
 button(buttons,"Rematch",func():rematch());button(buttons,"Slow mo",toggle_slow)
 hitboxes_button=button(buttons,"Hitboxes [2]",func():set_combat_hitboxes(not projectile_hitboxes_visible));hitboxes_button.toggle_mode=true;hitboxes_button.set_pressed_no_signal(projectile_hitboxes_visible)
 numbers_button=button(buttons,"Numbers [3]",func():set_combat_numbers(not combat_numbers_visible));numbers_button.toggle_mode=true;numbers_button.set_pressed_no_signal(combat_numbers_visible)
 spell_names_button=button(buttons,"Spells [4]",toggle_spell_names);spell_names_button.toggle_mode=true
 spell_names_button.tooltip_text="Show casts, cancelled feints and hesitations above each fighter"
 button(buttons,"Match report",show_report)
 self_play_button=button(buttons,"Self-play [T]",toggle_self_play);self_play_button.toggle_mode=true
 self_play_button.tooltip_text="Keep running matches and saving AI learning"
 var models_button:=button(buttons,"Models [M]",show_models);models_button.disabled=not learning_enabled
func set_combat_hitboxes(enabled:bool)->void:
 super.set_combat_hitboxes(enabled)
 if is_instance_valid(hitboxes_button):hitboxes_button.set_pressed_no_signal(enabled)
func set_combat_numbers(enabled:bool)->void:
 super.set_combat_numbers(enabled)
 if is_instance_valid(numbers_button):numbers_button.set_pressed_no_signal(enabled)
func show_models()->void:
 if not learning_enabled:return
 if not is_instance_valid(model_dialog):
  model_dialog=preload("res://scripts/ai/model_match_dialog.gd").new();add_child(model_dialog);model_dialog.setup(self)
 model_dialog.open()
func start_model_match(red_path:String,blue_path:String)->bool:
 if not learning_enabled:return false
 var models:Array=[];var captions:Array[String]=[]
 for file_path in [red_path,blue_path]:
  if file_path.is_empty():
   models.append(learning_store.data.learner.duplicate(true));captions.append("Current AI")
  else:
   var snapshot:Dictionary=learning_store.load_snapshot(file_path)
   if snapshot.is_empty():return false
   models.append(snapshot.learner.duplicate(true));captions.append("AI %d matches"%int(snapshot.matches))
 policy_overrides=models;policy_training_flags=[false,false];learning_updates=false
 model_match_labels=captions;model_match_paths.assign([red_path,blue_path])
 if self_play:toggle_self_play()
 rematch();return true
func resume_model_learning()->void:
 policy_overrides=[];policy_training_flags=[];learning_updates=true;model_match_labels.clear();model_match_paths.clear()
 rematch()
func toggle_spell_names()->void:
 spell_names_visible=not spell_names_visible
 if is_instance_valid(spell_names_button):spell_names_button.set_pressed_no_signal(spell_names_visible)
 update_spell_names()
func update_spell_names()->void:
 for id in last_spell_labels:
  last_spell_labels[id].visible=spell_names_visible and elapsed<float(last_spell_until.get(id,0.0))
func combat_cast_feedback(actor:CharacterBody3D,spec:Dictionary)->void:
 super.combat_cast_feedback(actor,spec)
 combat_tactical_feedback(actor,str(spec.get("name",spec.get("id","Spell"))))
func combat_tactical_feedback(actor:CharacterBody3D,text_:String)->void:
 if training_view:return
 var id:=actor.get_instance_id()
 if not last_spell_labels.has(id):
  var tag=actor.get_node("OverheadHealthTag")
  var spell_label:Label3D=tag.make_label(19,0.009)
  spell_label.name="LastSpellCast";spell_label.position.y=0.66
  spell_label.modulate=Color("fff0bb")
  tag.add_child(spell_label);last_spell_labels[id]=spell_label
 last_spell_labels[id].text=text_
 last_spell_until[id]=elapsed+2.5
 update_spell_names()
func toggle_pause()->void:
 paused=not paused;set_physics_process(not paused)
 if is_instance_valid(pause_button):pause_button.text="Resume" if paused else "Pause"
func toggle_self_play()->void:
 self_play=not self_play
 if is_instance_valid(self_play_button):self_play_button.set_pressed_no_signal(self_play)
func toggle_slow()->void:
 finish_slowmo_left=0.0
 Engine.time_scale=1.0 if Engine.time_scale<1.0 else 0.35
func step_finish_slowmo(real_delta:float)->void:
 if finish_slowmo_left<=0.0 or paused:return
 finish_slowmo_left=maxf(0.0,finish_slowmo_left-real_delta)
 Engine.time_scale=lerpf(1.0,0.2,clampf(finish_slowmo_left/0.4,0.0,1.0))
func show_report()->void:
 if not is_instance_valid(report_dialog):
  report_dialog=AcceptDialog.new();report_dialog.title="Match report";report_dialog.theme=hud.theme;add_child(report_dialog)
  var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(540,360);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;report_dialog.add_child(scroll)
  report_text=Label.new();report_text.custom_minimum_size.x=520;report_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;report_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;scroll.add_child(report_text)
 var text_:="Seed: %d\nElapsed: %.1f seconds\nSame loadouts; different decisions.\n"%[match_seed,finished_at if match_winner!=-2 else elapsed]
 text_+="Winner: "+("In progress" if match_winner==-2 else ("Draw" if match_winner<0 else str(fighters[match_winner].story_profile.name)))+"\n"
 if not finish_reason.is_empty():text_+="Result: "+finish_reason+"\n"
 if learning_store!=null and not learning_enabled:text_+="Learning unavailable: "+str(learning_store.error)+"\n"
 if learning_enabled:text_+="Learning: %d completed matches · %d updates · champion generation %d\n"%[learning_store.data.matches,learning_store.data.updates,learning_store.data.generation]
 if not model_match_labels.is_empty():text_+="Frozen comparison: Red %s vs Blue %s\n"%model_match_labels
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
 var separation:float=fighters[0].global_position.distance_to(fighters[1].global_position)
 if not result_camera_frame.is_empty():
  middle=result_camera_frame.middle;separation=result_camera_frame.separation
 if is_instance_valid(camera_focus_target):
  var focus:Vector3=result_camera_frame.get("focus",{}).get(camera_focus_target.get_instance_id(),camera_focus_target.focus_position())
  middle=middle.lerp(focus,0.4)
 var distance:float=preload("res://scripts/game_settings_access.gd").service().clamp_camera_distance(maxf(8.0,separation*1.2+5.0)*camera_zoom)
 var backward:=Vector3(sin(camera_orbit_yaw)*cos(camera_orbit_pitch),sin(camera_orbit_pitch),cos(camera_orbit_yaw)*cos(camera_orbit_pitch))
 var weight:=1.0-exp(-5.0*maxf(0.0,delta))
 if not camera_follow_ready:camera_follow_point=middle;camera_follow_ready=true
 # Smooth aim and eye together, so physics corrections cannot snap the view.
 camera_follow_point=camera_follow_point.lerp(middle,weight)
 camera.global_position=camera.global_position.lerp(middle+backward*distance,weight)
 camera.look_at(camera_follow_point)
func _process(delta:float)->void:
 if not ready_for_match:return
 step_finish_slowmo(delta/maxf(0.001,Engine.time_scale))
 if is_instance_valid(countdown_label):countdown_label.display(countdown,begin_flash)
 if is_instance_valid(timer_label):
  var seconds:=int(ceil(time_remaining()))
  timer_label.text="%d:%02d"%[seconds/60,seconds%60]
  var color:=Color("b64336") if seconds<=10 else Color("3a3022")
  if timer_label.get_theme_color("font_color")!=color:timer_label.add_theme_color_override("font_color",color)
 update_camera(delta)
 update_spell_names()
 hovered=Focus.pick(camera,fighters,get_viewport().get_mouse_position()) if get_viewport().gui_get_hovered_control()==null else null
 for actor in fighters:Focus.update_ring(Focus.ensure_ring(actor),actor==selected,actor==hovered,actor.health>0)
 Focus.update_marker(focus_marker,camera_focus_target)
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_SPACE:toggle_pause()
   KEY_R:rematch()
   KEY_T:toggle_self_play()
   KEY_M:show_models()
   KEY_ESCAPE:go_home()
   KEY_2:set_combat_hitboxes(not projectile_hitboxes_visible)
   KEY_3:set_combat_numbers(not combat_numbers_visible)
   KEY_4:toggle_spell_names()
   KEY_F:camera_focus_target=null if camera_focus_target==selected else selected
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:selected=hovered
  if event.button_index==MOUSE_BUTTON_MIDDLE:camera_dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:CameraControls.zoom(self,event.button_index==MOUSE_BUTTON_WHEEL_UP)
 elif event is InputEventMouseMotion and camera_dragging:CameraControls.orbit(self,event.relative)
func go_home()->void:
 Engine.time_scale=1.0;get_tree().set_meta("home_page","Fight");get_tree().change_scene_to_file("res://scenes/home.tscn")
func _exit_tree()->void:Engine.time_scale=1.0
