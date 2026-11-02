extends SceneTree
const Type=preload("res://scripts/animation_cast_type.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/knee_recovery_slider_prefs_test.cfg"
 b.draft_path="user://logs/knee_recovery_slider_draft_test.cfg"
 e.select_group("Spells")
 b.set_process(false);b.set_physics_process(false)
 e.actor.practice_god_mode=true;e.actor.collision_mask=1
 b.demo_animation_types.clear();b.select_demo_choice("knee",false)
 b.set_demo_duration(2.0)
 b.save_demo_preferences()
 var before:=FileAccess.get_file_as_string(b.preview_preferences_path)
 assert(b.knee_recovery_slider.visible and b.knee_recovery_slider.is_visible_in_tree())
 assert(b.knee_recovery_slider.min_value==0 and b.knee_recovery_slider.max_value==100)
 assert(b.knee_recovery_slider.value==60 and b.knee_recovery_slider.focus_mode==Control.FOCUS_ALL)
 b.stop_preview_controls(true);b.play_demo_preview();b.process_demo_preview(1.0)
 for percent in [0,90,0,100]:
  b.knee_recovery_slider.value=percent
  assert(b.playing and is_equal_approx(b.elapsed,1.0),"Slider restarted the animation")
  e.actor.set_meta("animation_cast_momentum",Vector3.ZERO)
  e.actor.velocity=Vector3.ZERO
  await physics_frame
  b.move_caster(1.0/60.0,Vector2(0,1),true)
  var speed:float=Vector2(e.actor.velocity.x,e.actor.velocity.z).length()
  if percent==0:assert(speed>3.0 and b.cast_recovery_weight()>0.49,"Early slider did not restore movement")
  else:assert(speed<0.01 and b.cast_recovery_weight()==0,"Late slider did not retain movement lock")
  assert(b.knee_recovery_label.text.contains(str(percent)+"%"))
 assert(FileAccess.get_file_as_string(b.preview_preferences_path)==before,"Temporary slider persisted into preferences")
 b.stop_preview_controls(true);b.select_demo_choice("roundhouse",false);b.elapsed=1.0
 assert(b.cast_recovery_weight()==0,"Knee test changed other Leg animations")
 b.stop_preview_controls(true);b.select_demo_choice("knee",false)
 b.knee_recovery_slider.value=20
 assert(b.knee_recovery_start==0.2,"Choosing Knee reset slider")
 b.knee_recovery_slider.value=60
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/knee_recovery_slider.png")
 print("KNEE RECOVERY SLIDER PASS: visible 0-100%, keyboard focus, live early/late change verified in actual m/s without restarting, other animations unchanged, temporary value not saved")
 quit()
