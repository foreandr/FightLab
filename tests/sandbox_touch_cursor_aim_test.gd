extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.spell_builder;var browser=s.animation_browser
 while not browser.ready_catalog:await process_frame
 b.saved_spells.directory="user://logs/touch_aim_"+Crypto.new().generate_random_bytes(4).hex_encode()
 b.draft_path="user://logs/touch_aim_draft.cfg";b.preview_preferences_path="user://logs/touch_aim_preview.cfg"
 var definition=load("res://scripts/spell_definition.gd")
 var saved:Dictionary=b.saved_spells.save("Physical Touch",definition.make("None","Touch",{"size":0.5,"speed":0.5},{}))
 assert(saved.ok);browser.spell_catalog.reload_catalog();assert(browser.spell_catalog.select_spell(saved.record.id))
 s.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 b.stop_preview_controls(true);b.spell_focus_target=null;b.manual_aim=true;b.manual_aim_valid=true
 var contact=load("res://scripts/combat_aim.gd")
 for title in ["Left cross","Left knee","Right roundhouse"]:
  var entry:Dictionary={}
  for candidate in browser.records:
   if candidate._origin=="Built-in" and str(candidate.title).nocasecmp_to(title)==0:entry=candidate;break
  assert(not entry.is_empty(),"Missing test animation "+title)
  b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
  assert(browser.select_animation(entry));b.stop_preview_controls(true)
  var emitter:String=contact.emitter(b.playback_animation())
  var positions:Array[Vector3]=[]
  for side in [-1.0,1.0]:
   b.stop_preview_controls(true)
   b.manual_aim_point=s.actor.bone_point("spine_03")+s.actor.global_basis*Vector3(side*4.0,0,5)
   b.play_demo_preview();b.demo_enter_pose.clear();b.process_demo_preview(b.playback_duration()*0.3)
   assert(not b.cast_pose_aim(0.3).is_empty(),"Touch skipped aiming")
   positions.append(s.actor.bone_point(emitter))
  var lateral:float=(positions[1]-positions[0]).dot(s.actor.global_basis.x)
  assert(lateral>0.005,"Touch limb did not steer left/right: "+title+" "+str(lateral))
  print("TOUCH AIM PASS: ",title," ",emitter," lateral shift ",lateral)
 b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 b.held_practice_shortcut.begin(b)
 assert(b.held_cast.active and b.previews_touch() and b.cast_pose_aim(0.3).emitter=="hand_l")
 b.held_practice_shortcut.cancel(b)
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 for record in b.saved_spells.entries():DirAccess.remove_absolute(b.saved_spells.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(b.saved_spells.directory)
 print("SANDBOX CURSOR AIM PASS: punch, knee, kick, and 2 shortcut route through shared directional pose")
 quit()

