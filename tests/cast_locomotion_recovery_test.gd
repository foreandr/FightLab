extends SceneTree
const Type=preload("res://scripts/animation_cast_type.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for type_ in [Type.LEGS,Type.WHOLE_BODY]:
  var profile={"animation_type":type_}
  assert(Type.recovery_weight(profile,0.69 if type_==Type.LEGS else 0.74,1.0)==0)
  assert(is_equal_approx(Type.recovery_weight(profile,0.85 if type_==Type.LEGS else 0.875,1.0),0.5))
  assert(Type.recovery_weight(profile,1.0,1.0)==1)
  if type_==Type.LEGS:
   assert(Type.recovery_weight(profile,7.0,10.0)==0)
   assert(is_equal_approx(Type.recovery_weight(profile,8.5,10.0),0.5))
  else:assert(Type.recovery_weight(profile,9.6,10.0)==0)
  assert(Type.recovery_weight(profile,0.9,1.0,0.95)==0)
  assert(is_equal_approx(Type.recovery_weight(profile,0.975,1.0,0.95),0.5))
 assert(Type.recovery_weight({"animation_type":Type.ARMS},0.9,1.0)==0)
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 e.select_group("Spells")
 var b=e.spell_builder
 b.draft_path="user://logs/cast_recovery_draft_test.cfg"
 b.preview_preferences_path="user://logs/cast_recovery_preview_test.cfg"
 b.open_projectile_workspace()
 b.set_process(false);b.set_physics_process(false)
 e.set_physics_process(false);e.field.set_physics_process(false)
 var actor=e.actor
 actor.practice_god_mode=true;actor.collision_mask=1
 for choice in ["knee","dismantle"]:
  b.stop_preview_controls(true);b.select_demo_choice(choice,false)
  b.set_demo_duration(1.0);b.stop_preview_controls(true)
  actor.global_position=e.field.surface_placement(Vector3.ZERO)
  b.move_caster(0.01,Vector2.ZERO,false)
  b.move_caster(1.0/60.0,Vector2(0,1),true)
  b.play_demo_preview()
  var early_frames:=42 if choice=="knee" else 45
  for frame in early_frames:
   await physics_frame
   b.move_caster(1.0/60.0,Vector2(0,1),true)
   b.process_demo_preview(1.0/60.0)
  assert(b.released and b.cast_committed() and b.playing)
  var early_speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
  assert(not b.caster_sprinting)
  var halfway_speed:=0.0
  var recovery_frames:=59-early_frames
  for frame in recovery_frames:
   await physics_frame
   b.move_caster(1.0/60.0,Vector2(0,1),true)
   b.process_demo_preview(1.0/60.0)
   if frame==recovery_frames/2:halfway_speed=Vector2(actor.velocity.x,actor.velocity.z).length()
  var late_speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
  assert(halfway_speed>early_speed and late_speed>halfway_speed and late_speed>6.0,"Speed did not return before animation ended")
  assert(b.playing and b.cast_committed() and b.cast_recovery_weight()>0.9)
  var actual:=Pose.capture(actor)
  var weight:float=b.cast_recovery_weight()
  Pose.pose(actor,b.playback_animation(),b.elapsed/b.playback_duration(),b.cast_pose_aim(b.elapsed/b.playback_duration()))
  Locomotion.cast_legs(actor,b.playback_animation(),Vector2(0,1),b.idle_elapsed,true)
  var cast:=Pose.capture(actor)
  Locomotion.pose(actor,Vector2(0,1),b.idle_elapsed,true)
  var gait:=Pose.capture(actor)
  for bone in actual.size():assert(actual[bone].is_equal_approx(cast[bone].interpolate_with(gait[bone],weight)),"Recovery pose mismatch")
  var time:float=b.elapsed
  b.play_projectile_once()
  assert(b.elapsed==time,"Recovery allowed post-release cancellation")
  await physics_frame
  b.move_caster(1.0/60.0,Vector2(0,1),true)
  b.process_demo_preview(0.05)
  assert(not b.playing and not b.cast_committed())
  assert(b.demo_exit_pose.is_empty(),"Completed recovery restarted a second frozen-pose fade")
  var final_speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
  await physics_frame
  b.move_caster(1.0/60.0,Vector2(0,1),true)
  assert(absf(Vector2(actor.velocity.x,actor.velocity.z).length()-final_speed)<0.2,"Speed snapped on completion")
 b.stop_preview_controls(true)
 print("CAST RECOVERY PASS: uncapped 70% Leg recovery, unchanged capped Movement recovery, no pre-release recovery, early drift preserved, running speed and pose blend before completion, no end speed snap, post-release commitment retained")
 quit()
