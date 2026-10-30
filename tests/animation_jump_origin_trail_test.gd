extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 for frame in range(600):
  await process_frame
  editor=current_scene
  if editor!=null and is_instance_valid(editor.get("slow_button")):break
 editor.timeline_name.text=""
 var first:CharacterBody3D=editor.spawn_editor_unit(Vector3(5,0.02,4))
 var second:CharacterBody3D=editor.spawn_editor_unit(Vector3(-4,0.02,3))
 var entry:Dictionary={"group":"Motion","category":"Jump","title":"Jump","step":"Jump","clip":"duel/air"}
 editor.focus_editor_unit(0)
 var before:Vector3=first.global_position
 editor.add_timeline_clip(entry,"BODY",0.8)
 assert(Vector2(first.global_position.x-before.x,first.global_position.z-before.z).length()<0.001,"Adding a clip teleports first bot")
 editor.focus_editor_unit(1)
 var second_before:Vector3=second.global_position
 editor.select_timeline_clip(editor.timeline_clips[0].id)
 assert(Vector2(second.global_position.x-second_before.x,second.global_position.z-second_before.z).length()<0.001,"Cached origin teleports newly selected bot")
 editor.move_editor_unit(second,Vector3(-6,0.02,5))
 editor.add_timeline_clip(entry,"LEFT LEG",0.2)
 assert(absf(second.global_position.x+6)<0.001 and absf(second.global_position.z-5)<0.001,"Dragged bot recenters on new clip")
 var id:int=editor.timeline_clips[0].id
 editor.edit_timeline_clip_edge(id,"right",9.0,true)
 assert(editor.timeline_clips[0].duration>8.0,"Old physical-airtime cap still limits pose length")
 editor.timeline_selected_id=id
 editor.timeline_motion_effort.value=25
 editor._timeline_motion_parameters_changed()
 assert(editor.timeline_clips[0].duration>8.0,"Changing stamina re-clamps clip duration")
 var count:int=editor.field.particles.size()
 editor.actor.velocity=Vector3.UP*12
 editor.field.speed_trail(editor.actor)
 editor.field.movement_burst(editor.actor,true)
 assert(editor.field.particles.size()==count,"Red speed trail or movement particles still appear")
 editor.play_timeline()
 assert(editor.actor.editor_pose_locked,"Hidden driver still runs jump physics")
 for frame in range(10):await process_frame
 assert(Vector2(second.global_position.x+6,second.global_position.z-5).length()<0.001,"Playing animation recenters bot")
 print("JUMP ORIGIN, LONG CLIP AND RED SPEED-TRAIL CHECK PASSED")
 quit()
