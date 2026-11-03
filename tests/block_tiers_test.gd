extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const World=preload("res://scripts/combat_world.gd")
func _initialize():call_deferred("run")
func run():
 var world=World.new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO)
 var attacker=world.spawn_combatant(1,Vector3(5,0,0))
 actor.editor_pose_locked=true;attacker.editor_pose_locked=true;actor.rotation=Vector3.ZERO
 for i in 3:await physics_frame
 var point:Vector3=actor.bone_point("spine_03");var area:Area3D=actor.nearest_hurtbox(point)
 var fire={"effect":"orb","damage":10.0,"projectile_element":"Fire","potency":1.0}
 var block=Rules.author(Rules.self_barrier_base(),1.0,0.3,false)
 var hp:float=actor.health
 # The attack trajectory, not the attacker's current location, decides direction.
 for item in [[0.2,Vector3.FORWARD,1,90.0,90.0,0],[0.06,Vector3.RIGHT,2,95.0,100.0,1],[0.06,Vector3.FORWARD,3,100.0,100.0,2],[0.06,Vector3.BACK,2,95.0,100.0,1], [0.06,-(Basis(Vector3.UP,deg_to_rad(30))*Vector3.BACK),3,100.0,100.0,2],[0.06,-(Basis(Vector3.UP,deg_to_rad(30.1))*Vector3.BACK),2,95.0,100.0,1]]:
  actor.self_barrier.clear();actor.parry_cast_haste.clear();actor.cleanse_burn();actor.invulnerability=0.0;actor.mana=100.0;actor.stamina=100.0
  assert(world.combat().release(actor,block,actor.global_position))
  actor.update_status(item[0])
  assert(world.combat().apply_impact(attacker,actor,fire,point,item[1],area))
  var event:Dictionary=world.events.back()
  assert(event.tier==item[2],"Wrong tier for incoming %s: %s"%[item[1],event])
  assert(actor.health==hp and is_equal_approx(actor.mana,item[3]) and is_equal_approx(actor.stamina,item[4]))
  assert(actor.parry_cast_haste.stacks==item[5])
  assert((actor.burn_time>0.0)==(int(item[2])==1))
  var label=actor.get_node("BlockTierFeedback")
  assert(label.text==["","BLOCK","PERFECT","DIRECTIONAL PERFECT"][int(item[2])])
  assert(actor.self_barrier.flash_color==preload("res://scripts/self_barrier.gd").TIER_COLORS[int(item[2])-1])
 # Upgrading blue to gold can only refund the missing difference, never farm refunds.
 actor.self_barrier.clear();actor.parry_cast_haste.clear();actor.cleanse_burn();actor.invulnerability=0.0;actor.mana=100.0;actor.stamina=100.0
 var strong=block.duplicate();strong.shield_strength=40.0
 assert(world.combat().release(actor,strong,actor.global_position))
 for incoming in [Vector3.RIGHT,Vector3.FORWARD,Vector3.FORWARD]:assert(world.combat().apply_impact(attacker,actor,fire,point,incoming,area))
 assert(actor.mana==100.0 and actor.stamina==100.0 and actor.parry_cast_haste.stacks==5)
 actor.reset_fighter(actor.global_position)
 assert(not actor.get_node("BlockTierFeedback").visible)
 print("BLOCK TIERS PASS: normal / timed / directional; physical/effect, stamina, 5/10 mana and 10/20% haste rewards; 30-degree boundary; actual trajectory; per-cast refund cap; colored feedback/reset")
 quit()
