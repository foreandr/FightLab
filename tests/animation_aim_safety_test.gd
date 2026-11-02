extends SceneTree
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Aim=preload("res://scripts/character_aim_pose.gd")
const Safety=preload("res://scripts/character_pose_safety.gd")
const Collision=preload("res://scripts/pose_self_collision.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 DirAccess.make_dir_recursive_absolute("res://work/hook_video")
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/aim_safety_test.cfg"
 b.draft_path="user://logs/aim_safety_draft_test.cfg"
 e.select_group("Spells");b.stop_preview_controls(true);b.set_process(false);b.set_physics_process(false)
 e.set_physics_process(false);e.field.set_physics_process(false)
 var actor=e.actor
 var largest_step:=0.0
 var largest_contact:=0.0
 var started:=Time.get_ticks_usec()
 var count:=0
 for choice in ["hook","cross"]:
  b.select_demo_choice(choice,false);b.stop_preview_controls(true)
  for offset in [Vector3(-3,8,8),Vector3(3,-3,8),Vector3(8,1,0.01),Vector3(-8,1,0.01),Vector3(0,1,-8)]:
   var target:Vector3=actor.global_position+actor.global_basis*offset
   var previous:Array[Transform3D]=[]
   for frame in 121:
    var progress:=frame/120.0
    Pose.pose(actor,b.casting_animation,progress)
    var native:=Pose.capture(actor)
    var baseline:=Collision.penetrations(actor.skeleton,Safety.PARTS)
    var weight:=smoothstep(0.0,0.12,progress)*(1.0-smoothstep(0.75,1.0,progress))
    Aim.apply(actor,target,"hand_r" if choice=="hook" else "hand_l",weight)
    var after:=Pose.capture(actor)
    var contacts:=Collision.penetrations(actor.skeleton,Safety.PARTS)
    for pair in contacts:
     var contact:float=contacts[pair]
     largest_contact=maxf(largest_contact,contact)
     if not check(contact<=maxf(Safety.TOLERANCE,float(baseline.get(pair,0)))+0.00004,"Aim introduced overlap at "+choice+" "+str(progress)+" "+pair+" "+str(contact)):return
    for name_ in ["root","thigh_l","calf_l","thigh_r","calf_r"]:
     var index:int=actor.bones[name_]
     if not check(native[index].is_equal_approx(after[index]),"Aim modified unrelated leg/root bone"):return
    if not previous.is_empty():
     for name_ in ["pelvis","spine_02","spine_03","lowerarm_r","upperarm_r","lowerarm_l"]:
      var index:int=actor.bones[name_]
      var step_angle:float=previous[index].basis.get_rotation_quaternion().angle_to(after[index].basis.get_rotation_quaternion())
      largest_step=maxf(largest_step,step_angle)
    previous=after
    count+=1
    if choice=="hook" and offset==Vector3(-3,8,8) and frame in [24,60,84]:
     await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png("res://work/hook_video/safe_%d.png"%frame)
 print("AIM SAFETY MEASURED: max adjacent angle ",rad_to_deg(largest_step)," max overlap ",largest_contact," test ms/sample ",(Time.get_ticks_usec()-started)/1000.0/count)
 if not check(largest_step<deg_to_rad(30),"Aim still snaps between adjacent frames"):return
 # The +/- PI ambiguity must fade out, never produce opposite full torso turns.
 b.select_demo_choice("hook",false);b.stop_preview_controls(true)
 Pose.pose(actor,b.casting_animation,0.3)
 var pivot:Vector3=actor.bone_point("spine_03")
 var back:Vector3=-actor.global_basis.z*5.0
 var yaw_a:float=Aim.endpoint_angles(actor,"hand_r",pivot+Basis(Vector3.UP,0.0001)*back).yaw
 var yaw_b:float=Aim.endpoint_angles(actor,"hand_r",pivot+Basis(Vector3.UP,-0.0001)*back).yaw
 if not check(absf(yaw_a-yaw_b)<0.002,"Hook rearward branch flips aim"):return
 # Source clips receive the same spine limit without flattening a root flip.
 var root_bone:int=actor.bones.root
 var pelvis:int=actor.bones.pelvis
 actor.skeleton.set_bone_pose_rotation(root_bone,Quaternion(Vector3.RIGHT,2.8))
 actor.skeleton.set_bone_pose_rotation(pelvis,Quaternion(Vector3.UP,1.4))
 for name_ in ["spine_01","spine_02","spine_03"]:
  var index:int=actor.bones[name_]
  var rest:Quaternion=actor.skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
  actor.skeleton.set_bone_pose_rotation(index,rest*Quaternion(Vector3.RIGHT,deg_to_rad(130)))
 Safety.limit_torso(actor)
 var total:=0.0
 for name_ in ["spine_01","spine_02","spine_03"]:
  var index:int=actor.bones[name_]
  var rest:Quaternion=actor.skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
  total+=Quaternion.IDENTITY.angle_to(rest.inverse()*actor.skeleton.get_bone_pose_rotation(index))
 if not check(total<=deg_to_rad(90.01),"Authored source exceeds spine budget"):return
 if not check(actor.skeleton.get_bone_pose_rotation(root_bone).is_equal_approx(Quaternion(Vector3.RIGHT,2.8)) and actor.skeleton.get_bone_pose_rotation(pelvis).is_equal_approx(Quaternion(Vector3.UP,1.4)),"Spine safety destroys root/pelvis acrobatics"):return
 var limited:=Pose.capture(actor)
 Safety.limit_torso(actor)
 for index in limited.size():
  if not check(limited[index].is_equal_approx(actor.skeleton.get_bone_pose(index)),"Safety compounds when called twice"):return
 b.stop_preview_controls(true);b.select_demo_choice("hook",false);b.stop_preview_controls(true)
 var target:Vector3=actor.global_position+actor.global_basis*Vector3(-3,8,8)
 Pose.pose(actor,b.casting_animation,0.45,{"target":target,"emitter":"hand_r","weight":1.0})
 var forward:=Pose.capture(actor)
 Pose.pose(actor,b.casting_animation,0.8,{"target":target,"emitter":"hand_r","weight":1.0})
 Pose.pose(actor,b.casting_animation,0.45,{"target":target,"emitter":"hand_r","weight":1.0})
 for index in forward.size():
  if not check(forward[index].is_equal_approx(actor.skeleton.get_bone_pose(index)),"Backwards scrub depends on previous frame"):return
 print("ANIMATION AIM SAFETY PASS: actual Hook/Cross, steep/side/rear aim, bounded body overlap, no root/leg edits, adjacent-frame continuity, deterministic reverse sampling")
 quit()
