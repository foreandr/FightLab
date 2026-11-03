extends RefCounted
## Tabular semi-Markov Q-learning over legal authored combat actions.
## Expert reflexes and shared combat rules remain outside this learned policy.
const WIN_REWARD:=20.0
const LOSS_REWARD:=-20.0
const DRAW_REWARD:=-5.0
var model:Dictionary={}
var learning:=true
var epsilon:=0.06
var rng:=RandomNumberGenerator.new()
var pending:Dictionary={}
var updates:=0
func configure(table:Dictionary,seed_:int,train:bool=true,explore:float=0.06)->void:
 model=table;rng.seed=seed_;learning=train;epsilon=clampf(explore,0,1) if train else 0.0
func state(actor:CharacterBody3D)->String:
 var distance:float=actor.flat_distance()
 var range_bucket:=0 if distance<=1.2 else (1 if distance<=3.0 else (2 if distance<=8.0 else 3))
 var stamina:=0 if actor.stamina<25 else (1 if actor.stamina<60 else 2)
 var mana:=0 if actor.mana<15 else (1 if actor.mana<40 else 2)
 var health:=0 if actor.health<actor.MAX_HEALTH*0.33 else (1 if actor.health<actor.MAX_HEALTH*0.66 else 2)
 var enemy_health:=0 if actor.rival.health<actor.rival.MAX_HEALTH*0.33 else (1 if actor.rival.health<actor.rival.MAX_HEALTH*0.66 else 2)
 return "%d:%d:%d:%d:%d:%d:%d"%[range_bucket,stamina,mana,health,enemy_health,1 if actor.rival.mode=="cast" else 0,1 if actor.rival.self_barrier.active() else 0]
func value(context:String,action:String,prior:float)->float:
 return float(model.get(context,{}).get(action,{}).get("q",prior))
func pick(actor:CharacterBody3D,options:Array[Dictionary])->Dictionary:
 assert(not options.is_empty())
 if learning and rng.randf()<epsilon:return options[rng.randi_range(0,options.size()-1)]
 var context:=state(actor);var best:=0;var score:=-INF
 for i in options.size():
  var q:=value(context,str(options[i].action),float(options[i].prior))
  if q>score:score=q;best=i
 return options[best]
func snapshot(actor:CharacterBody3D,time:float)->Dictionary:
 return {"damage":actor.damage_dealt,"taken":actor.damage_taken,"mana":actor.mana_spent,"stamina":actor.stamina_spent,"time":time}
func reward(actor:CharacterBody3D,time:float)->float:
 if pending.is_empty():return 0.0
 var old:Dictionary=pending.observation
 # Positive for damage advantage, small actual-spend/time penalties, large match outcome.
 return (actor.damage_dealt-float(old.damage)-actor.damage_taken+float(old.taken))*0.1-maxf(0,actor.mana_spent-float(old.mana))*0.003-maxf(0,actor.stamina_spent-float(old.stamina))*0.002-maxf(0,time-float(old.time))*0.015
func update(actor:CharacterBody3D,time:float,next_value:float,terminal_bonus:float=0.0,terminal:bool=false)->void:
 if not learning or pending.is_empty():return
 var context:String=pending.state;var action:String=pending.action
 if not model.has(context):model[context]={}
 var entry:Dictionary=model[context].get(action,{"q":pending.prior,"n":0})
 var seconds:=maxf(0.0,time-float(pending.observation.time))
 var target:=reward(actor,time)+terminal_bonus+(0.0 if terminal else pow(0.97,seconds)*next_value)
 var alpha:=0.12/sqrt(1.0+float(entry.n)*0.02)
 entry.q=clampf(float(entry.q)+alpha*(target-float(entry.q)),-100.0,100.0)
 entry.n=int(entry.n)+1;model[context][action]=entry;updates+=1
func begin(actor:CharacterBody3D,option:Dictionary,options:Array[Dictionary],time:float)->void:
 if not learning:return
 var context:=state(actor);var best:=-INF
 for next in options:best=maxf(best,value(context,str(next.action),float(next.prior)))
 update(actor,time,best if is_finite(best) else 0.0)
 pending={"state":context,"action":str(option.action),"prior":float(option.prior),"observation":snapshot(actor,time)}
func finish(actor:CharacterBody3D,winner:int,time:float)->void:
 update(actor,time,0.0,DRAW_REWARD if winner<0 else (WIN_REWARD if winner==actor.team else LOSS_REWARD),true)
 pending={}
