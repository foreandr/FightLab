extends SceneTree
const Registry=preload("res://scripts/spell_asset_library.gd")
const LegacyStyles=preload("res://scripts/fire_style_catalog.gd")
const LegacySounds=preload("res://scripts/fire_sound_catalog.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var library:=Registry.for_element("Fire")
 if not check(library!=null and library.styles().size()==74 and library.sounds().size()==13,"Shared Fire collection counts"):return
 var id:String=library.styles()[0].id
 var selection:Dictionary=library.selection(id,"fire_roar")
 var cfg:=ConfigFile.new();cfg.set_value("spell","appearance",selection)
 cfg.save("user://logs/shared_fire_library_test.cfg")
 var loaded:=ConfigFile.new();loaded.load("user://logs/shared_fire_library_test.cfg")
 var saved:Dictionary=loaded.get_value("spell","appearance")
 for delivery in ["Projectile","Touch","Beam","Targeted","Barrier"]:
  var spell:Dictionary={"element":"Fire","delivery_type":delivery,"appearance":saved}
  if not check(Registry.for_spell(spell)==library,"Delivery created another library: "+delivery):return
  if not check(Registry.sound_for(spell)=="fire_roar" and library.Styles.active_id(saved)==id,"Shared IDs fail for "+delivery):return
  if not check(Registry.sound_for({"element":"Fire","delivery_type":delivery})==library.Sounds.DEFAULT_ID,"Default fire sound depends on delivery"):return
 if not check(Registry.for_spell({"projectile_element":"Fire"})==library,"Old element field no longer resolves"):return
 if not check(LegacyStyles.entries()==library.styles() and LegacyStyles.active_id(saved)==id and LegacySounds.resolve({"element":"Fire","appearance":saved})=="fire_roar","Legacy paths no longer compatible"):return
 if not check(Registry.sound_for({"element":"None"})=="dash" and Registry.for_element("Unknown")==null,"Non-fire regression"):return
 if not check(Registry.sound_for({"element":"Fire","sound_id":"missing"})==library.Sounds.DEFAULT_ID,"Invalid sound ID fallback"):return
 var copy:Array=library.sounds();copy[0].title="changed"
 if not check(library.sounds()[0].title!="changed","Consumer modified shared sound records"):return
 print("SHARED FIRE LIBRARY PASS: 74 styles / 13 sounds; same library and saved IDs for all five deliveries; legacy paths and defaults preserved")
 quit()
