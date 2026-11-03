extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var world=current_scene
 await create_timer(0.25).timeout
 world.toggle_pause();world.countdown=0;world.round_active=true
 var actor=world.fighters[0];var enemy=world.fighters[1];var brain=world.brains[0]
 actor.global_position=world.surface_placement(Vector3.ZERO)
 enemy.global_position=world.surface_placement(Vector3(0,0,1.2));actor.rotation.y=0
 enemy.mode="cast";enemy.current_spell=brain.loadout[11].spec.duplicate(true)
 enemy.mode_length=1.5;enemy.cast_time=0.4;enemy.did_release=true
 world.combat().touch_casts[enemy.get_instance_id()]={"connected":false}
 var warning:Dictionary=brain.incoming()
 assert(warning.get("kind","")=="melee" and float(warning.eta)>0.2,"Ignored a released but still incoming knee")
 world.combat().touch_casts[enemy.get_instance_id()].connected=true
 assert(brain.incoming().is_empty(),"Reacted again to a spent contact")
 world.combat().touch_casts.clear();enemy.mode="idle"
 actor.mode="idle";actor.mana=100;actor.stamina=100
 assert(brain.defend({"eta":0.5,"kind":"projectile"}) and actor.mode=="idle","Blocked too early instead of waiting")
 assert(brain.defend({"eta":0.20,"kind":"projectile"}) and actor.mode=="cast")
 assert(actor.tick_cast(0.15))
 assert(world.combat().release(actor,actor.current_spell,actor.bone_point("hand_r"),actor.practice_spell_animation))
 actor.self_barrier.step(0.05)
 var stamina:float=actor.stamina
 var result:Dictionary=actor.self_barrier.resolve_hit(10.0,-actor.global_basis.z)
 assert(int(result.tier)==3 and result.parry and result.stamina_spent==0 and actor.stamina==stamina)
 print("CPU DEFENSE PASS: waits for the perfect window, real paid shield activation plus 50ms gives directional perfect, no impact stamina, sees late knee contact and ignores already connected hits")
 quit()
