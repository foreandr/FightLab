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
var jump_cooldown:=0.0
var air_action_used:=false
var deception=preload("res://scripts/ai/combat_deception.gd").new()
const Combo=preload("res://scripts/touch_combo_rules.gd")
const Burn=preload("res://scripts/burn_rules.gd")
const CastOpening=preload("res://scripts/ai/cast_opening.gd")
func knockdown_value(item:Dictionary)->float:
 var rules=preload("res://scripts/combat_defense_rules.gd")
 if not rules.ragdolls(float(item.spec.damage)) or is_instance_valid(actor.rival.ragdoll) or actor.rival.self_barrier.active():return 0.0
 return 1.25 if actor.rival.health>float(item.spec.damage) else 0.0
func projectile_score(item:Dictionary,distance:float)->float:
 if distance<=1.8 or distance>=18.0:return 0.0
 var score:=1.0+(1.0-aggression)*1.3
 if float(item.duration)<=0.8 and actor.rival.drive_velocity.length()>2.0:score+=1.0
 if float(item.duration)>=1.25 and actor.rival.mode=="cast":score+=0.8
 if float(item.duration)>=3.0:
  var safety:=CastOpening.safety(actor,item)
  # Long casts buy area/damage at real exposure and resource cost. A choice,
  # never a quota; incoming threats can still interrupt it through normal defense.
  score=(2.0+minf(4.0,expected_damage(item)*0.035)+knockdown_value(item))*lerpf(0.08,1.0,safety)
  if float(item.spec.stamina_cost)>actor.stamina-20.0:score*=0.5
  if world.has_method("time_remaining") and world.time_remaining()<float(item.duration)*float(item.spec.release)+0.5:return 0.0
 if actor.mana<35:score*=0.25
 if actor.mana-world.mana_cost(item.spec)<12 and actor.rival.health>float(item.spec.damage)*1.5:return 0.0
 if distance>10.0 and float(item.duration)<3.0:score*=0.55
 return score
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
 if float(item.duration)>=2.5:
  var opening:=CastOpening.safety(actor,item)
  # A low-resource opponent or committed recovery creates a heavy punish window.
  if actor.rival.stamina<15 or actor.rival.mana<5:opening=maxf(opening,0.8)
  score=(score+knockdown_value(item))*lerpf(0.2,1.0,opening)
 return score
func setup(unit:CharacterBody3D,host:Node3D,seed_:int,pressure:float)->void:
 actor=unit;world=host;rng.seed=seed_;aggression=pressure
 deception.setup(self)
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
 var profile:Dictionary=preload("res://scripts/cpu_duel_loadout.gd").cast_profile(actor,item)
 if not can_use(item) or not actor.start_authored_cast(item.spec,profile,actor.rival):return false
 combo_count=0;combo_checked=false
 note(str(item.title),why);action_left=0.18+rng.randf_range(0.0,0.18)
 return true
func can_jump()->bool:
 return jump_cooldown<=0 and actor.is_on_floor() and actor.stamina>=40 and not actor.combat_reaction_active() and not world.combat().cast_committed(actor)
func jump(why:String)->bool:
 var height:=rng.randf_range(0.15,0.55) if actor.flat_distance()<2.0 else rng.randf_range(0.4,1.0)
 if not can_jump() or not actor.start_motion_jump(height):return false
 jump_cooldown=3.5;air_action_used=false
 note("Jump",why)
 world.events.append({"time":world.elapsed,"event":"cpu_jump","team":actor.team,"stamina":actor.stamina,"height_fraction":height})
 return true
func dash(direction:int)->bool:
 # Close only the useful distance; lateral evasion can also be a short burst.
 var distance:=clampf(actor.flat_distance()-0.85,0.96,3.6) if direction==0 else rng.randf_range(1.0,2.4)
 return actor.start_motion_dash(direction,clampf((distance/12.0-0.08)/0.22,0.0,1.0))
