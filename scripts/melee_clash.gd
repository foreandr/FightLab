extends RefCounted
## Simultaneous swept striking volumes, resolved before passive hurtboxes.
const Contact=preload("res://scripts/melee_contact.gd")
const STAMINA_COST:=2.0
static func contact_time(a0:Vector3,a1:Vector3,ar:float,b0:Vector3,b1:Vector3,br:float)->float:
 var offset:=a0-b0;var motion:Vector3=(a1-a0)-(b1-b0)
 var c:=offset.length_squared()-pow(ar+br,2)
 if c<=0.0:return 0.0
 var aa:=motion.length_squared();var bb:=2.0*offset.dot(motion)
 if aa<0.00000001 or bb>=0.0:return -1.0
 var discriminant:=bb*bb-4.0*aa*c
 if discriminant<0.0:return -1.0
 var t:=(-bb-sqrt(discriminant))/(2.0*aa)
 return t if t>=0.0 and t<=1.0 else -1.0
static func collect(runtime:RefCounted,delta:float)->Array[Dictionary]:
 var strikes:Array[Dictionary]=[]
 for contact in runtime.touch_casts.values():
  var a=contact.actor.get_ref()
  if not is_instance_valid(a) or a.mode!=contact.mode or contact.connected:continue
  for bone in contact.previous:
   strikes.append({"actor":a,"source":contact,"kind":"touch","bone":str(bone),"id":str(contact.spec.get("id","touch")),"clock":0.5,"begin":0.0,"end":1.0,"previous":contact.previous[bone],"limb":a.bone_point(bone),"radius":Contact.radius_for(str(bone)),"min_speed":0.0,"forward":a.global_basis.z})
 for a in runtime.field.fighters:
  if a.mode=="punch" and a.get("melee_spec") is Array and not a.melee_spec.is_empty() and not a.melee_connected:
   var spec:Array=a.melee_spec;var bone:=str(spec[2])
   strikes.append({"actor":a,"source":{},"kind":"native","bone":bone,"id":str(spec[0]),"clock":a.melee_clock,"begin":spec[3],"end":spec[4],"previous":a.melee_previous,"limb":a.bone_point(bone),"radius":Contact.radius_for(bone,0.105),"forward":a.global_basis.z})
  if a.get("story_strikes") is Dictionary:
   for channel in a.story_strikes:
    var strike:Dictionary=a.story_strikes[channel];var spec:Array=strike.spec
    if strike.connected:continue
    strikes.append({"actor":a,"source":strike,"kind":"story","bone":str(spec[2]),"id":str(spec[0]),"clock":float(strike.clock)+delta*float(strike.rate),"begin":spec[3],"end":spec[4],"previous":strike.previous,"limb":a.bone_point(str(spec[2])),"radius":Contact.radius_for(str(spec[2]),0.105),"require_forward":true,"forward":strike.get("aim_direction",a.global_basis.z)})
 return strikes.filter(func(s):return Contact.active(s.actor,s,delta))
static func consumed(s:Dictionary)->bool:
 return bool(s.actor.melee_connected) if s.kind=="native" else bool(s.source.get("connected",false))
static func consume(s:Dictionary)->void:
 if s.kind=="native":s.actor.melee_connected=true
 else:s.source.connected=true
static func resolve(runtime:RefCounted,delta:float)->void:
 if not runtime.field.round_active:return
 var strikes:=collect(runtime,delta);var candidates:Array[Dictionary]=[]
 for i in strikes.size():
  for j in range(i+1,strikes.size()):
   var a:Dictionary=strikes[i];var b:Dictionary=strikes[j]
   if a.actor==b.actor or a.actor.team==b.actor.team:continue
   var t:=contact_time(a.previous,a.limb,a.radius,b.previous,b.limb,b.radius)
   if t>=0.0:candidates.append({"a":a,"b":b,"time":t})
 candidates.sort_custom(func(a,b):return float(a.time)<float(b.time))
 for hit in candidates:
  var a:Dictionary=hit.a;var b:Dictionary=hit.b
  if consumed(a) or consumed(b):continue
  if Contact.body_before(a.actor,a,b.actor,b.bone,hit.time) or Contact.body_before(b.actor,b,a.actor,a.bone,hit.time):continue
  consume(a);consume(b)
  var point:Vector3=(Vector3(a.previous).lerp(a.limb,hit.time)+Vector3(b.previous).lerp(b.limb,hit.time))*0.5
  var away:Vector3=a.actor.global_position-b.actor.global_position;away.y=0.0
  away=away.normalized() if away.length_squared()>0.0001 else Vector3.RIGHT
  var spent:Array[float]=[]
  for pair in [[a,away],[b,-away]]:
   var s:Dictionary=pair[0];var actor=s.actor;var before:float=actor.stamina
   actor.spend_stamina(minf(STAMINA_COST,actor.stamina))
   spent.append(maxf(0.0,before-actor.stamina))
   if actor.has_method("receive_melee_clash"):actor.receive_melee_clash(point,s.bone,pair[1])
  var field=runtime.field
  field.events.append({"event":"melee_clash","time":field.elapsed,"a":a.actor.team,"b":b.actor.team,"a_spell":a.id,"b_spell":b.id,"a_bone":a.bone,"b_bone":b.bone,"a_stamina":spent[0],"b_stamina":spent[1],"point":str(point)})
  if is_instance_valid(field.vfx):field.vfx.physical_contact(point)
  field.combat_sound("shield",point,0.8)
