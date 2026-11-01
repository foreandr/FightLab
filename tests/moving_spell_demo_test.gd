extends SceneTree
const Movement=preload("res://scripts/character_movement.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
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
    b.move_caster(1.0/60.0,Vector2(0,1),sprinting)
    b.demo_choices[choice].pressed.emit()
    if not check(b.playing,"Did not start "+choice):return
    for frame in 14:
     await physics_frame
     b.move_caster(1.0/60.0,Vector2(0,1),sprinting)
     b.process_demo_preview(1.0/60.0)
    if not check(b.playing,"Movement cancelled "+choice):return
    if not check(actor.global_position.distance_to(position)>0.15,"Translation locked during "+choice):return
    if not check(actor.global_basis.z.dot(forward)>0.995,"Free-facing locked during "+choice):return
    if not check(is_equal_approx(Vector2(actor.velocity.x,actor.velocity.z).length(),7.0 if sprinting else 4.0),"Run/sprint speed changed during "+choice):return
    # Compare the displayed legs against the running gait, not just actor translation.
    var actual:Array=CastPose.capture(actor)
    Locomotion.pose(actor,Vector2(0,1),b.idle_elapsed,sprinting)
    var gait:Array=CastPose.capture(actor)
    CastPose.pose(actor,b.playback_animation(),b.elapsed/b.playback_duration(),b.cast_pose_aim(b.elapsed/b.playback_duration()))
    var cast:Array=CastPose.capture(actor)
    for bone in actual.size():
     var expected:Transform3D=cast[bone].interpolate_with(gait[bone],1.0-Locomotion.leg_takeover(b.playback_animation())) if Locomotion.is_locomotion_bone(actor.skeleton,bone) else cast[bone]
     if not check(actual[bone].is_equal_approx(expected),"Wrong displayed pose on %s (%s)"%[actor.skeleton.get_bone_name(bone),choice]):return
    Locomotion.cast_legs(actor,b.playback_animation(),Vector2(0,1),b.idle_elapsed,sprinting)
    var thigh:int=actor.skeleton.find_bone("thigh_l")
    var first:Transform3D=actor.skeleton.get_bone_pose(thigh)
    b.move_caster(1.0/60.0,Vector2(0,1),sprinting)
    b.process_demo_preview(0.12)
    if not check(not first.is_equal_approx(actor.skeleton.get_bone_pose(thigh)),"Leg cycle frozen while casting "+choice):return
    # Stopping still restores the full original demo, including the knee motion.
    b.move_caster(1.0/60.0,Vector2.ZERO,false)
    b.process_demo_preview(0.05)
    actual=CastPose.capture(actor)
    CastPose.pose(actor,b.playback_animation(),b.elapsed/b.playback_duration(),b.cast_pose_aim(b.elapsed/b.playback_duration()))
    cast=CastPose.capture(actor)
    for bone in actual.size():
     if not check(actual[bone].is_equal_approx(cast[bone]),"Stationary demo changed (%s)"%choice):return

 b.stop_preview_controls(true)
 b.select_demo_choice("dismantle",false)
 b.stop_preview_controls(true)
 if not check(Locomotion.leg_takeover(b.casting_animation)==1.0,"Dismantle must default to full leg takeover"):return
 for weight in [0.0,0.5,1.0]:
  b.demo_movement_control.slider.value=weight*100.0
  if not check(Locomotion.leg_takeover(b.casting_animation)==weight,"Demo slider did not change authority"):return
  CastPose.pose(actor,b.casting_animation,0.5)
  var cast:Array=CastPose.capture(actor)
  Locomotion.pose(actor,Vector2(0,1),0.3,true)
  var gait:Array=CastPose.capture(actor)
  CastPose.pose(actor,b.casting_animation,0.5)
  Locomotion.cast_legs(actor,b.casting_animation,Vector2(0,1),0.3,true)
  var result:Array=CastPose.capture(actor)
  for bone in result.size():
   var expected:Transform3D=cast[bone].interpolate_with(gait[bone],1.0-weight) if Locomotion.is_locomotion_bone(actor.skeleton,bone) else cast[bone]
   if not check(result[bone].is_equal_approx(expected),"0/50/100% blend failed"):return
 b.save_demo_preferences()
 b.select_demo_choice("cross",false)
 b.load_demo_preferences()
 if not check(Locomotion.leg_takeover(b.casting_animation)==1.0,"Demo policy did not survive preferences reload"):return
 b.stop_preview_controls(true)
 editor.select_group("Attack")
 var source:Dictionary={}
 for entry in preload("res://scripts/animation_catalog.gd").entries():
  if entry.title=="Left cross":source=entry
 editor.open_custom_for(source)
 editor.set_custom_leg_takeover(0.0)
 editor.custom_history_baseline=editor._custom_history_snapshot()
 editor.custom_undo_history.clear();editor.custom_redo_history.clear()
 editor.custom_movement_control.slider.value=75.0
 if not check(editor.custom_leg_takeover==0.75,"Authoring control failed"):return
 editor.undo_custom_edit()
 if not check(editor.custom_leg_takeover==0.0,"Undo did not restore policy"):return
 editor.redo_custom_edit()
 if not check(editor.custom_leg_takeover==0.75,"Redo did not restore policy"):return
 var name_:="Leg Takeover Test "+str(Time.get_ticks_usec())
 editor.custom_name.text=name_
 editor.save_custom_jump()
 var saved_path:String=editor.custom_edit_path
 var found:=false
 for entry in editor.load_custom_motion("Punch"):
  if entry.title==name_:found=Locomotion.leg_takeover(entry)==0.75
 if not check(found,"Authored leg control did not survive save/reload"):return
 DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
 b.stop_preview_controls(true)
 print("MOVING DEMOS PASS: all seven demos run/sprint and turn in free aim in demo/projectile stages; per-animation leg takeover respected, casting upper body remains, stationary full-body demos return")
 quit()
