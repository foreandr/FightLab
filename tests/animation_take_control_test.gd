extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 for frame in range(600):
  await process_frame
  editor=current_scene
  if editor!=null and is_instance_valid(editor.get("slow_button")):break
 var idle:Dictionary={"group":"Motion","category":"Idle","step":"Idle","title":"Idle","clip":"spells/idle","effort":100.0,"duration":1.0}
 assert(editor._clip_combat_stats(idle).stamina==0,"Idle must never cost stamina")
 var attacker:CharacterBody3D=editor.spawn_editor_unit(Vector3(0,0.02,0))
 var victim:CharacterBody3D=editor.spawn_editor_unit(Vector3(0,0.02,2))
 editor.focus_editor_unit(0)
 editor.playtest.toggle()
 assert(editor.playtest.active)
 var start:Vector3=attacker.global_position
 var key:=InputEventKey.new()
 key.keycode=KEY_W;key.pressed=true
 assert(editor.playtest.handle_input(key))
 for frame in range(10):await process_frame
 key.pressed=false
 editor.playtest.handle_input(key)
 assert(attacker.global_position.distance_to(start)>0.05,"WASD did not move controlled bot")
 key.keycode=KEY_SPACE;key.pressed=true
 editor.playtest.handle_input(key)
 for frame in range(3):await process_frame
 assert(attacker.global_position.y>0.02,"Space did not jump")
 editor.playtest.reset_units()
 var attack:Dictionary
 for entry in editor.Library.entries():
  if entry.title=="Left jab":attack=entry.duplicate(true);break
 attack.merge({"id":987,"track":"BODY","start":0.0,"duration":1.0,"priority":3},true)
 editor.timeline_clips.assign([attack])
 editor.timeline_duration=1.0
 editor.playtest.trigger()
 assert(editor.timeline_playing)
 editor.timeline_playhead=0.45
 editor._apply_timeline_at(0.45,true)
 editor._blend_unit_pose_targets(1)
 var bone:String=attack.get("attack_bone","hand_l")
 var point:Vector3=attacker.bone_point(bone)
 var offset:Vector3=victim.bone_point("spine_03")-victim.global_position
 victim.global_position=point-offset
 var health_before:float=victim.health
 editor.playtest.contacts()
 assert(victim.health<health_before,"Authored attack limb did not hit practice target")
 var damaged:float=victim.health
 editor.playtest.contacts()
 assert(victim.health==damaged,"Repeated damage within same clip")
 var stamina_before:float=attacker.stamina
 editor._spend_timeline_stamina(0,0.5)
 assert(attacker.stamina<stamina_before)
 editor.playtest.reset_units()
 assert(victim.health==health_before)
 editor.playtest.release()
 assert(not editor.playtest.active)
 editor.select_group("Motion")
 editor.select_category("Idle",true)
 for frame in range(5):await process_frame
 var widths:Array=[]
 for row in editor.animation_list.get_children():
  if row is HBoxContainer:widths.append(row.get_child(0).size.x)
 for width in widths:assert(absf(width-widths[0])<1.0,"Starter name box wider than imported rows")
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("user://animation_take_control_test.png")
 print("TAKE CONTROL CHECK PASSED: zero idle cost, WASD, jump, timeline trigger, limb contact damage once, stamina, reset and release")
 quit()
