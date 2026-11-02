extends RefCounted
## Cosmetic presets built from the existing masks, silhouettes and palettes.
const Appearance=preload("res://scripts/spell_appearance.gd")
const TEXTURES=["flame_01","flame_02","flame_03","flame_04","flame_05","flame_06","fire_01","fire_02"]
const FORM_DEFAULTS={"flame_width":1.0,"flame_height":1.0,"flame_tongues":1,"flame_bend":0.0,"flame_turbulence":1.0,"flame_flow":1.0}
const FORMS=[
 {"id":"natural","title":"Natural"},
 {"id":"needle","title":"Needle","flame_width":0.45,"flame_turbulence":0.65,"flame_flow":1.15},
 {"id":"fan","title":"Fan","flame_height":0.65,"flame_turbulence":1.1,"flame_flow":0.8},
 {"id":"twins","title":"Twins","flame_tongues":2,"flame_turbulence":0.9},
 {"id":"crown","title":"Crown","flame_height":0.9,"flame_tongues":3,"flame_turbulence":1.1},
 {"id":"curl","title":"Curl","flame_width":0.85,"flame_bend":0.18,"flame_turbulence":1.3,"flame_flow":0.9},
 {"id":"crooked","title":"Crooked","flame_width":0.9,"flame_height":0.95,"flame_bend":-0.18,"flame_turbulence":1.15,"flame_flow":1.1},
 {"id":"wild","title":"Wild","flame_bend":0.05,"flame_turbulence":2.2,"flame_flow":1.8}]
const PALETTES=[
 {"id":"ember","title":"Ember","color":Color("ff641b"),"accent":Color("fff0a0")},
 {"id":"gold","title":"Gold","color":Color("ffb51e"),"accent":Color("fff6cc")},
 {"id":"crimson","title":"Crimson","color":Color("e62316"),"accent":Color("ffc471")},
 {"id":"white","title":"White","color":Color("ffb17b"),"accent":Color("ffffff")},
 {"id":"blue","title":"Blue","color":Color("228bff"),"accent":Color("d9f7ff")},
 {"id":"violet","title":"Violet","color":Color("9c3dff"),"accent":Color("ffe1ff")},
 {"id":"green","title":"Green","color":Color("20ca69"),"accent":Color("d5ffb0")},
 {"id":"rose","title":"Rose","color":Color("ff3c82"),"accent":Color("ffe1bd")}]
static var cached:Array[Dictionary]=[]
static var by_id:Dictionary={}
static func _add(entry:Dictionary) -> void:
 cached.append(entry);by_id[entry.id]=entry
static func entries() -> Array[Dictionary]:
 if not cached.is_empty():return cached
 for texture in TEXTURES:
  _add({"id":texture,"title":texture.replace("_"," ").capitalize(),"shape":"Flame","texture":texture})
 for shape in Appearance.SHAPES:
  if shape in ["Element style","Drawn","Flame"]:continue
  _add({"id":"shape_"+shape.to_lower(),"title":shape,"shape":shape,"texture":"Element style"})
 for texture in TEXTURES:
  for form in FORMS:
   for palette in PALETTES:
    if form.id=="natural" and palette.id=="ember":continue
    var entry:Dictionary={"id":"style_%s_%s_%s"%[texture,form.id,palette.id],"title":"%s %s %s"%[palette.title,form.title,texture.replace("flame_","F").replace("fire_","B")],"shape":"Flame","texture":texture,"color":palette.color,"accent":palette.accent}
    for key in FORM_DEFAULTS:entry[key]=form.get(key,FORM_DEFAULTS[key])
    _add(entry)
 return cached
static func find(id:String) -> Dictionary:
 entries()
 return by_id.get(id,{})
static func look(id:String,custom:Dictionary={}) -> Dictionary:
 var result:=custom.duplicate(true)
 var entry:=find(id)
 if entry.is_empty():return result
 result.erase("preset")
 result.merge(FORM_DEFAULTS,true)
 for key in entry:
  if key not in ["id","title"]:result[key]=entry[key]
 result.fire_style_id=id
 return result
static func _same(a:Variant,b:Variant) -> bool:
 if a is Color and b is Color:return a.is_equal_approx(b)
 if a is float or b is float:return is_equal_approx(float(a),float(b))
 return a==b
static func active_id(custom:Dictionary) -> String:
 var current:=Appearance.settings("Fire",custom)
 var saved:=str(current.get("fire_style_id",""))
 var entry:=find(saved)
 if not entry.is_empty():
  var matches:=true
  for key in entry:
   if key in ["id","title"]:continue
   if not _same(current.get(key,FORM_DEFAULTS.get(key)),entry[key]):matches=false;break
  for key in FORM_DEFAULTS:
   if not _same(current.get(key,FORM_DEFAULTS[key]),entry.get(key,FORM_DEFAULTS[key])):matches=false;break
  if matches:return saved
 for key in FORM_DEFAULTS:
  if not _same(current.get(key,FORM_DEFAULTS[key]),FORM_DEFAULTS[key]):return ""
 if current.shape=="Flame":
  var texture:String="flame_04" if current.texture=="Element style" else str(current.texture)
  return texture if texture in TEXTURES else ""
 var id:="shape_"+str(current.shape).to_lower()
 return id if not find(id).is_empty() else ""
