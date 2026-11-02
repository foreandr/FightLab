extends SceneTree
const Library=preload("res://scripts/community_fire_library.gd")
const Catalog=preload("res://scripts/fire_style_catalog.gd")
const Textures=preload("res://scripts/spell_textures.gd")
const Appearance=preload("res://scripts/spell_appearance.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 assert(Library.ENTRIES.size()==51)
 var artists:Dictionary={};var hashes:Dictionary={};var animated:=0
 var config:=ConfigFile.new()
 for entry in Library.ENTRIES:
  artists[entry.author]=true
  assert(str(entry.source).begins_with("https://") and entry.license in ["CC0-1.0","CC-BY-3.0","CC-BY-4.0"])
  assert(not str(entry.origin.get("archive_sha256",entry.origin.get("sha256",""))).is_empty(),"Missing source hash")
  var image:=Image.new()
  assert(image.load_png_from_buffer(FileAccess.get_file_as_bytes(entry.file))==OK)
  assert(image!=null and image.get_width()==entry.columns*128 and image.get_height()==entry.rows*128,"Invalid atlas grid: "+str(entry.id))
  var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(FileAccess.get_file_as_bytes(entry.file));var hash_:String=digest.finish().hex_encode()
  assert(hash_==entry.origin.normalised_sha256 and not hashes.has(hash_),"Duplicate or corrupt imported artwork: "+str(entry.id));hashes[hash_]=true
  var frames:Dictionary={};var nonempty:=false
  for frame in entry.frames:
   var tile:=image.get_region(Rect2i(frame%entry.columns*128,frame/entry.columns*128,128,128))
   frames[hash(tile.get_data())]=true
   if not tile.is_invisible():nonempty=true
  assert(nonempty,"Empty source artwork: "+str(entry.id))
  if entry.frames>1:
   animated+=1;assert(frames.size()>1,"Static source labelled as animation: "+str(entry.id))
  var look:=Catalog.look(entry.id)
  var texture:Texture2D=Textures.texture(entry.id)
  assert(texture!=null and texture.get_width()==image.get_width())
  var body:=Appearance.visual("Fire",0.4,look)
  assert(body.material_override.get_shader_parameter("flame_sheet_frames")==entry.frames)
  assert(body.material_override.get_shader_parameter("flame_soft_alpha")==true)
  assert(Catalog.active_id(look)==entry.id)
  config.set_value("artwork",entry.id,look);body.free()
 var path:="user://logs/community_fire_roundtrip.cfg";assert(config.save(path)==OK)
 var loaded:=ConfigFile.new();assert(loaded.load(path)==OK)
 for entry in Library.ENTRIES:
  var look:Dictionary=loaded.get_value("artwork",entry.id,{})
  assert(Catalog.active_id(look)==entry.id and look.author==entry.author and look.source==entry.source,"Saved source identity lost")
 assert(artists.size()==10 and animated==50)
 assert(Textures.texture("community_../../missing")==null,"Texture lookup accepts arbitrary paths")
 print("COMMUNITY FIRE IMPORT PASS: 51 distinct file hashes, 50 moving source clips + 1 mask, 10 artist credits, atlas layouts, whitelist, source hashes, actual materials and save/reload metadata")
 quit()
