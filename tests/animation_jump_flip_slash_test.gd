extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 for frame in range(600):
  await process_frame
  editor=current_scene
  if editor!=null and is_instance_valid(editor.get("slow_button")):break
 var unit:CharacterBody3D=editor.spawn_editor_unit(Vector3(2,0.02,2))
 var jump:Dictionary={"id":101,"group":"Motion","category":"Jump","title":"Jump","step":"Jump","clip":"duel/air","track":"BODY","start":0.0,"duration":1.2,"effort":100,"priority":5}
 var flip:Dictionary={"id":102,"group":"Motion","category":"Acrobatics","title":"Backflip","step":"Flip","clip":"duel/backflip","track":"BODY","start":0.2,"duration":0.68,"priority":2}
 var slash:Dictionary
 for entry in editor.Library.entries():
  if entry.title=="Left body slash":slash=entry.duplicate(true);break
 slash.merge({"id":103,"track":"LEFT ARM","start":0.3,"duration":0.7,"priority":4},true)
 editor.timeline_clips.assign([jump,flip,slash])
 editor.timeline_duration=1.5
 editor._capture_timeline_origin()
 editor._start_track("BODY",flip,0.25)
 var pelvis:int=editor.actor.bones.pelvis
 var arm:int=editor.actor.bones.upperarm_l
 var flip_pelvis:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(pelvis)
 var flip_arm:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(arm)
 editor._start_track("LEFT ARM",slash,0.15)
 var slash_arm:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(arm)
 editor._apply_timeline_at(0.45,true)
 assert(editor.timeline_active.BODY.id==102,"Lower-priority backflip still loses to jump height layer")
 assert(editor.actor.skeleton.get_bone_pose_rotation(pelvis).angle_to(flip_pelvis)<0.001,"Slash erased backflip pelvis")
 assert(editor.actor.skeleton.get_bone_pose_rotation(arm).angle_to(slash_arm)<0.001,"Higher-priority left arm slash missing")
 assert(unit.global_position.y>0.5,"Backflip suppressed physical jump")
 editor.timeline_clips[2].priority=1
 editor._apply_timeline_at(0.45,true)
 assert(editor.actor.skeleton.get_bone_pose_rotation(arm).angle_to(flip_arm)<0.001,"Higher-priority body pose should win over lower-priority limb")
 editor._apply_timeline_at(0.95,true)
 assert(editor.timeline_active.BODY.id==101,"Jump pose should return after backflip")
 for effort in [0,50,100]:
  jump.effort=effort
  assert(editor._clip_combat_stats(jump).damage==0 and editor._clip_combat_stats(jump).spell_multiplier==1)
 editor._rebuild_timeline_tracks()
 for row in editor.timeline_tracks.get_children():
  if row.get_child_count()<2:continue
  for clip_button in row.get_child(1).get_children():
   if clip_button is Button and clip_button.get("clip_id") in [101,102]:assert(not clip_button.text.contains("DMG"),"Motion label still shows damage")
 print("JUMP + BACKFLIP + LEFT ARM SLASH COMPOSITION CHECK PASSED: independent airtime, pose priorities, no motion damage labels")
 quit()