func air_step(delta:float)->void:
 if air_action_used or actor.air_clock<0.08:return
 think_left-=delta
 if think_left>0:return
 think_left=0.12
 var distance:float=actor.flat_distance()
 var options:Array[Dictionary]=[{"action":"air/wait","prior":0.4}]
 for item in loadout:
  if not can_use(item,12.0):continue
  if item.kind=="projectile" and distance>1.8 and distance<18:
   var score:=projectile_score(item,distance)
   if score>0.0:options.append({"action":"air/cast/"+str(item.spec.id),"prior":score,"item":item})
  elif item.kind=="melee" and distance<=float(item.range) and actor.bone_point(str(item.spec.hand)).distance_to(actor.rival.bone_point("spine_03"))<float(item.range)+0.2:
   options.append({"action":"air/cast/"+str(item.spec.id),"prior":melee_score(item,distance),"item":item})
 if actor.velocity.y>3 and actor.stamina>=30:
  options.append({"action":"air/flip","prior":1.7 if distance<2 else 1.1})
  options.append({"action":"air/twist","prior":1.3 if distance<2 else 0.9})
 var selected:Dictionary=options[0]
 if policy!=null:
  selected=policy.pick(actor,options);policy.begin(actor,selected,options,world.elapsed)
 else:
  var best:=-INF
  for option in options:
   var score:float=float(option.prior)*rng.randf_range(0.75,1.25)
   if score>best:best=score;selected=option
 if selected.has("item"):
  if cast(selected.item,"Airborne attack"):
   air_action_used=true
   world.events.append({"time":world.elapsed,"event":"cpu_air_attack","team":actor.team,"spell":selected.item.spec.id,"height":actor.global_position.y-world.ground_height(actor.global_position)})
 elif str(selected.action) in ["air/flip","air/twist"]:
  var trick:="Flip" if str(selected.action)=="air/flip" else "Twist"
  if actor.start_air_trick(trick):
   air_action_used=true;note(trick,"Airborne reposition")
   world.events.append({"time":world.elapsed,"event":"cpu_air_trick","team":actor.team,"trick":trick})
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
   apex=float(enemy.practice_spell_animation.get("contact_progress",apex))
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
  if str(threat.kind)=="melee" and rng.randf()<0.35 and jump("Jump away from the incoming strike"):
   defense_left=0.4;return true
  if dash(2 if rng.randf()<0.5 else 6):
   note("Evade","Too late to parry");defense_left=0.4;return true
 return false
func try_combo(allow_hesitation:bool=true)->bool:
 if str(actor.current_spell.get("effect",""))!="touch" or not actor.did_release:return false
 if combo_checked or combo_count>=2 or actor.cast_time<actor.mode_length*Combo.link_progress(actor.practice_spell_animation):return false
 if actor.cast_time>actor.mode_length*0.90:return false
 var choices:Array[Dictionary]=[]
 for item in loadout:
  if item.kind!="melee" or not can_use(item,16.0) or actor.flat_distance()>float(item.range):continue
  choices.append(item)
 if choices.is_empty():return false
 if policy==null and allow_hesitation and deception.cooldown<=0 and actor.rival.self_barrier.active() and rng.randf()<0.35:
  deception.begin_hesitation();return true
 combo_checked=true
 var next:Dictionary=choices[0]
 var best:=-INF
 for item in choices:
  var score:=combo_score(item)*rng.randf_range(0.9,1.1)
  if score>best:best=score;next=item
 if policy!=null:
  var options:Array[Dictionary]=[{"action":"combo/stop","prior":0.5}]
  if allow_hesitation and deception.cooldown<=0:
   options.append({"action":"combo/hesitate","prior":3.2 if actor.rival.self_barrier.can_parry() else 1.2})
  for item in choices:options.append({"action":"combo/"+str(item.spec.id),"prior":combo_score(item),"item":item})
  var selected:Dictionary=policy.pick(actor,options)
  policy.begin(actor,selected,options,world.elapsed)
  if str(selected.action)=="combo/stop":return false
  if str(selected.action)=="combo/hesitate":
   combo_checked=false;deception.begin_hesitation();return true
  next=selected.item
 var previous:=str(actor.current_spell.get("name","Touch"))
 if not actor.chain_touch_cast(next.spec,next.profile,actor.rival):return false
 combo_count+=1;combo_checked=false
 note(str(next.title),"Combo from "+previous)
 world.events.append({"time":world.elapsed,"event":"cpu_combo","team":actor.team,"from":previous,"to":next.title})
 return true
