extends RefCounted
## Fire structure, motion and texture presets; colour is deliberately fixed red.
const Appearance=preload("res://scripts/spell_appearance.gd")
const TEXTURES=["flame_01","flame_02","flame_03","flame_04","flame_05","flame_06","fire_01","fire_02"]
const FORM_DEFAULTS={"flame_width":1.0,"flame_height":1.0,"flame_tongues":1,"flame_bend":0.0,"flame_turbulence":1.0,"flame_flow":1.0,"flame_structure":0,"flame_sheet_columns":1,"flame_sheet_rows":1,"flame_sheet_frames":1,"flame_sheet_fps":24.0}
const FORMS=[
 {"id":"natural","title":"Natural"},
 {"id":"needle","title":"Needle","flame_width":0.45,"flame_turbulence":0.65,"flame_flow":1.15},
 {"id":"fan","title":"Fan","flame_height":0.65,"flame_turbulence":1.1,"flame_flow":0.8},
 {"id":"twins","title":"Twins","flame_tongues":2,"flame_turbulence":0.9},
 {"id":"crown","title":"Crown","flame_height":0.9,"flame_tongues":3,"flame_turbulence":1.1},
 {"id":"curl","title":"Curl","flame_width":0.85,"flame_bend":0.18,"flame_turbulence":1.3,"flame_flow":0.9},
 {"id":"crooked","title":"Crooked","flame_width":0.9,"flame_height":0.95,"flame_bend":-0.18,"flame_turbulence":1.15,"flame_flow":1.1},
 {"id":"wild","title":"Wild","flame_bend":0.05,"flame_turbulence":2.2,"flame_flow":1.8}]
# Legacy suffixes preserve saved IDs; these now select structure, never colour.
const STRUCTURES=[
 {"id":"ember","title":"Soft","flame_structure":0},
 {"id":"gold","title":"Hollow","flame_structure":1},
 {"id":"crimson","title":"Torn","flame_structure":2},
 {"id":"white","title":"Spiral","flame_structure":3},
 {"id":"blue","title":"Halo","flame_structure":4},
 {"id":"violet","title":"Forked","flame_structure":5},
 {"id":"green","title":"Cinders","flame_structure":6},
 {"id":"rose","title":"Vortex","flame_structure":7}]
const EXTERNAL=[
 {"id":"ben_fire_01","title":"Dancing flame","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"ben_fire_03","title":"Rolling plume","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"soluna_fire","title":"Billowing jet","author":"Soluna Software","columns":8,"rows":4,"frames":32},
 {"id":"ben_fire_04","title":"Needle plume","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"ben_fire_05","title":"Ragged torch","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"ben_fire_08","title":"Licking flame","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"ben_fire_02","title":"Thin flicker","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"ben_fire_06","title":"Forked plume","author":"Ben Hickling","columns":10,"rows":6,"frames":60},
 {"id":"ben_fire_07","title":"Rising wisp","author":"Ben Hickling","columns":10,"rows":6,"frames":60}]
static var cached:Array[Dictionary]=[]
static var by_id:Dictionary={}
static func _add(entry:Dictionary) -> void:
 cached.append(entry);by_id[entry.id]=entry
static func entries() -> Array[Dictionary]:
 if not cached.is_empty():return cached
 for source in EXTERNAL:
  var entry:Dictionary={"id":source.id,"title":source.title,"shape":"Flame","texture":source.id,"author":source.author,"source":"https://opengameart.org/content/"+("lots-of-game-effects" if source.id=="soluna_fire" else "animated-fire"),"license":"CC0-1.0"}
  entry.merge(FORM_DEFAULTS,false)
  entry.flame_sheet_columns=source.columns;entry.flame_sheet_rows=source.rows;entry.flame_sheet_frames=source.frames
  _add(entry)
 for texture in TEXTURES:
  _add({"id":texture,"title":texture.replace("_"," ").capitalize(),"shape":"Flame","texture":texture})
 for shape in Appearance.SHAPES:
  if shape in ["Element style","Drawn","Flame"]:continue
  _add({"id":"shape_"+shape.to_lower(),"title":shape,"shape":shape,"texture":"Element style"})
 for texture in TEXTURES:
  for form in FORMS:
   for structure in STRUCTURES:
    if form.id=="natural" and structure.id=="ember":continue
    var entry:Dictionary={"id":"style_%s_%s_%s"%[texture,form.id,structure.id],"title":"%s %s %s"%[structure.title,form.title,texture.replace("flame_","F").replace("fire_","B")],"shape":"Flame","texture":texture,"color":preload("res://scripts/fire_palette.gd").PRESETS[0].color,"accent":preload("res://scripts/fire_palette.gd").PRESETS[0].accent}
    for key in FORM_DEFAULTS:entry[key]=form.get(key,FORM_DEFAULTS[key])
    entry.flame_structure=structure.flame_structure
    _add(entry)
 # Lead with visibly different structures rather than near-neighbour variations.
 var featured=["soluna_fire","ben_fire_01","ben_fire_03","style_flame_04_natural_gold","style_flame_04_natural_white","style_flame_04_natural_blue","style_flame_04_natural_violet","style_flame_04_natural_green","style_flame_04_natural_rose","style_flame_04_twins_ember","style_flame_04_crown_ember","style_flame_04_needle_ember"]
 for i in featured.size():
  var entry:Dictionary=by_id[featured[i]]
  cached.erase(entry);cached.insert(i,entry)
 return cached
static func find(id:String) -> Dictionary:
 entries()
 return by_id.get(id,{})
static func look(id:String,custom:Dictionary={}) -> Dictionary:
 var result:=custom.duplicate(true)
 var entry:=find(id)
 if entry.is_empty():return result
 result.erase("preset")
 for key in ["author","source","license"]:result.erase(key)
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
