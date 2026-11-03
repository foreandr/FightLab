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
var combo_count:=0
var combo_checked:=false
var policy:RefCounted
const Combo=preload("res://scripts/touch_combo_rules.gd")
const Burn=preload("res://scripts/burn_rules.gd")
func expected_damage(item:Dictionary)->float:
 var damage:=float(item.spec.damage)
 if str(item.spec.get("projectile_element","None"))=="Fire":
  var duration:=float(item.spec.get("burn_duration",Burn.DURATION))
  var fresh_burn:=Burn.dps(float(item.spec.get("potency",0.0)))*duration
  # Burn refreshes rather than stacks: count only the extra pending damage.
  var pending:=float(actor.rival.burn_damage)/Burn.TICK_INTERVAL*float(actor.rival.burn_time)
  damage+=maxf(0.0,fresh_burn-pending)
 return damage
func combo_score(item:Dictionary)->float:
 var score:=1.0+expected_damage(item)*0.03+range_fit(item,actor.flat_distance())*0.5
 var old_bone:=str(actor.current_spell.get("hand",""))
 var new_bone:=str(item.spec.get("hand",""))
 if Combo.speed(actor.current_spell,item.spec)>1.0:
  score+=0.35
  # A compact opposite-hand follow-up is a useful one-two, not just another
  # randomly chosen kick. It remains a learned choice, not a forced sequence.
  if old_bone.begins_with("hand_") and new_bone.begins_with("hand_"):
   score+=0.5/maxf(0.5,float(item.duration))
 return score
func range_fit(item:Dictionary,distance:float)->float:
 var bone:=str(item.spec.get("hand",""))
 if "elbow" in str(item.title).to_lower():return 1.6*(1.0-smoothstep(0.62,0.90,distance))
 if bone.begins_with("hand_"):return 0.9*(1.0-smoothstep(0.82,1.05,distance))
 if bone.begins_with("foot_"):return -1.8*(1.0-smoothstep(0.65,0.95,distance))
 if bone.begins_with("calf_"):return 0.6*(1.0-smoothstep(0.65,0.95,distance))
 return 0.0
func melee_score(item:Dictionary,distance:float)->float:
 # Damage per animation second, not just the largest single-hit number.
 var damage:=expected_damage(item)
 var score:=2.0+aggression+damage*0.025+minf(2.0,damage/maxf(0.25,float(item.duration))*0.06)+range_fit(item,distance)
 if actor.rival.mode=="cast":score+=0.8/float(item.duration)
 if float(item.spec.damage)>=actor.rival.health:score+=3.0
 if actor.rival.self_barrier.active():score*=0.35
 return score
func setup(unit:CharacterBody3D,host:Node3D,seed_:int,pressure:float)->void:
 actor=unit;world=host;rng.seed=seed_;aggression=pressure
 loadout=preload("res://scripts/cpu_duel_loadout.gd").build()
 think_left=rng.randf_range(0.05,0.2)
 # Warm immutable contact geometry before the fight, rather than on first hit.
 preload("res://scripts/cpu_duel_loadout.gd").prepare(actor)
func note(action:String,why:String)->void:
 if plan!=action or reason!=why:
  world.events.append({"time":world.elapsed,"event":"cpu_decision","team":actor.team,"action":action,"reason":why,"distance":actor.flat_distance(),"stamina":actor.stamina,"mana":actor.mana})
 plan=action;reason=why
 counts[action]=int(counts.get(action,0))+1
func can_use(item:Dictionary,reserve:float=0.0)->bool:
 return actor.stamina>=float(item.spec.stamina_cost)+reserve and actor.mana>=world.mana_cost(item.spec)
