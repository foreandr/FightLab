extends SceneTree
func _initialize():call_deferred("run")
func run():
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO);actor.editor_pose_locked=true
 for i in 3:await physics_frame
 actor.self_barrier.activate(actor,40,1);actor.self_barrier.age=0.3;actor.stamina=5
 var result:Dictionary=actor.self_barrier.resolve_hit(10,Vector3.FORWARD)
 assert(result.broken and actor.stamina==0)
 var effects:=[]
 for child in world.get_children():
  if child.get_script()==preload("res://scripts/block_shatter_effect.gd"):effects.append(child)
 assert(effects.size()==1 and effects[0].shards.size()==32)
 var effect=effects[0];var position:Vector3=effect.shards[0].node.position
 effect._process(0.1);assert(effect.shards[0].node.position.distance_to(position)>0.1)
 assert(not actor.self_barrier.active())
 actor.self_barrier.activate(actor,40,1);actor.stamina=100;actor.self_barrier.age=0.3
 result=actor.self_barrier.resolve_hit(10,Vector3.FORWARD)
 assert(not result.broken and result.absorbed==10)
 assert(actor.stamina==90)
 actor.self_barrier.clear()
 actor.impact_physics.reset(actor.skeleton)
 actor.impact_physics.hit(actor.skeleton,actor.bone_point("spine_03"),Vector3.BACK*90,"chest","spine_03",true)
 actor.impact_physics.step(0.05)
 assert(actor.impact_physics.joints.spine_03.angle.length()>0.01,"Centre-line hit lacks visible recoil")
 assert(actor.mode!="hit","Visual recoil added action stun")
 effect._process(1.0);assert(effect.is_queued_for_deletion())
 print("CONTACT PRESENTATION PASS: broken block creates flying glass, normal block unchanged, centreline body recoil without action stun, fragments expire")
 quit()
