extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var world=current_scene
 await create_timer(0.25).timeout
 world.toggle_pause();world.countdown=0;world.round_active=true
 var actor=world.fighters[0]
 var options=preload("res://scripts/cpu_duel_loadout.gd").build()
 var left:Dictionary=options[1];var right:Dictionary=options[4];var knee:Dictionary=options[10]
 assert(left.spec.hand=="hand_l" and right.spec.hand=="hand_r" and knee.spec.hand=="calf_r")
 actor.mana=100;actor.stamina=100
 assert(actor.start_authored_cast(left.spec,left.profile))
 assert(not actor.chain_touch_cast(right.spec,right.profile),"Linked before release")
 actor.tick_cast(0.6)
 assert(world.combat().release(actor,actor.current_spell,actor.bone_point("hand_l"),left.profile))
 var paid_stamina:float=actor.stamina;var paid_mana:float=actor.mana
 assert(actor.chain_touch_cast(right.spec,right.profile))
 assert(actor.cast_time==0 and actor.current_spell.hand=="hand_r" and actor.authored_entry_pose.size()>0)
 assert(actor.stamina==paid_stamina and actor.mana==paid_mana,"Chain paid again before its own release")
 assert(world.combat().touch_casts.is_empty(),"Old contact remained armed after link")
 actor.tick_cast(0.6)
 assert(world.combat().release(actor,actor.current_spell,actor.bone_point("hand_r"),right.profile))
 assert(is_equal_approx(actor.stamina,paid_stamina-float(right.spec.stamina_cost)))
 assert(actor.chain_touch_cast(knee.spec,knee.profile))
 actor.tick_cast(0.6)
 assert(world.combat().release(actor,actor.current_spell,actor.bone_point("calf_r"),knee.profile))
 assert(actor.chain_touch_cast(left.spec,left.profile),"Knee could not link back into a punch")
 # The existing post-launch projectile lock is unchanged.
 world.combat().discard_cast_attempt(actor);actor.reset_fighter(actor.position)
 var fire:Dictionary=options[13]
 assert(actor.start_authored_cast(fire.spec,fire.profile))
 actor.tick_cast(0.4)
 assert(world.combat().release(actor,actor.current_spell,actor.bone_point("hand_l"),fire.profile))
 actor.cast_time=actor.mode_length*0.7
 assert(not actor.chain_touch_cast(left.spec,left.profile),"Touch chain canceled a released projectile")
 print("TOUCH COMBO PASS: left/right/punch/knee links, release/55-percent gate, previous hit-window cleanup, blended pose, each new hit pays once, projectile commitment preserved")
 quit()
