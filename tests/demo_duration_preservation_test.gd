extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 e.select_group("Spells")
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/demo_duration_preserve_test.cfg"
 b.draft_path="user://logs/demo_duration_preserve_draft.cfg"
 b.set_process(false);b.set_physics_process(false)
 e.actor.practice_god_mode=true
 for seconds in [0.7,4.0,12.3,60.0]:
  b.stop_preview_controls(true)
  b.show_creation_step("demo")
  b.set_demo_duration(seconds)
  var timeline=b.get_meta("cast_timeline")
  timeline.fit_time();timeline.zoom_time(1.25)
  var span:float=timeline.view_span
  for choice in b.DEMO_ANIMATIONS:
   b.demo_choices[choice].pressed.emit()
   assert(is_equal_approx(b.demo_duration,seconds) and is_equal_approx(b.cast_duration(),seconds))
   assert(is_equal_approx(b.demo_duration_slider.value,seconds) and is_equal_approx(b.get_meta("cast_length_input").value,seconds))
   assert(is_equal_approx(timeline.view_span,span),"Selecting a demo reset time zoom")
  # The collection picker must not substitute the source's native duration.
  var entry=b.DEMO_ANIMATIONS.headbutt.profile.duplicate(true)
  entry.duration=1.0
  assert(b.choose_demo_animation(entry,false))
  assert(is_equal_approx(b.cast_duration(),seconds) and entry.duration==1.0 and b.casting_animation.source_duration==1.0)
  b.select_demo_choice("cross",false)
  b.demo_confirm_button.pressed.emit()
  b.delivery_choices.Projectile.pressed.emit()
  b.delivery_confirm_button.pressed.emit()
  assert(b.creation_step=="projectile" and is_equal_approx(b.demo_duration,seconds) and is_equal_approx(b.cast_duration(),seconds))
  assert(is_equal_approx(timeline.view_span,span),"Confirm reset time zoom")
  b.stop_preview_controls(true)
  b.load_demo_preferences()
  assert(is_equal_approx(b.demo_duration,seconds) and is_equal_approx(b.cast_duration(),seconds))
 print("DEMO DURATION PASS: 0.7/4/12.3/60s survive all eight choices, collection source with different native length, Confirm/Projectile, time zoom and preference reload")
 quit()
