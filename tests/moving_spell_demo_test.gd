extends SceneTree
const Movement=preload("res://scripts/character_movement.gd")
const CastPose=preload("res://scripts/spell_cast_motion.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error("MOVING DEMO FAILED: "+message)
 quit(1)
 return false
func run() -> void:
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 while true:
  await process_frame
  editor=current_scene
  if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
 editor.select_group("Spells")
 var b=editor.spell_builder
 b.draft_path="user://logs/moving_demo_test.cfg"
 b.preview_preferences_path="user://logs/moving_demo_preview_test.cfg"
 b.set_process(false);b.set_physics_process(false)
 var actor=editor.actor
 b.set_character_god_mode(actor,true)
 b.set_third_person_focus(null)
 for stage in ["demo","projectile"]:
  b.stop_preview_controls(true)
  if stage=="projectile":b.open_projectile_workspace()
  else:b.show_creation_step("demo")
  for choice in b.DEMO_ANIMATIONS:
   for sprinting in [false,true]:
    b.stop_preview_controls(true)
    b.select_demo_choice(choice,false)
    b.stop_preview_controls(true)
    b.set_demo_duration(2.0)
    b.move_caster(0.01,Vector2.ZERO,false)
    actor.global_position=editor.field.surface_placement(Vector3.ZERO)
    actor.collision_mask=1
    var forward:Vector3=Movement.camera_forward(editor.field.camera)
    actor.rotation.y=atan2(forward.x,forward.z)+PI*0.5
    var position:Vector3=actor.global_position
    b.play_demo_preview()
    if not check(b.playing,"Did not start "+choice):return
    for frame in 14:
     await physics_frame
     b.move_caster(1.0/60.0,Vector2(0,1),sprinting)
     b.process_demo_preview(1.0/60.0)
    if not check(b.playing,"Movement cancelled "+choice):return
    if not check(actor.global_position.distance_to(position)>0.15,"Translation locked during "+choice):return
    if not check(actor.global_basis.z.dot(forward)>0.995,"Free-facing locked during "+choice):return
    if not check(is_equal_approx(Vector2(actor.velocity.x,actor.velocity.z).length(),7.0 if sprinting else 4.0),"Run/sprint speed changed during "+choice):return
    # The original full-body demo pose, including the knee, must remain intact.
    var actual:Array=CastPose.capture(actor)
    CastPose.pose(actor,b.playback_animation(),b.elapsed/b.playback_duration(),b.cast_pose_aim(b.elapsed/b.playback_duration()))
    var expected:Array=CastPose.capture(actor)
    for bone in actual.size():
     if not check(actual[bone].is_equal_approx(expected[bone]),"Demo was masked or replaced on bone %d (%s)"%[bone,choice]):return
 b.stop_preview_controls(true)
 print("MOVING DEMOS PASS: all five demos run/sprint and turn in free aim in demo/projectile stages; original full-body knee and other poses unchanged")
 quit()
