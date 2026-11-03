extends RefCounted
## Swept opposing-projectile contacts, ordered by first contact within the step.
const EPSILON:=0.0001
static func contact_time(a:Dictionary,b:Dictionary,delta:float)->float:
 var relative:Vector3=a.node.position-b.node.position
 var movement:Vector3=(a.velocity-b.velocity)*delta
 var radius:float=float(a.radius)+float(b.radius)
 var c:=relative.length_squared()-radius*radius
 if c<=0:return 0.0
 var aa:=movement.length_squared()
 if aa<EPSILON*EPSILON:return -1.0
 var bb:=2.0*relative.dot(movement)
 var discriminant:=bb*bb-4.0*aa*c
 if discriminant<0:return -1.0
 var time:=(-bb-sqrt(discriminant))/(2.0*aa)
 return time if time>=0.0 and time<=1.0 else -1.0
static func travel_limit(field:Node,shot:Dictionary,delta:float)->float:
 var movement:Vector3=shot.velocity*delta
 if movement.length_squared()<EPSILON*EPSILON:return 1.0
 var origin:Vector3=shot.node.position
 var hit:Dictionary=field.projectile_impact_predictor.predict(field,shot.caster,origin,origin+movement,float(shot.radius),shot.spec)
 return clampf(origin.distance_to(hit.get("center",origin+movement))/movement.length(),0.0,1.0) if hit.hit else 1.0
static func reduce(shot:Dictionary,remaining:float,previous:float)->void:
 var fraction:=remaining/maxf(EPSILON,previous)
 shot.spec=preload("res://scripts/combat_spec.gd").copy(shot.spec)
 shot.spec["damage"]=remaining;shot.spec["physical_damage"]=remaining
 for field in ["potency","motion_damage","charge"]:
  if shot.spec.has(field):shot.spec[field]=float(shot.spec[field])*fraction
 shot.mass=float(shot.mass)*fraction
 if shot.spec.has("mass"):shot.spec.mass=shot.mass
 shot.spec["clash_power_fraction"]=float(shot.spec.get("clash_power_fraction",1.0))*fraction
static func resolve(field:Node,delta:float)->void:
 if delta<=0.0 or field.shots.size()<2 or not field.round_active:return
 var candidates:Array[Dictionary]=[]
 for i in field.shots.size():
  var a:Dictionary=field.shots[i]
  if not is_instance_valid(a.node):continue
  for j in range(i+1,field.shots.size()):
   var b:Dictionary=field.shots[j]
   if not is_instance_valid(b.node) or a.caster.team==b.caster.team:continue
   var time:=contact_time(a,b,delta)
   if time<0:continue
   if float(a.age)+delta*time>float(a.get("max_age",2.2)) or float(b.age)+delta*time>float(b.get("max_age",2.2)):continue
   candidates.append({"a":a,"b":b,"time":time,"tie":mini(int(a.id),int(b.id)),"tie2":maxi(int(a.id),int(b.id))})
 candidates.sort_custom(func(a,b):
  if a.time!=b.time:return a.time<b.time
  return a.tie<b.tie if a.tie!=b.tie else a.tie2<b.tie2)
 var consumed:Dictionary={};var limits:Dictionary={}
 for candidate in candidates:
  var a:Dictionary=candidate.a;var b:Dictionary=candidate.b
  if consumed.has(a.id) or consumed.has(b.id):continue
  if not limits.has(a.id):limits[a.id]=travel_limit(field,a,delta)
  if not limits.has(b.id):limits[b.id]=travel_limit(field,b,delta)
  # A wall, body, shield or water surface already in the path gets hit first.
  if float(candidate.time)>float(limits[a.id])+EPSILON or float(candidate.time)>float(limits[b.id])+EPSILON:continue
  var first:float=maxf(0.0,field.damage_for(a.spec));var second:float=maxf(0.0,field.damage_for(b.spec))
  var difference:=first-second;var survivor:=-1
  if absf(difference)<=EPSILON:consumed[a.id]=true;consumed[b.id]=true
  elif difference>0:consumed[b.id]=true;reduce(a,difference,first);survivor=int(a.id)
  else:consumed[a.id]=true;reduce(b,-difference,second);survivor=int(b.id)
  var first_point:Vector3=a.node.position+a.velocity*delta*float(candidate.time)
  var second_point:Vector3=b.node.position+b.velocity*delta*float(candidate.time)
  var point:Vector3=first_point.lerp(second_point,float(a.radius)/maxf(EPSILON,float(a.radius)+float(b.radius)))
  field.projectile_clash_feedback(point,{"first":a.id,"second":b.id,"first_damage":first,"second_damage":second,"remaining_damage":absf(difference) if survivor>=0 else 0.0,"survivor":survivor,"first_element":a.spec.get("projectile_element","None"),"second_element":b.spec.get("projectile_element","None")})
 for i in range(field.shots.size()-1,-1,-1):
  if consumed.has(field.shots[i].id):
   field.shots[i].node.queue_free();field.shots.remove_at(i)
