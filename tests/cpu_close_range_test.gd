extends SceneTree
const Policy=preload("res://scripts/ai/adaptive_policy.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var brain=w.brains[0];var a=brain.actor;var b=a.rival
 var elbow:Dictionary={};var flame:Dictionary={};var punch:Dictionary=brain.loadout[1];var kick:Dictionary=brain.loadout[7]
 for item in brain.loadout:
  if item.title=="Elbow":elbow=item
  if item.title=="Flame elbow":flame=item
 assert(brain.melee_score(punch,0.6)>brain.melee_score(kick,0.6),"Kicks dominate boxing distance")
 assert(brain.melee_score(elbow,0.55)>brain.melee_score(punch,0.55),"Elbow has no useful close-range role")
 assert(brain.range_fit(kick,1.1)>brain.range_fit(kick,0.6))
 var policy=Policy.new();policy.configure({},4,false)
 a.position=Vector3.ZERO;b.position=Vector3(0,0,0.6);var close:String=policy.state(a)
 b.position.z=0.9;var boxing:String=policy.state(a)
 b.position.z=1.4;var kicking:String=policy.state(a)
 assert(close!=boxing and boxing!=kicking)
 var old_state:=close.get_slice("|",1)
 policy.model={old_state:{"old_action":{"q":8.0,"n":12}}}
 assert(policy.value(close,"old_action",4.0)>4.0,"Archived policy knowledge was discarded")
 assert(not policy.model.has(close),"Frozen fallback rewrote archived policy")
 for item in [elbow,flame]:
  w.clear_battle_effects();w.combat().cast_attempts.clear();w.combat().cast_recoveries.clear();w.combat().touch_casts.clear()
  a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.6));a.rotation.y=0;b.rotation.y=PI
  w.round_active=true;b.invulnerability=0;b.guard_energy=0
  assert(a.start_authored_cast(item.spec,item.profile,b))
  for i in 85:
   await physics_frame
   w.tick_combat(1.0/60.0)
  assert(b.last_physical_impact_damage>0,"Actual elbow contact failed: "+str(item.title))
  if item==flame:assert(b.burn_time>0,"Fire elbow did not apply real burn")
 print("CLOSE RANGE PASS: actual physical/fire elbow hits, close punches beat crowded kicks, distinct learned distance states, frozen old model fallback without mutation")
 quit()
