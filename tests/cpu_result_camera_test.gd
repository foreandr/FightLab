extends SceneTree
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame
 await process_frame
 var world=current_scene
 world.set_physics_process(false);world.round_active=true
 var victim=world.fighters[1]
 world.camera_focus_target=victim
 for i in 180:world.update_camera(1.0/60.0)
 victim.global_position.y+=0.1
 world.update_camera(1.0/60.0)
 var pivot:Vector3=world.camera_follow_point
 var target:Vector3=(world.fighters[0].global_position+victim.global_position)*0.5+Vector3.UP*1.3
 target=target.lerp(victim.focus_position(),0.4)
 assert(pivot.distance_to(target)>0.01,"Camera aim still snaps to physics target")
 victim.global_position.y-=0.1
 victim.invulnerability=0;victim.guard_energy=0
 var chest:Area3D
 for pair in victim.targets:
  if pair[0].get_meta("zone","")=="chest":chest=pair[0]
 assert(world.apply_impact(world.fighters[0],victim,{"id":"camera_test","effect":"touch","projectile_element":"None","damage":200.0},chest.global_position,Vector3.BACK,chest,Vector3.BACK*300))
 assert(world.match_winner==0 and is_instance_valid(victim.ragdoll))
 for i in 180:world.update_camera(1.0/60.0)
 var settled:Transform3D=world.camera.global_transform
 for i in 90:
  await physics_frame
  victim.tick(1.0/60.0)
  # Stress both settling roots and a dead focused body, including uneven frame times.
  world.fighters[0].global_position.y=0.06 if i%2==0 else 0.0
  world.update_camera(0.12 if i%2==0 else 1.0/60.0)
  assert(world.camera.position.distance_to(settled.origin)<0.001,"Result camera follows settling actors")
  assert(world.camera.quaternion.angle_to(settled.basis.get_rotation_quaternion())<0.001,"Result camera shakes")
 world.camera_zoom*=1.3;world.camera_orbit_yaw+=0.3
 for i in 120:world.update_camera(1.0/60.0)
 assert(world.camera.position.distance_to(settled.origin)>0.5,"Result framing disabled orbit/zoom")
 world.rematch(19)
 assert(world.result_camera_frame.is_empty() and not world.camera_follow_ready)
 print("RESULT CAMERA PASS: smooth live aim; actual lethal hit/ragdoll; stable result under corpse/root jitter and uneven frames; orbit/zoom retained; rematch resets")
 quit()
