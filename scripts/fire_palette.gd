extends RefCounted
## Red-only fire palette. Legacy IDs remain stable for saved appearances.
const PRESETS=[
 {"id":"ember","title":"Ember","color":Color("e62917"),"accent":Color("ff5945")},
 {"id":"gold","title":"Scarlet","color":Color("ef1810"),"accent":Color("ff4935")},
 {"id":"crimson","title":"Crimson","color":Color("b91416"),"accent":Color("f53b30")},
 {"id":"white","title":"Vermilion","color":Color("f6321b"),"accent":Color("ff6146")},
 {"id":"blue","title":"Ruby","color":Color("b70920"),"accent":Color("f52b3a")},
 {"id":"violet","title":"Carmine","color":Color("cd1025"),"accent":Color("ff4050")},
 {"id":"green","title":"Blood","color":Color("910d12"),"accent":Color("dc2820")},
 {"id":"rose","title":"Flare","color":Color("ff2212"),"accent":Color("ff7058")}]
static func colors(appearance:Dictionary={}) -> Dictionary:
 var id:=str(appearance.get("fire_style_id",""))
 for preset in PRESETS:
  if id.ends_with("_"+str(preset.id)):return preset
 return PRESETS[0]