func cast(item:Dictionary,why:String)->bool:
 if not can_use(item) or not actor.start_authored_cast(item.spec,item.profile,actor.rival):return false
 combo_count=0;combo_checked=false
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
  time=maxf(0.0,time-(float(shot.radius)+0.35)/maxf(0.1,velocity.length()))
  if time<earliest:earliest=time;best={"eta":time,"kind":"projectile"}
 var enemy:CharacterBody3D=actor.rival
 if enemy.mode=="cast":
  var effect:=str(enemy.current_spell.get("effect",""))
  var eta:=INF
  if effect=="touch" and actor.flat_distance()<1.65 and not bool(world.combat().touch_casts.get(enemy.get_instance_id(),{}).get("connected",false)):
   var bone:=str(enemy.current_spell.get("hand","hand_r"))
   var apex:=0.48 if bone.begins_with("calf") else (0.44 if bone.begins_with("foot") else 0.36)
   eta=maxf(0.0,enemy.mode_length*apex-enemy.cast_time)/enemy.cast_speed_multiplier()
  elif effect=="orb" and not enemy.did_release:
   var speed:float=preload("res://scripts/combat_spell_rules.gd").motion(enemy.current_spell).speed
   eta=maxf(0.0,float(enemy.current_spell.release)-enemy.cast_time)/enemy.cast_speed_multiplier()+maxf(0.0,actor.flat_distance()-0.5)/maxf(1.0,speed)
  if eta<earliest and eta<0.85:best={"eta":eta,"kind":"melee" if effect=="touch" else "projectile"}
 return best
func defend(threat:Dictionary)->bool:
 if threat.is_empty() or defense_left>0:return false
 if actor.mode=="cast" and (actor.did_release or str(actor.current_spell.get("effect",""))!="touch"):return false
 var shield:Dictionary=loadout.back()
 if not can_use(shield):return false
 var eta:float=threat.eta
 # A new shield resets the preceding Touch-chain bonus; only parry haste carries.
 var activation:float=float(shield.duration)*float(shield.spec.release)/actor.parry_cast_haste.multiplier()
 # Aim for impact about 50 ms into the real 120 ms perfect-parry window.
 if eta>activation+0.09 and eta<0.65:
  if actor.mode=="cast":return false
  if plan!="Time the block":note("Time the block","Read incoming "+str(threat.kind))
  return true
 if eta>=activation-0.035 and eta<=activation+0.09:
  if actor.mode=="cast":
   world.combat().interrupt_cast_attempt(actor);actor.mode="idle"
  if cast(shield,"Perfect-block timing · "+str(threat.kind)):
   defense_left=0.18;return true
 if eta<activation-0.035 and actor.mode!="cast" and actor.stamina>30:
  if actor.start_motion_dash(2 if rng.randf()<0.5 else 6):
   note("Evade","Too late to parry");defense_left=0.4;return true
 return false
func try_combo()->bool:
 if str(actor.current_spell.get("effect",""))!="touch" or not actor.did_release:return false
 if combo_checked or combo_count>=2 or actor.cast_time<actor.mode_length*Combo.LINK_PROGRESS:return false
 if actor.cast_time>actor.mode_length*0.90:return false
 var choices:Array[Dictionary]=[]
 for item in loadout:
  if item.kind!="melee" or not can_use(item,16.0) or actor.flat_distance()>float(item.range):continue
  choices.append(item)
 if choices.is_empty():return false
 combo_checked=true
 var next:Dictionary=choices[0]
 var best:=-INF
 for item in choices:
  var score:=combo_score(item)*rng.randf_range(0.9,1.1)
  if score>best:best=score;next=item
 if policy!=null:
  var options:Array[Dictionary]=[{"action":"combo/stop","prior":0.5}]
  for item in choices:options.append({"action":"combo/"+str(item.spec.id),"prior":combo_score(item),"item":item})
  var selected:Dictionary=policy.pick(actor,options)
  policy.begin(actor,selected,options,world.elapsed)
  if str(selected.action)=="combo/stop":return false
  next=selected.item
 var previous:=str(actor.current_spell.get("name","Touch"))
 if not actor.chain_touch_cast(next.spec,next.profile,actor.rival):return false
 combo_count+=1;combo_checked=false
 note(str(next.title),"Combo from "+previous)
 world.events.append({"time":world.elapsed,"event":"cpu_combo","team":actor.team,"from":previous,"to":next.title})
 return true
