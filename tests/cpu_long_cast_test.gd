extends SceneTree
const Opening=preload("res://scripts/ai/cast_opening.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true;w.countdown=0
 var brain=w.brains[0];var a=brain.actor;var b=a.rival
 var charged:Array[Dictionary]=[]
 for item in brain.loadout:
  if float(item.duration)>=3.0:charged.append(item)
 assert(charged.size()==4 and brain.loadout.back().kind=="shield")
 var small:Dictionary=brain.loadout[13];var last_radius:=0.0
 for item in charged:
  assert(item.duration==item.profile.duration and item.duration==item.spec.animation_duration)
  assert(is_equal_approx(float(item.spec.release),0.55))
  assert(item.spec.projectile_radius>last_radius and item.spec.projectile_radius>small.spec.projectile_radius*2.0)
  assert(item.spec.stamina_cost>small.spec.stamina_cost and brain.can_use(item,10.0))
  last_radius=item.spec.projectile_radius
 a.position=Vector3.ZERO;b.position=Vector3(0,0,3.0)
 var unsafe:float=brain.projectile_score(charged[0],3.0)
 b.position.z=16.0
 var safe:float=brain.projectile_score(charged[0],16.0)
 assert(safe>unsafe*2.0,"Long-cast decision ignores rush exposure")
 b.mode="cast";b.mode_length=5.0;b.cast_time=1.0
 w.combat().cast_recoveries[b.get_instance_id()]={"actor":weakref(b),"mode":"cast"}
 var busy:float=brain.projectile_score(charged[-1],16.0)
 w.combat().finish_cast(b);b.mode="idle"
 assert(busy>brain.projectile_score(charged[-1],16.0),"Does not recognize opponent's committed recovery")
 w.elapsed=119.0
 assert(brain.projectile_score(charged[0],16.0)==0.0,"Starts a charge too late to release before timeout")
 w.elapsed=0
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,16));a.rotation.y=0;b.rotation.y=PI;w.round_active=true
 for i in 10:
  await physics_frame
  w.tick_combat(1.0/60.0)
 var item:Dictionary=charged[2]
 var model:Dictionary={};var policy=preload("res://scripts/ai/adaptive_policy.gd").new()
 model[policy.state(a)]={"cast/"+str(item.spec.id):{"q":99.0,"n":1}}
 policy.configure(model,13,false,0);brain.policy=policy
 var choices:Array[Dictionary]=[item,small];var scores:Array[float]=[brain.projectile_score(item,16),brain.projectile_score(small,16)]
 assert(brain.adaptive_decision(16,choices,scores) and a.mode=="cast" and a.mode_length==6.0)
 var stamina_before:float=a.stamina_spent;var mana_before:float=a.mana_spent
 for i in 220:
  await physics_frame
  w.tick_combat(1.0/60.0)
  if a.cast_time<3.3:assert(w.shots.is_empty(),"Long cast launched early")
  if not w.shots.is_empty():break
 assert(not w.shots.is_empty() and a.cast_time>=3.3)
 var shot:Dictionary=w.shots.back()
 assert(is_equal_approx(float(shot.radius),float(item.spec.projectile_radius)))
 assert(is_equal_approx(a.stamina_spent-stamina_before,float(item.spec.stamina_cost)))
 assert(is_equal_approx(a.mana_spent-mana_before,w.mana_cost(item.spec)))
 assert(w.combat().cast_committed(a),"Long spell bypassed the release commitment")
 print("LONG CAST PASS: 3/4.5/6/8-second genuine shared-rule spells, increasing radius and cost, rush/committed-opponent/deadline scoring, learned choice, 3.3-second windup before real six-second spell launch; radius=",shot.radius," stamina=",item.spec.stamina_cost," mana=",w.mana_cost(item.spec))
 quit()