func adaptive_decision(distance:float,choices:Array[Dictionary],scores:Array[float])->bool:
 var options:Array[Dictionary]=[]
 var closing:bool=world.has_method("time_remaining") and world.time_remaining()<=10.0
 var protect_lead:bool=closing and actor.health>actor.rival.health
 for i in choices.size():
  var tempo:=0.65 if protect_lead else (1.2 if closing else 1.0)
  options.append({"action":"cast/"+str(choices[i].spec.id),"prior":scores[i]*tempo,"item":choices[i]})
 options.append({"action":"move/strafe","prior":2.5 if protect_lead else 0.4})
 if distance>0.56:
  var inside:bool=not protect_lead and distance<1.6 and actor.stamina>40 and actor.rival.mode!="cast"
  options.append({"action":"move/approach","prior":4.0+aggression if inside else (0.9 if distance<3 else 0.35)})
 if distance<4.5:options.append({"action":"move/retreat","prior":4.5 if protect_lead else (0.7 if actor.stamina<45 else 0.2)})
 if distance>3.5 and actor.stamina>55:options.append({"action":"move/chase","prior":0.2 if protect_lead else (2.0 if closing else (1.2 if aggression>0.6 else 0.6))})
 if distance>2 and distance<7 and actor.stamina>55 and defense_left<=0:options.append({"action":"move/dash","prior":0.5})
 if distance>1.6 and distance<9 and can_jump():
  var jump_score:=3.0+(0.6 if actor.drive_velocity.length()>2 else 0.0)+(0.5 if actor.rival.mode=="cast" else 0.0)
  options.append({"action":"move/jump","prior":jump_score})
 var feint:Dictionary=deception.feint_source()
 if not feint.is_empty():options.append({"action":"tactic/feint","prior":4.6+aggression,"feint":feint})
 var selected:Dictionary=policy.pick(actor,options)
 policy.begin(actor,selected,options,world.elapsed)
 if selected.has("item"):return cast(selected.item,"Learned attack choice")
 if selected.has("feint"):return deception.begin_feint(selected.feint)
 var kind:=str(selected.action).trim_prefix("move/")
 if kind=="jump":return jump("Change elevation / airborne opening")
 if kind=="dash":
  if dash(0):note("Dash in","Learned movement choice");defense_left=1.2;return true
  return false
 move(kind,"Learned movement choice");action_left=0.45
 return true
func step(delta:float)->void:
 if not world.round_active or actor.health<=0:return
 # Reassess immediately when a physical flinch ends, without an extra think delay.
 if actor.mode=="hit":think_left=0.0
 defense_left=maxf(0.0,defense_left-delta);action_left=maxf(0.0,action_left-delta);jump_cooldown=maxf(0.0,jump_cooldown-delta)
 if actor.damage_dealt>last_progress+0.1:last_progress=actor.damage_dealt;stale_time=0.0
 else:stale_time+=delta
 if actor.combat_reaction_active() or actor.mode in ["motion_dash","takeoff","air_trick","land"]:return
 var threat:=incoming()
 if defend(threat):return
 if actor.mode=="air":air_step(delta);return
 if deception.step(delta):return
 if actor.mode=="cast":
  var direction:Vector3=actor.rival.global_position-actor.global_position;direction.y=0.0
  actor.set_cast_movement(direction.normalized()*clampf((actor.flat_distance()-0.55)*0.5,0.0,0.25) if str(actor.current_spell.get("effect",""))=="touch" and actor.touch_parry_recovery<=0.0 else Vector3.ZERO)
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
 if policy==null and distance>1.6 and distance<9 and can_jump() and rng.randf()<0.20 and jump("Change elevation / airborne opening"):return
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
   score=projectile_score(item,distance)
  if score>0:
   choices.append(item);scores.append(score*rng.randf_range(0.6,1.4))
 if policy!=null:
  adaptive_decision(distance,choices,scores)
  return
 if not choices.is_empty():
  var feint:Dictionary=deception.feint_source()
  if not feint.is_empty() and rng.randf()<0.20 and deception.begin_feint(feint):return
  if distance>0.78 and distance<1.6 and actor.stamina>40 and actor.rival.mode!="cast" and rng.randf()<0.35:
   move("approach","Work into punching range");action_left=0.2;return
  var best:=0
  for i in scores.size():if scores[i]>scores[best]:best=i
  if cast(choices[best],"Close contact" if distance<1.8 else "Ranged opening"):return
 if distance>3.5 and actor.stamina>55:
  if distance<7.0 and defense_left<=0 and rng.randf()<0.15 and dash(0):
   note("Dash in","Close the gap");defense_left=1.2;return
  move("chase","Pressure at range")
 elif distance>0.85:move("approach","Find contact range")
 elif stale_time>4.0:move("retreat","Create a new angle")
 else:move("strafe","Find an opening")
