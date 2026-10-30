extends RefCounted
## Kenney Particle Pack, CC0. License: assets/combat/licenses/Kenney-Particle-Pack-CC0.txt
const NAMES=["circle_01", "circle_02", "circle_03", "circle_04", "circle_05", "dirt_01", "dirt_02", "dirt_03", "fire_01", "fire_02", "flame_01", "flame_02", "flame_03", "flame_04", "flame_05", "flame_06", "flare_01", "light_01", "light_02", "light_03", "magic_01", "magic_02", "magic_03", "magic_04", "magic_05", "muzzle_01", "muzzle_02", "muzzle_03", "muzzle_04", "muzzle_05", "scorch_01", "scorch_02", "scorch_03", "scratch_01", "slash_01", "slash_02", "slash_03", "slash_04", "smoke_01", "smoke_02", "smoke_03", "smoke_04", "smoke_05", "smoke_06", "smoke_07", "smoke_08", "smoke_09", "smoke_10", "spark_01", "spark_02", "spark_03", "spark_04", "spark_05", "spark_06", "spark_07", "star_01", "star_02", "star_03", "star_04", "star_05", "star_06", "star_07", "star_08", "star_09", "symbol_01", "symbol_02", "trace_01", "trace_02", "trace_03", "trace_04", "trace_05", "trace_06", "trace_07", "twirl_01", "twirl_02", "twirl_03", "window_01", "window_02", "window_03", "window_04"]
static var user_cache:Dictionary={}
static func texture(name_:String) -> Texture2D:
 if name_.begins_with("user://spell_textures/") and name_.get_base_dir()=="user://spell_textures":
  if user_cache.has(name_):return user_cache[name_]
  var image:=Image.load_from_file(name_)
  if image==null or image.is_empty():return null
  var output:=ImageTexture.create_from_image(image)
  if user_cache.size()>=24:user_cache.erase(user_cache.keys()[0])
  user_cache[name_]=output
  return output
 if name_ not in NAMES:return null
 return load("res://assets/combat/vfx/"+name_+".png")

static func user_names() -> Array:
 var names:Array=[]
 if not DirAccess.dir_exists_absolute("user://spell_textures"):return names
 for name_ in DirAccess.get_files_at("user://spell_textures"):
  if name_.get_extension().to_lower()=="png":names.append("user://spell_textures/"+name_)
 return names
