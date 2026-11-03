extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.set_process(false);w.round_active=true
 var a=w.fighters[0];a.player_controlled=true
 a.start_ragdoll(Vector3(200,0,0),a.bone_point("spine_03"));a.recovery_timing.age=0.5
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://work/recovery_prompt_review.png")
 assert(a.recovery_prompt.visible)
 a.recovery_timing.age=1.0
 var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true
 Input.parse_input_event(key);await process_frame
 assert(a.recovery_timing.result=="Perfect","Space did not trigger timing event")
 a.reset_fighter(a.position);await process_frame;assert(not a.recovery_prompt.visible)
 print("RECOVERY UI PASS: prompt draws, actual Space input triggers perfect, reset hides prompt")
 quit()
