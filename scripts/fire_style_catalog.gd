extends RefCounted
## Visual-only styles; selecting one never changes combat stats or hitboxes.
const Appearance=preload("res://scripts/spell_appearance.gd")
const TEXTURES=["flame_01","flame_02","flame_03","flame_04","flame_05","flame_06","fire_01","fire_02"]
static var cached:Array[Dictionary]=[]
static func entries() -> Array[Dictionary]:
 if not cached.is_empty():return cached
 for texture in TEXTURES:
  cached.append({"id":texture,"title":texture.replace("_"," ").capitalize(),"shape":"Flame","texture":texture})
 for shape in Appearance.SHAPES:
  if shape in ["Element style","Drawn","Flame"]:continue
  cached.append({"id":"shape_"+shape.to_lower(),"title":shape,"shape":shape,"texture":"Element style"})
 return cached
static func find(id:String) -> Dictionary:
 for entry in entries():
  if entry.id==id:return entry
 return {}
static func look(id:String,custom:Dictionary={}) -> Dictionary:
 var result:=custom.duplicate(true)
 var entry:=find(id)
 if entry.is_empty():return result
 result.erase("preset")
 result.shape=entry.shape;result.texture=entry.texture;result.fire_style_id=id
 return result
static func active_id(custom:Dictionary) -> String:
 var current:=Appearance.settings("Fire",custom)
 if current.shape=="Flame":
  var texture:String="flame_04" if current.texture=="Element style" else str(current.texture)
  return texture if texture in TEXTURES else ""
 var id:="shape_"+str(current.shape).to_lower()
 return id if not find(id).is_empty() else ""
