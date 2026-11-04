extends SceneTree
## Idempotent library operation: do not replace the player's named creations.
func _initialize()->void:call_deferred("run")
func run()->void:
 var definition=load("res://scripts/spell_definition.gd")
 var library=load("res://scripts/saved_spell_library.gd").new()
 var fire=load("res://assets/spells/fire/library.gd")
 var physical:Dictionary=definition.make("None","Touch",{"size":0.5,"speed":0.5},{})
 var burning:Dictionary=definition.make("Fire","Touch",{"size":0.15,"speed":0.55,"effect":0.30},fire.selection("fire_02","fire_whoosh"))
 var shield:Dictionary=definition.make("None","Barrier",{"size":0.5,"speed":0.5},{})
 for recipe in [["Physical Touch",physical],["Fire Touch",burning],["Self Barrier",shield]]:
  var exists:=false
  for record in library.entries():
   if str(record.name).nocasecmp_to(recipe[0])==0 and record.delivery_type==recipe[1].delivery_type:exists=true;break
  if exists:print("Already saved: ",recipe[0]);continue
  var result:Dictionary=library.save(recipe[0],recipe[1])
  if not result.ok:push_error(str(result.error));quit(1);return
  print("Saved: ",result.record.name," · ",result.record.delivery_type)
 quit()
