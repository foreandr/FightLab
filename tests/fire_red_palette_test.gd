extends SceneTree
const Catalog=preload("res://scripts/fire_style_catalog.gd")
const Appearance=preload("res://scripts/spell_appearance.gd")
const Plume=preload("res://scripts/fire_plume.gd")
func red(color:Color) -> bool:
 return color.r>color.g*2.0 and color.r>color.b*2.0
func _initialize() -> void:
 assert(Catalog.entries().size()==23)
 for entry in Catalog.entries():
  var look:=Catalog.look(entry.id)
  var resolved:=Appearance.settings("Fire",look)
  assert(resolved.color==Color("e62917") and resolved.accent==resolved.color,entry.id)
  assert(Catalog.active_id(look)==entry.id,entry.id)
  # Existing saved colors cannot bring back a blue/green/white flame.
  look.color=Color.BLUE;look.accent=Color.GREEN;look.glow=5.0;look.opacity=0.1
  resolved=Appearance.settings("Fire",look)
  assert(resolved.color==Color("e62917") and resolved.accent==resolved.color,entry.id)
  assert(Catalog.active_id(look)==entry.id,entry.id)
  if entry.id.begins_with("style_"):
   var legacy:=look.duplicate(true);legacy.erase("flame_structure")
   assert(Catalog.active_id(legacy)==entry.id,"Legacy preset loses selection: "+str(entry.id))
  assert(resolved.glow==1.8 and resolved.opacity==0.95,"Saved style changes colour/brightness")
  var body:=Appearance.visual("Fire",0.3,look)
  assert(red(body.material_override.get_shader_parameter("primary")))
  body.free()
 # Removed choices stay loadable for existing saved spells, but never fill pages.
 for id in ["style_flame_03_crown_blue","ben_fire_08","flame_02","shape_wisp"]:
  assert(not Catalog.entries().has(Catalog.find(id)),"Redundant style remains in gallery: "+id)
  assert(not Catalog.find(id).is_empty(),"Removing duplicate breaks saved spell: "+id)
  var old_body:=Appearance.visual("Fire",0.3,Catalog.look(id))
  assert(old_body.mesh!=null)
  assert(old_body.get_meta("look").color==Color("e62917"))
  old_body.free()
 var plume:=Plume.flame(0.3,0.5,0.0,{"color":Color.BLUE,"accent":Color.GREEN})
 assert(red(plume.material_override.get_shader_parameter("primary")))
 assert(red(plume.material_override.get_shader_parameter("accent")))
 plume.free()
 assert(Appearance.settings("Ice",{"color":Color.BLUE}).color==Color.BLUE)
 print("RED FIRE PASS: 23 curated styles, legacy colors, projectile and plume materials; other elements unchanged")
 quit()
