extends RefCounted
## Red-only fire palette. Legacy IDs remain stable for saved appearances.
const PRESETS=[{"id":"ember","title":"Red","color":Color("e62917"),"accent":Color("ff5945")}]
static func colors(_appearance:Dictionary={}) -> Dictionary:
 # No colour variants: all fire presets use the same red.
 return PRESETS[0]
static func legacy_structure(id:String) -> int:
 return maxi(0,["ember","gold","crimson","white","blue","violet","green","rose"].find(id.get_slice("_",id.get_slice_count("_")-1)))
