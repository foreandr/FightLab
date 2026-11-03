extends SceneTree
const Cache=preload("res://scripts/ai/collision_pose_cache.gd")
const Motion=preload("res://scripts/spell_cast_motion.gd")
var max_position:=0.0
var max_angle:=0.0
var max_basis_error:=0.0
var worst:=""
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);var actor=w.fighters[0]
 var indices:Array=Cache.rig_info(actor).indices
 var poses:=0
 for item in w.brains[0].loadout:
  for progress in [0.0,0.0713,0.224,0.3981,0.5517,0.786,0.9999]:
   for aiming in [false,true]:
    var aim:Dictionary={"target":actor.global_position+Vector3(1,1.7,2),"emitter":str(item.spec.get("hand","hand_r")),"weight":0.8} if aiming else {}
    set_meta("collision_pose_cache",false);Motion.pose(actor,item.profile,progress,aim)
    var expected:Array[Transform3D]=[]
    for index in indices:expected.append(actor.skeleton.get_bone_global_pose(index))
    set_meta("collision_pose_cache",true);Motion.pose(actor,item.profile,progress,aim)
    for slot in indices.size():
     var got:Transform3D=actor.skeleton.get_bone_global_pose(indices[slot]);var original:Transform3D=expected[slot]
     var error:=got.origin.distance_to(original.origin)
     if error>max_position:worst="%s progress=%s aim=%s bone=%s"%[item.title,progress,aiming,actor.skeleton.get_bone_name(indices[slot])]
     max_position=maxf(max_position,error)
     max_angle=maxf(max_angle,original.basis.get_rotation_quaternion().angle_to(got.basis.get_rotation_quaternion()))
     for axis in 3:max_basis_error=maxf(max_basis_error,original.basis[axis].distance_to(got.basis[axis]))
    poses+=1
 print("COLLISION POSE ERROR poses=",poses," bones=",indices.size(),"/",actor.skeleton.get_bone_count()," max_metres=",max_position," max_degrees=",rad_to_deg(max_angle)," bake_seconds=",Cache.build_usec/1000000.0," worst=",worst)
 assert(max_position<0.00001 and max_basis_error<0.00001,"Collision motion diverged")
 # Animation edits must invalidate baked data.
 var clip:=str(w.brains[0].loadout[0].profile.clip)
 var animation:Animation=actor.player.get_animation(clip)
 var old:float=animation.length
 animation.length=old+0.0001
 assert(Cache.tables.is_empty(),"Edited animation retained stale collision cache")
 animation.length=old
 print("COLLISION POSE PARITY PASS")
 quit()
