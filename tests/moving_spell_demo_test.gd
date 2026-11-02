extends SceneTree
const RigPose=preload("res://scripts/editor_rig_pose.gd")
const Type=preload("res://scripts/animation_cast_type.gd")
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
    b.stop_preview_controls(true)
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
    var speed:float=Vector2(actor.velocity.x,actor.velocity.z).length()
    var initial_speed:=7.0 if sprinting else 4.0
    if Type.owns_legs(b.playback_animation()):
     if not check(speed>0.05 and speed<initial_speed*0.6,"Momentum did not coast and slow during "+choice):return
     if not check(not b.caster_sprinting,"Sprint remained active during "+choice):return
     var drift:Vector3=actor.velocity;drift.y=0
     b.move_caster(0.02,Vector2(0,-1),true)
     if not check(actor.velocity.dot(drift)>0 and actor.velocity.length()<drift.length()+0.001,"Held input redirected/reaccelerated a committed body animation"):return
    elif not check(is_equal_approx(speed,initial_speed),"Arms cast stopped running during "+choice):return
    # Compare the displayed legs against the running gait, not just actor translation.
    var actual:Array=CastPose.capture(actor)
    if Type.owns_legs(b.playback_animation()):RigPose.idle(actor,b.idle_elapsed)
    else:Locomotion.pose(actor,Vector2(0,1),b.idle_elapsed,sprinting)
    var gait:Array=CastPose.capture(actor)
    CastPose.pose(actor,b.playback_animation(),b.elapsed/b.playback_duration(),b.cast_pose_aim(b.elapsed/b.playback_duration()))
    var cast:Array=CastPose.capture(actor)
    for bone in actual.size():
     var expected:Transform3D=(cast[bone] if Type.controls_bone(actor.skeleton,bone,Type.kind(b.playback_animation())) else gait[bone]) if Type.applies(b.playback_animation()) else (gait[bone] if Locomotion.is_locomotion_bone(actor.skeleton,bone) else cast[bone])
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
    RigPose.idle(actor,b.idle_elapsed)
    var idle:Array=CastPose.capture(actor)
    for bone in actual.size():
     var expected:Transform3D=(cast[bone] if Type.controls_bone(actor.skeleton,bone,Type.kind(b.playback_animation())) else idle[bone]) if Type.applies(b.playback_animation()) else cast[bone]
     if not check(actual[bone].is_equal_approx(expected),"Stationary type mask changed (%s)"%choice):return

 b.stop_preview_controls(true)
 b.select_demo_choice("dismantle",false)
 b.stop_preview_controls(true)
 if not check(Locomotion.leg_takeover(b.casting_animation)==1.0,"Dismantle must default to full leg takeover"):return
 for type_ in Type.TYPES:
  b.demo_movement_control.menu.select(Type.TYPES.find(type_)+1)
  b.demo_movement_control.menu.item_selected.emit(Type.TYPES.find(type_)+1)
  if not check(Type.kind(b.casting_animation)==type_,"Demo type selector failed"):return
  CastPose.pose(actor,b.casting_animation,0.5)
  var cast:Array=CastPose.capture(actor)
  if type_==Type.LEGS:RigPose.idle(actor,0.3)
  else:Locomotion.pose(actor,Vector2(0,1),0.3,true)
  var gait:Array=CastPose.capture(actor)
  CastPose.pose(actor,b.casting_animation,0.5)
  Locomotion.cast_legs(actor,b.casting_animation,Vector2(0,1),0.3,true)
  var result:Array=CastPose.capture(actor)
  for bone in result.size():
   var expected:Transform3D=cast[bone] if Type.controls_bone(actor.skeleton,bone,type_) else gait[bone]
   if not check(result[bone].is_equal_approx(expected),"Type pose policy failed: "+type_):return
 b.save_demo_preferences()
 b.select_demo_choice("cross",false)
 b.load_demo_preferences()
 if not check(Type.kind(b.casting_animation)==Type.WHOLE_BODY,"Demo policy did not survive preferences reload"):return
 b.stop_preview_controls(true)
 editor.select_group("Attack")
 var source:Dictionary={}
 for entry in preload("res://scripts/animation_catalog.gd").entries():
  if entry.title=="Left cross":source=entry
 source["animation_resource"]="user://logs/type_custom_cross.res"
 ResourceSaver.save(actor.player.get_animation(source.clip),source.animation_resource)
 source["animation_components"]=[{"animation_type":Type.WHOLE_BODY},{"animation_type":Type.ARMS}]
 editor.open_custom_for(source)
 editor.custom_history_baseline=editor._custom_history_snapshot()
 editor.custom_undo_history.clear();editor.custom_redo_history.clear()
 editor.custom_movement_control.menu.select(Type.TYPES.find(Type.LEGS)+1)
 editor.custom_movement_control.menu.item_selected.emit(Type.TYPES.find(Type.LEGS)+1)
 if not check(editor.custom_animation_type==Type.LEGS,"Authoring type control failed"):return
 editor.undo_custom_edit()
 if not check(editor.custom_animation_type==Type.ARMS,"Undo did not restore type"):return
 editor.redo_custom_edit()
 if not check(editor.custom_animation_type==Type.LEGS,"Redo did not restore type"):return
 var name_:="Animation Type Test "+str(Time.get_ticks_usec())
 editor.custom_name.text=name_
 editor.custom_animation_type=""
 editor.save_custom_jump()
 if not check(editor.custom_status.text.contains("Choose Head"),"Undeclared custom animation was accepted"):return
 editor.set_custom_animation_type(Type.LEGS)
 editor.save_custom_jump()
 var saved_path:String=editor.custom_edit_path
 var found:=false
 for entry in editor.load_custom_motion("Punch"):
  if entry.title==name_:found=Type.kind(entry)==Type.LEGS and entry.get("animation_resource","")==source.animation_resource and Type.component_types(entry)==[Type.WHOLE_BODY,Type.ARMS]
 if not check(found,"Authored leg control did not survive save/reload"):return
 DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(source.animation_resource))
 editor.open_animation_type_dialog({"title":"Unclassified import","clip":"missing"},"Motion","Downloaded")
 var dialog:ConfirmationDialog=editor.get_child(editor.get_child_count()-1)
 if not check(dialog.get_ok_button().disabled,"Import did not require a declaration"):return
 var control=dialog.get_child(0)
 for child in dialog.get_children():
  if child.name=="AnimationType":control=child
 control.menu.select(3);control.menu.item_selected.emit(3)
 if not check(not dialog.get_ok_button().disabled,"Choosing import type did not enable confirmation"):return
 dialog.canceled.emit()

 b.stop_preview_controls(true)
 print("MOVING DEMOS PASS: all eight demos run/sprint and turn in free aim in demo/projectile stages; non-Touch ignores type and preserves gait, stationary full-body demos return, source type editing and save/undo remain intact")
 quit()
