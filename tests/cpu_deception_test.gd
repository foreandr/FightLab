extends SceneTree
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.countdown=0;w.round_active=true
 var a=w.fighters[0];var b=w.fighters[1];var brain=w.brains[0];var defender=w.brains[1]
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.8));a.rotation.y=0;b.rotation.y=PI
 var source:Dictionary=brain.deception.feint_source();assert(not source.is_empty())
 var stamina:float=a.stamina;var mana:float=a.mana
 brain.policy=preload("res://scripts/ai/adaptive_policy.gd").new()
 var feint_model:Dictionary={}
 feint_model[brain.policy.state(a)]={"tactic/feint":{"q":100.0,"n":1}}
 brain.policy.configure(feint_model,4,false,0.0)
 var attacks:Array[Dictionary]=[];var scores:Array[float]=[]
 assert(brain.adaptive_decision(a.flat_distance(),attacks,scores) and brain.deception.phase=="feint","Feint is not a selectable policy action")
 var feint_event:Dictionary={}
 var cancelled_checked:=false;var followed:=false
 for i in 60:
  await physics_frame
  # Defender observes the ordinary animation through its real incoming/guard path.
  defender.step(1.0/60.0)
  brain.deception.step(1.0/60.0)
  for event in w.events:
   if event.event=="cpu_feint":feint_event=event
   if event.event=="cpu_feint_followup":followed=true
  if not feint_event.is_empty() and not cancelled_checked:
   cancelled_checked=true
   assert(feint_event.baited,"Visible windup failed to draw the actual CPU shield")
   assert(float(feint_event.stamina)>0 and float(feint_event.stamina)<float(source.spec.stamina_cost))
   assert(a.mana==mana,"Cancelled windup paid spell mana")
   assert(w.combat().touch_casts.is_empty() and w.shots.is_empty(),"Feint created a real hit/projectile")
  w.tick_combat(1.0/60.0)
  if followed:break
 assert(cancelled_checked and followed and b.mode=="cast")
 assert(brain.deception.cooldown>0 and brain.deception.feint_source().is_empty(),"No anti-spam cooldown")
 assert(a.stamina<stamina)
 # Hesitation lets the existing animation continue, then links a normal paid hit.
 w.rematch(33);w.set_physics_process(false);w.round_active=true
 brain=w.brains[0];a=w.fighters[0];b=w.fighters[1]
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.8))
 source=brain.loadout[1]
 assert(a.start_authored_cast(source.spec,source.profile,b))
 a.tick_cast(0.6)
 assert(w.combat().release(a,a.current_spell,a.bone_point("hand_l"),source.profile))
 var paid:float=a.stamina
 brain.policy=preload("res://scripts/ai/adaptive_policy.gd").new()
 var delay_model:Dictionary={}
 delay_model[brain.policy.state(a)]={"combo/hesitate":{"q":100.0,"n":1}}
 brain.policy.configure(delay_model,7,false,0.0)
 assert(brain.try_combo() and brain.deception.phase=="hesitate","Hesitation is not a selectable policy action")
 assert(brain.deception.step(0.05) and a.cast_time==0.6 and brain.combo_count==0)
 a.tick_cast(0.19)
 assert(brain.deception.step(0.05) and brain.combo_count==1,"Delayed follow-up never linked")
 assert(a.stamina==paid,"Waiting/queuing gave an extra stamina charge")
 # Post-release commitment survives the new cancel API.
 a.tick_cast(a.mode_length*0.5/a.cast_speed_multiplier())
 assert(a.mode=="cast" and a.did_release)
 assert(w.combat().release(a,a.current_spell,a.bone_point(str(a.current_spell.hand)),a.practice_spell_animation))
 var before:float=a.stamina
 assert(not a.cancel_authored_windup().cancelled and a.stamina==before)
 print("DECEPTION PASS: actual windup baits expert guard, partial stamina/no mana/no phantom hit, off-beat follow-up, cooldown, continuing animation hesitation, paid chain and released-cast commitment")
 quit()
