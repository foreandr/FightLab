extends SceneTree
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Aim=preload("res://scripts/character_aim_pose.gd")
const Contact=preload("res://scripts/combat_aim.gd")
const Mirror=preload("res://scripts/animation_mirror.gd")
const Collision=preload("res://scripts/pose_self_collision.gd")
const Type=preload("res://scripts/animation_cast_type.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/regional_aim_test.cfg";b.draft_path="user://logs/regional_aim_draft_test.cfg"
 e.select_group("Spells");b.stop_preview_controls(true);b.set_process(false);b.set_physics_process(false)
 e.set_physics_process(false);e.field.set_physics_process(false)
 var actor=e.actor
 b.demo_animation_types.clear()
 for choice in ["knee","roundhouse","headbutt"]:
  b.select_demo_choice(choice,false);b.stop_preview_controls(true)
  var original:Dictionary=b.casting_animation.duplicate()
  var base_emitter:=Contact.emitter(original)
  if not check(base_emitter=={"knee":"calf_l","roundhouse":"ball_r","headbutt":"Head"}[choice],"Wrong contact region in demo metadata"):return
  for mirrored in ([false] if choice=="headbutt" else [false,true]):
   var profile:Dictionary=original.duplicate()
   if mirrored:
    profile.mirrored=not bool(profile.get("mirrored",false));profile.attack_bone=Mirror.opposite(base_emitter)
   var emitter:=Contact.emitter(profile)
   var side:=emitter.right(1)
   var parts:Array=["head"] if choice=="headbutt" else ["thigh_"+side,"calf_"+side,"foot_"+side]
   var displacements:Dictionary={}
   for offset in [Vector3(-4,0,5),Vector3(4,0,5),Vector3(0,-4,5),Vector3(0,4,5)]:
    Pose.pose(actor,profile,0.25)
    var native:=Pose.capture(actor)
    var start:Vector3=actor.bone_point(emitter)
    var baseline:=Collision.penetrations(actor.skeleton,parts)
    var pivot:Vector3=actor.bone_point("Head" if choice=="headbutt" else "spine_03")
    var target:Vector3=pivot+actor.global_basis*offset
    Aim.apply(actor,target,emitter,0.0)
    for index in native.size():
     if not check(native[index].is_equal_approx(actor.skeleton.get_bone_pose(index)),"Zero weight changes pose"):return
    Aim.apply(actor,target,emitter,1.0)
    var actual:=Pose.capture(actor)
    var shift:Vector3=actor.global_basis.inverse()*(actor.bone_point(emitter)-start)
    displacements[offset]=shift
    var allowed:Array=["neck_01","Head"] if choice=="headbutt" else ["thigh_"+side]
    for index in actual.size():
     var name_:String=actor.skeleton.get_bone_name(index)
     if name_ not in allowed and not check(native[index].is_equal_approx(actual[index]),"Aim changed an unowned joint: "+name_):return
    var contacts:=Collision.penetrations(actor.skeleton,parts)
    for pair in contacts:
     if not check(float(contacts[pair])<=maxf(0.005,float(baseline.get(pair,0)))+0.00004,"Regional aim introduced overlap: "+pair):return
    # Story's limb adapter must use precisely the same shared pose operation.
    Pose.pose(actor,profile,0.25)
    var channel:String="face" if choice=="headbutt" else "leg_"+side
    actor.story_strikes={channel:{"aim_direction":(target-pivot).normalized()}}
    actor.story_punch_previews.clear();actor.story_limb_reservations.clear()
    actor.story_torso_recovery_pending=false
    actor.story_calibration_aim_enabled=true;actor.story_calibration_aim_target=target
    actor.player_controlled=true;e.field.story_mode=true
    actor._apply_story_punch_aim(0.016)
    for index in actual.size():
     if not check(actual[index].is_equal_approx(actor.skeleton.get_bone_pose(index)),"Story/Create regional aiming diverged"):return
    actor.story_strikes.clear();actor.story_calibration_aim_enabled=false;actor.player_controlled=false;e.field.story_mode=false
   print("REGIONAL DIRECTIONS ",choice," mirrored ",mirrored," ",displacements)
   if not check(displacements[Vector3(-4,0,5)].x< -0.0001 and displacements[Vector3(4,0,5)].x>0.0001,"Left/right aiming did not steer contact region"):return
   if not check(displacements[Vector3(0,4,5)].y>displacements[Vector3(0,-4,5)].y+0.0001,"Up/down aiming did not steer contact region"):return
 # Actual spell preview route, including the type mask and chosen contact point.
 b.stop_preview_controls(true);b.select_demo_choice("knee",false);b.open_projectile_workspace();b.stop_preview_controls(true)
 b.spell_focus_target=null;b.manual_aim_valid=true
 var knee_positions:Array[Vector3]=[]
 for x in [-4.0,4.0]:
  b.stop_preview_controls(true)
  b.manual_aim_point=actor.bone_point("spine_03")+actor.global_basis*Vector3(x,0,5)
  b.play_demo_preview();b.process_demo_preview(b.playback_duration()*0.25)
  knee_positions.append(actor.bone_point("calf_l"))
 if not check((knee_positions[1]-knee_positions[0]).dot(actor.global_basis.x)>0.02,"Displayed Knee does not follow cursor aim"):return
 b.stop_preview_controls(true)
 # Continuity across full authored clips, not just their strike frame.
 for choice in ["knee","roundhouse","headbutt"]:
  b.select_demo_choice(choice,false);b.stop_preview_controls(true)
  var profile:Dictionary=b.casting_animation
  var emitter:=Contact.emitter(profile)
  for x in [-4.0,4.0]:
   var target:Vector3=actor.bone_point("Head" if choice=="headbutt" else "spine_03")+actor.global_basis*Vector3(x,2,5)
   var previous:=Quaternion.IDENTITY
   var previous_native:=Quaternion.IDENTITY
   for frame in 121:
    var progress:=frame/120.0
    Pose.pose(actor,profile,progress)
    var joint:String="neck_01" if choice=="headbutt" else "thigh_"+emitter.right(1)
    var native_rotation:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.bones[joint])
    var weight:=smoothstep(0.0,0.12,progress)*(1.0-smoothstep(0.75,1.0,progress))
    Aim.apply(actor,target,emitter,weight)
    var rotation:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.bones[joint])
    if frame>0 and not check(previous.angle_to(rotation)<deg_to_rad(30),"Regional aim snaps: %s frame %d aimed %.1f native %.1f"%[choice,frame,rad_to_deg(previous.angle_to(rotation)),rad_to_deg(previous_native.angle_to(native_rotation))]):return
    previous=rotation
    previous_native=native_rotation
 # Elbow contact uses the same directional path, preserving its hinge.
 b.select_demo_choice("cross",false);b.stop_preview_controls(true)
 Pose.pose(actor,b.casting_animation,0.25)
 var lower:int=actor.bones.lowerarm_l
 var original_hinge:Quaternion=actor.skeleton.get_bone_pose_rotation(lower)
 var upper:int=actor.bones.upperarm_l
 var original_upper:Quaternion=actor.skeleton.get_bone_pose_rotation(upper)
 Aim.apply(actor,actor.bone_point("spine_03")+actor.global_basis*Vector3(-4,2,5),"lowerarm_l",1.0)
 if not check(original_hinge.is_equal_approx(actor.skeleton.get_bone_pose_rotation(lower)) and not original_upper.is_equal_approx(actor.skeleton.get_bone_pose_rotation(upper)),"Elbow aiming bypasses its contact chain"):return
 print("REGIONAL COMBAT AIM PASS: both knee/kick sides, left/right/up/down, hinge and ownership preserved, overlap checks, zero-weight native pose, identical Story/Create routing, actual spell preview contact steering")
 quit()
