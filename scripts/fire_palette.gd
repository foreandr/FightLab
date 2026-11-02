extends RefCounted
## Shared warm fire palette. Legacy IDs remain stable for saved appearances.
const PRESETS=[{"id":"ember","title":"Flame","color":Color("ff681c"),"accent":Color("ffe889")}]
static func colors(_appearance:Dictionary={}) -> Dictionary:
 # No colour variants: all fire presets use the same orange/yellow palette.
 return PRESETS[0]
static func legacy_structure(id:String) -> int:
 return maxi(0,["ember","gold","crimson","white","blue","violet","green","rose"].find(id.get_slice("_",id.get_slice_count("_")-1)))
