extends SceneTree
const Catalog=preload("res://scripts/fire_style_catalog.gd")
const Appearance=preload("res://scripts/spell_appearance.gd")
const Plume=preload("res://scripts/fire_plume.gd")
func red(color:Color) -> bool:
 return color.r>color.g*2.0 and color.r>color.b*2.0
func _initialize() -> void:
 assert(Catalog.entries().size()==533)
 for entry in Catalog.entries():
  var look:=Catalog.look(entry.id)
  var resolved:=Appearance.settings("Fire",look)
  assert(red(resolved.color) and red(resolved.accent),entry.id)
  assert(Catalog.active_id(look)==entry.id,entry.id)
  # Existing saved colors cannot bring back a blue/green/white flame.
  look.color=Color.BLUE;look.accent=Color.GREEN
  resolved=Appearance.settings("Fire",look)
  assert(red(resolved.color) and red(resolved.accent),entry.id)
  assert(Catalog.active_id(look)==entry.id,entry.id)
  if entry.id.begins_with("style_"):
   var legacy:=look.duplicate(true);legacy.erase("flame_structure")
   assert(Catalog.active_id(legacy)==entry.id,"Legacy preset loses selection: "+str(entry.id))
  var body:=Appearance.visual("Fire",0.3,look)
  assert(red(body.material_override.get_shader_parameter("primary")))
  body.free()
 var plume:=Plume.flame(0.3,0.5,0.0,{"color":Color.BLUE,"accent":Color.GREEN})
 assert(red(plume.material_override.get_shader_parameter("primary")))
 assert(red(plume.material_override.get_shader_parameter("accent")))
 plume.free()
 assert(Appearance.settings("Ice",{"color":Color.BLUE}).color==Color.BLUE)
 print("RED FIRE PASS: 533 styles, legacy colors, projectile and plume materials; other elements unchanged")
 quit()
