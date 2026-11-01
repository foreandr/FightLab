extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var world=preload("res://scripts/combat_world.gd").new()
 root.add_child(world)
 world.set_physics_process(false)
 world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO)
 actor.practice_god_mode=false
 var runtime=world.combat()
 var spec={"effect":"orb","mana":10.0,"stamina_cost":10.0}
 actor.stamina=9.99
 assert(not runtime.begin_cast_attempt(actor,spec,0.5))
 assert(runtime.cast_attempts.is_empty())
 assert(actor.get_node("CastResourceNotice").text=="Not enough stamina")
 actor.stamina=10.0;actor.mana=0.0
 assert(runtime.begin_cast_attempt(actor,spec,0.5))
 runtime.advance_cast_attempt(actor,0.5)
 assert(not runtime.release(actor,spec,Vector3.ZERO))
 assert(actor.get_node("CastResourceNotice").text=="Not enough mana")
 assert(actor.mana==0 and actor.stamina==0)
 actor.practice_god_mode=true
 assert(runtime.begin_cast_attempt(actor,spec,0.5))
 print("CAST RESOURCE FEEDBACK PASS: stamina gate, exact boundary, mana failure notice, attempted animation stamina and God bypass")
 world.queue_free()
 await process_frame
 quit()

