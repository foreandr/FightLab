extends SceneTree
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame
 await process_frame
 var world=current_scene
 world.set_physics_process(false);world.round_active=true
 var brain=world.brains[0];var actor=brain.actor;var enemy=actor.rival
 var left:Dictionary=brain.loadout[1];var right:Dictionary=brain.loadout[4];var flame:Dictionary={}
 for item in brain.loadout:
  if item.title=="Flame right cross":flame=item
 assert(not flame.is_empty())
 assert(brain.expected_damage(flame)>float(flame.spec.damage),"AI ignored fresh burn damage")
 enemy.burn_time=5.0;enemy.burn_damage=100.0
 assert(is_equal_approx(brain.expected_damage(flame),float(flame.spec.damage)),"AI counted burns as stacking")
 enemy.burn_time=0
 actor.mana=100;actor.stamina=100
 assert(actor.start_authored_cast(left.spec,left.profile))
 actor.tick_cast(0.6)
 assert(world.combat().release(actor,actor.current_spell,actor.bone_point("hand_l"),left.profile))
 enemy.global_position=actor.global_position+Vector3.BACK*3.0
 assert(not brain.try_combo() and not brain.combo_checked,"One out-of-range check discarded the entire combo opportunity")
 assert(brain.combo_score(right)>brain.combo_score(left),"AI does not value alternating hands")
 brain.loadout.assign([left,right,flame,brain.loadout.back()])
 enemy.global_position=actor.global_position+Vector3.BACK*0.8
 assert(brain.try_combo(),"AI did not retry a legal close follow-up")
 assert(actor.current_spell.hand=="hand_r" and actor.current_spell.projectile_element=="Fire","AI did not take the useful fire one-two")
 assert(is_equal_approx(actor.cast_speed_multiplier(),1.12))
 print("CPU COMBO CHOICES PASS: burn value and refresh discount, late range retry, alternate-hand preference, real physical jab into fire cross at shared 12-percent speed bonus")
 quit()
