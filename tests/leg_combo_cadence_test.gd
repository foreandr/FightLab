extends SceneTree
const Combo=preload("res://scripts/touch_combo_rules.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func release(a:Node,w:Node,seconds:float):
 a.tick_cast(seconds)
 assert(w.combat().release(a,a.current_spell,a.bone_point(str(a.current_spell.hand)),a.practice_spell_animation))
func run():
 for pair in [["hand_l","foot_r"],["foot_l","foot_r"],["calf_l","calf_r"],["foot_r","hand_l"]]:
  assert(Combo.speed({"hand":pair[0]},{"hand":pair[1]})==1.0,"Boxing bonus leaked to legs")
 assert(Combo.speed({"hand":"hand_l"},{"hand":"hand_r"})==1.12)
 assert(Combo.link_progress({"attack_bone":"foot_r","combo_link_progress":0.55})==0.90)
 assert(Combo.link_progress({"attack_bone":"calf_l"})==0.90)
 assert(Combo.link_progress({"clip":"boxing/hook_r","attack_bone":"hand_r"})==0.68)
 assert(Combo.link_progress({"clip":"fight/tornado_kick","attack_bone":"foot_r"})==0.90)
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var a=w.fighters[0];var list=w.brains[0].loadout
 a.reset_fighter(a.position);a.stamina=100;a.mana=100
 var left:Dictionary=list[0];var right:Dictionary=list[3];var kick:Dictionary=list[6];var knee:Dictionary=list[9]
 assert(a.start_authored_cast(left.spec,left.profile))
 release(a,w,0.31)
 assert(a.chain_touch_cast(right.spec,right.profile) and a.cast_speed_multiplier()==1.12)
 release(a,w,0.31)
 assert(a.chain_touch_cast(kick.spec,kick.profile),"Fast one-two could not link into a kick")
 assert(a.cast_speed_multiplier()==1.0,"Kick inherited boxing speed")
 release(a,w,0.34)
 assert(not a.chain_touch_cast(knee.spec,knee.profile),"Kick linked out at punch cadence")
 a.tick_cast(0.17)
 assert(a.chain_touch_cast(knee.spec,knee.profile),"Kick could not link after recovery")
 assert(a.cast_speed_multiplier()==1.0)
 release(a,w,0.34)
 assert(not a.chain_touch_cast(left.spec,left.profile),"Knee skipped its slower recovery")
 a.tick_cast(0.17)
 assert(a.chain_touch_cast(left.spec,left.profile))
 assert(a.cast_speed_multiplier()==1.0,"Punch immediately after knee inherited a boxing chain")
 # An actual opposite-leg chain also stays at base speed.
 w.combat().discard_cast_attempt(a);a.reset_fighter(a.position)
 var left_kick:Dictionary={}
 for item in list:
  if item.title=="Left front kick":left_kick=item
 assert(a.start_authored_cast(kick.spec,kick.profile));release(a,w,0.51)
 assert(a.chain_touch_cast(left_kick.spec,left_kick.profile))
 assert(a.cast_speed_multiplier()==1.0)
 # CPUs must still see the late leg window instead of discarding it at 90%.
 w.combat().discard_cast_attempt(a);a.reset_fighter(a.position)
 a.rival.global_position=a.global_position+Vector3.BACK*0.6
 var brain=w.brains[0];brain.combo_count=0;brain.combo_checked=false
 assert(a.start_authored_cast(kick.spec,kick.profile));release(a,w,0.52)
 assert(brain.try_combo(false),"CPU discarded the legal late kick recovery window")
 print("LEG CADENCE PASS: fast left-right punches -> base-speed kick, 90% kick/knee recovery before next link, no opposite-leg/leg-to-arm boxing bonus, hooks keep follow-through, airborne kicks retain recovery")
 quit()
