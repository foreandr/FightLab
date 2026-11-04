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
 for title in ["Melee Hook","Left cross","Left knee","Right roundhouse"]:
  var entry:Dictionary={}
  for candidate in browser.records:
   if candidate._origin=="Built-in" and str(candidate.title).nocasecmp_to(title)==0:entry=candidate;break
  assert(not entry.is_empty(),"Missing test animation "+title)
  b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
  assert(browser.select_animation(entry));b.stop_preview_controls(true)
  var emitter:String=contact.emitter(b.playback_animation())
  var positions:Array[Vector3]=[]
  var center:Vector3=s.actor.global_position+Vector3.UP*1.25+s.actor.global_basis.z*1.8
  s.field.camera.global_position=s.actor.global_position-s.actor.global_basis.z*5.0+Vector3.UP*3.0
  s.field.camera.look_at(center)
  for offset in [Vector3(-1.8,0,0),Vector3(1.8,0,0),Vector3(0,-1.0,0),Vector3(0,1.0,0)]:
   b.stop_preview_controls(true)
   var pointer:Vector2=s.field.camera.unproject_position(center+s.actor.global_basis*offset)
   b.aim_at_screen(pointer)
   var expected:Vector3=contact.calibration_point(s.field.camera,s.actor,pointer)
   assert(b.manual_aim_point.is_equal_approx(expected),"Touch still uses projectile-depth targeting")
   b.play_demo_preview();b.demo_enter_pose.clear();b.process_demo_preview(b.playback_duration()*0.3)
   assert(not b.cast_pose_aim(0.3).is_empty(),"Touch skipped aiming")
   assert(b.cast_pose_aim(0.3).target.is_equal_approx(expected),"Contact target altered by projectile convergence")
   positions.append(s.actor.bone_point(emitter))
  var horizontal:float=positions[1].distance_to(positions[0])
  var vertical:float=positions[3].distance_to(positions[2])
  assert(horizontal>0.03,"Displayed contact does not respond horizontally: "+title)
  assert(vertical>0.03,"Displayed contact does not respond vertically: "+title)
  print("SCREEN CURSOR PASS: ",title," horizontal ",horizontal," vertical ",vertical)
 b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 b.held_practice_shortcut.begin(b)
 assert(b.held_cast.active and b.previews_touch() and b.cast_pose_aim(0.3).emitter=="hand_l")
 var point:Vector2=s.field.camera.unproject_position(s.actor.global_position+Vector3.UP*2.2+s.actor.global_basis.z*1.8)
 b.aim_at_screen(point)
 assert(b.cast_pose_aim(0.3).target.is_equal_approx(contact.calibration_point(s.field.camera,s.actor,point)))
 b.held_practice_shortcut.cancel(b)
 # Explicit lock-on continues aiming at the locked character.
 b.spell_focus_target=s.target
 assert(b.cast_pose_aim(0.3).target.is_equal_approx(contact.focused_chest(b.spell_focus_target)))
 b.spell_focus_target=null
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 for record in b.saved_spells.entries():DirAccess.remove_absolute(b.saved_spells.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(b.saved_spells.directory)
 print("SANDBOX SCREEN CURSOR AIM PASS: punch, knee, kick, and 2 shortcut route through shared directional pose")
 quit()


