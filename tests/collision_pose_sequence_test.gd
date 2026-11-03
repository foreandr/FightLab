extends SceneTree
const Cache=preload("res://scripts/ai/collision_pose_cache.gd")
var w
var a
var b
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func sequence(fast:bool)->Array:
 set_meta("collision_pose_cache",fast)
 w.rematch(7001);w.set_physics_process(false);w.countdown=0;w.round_active=true
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.75));a.rotation.y=0;b.rotation.y=PI
 a.guard_energy=0;b.guard_energy=0
 for i in 8:await physics_frame;w.tick_combat(1.0/60)
 var trace:Array=[]
 for frame in 300:
  if frame in [0,100,200]:
   var item:Dictionary=w.brains[0].loadout[1 if frame==0 else (4 if frame==100 else 15)]
   a.start_authored_cast(item.spec,item.profile,b)
  await physics_frame;w.tick_combat(1.0/60)
  var points:=PackedVector3Array()
  for actor in [a,b]:
   for index in Cache.rig_info(actor).indices:points.append(actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(index).origin)
  trace.append({"points":points,"hp":b.health,"stamina":a.stamina,"mana":a.mana,"mode":a.mode})
 return trace
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 w=current_scene;w.set_physics_process(false);a=w.fighters[0];b=w.fighters[1]
 var full:Array=await sequence(false);var fast:Array=await sequence(true)
 var max_error:=0.0;var worst:=""
 for frame in full.size():
  for index in full[frame].points.size():
   var error:float=full[frame].points[index].distance_to(fast[frame].points[index])
   if error>max_error:max_error=error;worst="frame=%s index=%s mode=%s"%[frame,index,full[frame].mode]
  assert(is_equal_approx(full[frame].hp,fast[frame].hp) and is_equal_approx(full[frame].stamina,fast[frame].stamina) and is_equal_approx(full[frame].mana,fast[frame].mana) and full[frame].mode==fast[frame].mode,"Sequence combat diverged at frame %s"%frame)
 print("COLLISION LIVE SEQUENCE max_metres=",max_error," worst=",worst)
 assert(max_error<0.0001,"Live hitbox motion diverged")
 print("COLLISION LIVE SEQUENCE PASS: actual casts, entry/return blends, hit reactions, HP/resources, all collision joints over 300 frames")
 quit()
