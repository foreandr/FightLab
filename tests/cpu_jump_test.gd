extends SceneTree
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var a=w.fighters[0];var b=w.fighters[1];var brain=w.brains[0]
 a.reset_fighter(Vector3(-2,0,0));b.reset_fighter(Vector3(2,0,0))
 for i in 10:
  await physics_frame
  w.tick_combat(1.0/60.0)
 assert(a.is_on_floor())
 brain.policy=preload("res://scripts/ai/adaptive_policy.gd").new()
 var model:Dictionary={};model[brain.policy.state(a)]={"move/jump":{"q":100.0,"n":1}}
 brain.policy.configure(model,8,false,0)
 var empty:Array[Dictionary]=[];var scores:Array[float]=[]
 var stamina:float=a.stamina
 assert(brain.adaptive_decision(a.flat_distance(),empty,scores))
 assert(a.mode=="takeoff" and stamina-a.stamina>=4.0 and stamina-a.stamina<=12.0,"Jump choice did not use the real paid variable jump")
 assert(not brain.jump("repeat"),"Jump repeated without landing/cooldown")
 var peak:=0.0;var airborne_cast:=false;var landed:=false
 for i in 180:
  await physics_frame
  brain.step(1.0/60.0);w.tick_combat(1.0/60.0)
  peak=maxf(peak,a.global_position.y-w.ground_height(a.global_position))
  if a.mode=="cast" and not a.is_on_floor():
   airborne_cast=true
   assert(str(a.practice_spell_animation.clip).begins_with("duel/air_"),"Ground pose used for airborne projectile")
  if peak>1 and a.is_on_floor():landed=true;break
 assert(peak>1.0 and airborne_cast and landed,"Missing real ascent, aerial cast or gravity-driven landing")
 assert(w.events.any(func(e):return e.event=="cpu_air_attack"))
 assert(not w.casts.is_empty(),"Airborne attack was only cosmetic")
 # Both trick choices use the existing airborne controller and its resource cost.
 for trick in ["flip","twist"]:
  w.combat().discard_cast_attempt(a);a.reset_fighter(Vector3(-2,0,0));w.round_active=true
  brain.jump_cooldown=0;brain.air_action_used=false
  for i in 8:
   await physics_frame
   w.tick_combat(1.0/60.0)
  assert(brain.jump("trick fixture"))
  for i in 20:
   await physics_frame
   w.tick_combat(1.0/60.0)
  var actions:Dictionary={};actions[brain.policy.state(a)]={"air/"+trick:{"q":100.0,"n":1}}
  brain.policy.configure(actions,7,false,0);brain.think_left=0
  var before:float=a.stamina
  brain.air_step(0.1)
  assert(a.mode=="air_trick" and a.stamina<before,"Selected trick did not animate/pay")
 a.stamina=11;brain.jump_cooldown=0
 assert(not brain.can_jump())
 print("CPU JUMP PASS: selectable paid jump, cooldown, real ascent/landing, native airborne projectile pose and release, selectable paid flip/twist, resource gate")
 quit()
