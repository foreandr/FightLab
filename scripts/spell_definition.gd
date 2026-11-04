extends RefCounted
## A spell is an element asset + allocation, independent of any demonstration cast.
const Assets=preload("res://scripts/spell_asset_library.gd")
const Provenance=preload("res://scripts/asset_provenance.gd")
const KEYS:=["schema","id","name","delivery_type","element","allocation","appearance","provenance","metadata","barrier"]
static func make(element:String,delivery:String,mix:Dictionary,look:Dictionary,parent:Dictionary={})->Dictionary:
 var appearance:Dictionary={}
 if element=="Fire":
  var library:=Assets.for_element(element)
  appearance={"fire_style_id":library.Styles.active_id(look),"sound_id":library.sound(str(look.get("sound_id","")))}
 var record:Dictionary={"schema":1,"delivery_type":delivery,"element":element,"allocation":preload("res://scripts/projectile_allocation.gd").normalize(mix,element!="None"),"appearance":appearance,"provenance":parent.duplicate(true)}
 if delivery=="Barrier":record["barrier"]={"kind":"Shield","attachment":"Self","strength":10.0,"duration":1.0}
 return record
static func error(record:Dictionary)->String:
 for key in record:
  if key not in KEYS:return "Unsupported saved field: "+str(key)
 if int(record.get("schema",0))!=1:return "Unsupported spell version"
 if str(record.get("delivery_type","")) not in ["Projectile","Touch","Barrier"]:return "Choose an available spell type"
 if record.delivery_type=="Barrier":
  var shield:Variant=record.get("barrier",{})
  if not shield is Dictionary or shield.get("kind","")!="Shield" or shield.get("attachment","")!="Self" or record.get("element","")!="None":return "Only Self Shield barriers are available"
  for key in shield:
   if key not in ["kind","attachment","strength","duration"]:return "Unsupported shield field"
  for key in ["strength","duration"]:
   var value:Variant=shield.get(key)
   if not (value is float or value is int) or not is_finite(float(value)) or float(value)<=0.0 or float(value)>(100.0 if key=="strength" else 30.0):return "Invalid shield "+key
 elif record.has("barrier"):return "Barrier settings require a Barrier spell"
 if str(record.get("element","")) not in ["None","Fire"]:return "Choose an available effect"
 if not record.get("allocation") is Dictionary or not record.get("appearance") is Dictionary or not record.get("provenance") is Dictionary:return "Invalid spell data"
 if record.has("metadata"):
  if not record.metadata is Dictionary:return "Invalid spell metadata"
  for key in ["creator","created_utc","name"]:
   if not record.metadata.get(key) is String:return "Invalid spell metadata"
  if record.has("name") and record.metadata.name!=record.name:return "Spell name and metadata differ"
 var mix:Dictionary=record.allocation
 var keys:Array=["size","speed"]+(["effect"] if record.element!="None" else [])
 for key in mix:
  if key not in keys:return "Unsupported allocation field"
 for key in record.appearance:
  if key not in ["fire_style_id","sound_id"]:return "Unsupported appearance field"
 var total:=0.0
 for key in keys:
  if not (mix.get(key) is float or mix.get(key) is int):return "Invalid power distribution"
  var value:=float(mix.get(key,-1))
  if not is_finite(value) or value<0 or value>1:return "Invalid power distribution"
  total+=value
 if not is_equal_approx(total,1.0):return "Power distribution must add up to 100%"
 if record.element=="Fire":
  var library:=Assets.for_element("Fire")
  if library.Styles.find(str(record.appearance.get("fire_style_id",""))).is_empty():return "Confirm a fire style"
  if library.Sounds.find(str(record.appearance.get("sound_id",""))).is_empty():return "Confirm a fire sound"
 return ""
static func metadata_for(record:Dictionary)->Dictionary:
 var graph:Dictionary=record.get("provenance",{})
 var head:Dictionary=graph.get("nodes",{}).get(str(graph.get("head","")),{})
 var created:=str(head.get("created_utc",""))
 if not created.is_empty() and not created.ends_with("Z"):created+="Z"
 return {"creator":str(head.get("author","")),"created_utc":created,"name":str(record.get("name",head.get("title","")))}