func adaptive_decision(distance:float,choices:Array[Dictionary],scores:Array[float])->bool:
 var options:Array[Dictionary]=[]
 for i in choices.size():options.append({"action":"cast/"+str(choices[i].spec.id),"prior":scores[i],"item":choices[i]})
 options.append({"action":"move/strafe","prior":0.4})
 if distance>0.56:
  var inside:bool=distance<1.6 and actor.stamina>40 and actor.rival.mode!="cast"
  options.append({"action":"move/approach","prior":4.0+aggression if inside else (0.9 if distance<3 else 0.35)})
 if distance<4.5:options.append({"action":"move/retreat","prior":0.7 if actor.stamina<45 else 0.2})
 if distance>3.5 and actor.stamina>55:options.append({"action":"move/chase","prior":1.2 if aggression>0.6 else 0.6})
 if distance>2 and distance<7 and actor.stamina>55 and defense_left<=0:options.append({"action":"move/dash","prior":0.5})
 var selected:Dictionary=policy.pick(actor,options)
 policy.begin(actor,selected,options,world.elapsed)
 if selected.has("item"):return cast(selected.item,"Learned attack choice")
 var kind:=str(selected.action).trim_prefix("move/")
 if kind=="dash":
  if actor.start_motion_dash(0):note("Dash in","Learned movement choice");defense_left=1.2;return true
  return false
 move(kind,"Learned movement choice");action_left=0.45
 return true
func step(delta:float)->void:
 if not world.round_active or actor.health<=0:return
 # Reassess immediately when a physical flinch ends, without an extra think delay.
 if actor.mode=="hit":think_left=0.0
 defense_left=maxf(0.0,defense_left-delta);action_left=maxf(0.0,action_left-delta)
 if actor.damage_dealt>last_progress+0.1:last_progress=actor.damage_dealt;stale_time=0.0
 else:stale_time+=delta
 if actor.combat_reaction_active() or actor.mode in ["motion_dash","takeoff","air","land"]:return
 var threat:=incoming()
 if defend(threat):return
 if actor.mode=="cast":
  try_combo()
  return
 think_left-=delta
 if think_left>0:return
 think_left=rng.randf_range(0.14,0.26)
 var distance:float=actor.flat_distance()
 if recovering:
  recovering=actor.stamina<60 or (actor.mana<22 and distance>2.0)
 elif actor.stamina<24 or (actor.mana<8 and distance>2.0):recovering=true
 if recovering:
  move("retreat" if distance<3.0 else "strafe","Recover stamina / mana")
  return
 if action_left>0:return
 # Pressure fighters sometimes spend movement stamina to deny a ranged reset.
 if policy==null and distance>3.0 and distance<10.0 and actor.stamina>55 and aggression>0.6 and rng.randf()<0.35:
  move("chase","Deny a ranged opening");action_left=0.45;return
 var choices:Array[Dictionary]=[]
 var scores:Array[float]=[]
 for item in loadout:
  if item.kind=="shield" or not can_use(item,10.0):continue
  var score:=0.0
  if item.kind=="melee" and distance<=float(item.range):
   score=melee_score(item,distance)
  elif item.kind=="projectile" and distance>1.8 and distance<18.0:
   score=1.0+(1.0-aggression)*1.3
   if float(item.duration)<=0.8 and actor.rival.drive_velocity.length()>2.0:score+=1.0
   if float(item.duration)>=1.25 and actor.rival.mode=="cast":score+=0.8
   if actor.mana<35:score*=0.25
   # Preserve one defensive cast unless this shot could finish the opponent.
   if actor.mana-world.mana_cost(item.spec)<12 and actor.rival.health>float(item.spec.damage)*1.5:score=0.0
   if distance>10.0:score*=0.55
  if score>0:
   choices.append(item);scores.append(score*rng.randf_range(0.6,1.4))
 if policy!=null:
  adaptive_decision(distance,choices,scores)
  return
 if not choices.is_empty():
  if distance>0.78 and distance<1.6 and actor.stamina>40 and actor.rival.mode!="cast" and rng.randf()<0.35:
   move("approach","Work into punching range");action_left=0.2;return
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
