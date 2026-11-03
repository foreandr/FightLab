extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const World=preload("res://scripts/combat_world.gd")
const Barrier=preload("res://scripts/self_barrier.gd")
func _initialize():call_deferred("run")
func run():
 var neutral:Dictionary=Rules.neutral_projectile()
 var block:Dictionary=Rules.author(Rules.self_barrier_base(),1.0,0.3,false)
 assert(is_equal_approx(neutral.damage,10.0) and is_equal_approx(block.shield_strength,10.0))
 for fraction in [0.05,0.3,0.55]:
  var base=Rules.allocate(Rules.projectile_base("None"),{"size":0.5,"speed":0.5},"None",1.0)
  assert(is_equal_approx(Rules.author(base,1.0,fraction,true).damage,Rules.author(Rules.self_barrier_base(),1.0,fraction,false).shield_strength))
 var world=World.new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO)
 var attacker=world.spawn_combatant(1,Vector3(0,0,1))
 actor.editor_pose_locked=true;attacker.editor_pose_locked=true
 for i in 3:await physics_frame
 var point:Vector3=actor.bone_point("spine_03");var area:Area3D=actor.nearest_hurtbox(point)
 assert(area.get_meta("zone")!="head")
 var fire={"effect":"orb","damage":10.0,"projectile_element":"Fire","potency":1.0}
 var hp:float=actor.health
 # Matching physical strength protects HP, but an old block does not stop burn.
 actor.invulnerability=0.0
 world.combat().dispatch(actor,block,actor.global_position)
 actor.update_status(Barrier.PARRY_WINDOW+0.01)
 assert(not actor.self_barrier.can_parry())
 assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.health==hp and actor.burn_time>0.0 and not actor.self_barrier.active())
 assert(world.events.back().event=="self_block" and not world.events.back().effects_blocked)
 actor.cleanse_burn();actor.invulnerability=0.0
 # A freshly activated block cancels physical and effect, even at exact capacity.
 world.combat().dispatch(actor,block,actor.global_position)
 actor.update_status(Barrier.PARRY_WINDOW*0.5)
 assert(actor.self_barrier.can_parry())
 assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.health==hp and actor.burn_time==0.0 and not actor.self_barrier.active())
 assert(world.events.back().event=="parry" and world.events.back().effects_blocked)
 # Perfect timing cannot cover physical damage beyond shield capacity.
 actor.invulnerability=0.0
 world.combat().dispatch(actor,block,actor.global_position)
 var heavy=fire.duplicate();heavy.damage=15.0
 assert(world.combat().apply_impact(attacker,actor,heavy,point,actor.global_basis.x,area))
 assert(is_equal_approx(actor.health,hp-5.0) and actor.burn_time>0.0)
 print("SELF BLOCK/PARRY PASS: neutral 1s block exactly cancels neutral 10-damage spell; held block passes effects; fresh parry cancels both; insufficient capacity passes overflow and effect; shared new-mode runtime")
 quit()
