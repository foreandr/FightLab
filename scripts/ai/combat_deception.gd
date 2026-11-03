extends RefCounted
## Tactical intentions only. The opponent sees ordinary animation and shield
## state, never this private plan. Runtime owns cancellation, payment and hits.
var controller_ref:WeakRef
var brain:RefCounted:
 get:return controller_ref.get_ref()
var phase:=""
var cooldown:=0.0
var wait_left:=0.0
var source_id:=""
var source_hand:=""
var delay_until:=0.0
var baited:=false
func setup(controller:RefCounted)->void:controller_ref=weakref(controller)
func feint_source()->Dictionary:
 if cooldown>0 or not phase.is_empty() or brain.actor.stamina<30:return {}
 var enemy=brain.actor.rival
 if enemy.health<=0 or enemy.mana<12 or enemy.self_barrier.active() or enemy.combat_reaction_active():return {}
 if enemy.mode=="cast" and (not enemy.did_release or enemy.mode_length-enemy.cast_time>0.1):return {}
 var distance:float=brain.actor.flat_distance()
 if distance<0.50 or distance>1.1:return {}
 for item in brain.loadout:
  if item.kind=="melee" and item.profile.clip=="ual1/Punch_Jab" and distance<=float(item.range)+0.05 and is_equal_approx(float(item.duration),1.0) and brain.can_use(item,15.0):return item
 return {}
func begin_feint(item:Dictionary)->bool:
 if item.is_empty() or not brain.cast(item,"Show a windup to draw the block"):return false
 source_id=str(item.spec.id);source_hand=str(item.spec.hand);phase="feint";baited=false
 cooldown=3.5
 return true
func begin_hesitation()->void:
 cooldown=maxf(cooldown,1.0)
 phase="hesitate";source_id=str(brain.actor.current_spell.id)
 delay_until=minf(brain.actor.mode_length*0.86,brain.actor.cast_time+minf(0.18,brain.actor.mode_length*0.22))
 announce("Hesitation")
 brain.world.events.append({"time":brain.world.elapsed,"event":"cpu_hesitation","team":brain.actor.team})
func announce(text:String)->void:
 if brain.world.has_method("combat_tactical_feedback"):brain.world.combat_tactical_feedback(brain.actor,text)
func step(delta:float)->bool:
 cooldown=maxf(0.0,cooldown-delta)
 if phase.is_empty():return false
 var actor=brain.actor;var enemy=actor.rival
 if actor.combat_reaction_active():phase="";return false
 if phase=="hesitate":
  if actor.mode!="cast" or str(actor.current_spell.id)!=source_id:phase="";return false
  if actor.cast_time<delay_until:return true
  phase="";brain.try_combo(false);return true
 if phase=="feint":
  if actor.mode!="cast" or actor.did_release or str(actor.current_spell.id)!=source_id:phase="";return false
  baited=enemy.self_barrier.active() or (enemy.mode=="cast" and str(enemy.current_spell.get("effect",""))=="self_barrier")
  if not baited and actor.cast_time<float(actor.current_spell.release)*0.80:return true
  var cancelled:Dictionary=actor.cancel_authored_windup()
  phase=""
  if not cancelled.cancelled:return false
  brain.note("Feint","Drew an early block" if baited else "Opponent held their nerve")
  announce("Feint · cancelled windup")
  brain.world.events.append({"time":brain.world.elapsed,"event":"cpu_feint","team":actor.team,"baited":baited,"stamina":cancelled.stamina})
  wait_left=brain.rng.randf_range(0.08,0.16);phase="followup"
  return true
 if phase=="followup":
  # A defensive response can supersede the plan; never cancel it to keep a bait.
  if actor.mode=="cast":phase="";return false
  wait_left-=delta
  if wait_left>0:return true
  phase=""
  var best:Dictionary={};var score:=-INF
  for item in brain.loadout:
   if item.kind!="melee" or actor.flat_distance()>float(item.range) or not brain.can_use(item,12.0):continue
   var value:float=brain.melee_score(item,actor.flat_distance())
   if str(item.spec.hand)!=source_hand:value+=0.5
   if str(item.spec.get("projectile_element","None"))=="Fire" and enemy.self_barrier.active():value+=0.8
   if value>score:score=value;best=item
  if not best.is_empty():
   if brain.cast(best,"Off-beat follow-up after feint"):
    brain.world.events.append({"time":brain.world.elapsed,"event":"cpu_feint_followup","team":actor.team,"spell":best.spec.id,"baited":baited})
    return true
 return false
