extends SceneTree
const Catalog=preload("res://scripts/fire_style_catalog.gd")
const Gallery=preload("res://scripts/fire_style_gallery.gd")
var worlds:Array[SubViewport]=[]
var ids:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func different(a:Image,b:Image) -> int:
 var count:=0
 for y in a.get_height():
  for x in a.get_width():
   var left:=a.get_pixel(x,y);var right:=b.get_pixel(x,y)
   if absf(left.r-right.r)+absf(left.g-right.g)+absf(left.b-right.b)>0.05:count+=1
 return count
func run() -> void:
 var gallery:=Gallery.new();root.add_child(gallery)
 for entry in Catalog.EXTERNAL:ids.append(entry.id)
 for structure in Catalog.STRUCTURES:
  ids.append("flame_04" if structure.id=="ember" else "style_flame_04_natural_"+str(structure.id))
 for id in ids:
  var world:SubViewport=gallery._preview(id);root.add_child(world);worlds.append(world)
 for i in 4:await process_frame
 await RenderingServer.frame_post_draw
 var images:Array[Image]=[]
 var canvas:=Image.create(6*144,3*144,false,Image.FORMAT_RGBA8)
 canvas.fill(Color("382b21"))
 for i in worlds.size():
  var image:Image=worlds[i].get_texture().get_image();images.append(image)
  var blank:=Image.create(144,144,false,Image.FORMAT_RGBA8);blank.fill(Color("382b21"))
  assert(different(image,blank)>30,"Empty flame structure: "+ids[i])
  canvas.blit_rect(image,Rect2i(0,0,144,144),Vector2i(i%6*144,i/6*144))
 canvas.save_png("res://work/fire_structures_contact.png")
 # Equal red, equal camera/time/mask: structure must visibly alter rendered pixels.
 for i in range(9,worlds.size()):
  for j in range(9,i):assert(different(images[i],images[j])>16,"Visually duplicate structures: "+ids[i]+" / "+ids[j])
 # Each imported animation must actually advance its own source frames.
 for i in Catalog.EXTERNAL.size():
  var visual:MeshInstance3D=worlds[i].get_child(2)
  visual.material_override.set_shader_parameter("flame_preview_time",1.3)
  worlds[i].render_target_update_mode=SubViewport.UPDATE_ONCE
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 for i in Catalog.EXTERNAL.size():
  assert(different(images[i],worlds[i].get_texture().get_image())>20,"Static external fire: "+ids[i])
 print("FIRE STRUCTURE VISUAL PASS: 9 imported animated sheets advance, 8 structural treatments render distinct nonempty silhouettes, all through shared renderer")
 quit()