static func credit(record:Dictionary,name:String)->Dictionary:
 var parents:Array=[]
 if not record.get("provenance",{}).is_empty():parents.append(record.provenance)
 if record.element=="Fire":
  var library:=Assets.for_element("Fire")
  for asset in [library.Styles.find(record.appearance.fire_style_id),library.Sounds.find(record.appearance.sound_id)]:
   asset=asset.duplicate(true)
   if not asset.has("author") and (str(asset.get("texture","")).begins_with("flame_") or str(asset.get("texture","")).begins_with("fire_")):
    asset.merge({"author":"Kenney","source":"https://kenney.nl/assets/particle-pack","license":"CC0-1.0"},true)
   var id:="source:spell_asset:"+str(asset.id)
   parents.append({"schema":1,"head":id,"nodes":{id:{"id":id,"asset_type":"spell asset","operation":"original source","title":asset.title,"author":asset.get("author","foreandr"),"parents":[],"citations":[{"author":asset.get("author","foreandr"),"url":asset.get("source",""),"license":asset.get("license","FightLab original"),"asset_id":asset.id}]}}})
 return Provenance.derive(parents,"spell",name,Provenance.creator_name(),"saved spell definition")
static func base_spec(record:Dictionary,binding:Dictionary={})->Dictionary:
 if not error(record).is_empty():return {}
 var rules=preload("res://scripts/combat_spell_rules.gd")
 var base:Dictionary
 if record.delivery_type=="Touch":
  var contacts:Array=binding.get("contacts",[str(binding.get("hand","hand_r"))])
  if contacts.is_empty():return {}
  for contact in contacts:
   if contact not in rules.TOUCH_CONTACT_BONES:return {}
  base=rules.touch_base(contacts,record.element)
  if record.element=="Fire":base=rules.allocate(base,record.allocation,record.element,1.0)
 elif record.delivery_type=="Barrier":base=rules.self_barrier_base(float(record.barrier.strength),float(record.barrier.duration))
 else:base=rules.allocate(rules.projectile_base(record.element),record.allocation,record.element,1.0)
 base["delivery_type"]=record.delivery_type
 base["appearance"]=Assets.for_element("Fire").selection(record.appearance.fire_style_id,record.appearance.sound_id) if record.element=="Fire" else {}
 base["sound_id"]=Assets.sound_for({"element":record.element,"appearance":base.appearance})
 base["name"]=record.get("name","Spell")
 base["spell_definition_id"]=record.get("id","")
 base["provenance"]=record.provenance.duplicate(true)
 base["spell_metadata"]=record.get("metadata",metadata_for(record)).duplicate(true)
 return base
static func compile(record:Dictionary,animation:Dictionary,binding:Dictionary)->Dictionary:
 var resolved:=binding.duplicate(true)
 resolved["hand"]=str(binding.get("hand",preload("res://scripts/combat_aim.gd").emitter(animation)))
 var base:=base_spec(record,resolved)
 if base.is_empty():return {}
 var seconds:=float(animation.get("duration",0.0))
 if not is_finite(seconds) or seconds<=0.0:return {}
 base["animation_type"]=preload("res://scripts/animation_cast_type.gd").kind(animation)
 if binding.has("hold_seconds"):
  base["cast_charge_time"]=float(binding.hold_seconds)
  var limits:=preload("res://scripts/held_cast_preview.gd").duration_range(animation)
  base["cast_charge_reference_duration"]=maxf(0.1,float(binding.get("charge_reference_duration",(limits.x+limits.y)*0.5)))
  if record.delivery_type=="Touch":base["cast_charge_damage_reference_duration"]=1.0
 var jump:=preload("res://scripts/animation_jump_motion.gd").settings(animation)
 if not jump.is_empty():base["jump_motion"]=jump
 var spec:Dictionary=preload("res://scripts/combat_spell_rules.gd").author(base,seconds,float(binding.get("release",0.3)),record.delivery_type!="Barrier" and str(animation.get("group","Attack"))=="Attack")
 spec["hand"]=resolved.hand
 return spec
