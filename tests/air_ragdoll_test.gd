extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);var a=w.fighters[0];var b=w.fighters[1]
 for title in ["Tornado kick","Rising uppercut","Hurricane kicks"]:
  w.clear_battle_effects();w.combat().discard_cast_attempt(a)
  a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,10));w.round_active=true;a.guard_energy=0
  for i in 10:
   await physics_frame
   w.tick_combat(1.0/60.0)
  var item:Dictionary={}
  for candidate in w.brains[0].loadout:
   if candidate.title==title:item=candidate
  a.start_authored_cast(item.spec,item.profile,b)
  for i in int(item.duration*0.42*60):
   await physics_frame
   w.tick_combat(1.0/60.0)
  var lengths:Dictionary={}
  for bone in a.skeleton.get_bone_count():
   var parent:int=a.skeleton.get_bone_parent(bone)
   if parent<0 or a.skeleton.get_bone_name(bone)=="pelvis":continue
   lengths[bone]=a.skeleton.get_bone_global_pose(bone).origin.distance_to(a.skeleton.get_bone_global_pose(parent).origin)
  var chest:Area3D=a.nearest_hurtbox(a.bone_point("spine_03"))
  w.apply_impact(b,a,{"id":"air_probe","effect":"orb","projectile_element":"None","damage":45.0},chest.global_position,Vector3.BACK,chest,Vector3(700,500,350))
  var ratio:=1.0;var error:=0.0;var worst:="";var body_span:=0.0
  for i in 150:
   await physics_frame
   w.tick_combat(1.0/60.0)
   if not is_instance_valid(a.ragdoll):break
   for bone in lengths:
    var parent:int=a.skeleton.get_bone_parent(bone)
    var distance:float=a.skeleton.get_bone_global_pose(bone).origin.distance_to(a.skeleton.get_bone_global_pose(parent).origin)
    if float(lengths[bone])>0.03 and distance/float(lengths[bone])>ratio:
     ratio=distance/float(lengths[bone]);error=distance-float(lengths[bone]);worst=a.skeleton.get_bone_name(bone)
   for body in a.ragdoll.bodies.values():body_span=maxf(body_span,body.global_position.distance_to(a.ragdoll.bodies.pelvis.global_position))
  assert(ratio<1.01 and error<0.001,"Airborne ragdoll stretched rig")
  print("AIR RAGDOLL ",title," ratio=",ratio," error=",error," bone=",worst," body span=",body_span)
 print("AIR RAGDOLL PASS: three airborne spinning moves retain bone lengths under heavy impact")
 quit()
