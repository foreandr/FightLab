extends RefCounted
## Resolve assets by element, never by projectile/touch/beam/barrier delivery.
const LIBRARIES:={"Fire":"res://assets/spells/fire/library.gd"}
static func for_element(element:String)->GDScript:
 return load(LIBRARIES[element]) if LIBRARIES.has(element) else null
static func element_of(spec:Dictionary)->String:
 return str(spec.get("element",spec.get("projectile_element","None")))
static func for_spell(spec:Dictionary)->GDScript:
 return for_element(element_of(spec))
static func sound_for(spec:Dictionary)->String:
 var library:=for_spell(spec)
 if library==null:return "dash"
 return library.sound(str(spec.get("sound_id",spec.get("appearance",{}).get("sound_id",""))))
