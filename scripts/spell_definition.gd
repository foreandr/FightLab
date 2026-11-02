extends RefCounted
## A spell is an element asset + allocation, independent of any demonstration cast.
const Assets=preload("res://scripts/spell_asset_library.gd")
const Provenance=preload("res://scripts/asset_provenance.gd")
const KEYS:=["schema","id","name","delivery_type","element","allocation","appearance","provenance","metadata"]
static func make(element:String,delivery:String,mix:Dictionary,look:Dictionary,parent:Dictionary={})->Dictionary:
 var appearance:Dictionary={}
 if element=="Fire":
  var library:=Assets.for_element(element)
  appearance={"fire_style_id":library.Styles.active_id(look),"sound_id":library.sound(str(look.get("sound_id","")))}
 return {"schema":1,"delivery_type":delivery,"element":element,"allocation":preload("res://scripts/projectile_allocation.gd").normalize(mix,element!="None"),"appearance":appearance,"provenance":parent.duplicate(true)}
static func error(record:Dictionary)->String:
 for key in record:
  if key not in KEYS:return "Unsupported saved field: "+str(key)
 if int(record.get("schema",0))!=1:return "Unsupported spell version"
 if str(record.get("delivery_type",""))!="Projectile":return "Only Projectile spells are available yet"
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
static func compile(record:Dictionary,animation:Dictionary,binding:Dictionary)->Dictionary:
 if not error(record).is_empty():return {}
 var seconds:=float(animation.get("duration",0.0))
 if not is_finite(seconds) or seconds<=0.0:return {}
 var rules=preload("res://scripts/combat_spell_rules.gd")
 var base:Dictionary=rules.allocate(rules.projectile_base(record.element),record.allocation,record.element,1.0)
 base["delivery_type"]=record.delivery_type
 base["animation_type"]=preload("res://scripts/animation_cast_type.gd").kind(animation)
 base["appearance"]=Assets.for_element("Fire").selection(record.appearance.fire_style_id,record.appearance.sound_id) if record.element=="Fire" else {}
 base["sound_id"]=Assets.sound_for({"element":record.element,"appearance":base.appearance})
 base["name"]=record.get("name","Spell")
 base["spell_definition_id"]=record.get("id","")
 base["provenance"]=record.provenance
 base["spell_metadata"]=record.get("metadata",metadata_for(record)).duplicate(true)
 var spec:Dictionary=rules.author(base,seconds,float(binding.get("release",0.3)),str(animation.get("group","Attack"))=="Attack")
 spec["hand"]=str(binding.get("hand",animation.get("attack_bone","hand_r")))
 return spec
