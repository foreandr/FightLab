extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.spell_builder;var browser=s.animation_browser
 while not browser.ready_catalog:await process_frame
 var definition=load("res://scripts/spell_definition.gd")
 b.saved_spells.directory="user://logs/charge_tiers_"+Crypto.new().generate_random_bytes(4).hex_encode()
 b.draft_path="user://logs/charge_tiers_draft.cfg";b.preview_preferences_path="user://logs/charge_tiers_preview.cfg"
 for type_ in ["Touch","Barrier"]:
  var record:Dictionary=definition.make("None",type_,{"size":0.5,"speed":0.5},{})
  assert(b.saved_spells.save("Physical Touch" if type_=="Touch" else "Self Barrier",record).ok)
 browser.spell_catalog.reload_catalog();browser.load_default_pair()
 assert(b.casting_animation.title.to_lower().replace(" ","").replace("_","")=="meleehook")
 assert(b.sandbox_spell_record.name=="Physical Touch" and browser.spell_catalog.selected_type=="Touch")
 s.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 var values:Array=[]
 for hold in [0.0,0.4,0.75,1.1,2.3]:
  b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100;s.actor.health=100
  root.grab_focus();await process_frame
  b.held_cast.begin(b);assert(b.held_cast.active)
  b.process_demo_preview(hold)
  var quote:Dictionary=b.demo_preview_spec()
  assert(b.held_cast.active and quote.has("cast_charge_multiplier"))
  assert(b.held_cast.feedback.quote_label.text.contains("Physical") and b.held_cast.feedback.quote_label.text.contains("Stamina"))
  var state:Dictionary=load("res://scripts/cast_charge_rules.gd").sample(hold)
  assert(b.held_cast.feedback.tier==state.tier)
  assert(b.held_cast.feedback.overlays[0].get_shader_parameter("charge_color").is_equal_approx(state.color))
  if hold==1.1 or hold==2.3:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://work/charge_"+("perfect" if hold==1.1 else "overheld")+".png")
  b.held_cast.release(b)
  assert(is_equal_approx(b.demo_preview_spec().stamina_cost,quote.stamina_cost),"Key-up changed the displayed charge price")
  for i in 120:
   b.process_demo_preview(0.01)
   if b.released:break
  assert(b.released)
  var actual:Dictionary=s.field.combat().touch_casts[s.actor.get_instance_id()].spec
  assert(is_equal_approx(actual.damage,quote.damage) and is_equal_approx(s.actor.stamina,100.0-quote.stamina_cost))
  values.append(quote)
 assert(is_equal_approx(values[0].damage,10.0),"Default quick tap is not ten physical damage")
 assert(values[0].damage<values[1].damage and values[1].damage<values[2].damage and values[2].damage<values[3].damage)
 assert(values[0].stamina_cost<values[1].stamina_cost and values[1].stamina_cost<values[2].stamina_cost )
 assert(is_equal_approx(values[3].stamina_cost,values[0].stamina_cost),"Perfect timing did not remove the hold surcharge")
 assert(values[4].damage>0 and values[4].damage<values[0].damage and values[4].stamina_cost<values[0].stamina_cost)
 b.stop_preview_controls(true)
 var catalog=browser.spell_catalog
 catalog.set_type("Barrier")
 for record in catalog.records:
  if record.name=="Self Barrier":assert(catalog.select_spell(record.id));break
 s.actor.stamina=100;s.actor.mana=100;b.play_projectile_once()
 for i in 120:
  b.process_demo_preview(0.01)
  if b.released:break
 assert(s.actor.self_barrier.active())
 b.held_cast.feedback.finish();b.held_cast.feedback._process(0.5)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/self_barrier_clear.png")
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 b.stop_preview_controls(true);s.actor.self_barrier.clear();s.actor.stamina=100;s.actor.mana=100
 var selected_before:String=b.casting_animation.title
 var shortcut_values:Array=[]
 for hold in [0.0,0.5,1.1,2.3]:
  b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
  var hotkey:=InputEventKey.new();hotkey.keycode=KEY_2;hotkey.physical_keycode=KEY_2;hotkey.pressed=true
  root.grab_focus();await process_frame
  b._input(hotkey)
  assert(b.held_practice_shortcut.active and b.held_cast.active and b.casting_animation.title=="Left Cross")
  b.process_demo_preview(hold)
  var shortcut_quote:Dictionary=b.demo_preview_spec()
  assert(not b.released and shortcut_quote.touch_contacts==["hand_l"])
  shortcut_values.append(shortcut_quote)
  print("2 hold=",hold," duration=",shortcut_quote.animation_duration," damage=",shortcut_quote.damage," stamina=",shortcut_quote.stamina_cost," mana=",shortcut_quote.mana)
  hotkey.pressed=false;b._input(hotkey)
  for i in 120:
   b.process_demo_preview(0.01)
   if b.released:break
  assert(b.released)
  var shortcut_spec:Dictionary=s.field.combat().touch_casts[s.actor.get_instance_id()].spec
  assert(is_equal_approx(shortcut_spec.damage,shortcut_quote.damage) and is_equal_approx(s.actor.stamina,100.0-shortcut_quote.stamina_cost))
  assert(is_equal_approx(s.actor.mana,100.0-shortcut_quote.mana))
  assert(b.cast_committed() and not b.apply_spell_record(b.sandbox_spell_record),"Released shortcut could be canceled by selecting a spell")
  b.process_demo_preview(3.0)
  assert(not b.held_practice_shortcut.active and b.casting_animation.title==selected_before,"2 replaced the selected animation")
 assert(is_equal_approx(shortcut_values[0].damage,10.0) and is_equal_approx(shortcut_values[2].damage,20.0))
 assert(shortcut_values[1].stamina_cost>shortcut_values[0].stamina_cost and is_equal_approx(shortcut_values[2].stamina_cost,shortcut_values[0].stamina_cost))
 assert(shortcut_values[3].damage<shortcut_values[0].damage)
 b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 var cancel_key:=InputEventKey.new();cancel_key.keycode=KEY_2;cancel_key.physical_keycode=KEY_2;cancel_key.pressed=true
 root.grab_focus();await process_frame
 b._input(cancel_key);b.process_demo_preview(0.4);b.stop_preview_controls(true);b.process_demo_preview(0.0)
 assert(not b.held_practice_shortcut.active and b.casting_animation.title==selected_before)
 assert(s.actor.stamina<100.0 and is_equal_approx(s.actor.mana,100.0),"Interrupted shortcut did not settle stamina without mana")
 assert(not s.target_behavior.menu.visible)
 for button in b.spell_playback_panel.find_children("*","Button",true,false):assert(not button.text.contains("[2]"),"Left Cross was added to the hotbar")
 for record in b.saved_spells.entries():DirAccess.remove_absolute(b.saved_spells.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(b.saved_spells.directory)
 print("SANDBOX CHARGE PASS: default hook/physical pair, tier colors, real quote/payment/damage, red below tap, transparent spaced shield")
 quit()
