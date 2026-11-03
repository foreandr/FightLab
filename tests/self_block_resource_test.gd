extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const World=preload("res://scripts/combat_world.gd")
const Barrier=preload("res://scripts/self_barrier.gd")
func _initialize():call_deferred("run")
func run():
 var spec:Dictionary=Rules.author(Rules.self_barrier_base(),1.0,0.3,false)
 assert(spec.shield_strength==10.0 and spec.shield_duration==1.0 and is_equal_approx(Rules.mana_cost(spec),10.0))
 var world=World.new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO)
 var attacker=world.spawn_combatant(1,Vector3(0,0,1))
 actor.editor_pose_locked=true;attacker.editor_pose_locked=true
 for i in 3:await physics_frame
 var point:Vector3=actor.bone_point("spine_03");var area:Area3D=actor.nearest_hurtbox(point)
 var fire={"effect":"orb","damage":10.0,"projectile_element":"Fire","potency":1.0}
 actor.invulnerability=0.0;actor.mana=100.0;actor.stamina=100.0
 var hp:float=actor.health
 assert(world.combat().release(actor,spec,actor.global_position))
 assert(is_equal_approx(actor.mana,90.0) and actor.stamina==100.0)
 assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.health==hp and actor.burn_time==0.0 and actor.stamina==100.0 and actor.mana==95.0)
 assert(world.events.back().event=="parry" and world.events.back().mana_refund==5.0 and world.events.back().stamina_spent==0.0)
 assert(actor.self_barrier.flash_left>0.0)
 for overlay in actor.self_barrier.overlays:assert(float(overlay.get_shader_parameter("block_flash"))==1.0)
 actor.update_status(Barrier.BLOCK_FLASH_SECONDS+0.01)
 for overlay in actor.self_barrier.overlays:assert(float(overlay.get_shader_parameter("block_flash"))==0.0)
 # A higher-capacity barrier cannot repeatedly refund mana from one cast.
 var strong:Dictionary=spec.duplicate();strong.shield_strength=30.0
 actor.mana=100.0;actor.stamina=100.0
 assert(world.combat().release(actor,strong,actor.global_position))
 for i in 2:assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.mana==95.0 and actor.stamina==100.0 and actor.health==hp)
 # A perfect parry also succeeds at zero stamina, without a negative balance.
 actor.self_barrier.clear();actor.mana=100.0;actor.stamina=0.0
 assert(world.combat().release(actor,spec,actor.global_position))
 assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.stamina==0.0 and actor.health==hp and actor.burn_time==0.0 and actor.mana==95.0)
 # Exactly enough stamina holds; a late block passes burn and gives no refund.
 actor.self_barrier.clear();actor.mana=100.0;actor.stamina=10.0
 assert(world.combat().release(actor,spec,actor.global_position))
 actor.update_status(Barrier.PARRY_WINDOW+0.01)
 assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.stamina==0.0 and actor.health==hp and actor.burn_time>0.0 and actor.mana==90.0)
 assert(world.events.back().event=="self_block" and actor.self_barrier.flash_left>0.0)
 # A normal block with a stamina deficit breaks before absorption; the hit and effect get through.
 actor.cleanse_burn();actor.invulnerability=0.0;actor.mana=100.0;actor.stamina=9.0
 assert(world.combat().release(actor,spec,actor.global_position))
 actor.update_status(Barrier.PARRY_WINDOW+0.01)
 assert(world.combat().apply_impact(attacker,actor,fire,point,actor.global_basis.x,area))
 assert(actor.stamina==0.0 and actor.health==hp-10.0 and actor.burn_time>0.0 and actor.mana==90.0)
 assert(not actor.self_barrier.active() and actor.self_barrier.flash_left==0.0)
 assert(world.events.any(func(event):return event.event=="self_block_break"))
 print("SELF BLOCK RESOURCES PASS: 1s / 10 strength / 10 mana; perfect parry costs zero impact stamina and refunds 5 once; green success flash fades; normal block spends 10 stamina for 10 damage; exact zero holds, deficit breaks and passes damage/effect")
 quit()
