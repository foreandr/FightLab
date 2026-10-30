extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 for frame in range(600):
  await process_frame
  editor=current_scene
  if editor!=null and is_instance_valid(editor.get("slow_button")):break
 var unit:CharacterBody3D=editor.spawn_editor_unit(Vector3(1,0.02,2))
 var other:CharacterBody3D=editor.spawn_editor_unit(Vector3(3,0.02,2))
 assert(unit.clip=="default_idle/ual1_Idle" and other.clip==unit.clip,"Spawn does not use Idle cannon")
 editor.focus_editor_unit(0)
 var jump:Dictionary={"group":"Motion","category":"Jump","title":"Jump","step":"Jump","clip":"duel/air"}
 editor.timeline_name.text=""
 editor.add_timeline_clip(jump,"BODY",0.7)
 assert(editor.timeline_clips.back().start==0,"New animation must start at zero")
 editor.timeline_clips.back().effort=100.0
 editor.timeline_clips.back().duration=0.5
 editor.timeline_duration=0.5
 editor.timeline_length_input.set_value_no_signal(0.5)
 editor._refresh_timeline_motion_controls(editor.timeline_clips.back())
 assert(editor.timeline_motion_output.text.contains("Air continues +"))
 for motion in ["Jump","Run","Sprint","Dash"]:
  assert(editor._timeline_motion_stats({"step":motion,"duration":1,"effort":100}).distance==0,"Unwanted horizontal travel")
 var start:Vector3=unit.global_position
 start.y=float(unit.get_meta("editor_ground_y",0.02))
 editor.play_timeline()
 var ended_airborne:=false
 for frame in range(200):
  await process_frame
  if not editor.timeline_playing:
   ended_airborne=unit.global_position.y>start.y+0.05
   break
 assert(ended_airborne and not editor.jump_tails.is_empty(),"Jump did not continue after timeline ended")
 var end_height:float=unit.global_position.y
 for frame in range(200):
  await process_frame
  if editor.jump_tails.is_empty():break
 print("TAIL STATE ",editor.jump_tails," Y=",unit.global_position.y," ground=",start.y)
 assert(editor.jump_tails.is_empty() and absf(unit.global_position.y-start.y)<0.01,"Bot remained frozen in midair")
 assert(Vector2(unit.global_position.x-start.x,unit.global_position.z-start.z).length()<0.01,"Jump travelled horizontally")
 # Hidden fighter charge visual must never leak into animation workspace.
 editor.actor.editor_pose_locked=true
 editor.actor.mode="cast"
 editor.actor.did_release=false
 editor.field.round_active=true
 for frame in range(8):await process_frame
 for charge in editor.field.charges:assert(not charge.visible,"Hidden charge artifact visible")
 var before_mode:String=editor.actor.mode
 editor.preview_animation(jump)
 for frame in range(8):await process_frame
 assert(not editor.live_preview_sequence.active,"Hover started hidden gameplay")
 print("JUMP FINISH CHECK PASSED: Idle cannon, zero-start clips, no horizontal travel, airtime delta, continued flight/landing, hidden charge suppressed")
 quit()
