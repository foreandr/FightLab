extends SceneTree
const Pose=preload("res://scripts/spell_cast_motion.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 Engine.time_scale=4;Engine.physics_ticks_per_second=240
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var a=w.fighters[0];var b=w.fighters[1]
 var angles:Array=[]
 for title in ["Left hook","Right hook","Flame left hook","Flame right hook"]:
  var item:Dictionary={}
  for candidate in w.brains[0].loadout:
   if candidate.title==title:item=candidate
  assert(not item.is_empty())
  a.reset_fighter(Vector3.ZERO);a.rotation.y=0
  Pose.pose(a,item.profile,0.44)
  var side:=str(item.spec.hand).right(1)
  var elbow:Vector3=a.bone_point("lowerarm_"+side)
  var angle:=rad_to_deg((a.bone_point("upperarm_"+side)-elbow).angle_to(a.bone_point("hand_"+side)-elbow))
  angles.append(angle)
  assert(angle<145.0,"Hook straightened into a cross")
  Pose.pose(a,item.profile,0.44,{"target":Vector3(0,1.3,0.65),"emitter":str(item.spec.hand),"weight":1.0})
  elbow=a.bone_point("lowerarm_"+side)
  assert(rad_to_deg((a.bone_point("upperarm_"+side)-elbow).angle_to(a.bone_point("hand_"+side)-elbow))<145.0,"Target steering straightened the hook")
  Pose.pose(a,item.profile,0.23);var wide:Vector3=a.bone_point(str(item.spec.hand))
  Pose.pose(a,item.profile,0.59);var follow:Vector3=a.bone_point(str(item.spec.hand))
  assert(absf(wide.x-follow.x)>0.20,"Hook has no sideways sweep")
  a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.65));a.rotation.y=0;b.rotation.y=PI
  w.round_active=true;b.invulnerability=0;b.guard_energy=0
  assert(a.start_authored_cast(item.spec,item.profile,b))
  for i in 85:
   await physics_frame
   w.tick_combat(1.0/60.0)
  assert(b.last_physical_impact_damage>0,"Hook did not make real contact: "+title)
  if title.begins_with("Flame"):assert(b.burn_time>0)
  # Both the controller and public chain API preserve hook follow-through.
  w.combat().discard_cast_attempt(a);a.reset_fighter(Vector3.ZERO)
  assert(a.start_authored_cast(item.spec,item.profile,b))
  a.tick_cast(float(item.duration)*0.56)
  assert(w.combat().release(a,a.current_spell,a.bone_point(str(item.spec.hand)),item.profile))
  assert(not a.chain_touch_cast(w.brains[0].loadout[1].spec,w.brains[0].loadout[1].profile,b),"Combo cut the hook sweep short")
  a.tick_cast(float(item.duration)*0.14)
  assert(a.chain_touch_cast(w.brains[0].loadout[1].spec,w.brains[0].loadout[1].profile,b))
  w.combat().discard_cast_attempt(a)
 print("HOOK PASS: bent elbow angles ",angles,"; bilateral sweep, actual physical/fire contact and follow-through before links")
 quit()
