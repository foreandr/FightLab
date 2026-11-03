extends RefCounted
## Decisions only: the actor/runtime owns movement, animation, resources and hits.
var actor:CharacterBody3D
var world:Node3D
var loadout:Array[Dictionary]=[]
var rng:=RandomNumberGenerator.new()
var aggression:=0.5
var think_left:=0.0
var action_left:=0.0
var defense_left:=0.0
var recovering:=false
var plan:="Ready"
var reason:=""
var counts:Dictionary={}
var last_progress:=0.0
var stale_time:=0.0
func setup(unit:CharacterBody3D,host:Node3D,seed_:int,pressure:float)->void:
 actor=unit;world=host;rng.seed=seed_;aggression=pressure
 loadout=preload("res://scripts/cpu_duel_loadout.gd").build()
 think_left=rng.randf_range(0.05,0.2)
 # Warm immutable contact geometry before the fight, rather than on first hit.
 for bone in ["hand_l","hand_r","foot_r","calf_r"]:actor.ensure_touch_contact_visual().ensure_region(bone)
func note(action:String,why:String)->void:
 if plan!=action or reason!=why:
  world.events.append({"time":world.elapsed,"event":"cpu_decision","team":actor.team,"action":action,"reason":why,"stamina":actor.stamina,"mana":actor.mana})
 plan=action;reason=why
 counts[action]=int(counts.get(action,0))+1
func can_use(item:Dictionary,reserve:float=0.0)->bool:
 return actor.stamina>=float(item.spec.stamina_cost)+reserve and actor.mana>=world.mana_cost(item.spec)
func cast(item:Dictionary,why:String)->bool:
 if not can_use(item) or not actor.start_authored_cast(item.spec,item.profile):return false
 note(str(item.title),why);action_left=0.18+rng.randf_range(0.0,0.18)
 return true
func move(kind:String,why:String)->void:
 if actor.mode!=kind:
  if kind=="chase":
   actor.mode="chase";actor.mode_time=0;actor.mode_length=0.45;actor.clip=""
  else:actor.start_footwork(kind)
  note({"chase":"Sprint in","approach":"Close distance","retreat":"Give ground","strafe":"Circle"}.get(kind,kind),why)
func incoming()->Dictionary:
 var best:Dictionary={};var earliest:=INF
 for shot in world.shots:
  if not is_instance_valid(shot.caster) or shot.caster.team==actor.team or not is_instance_valid(shot.node):continue
  var offset:Vector3=actor.global_position+Vector3.UP-shot.node.global_position
  var velocity:Vector3=shot.velocity
  var time:float=offset.dot(velocity)/maxf(0.001,velocity.length_squared())
  if time<0 or time>0.85:continue
  if (offset-velocity*time).length()>float(shot.radius)+0.7:continue
  if time<earliest:earliest=time;best={"eta":time,"kind":"projectile"}
 var enemy:CharacterBody3D=actor.rival
 if enemy.mode=="cast" and not enemy.did_release and actor.flat_distance()<1.65 and str(enemy.current_spell.get("effect",""))=="touch":
  var eta:float=maxf(0.0,float(enemy.current_spell.release)-enemy.cast_time)+0.12
  if eta<earliest:best={"eta":eta,"kind":"melee"}
 return best
func step(delta:float)->void:
 if not world.round_active or actor.health<=0:return
 defense_left=maxf(0.0,defense_left-delta);action_left=maxf(0.0,action_left-delta)
 if actor.damage_dealt>last_progress+0.1:last_progress=actor.damage_dealt;stale_time=0.0
 else:stale_time+=delta
 if actor.mode=="cast" or actor.combat_reaction_active() or actor.mode in ["motion_dash","takeoff","air","land"]:return
 think_left-=delta
 if think_left>0:return
 think_left=rng.randf_range(0.14,0.26)
 var distance:float=actor.flat_distance()
 var threat:=incoming()
 if not threat.is_empty() and defense_left<=0:
  var shield:Dictionary=loadout.back()
  if float(threat.eta)>0.24 and float(threat.eta)<0.65 and not actor.self_barrier.active() and can_use(shield,8.0) and rng.randf()<0.68:
   if cast(shield,"Incoming "+str(threat.kind)):defense_left=1.4;return
  if float(threat.eta)<0.45 and actor.stamina>35 and rng.randf()<0.7:
   if actor.start_motion_dash(2 if rng.randf()<0.5 else 6):
    note("Evade","Incoming "+str(threat.kind));defense_left=1.3;return
 if recovering:
  recovering=actor.stamina<60 or (actor.mana<22 and distance>2.0)
 elif actor.stamina<24 or (actor.mana<8 and distance>2.0):recovering=true
 if recovering:
  move("retreat" if distance<3.0 else "strafe","Recover stamina / mana")
  return
 if action_left>0:return
 # Pressure fighters sometimes spend movement stamina to deny a ranged reset.
 if distance>3.0 and distance<10.0 and actor.stamina>55 and aggression>0.6 and rng.randf()<0.35:
  move("chase","Deny a ranged opening");action_left=0.45;return
 var choices:Array[Dictionary]=[]
 var scores:Array[float]=[]
 for item in loadout:
  if item.kind=="shield" or not can_use(item,10.0):continue
  var score:=0.0
  if item.kind=="melee" and distance<=float(item.range):
   score=2.0+aggression+float(item.spec.damage)*0.055
   if actor.rival.mode=="cast":score+=0.8/float(item.duration)
   if float(item.spec.damage)>=actor.rival.health:score+=3.0
   if actor.rival.self_barrier.active():score*=0.35
  elif item.kind=="projectile" and distance>1.8 and distance<18.0:
   score=1.0+(1.0-aggression)*1.3
   if str(item.title)=="Quick fireball" and actor.rival.drive_velocity.length()>2.0:score+=1.0
   if str(item.title)=="Large fireball" and actor.rival.mode=="cast":score+=0.8
   if actor.mana<35:score*=0.25
   # Preserve one defensive cast unless this shot could finish the opponent.
   if actor.mana-world.mana_cost(item.spec)<12 and actor.rival.health>float(item.spec.damage)*1.5:score=0.0
   if distance>10.0:score*=0.55
  if score>0:
   choices.append(item);scores.append(score*rng.randf_range(0.6,1.4))
 if not choices.is_empty():
  var best:=0
  for i in scores.size():if scores[i]>scores[best]:best=i
  if cast(choices[best],"Close contact" if distance<1.8 else "Ranged opening"):return
 if distance>3.5 and actor.stamina>55:
  if distance<7.0 and defense_left<=0 and rng.randf()<0.15 and actor.start_motion_dash(0):
   note("Dash in","Close the gap");defense_left=1.2;return
  move("chase","Pressure at range")
 elif distance>0.85:move("approach","Find contact range")
 elif stale_time>4.0:move("retreat","Create a new angle")
 else:move("strafe","Find an opening")
