extends Node
## Local, page-scoped screenshots using the real rig and shared animation evaluator.
const CACHE="user://animation_thumbnails_v2/"
var actor:CharacterBody3D
var viewport:SubViewport
var camera:Camera3D
var jobs:Array[Dictionary]=[]
var busy:=false
var generation:=0
var rendered_count:=0
var cache_hits:=0
func request_page(entries:Array, cards:Array, details:String)->void:
 generation+=1;jobs.clear()
 for i in entries.size():
  jobs.append({"entry":entries[i],"card":weakref(cards[i]),"details":details,"generation":generation})
 if not busy:call_deferred("drain")
func initialize_stage()->void:
 viewport=SubViewport.new();viewport.size=Vector2i(256,176);viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(viewport)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("392c22")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.75;viewport.add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-35,0);light.light_energy=1.3;viewport.add_child(light)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;viewport.add_child(camera);camera.current=true
 var world=preload("res://scripts/spell_creation_world.gd").new();viewport.add_child(world)
 actor=world.spawn_combatant(0,Vector3.ZERO,preload("res://scripts/creation_bot_outfit.gd").profile(0))
 world.process_mode=Node.PROCESS_MODE_DISABLED;actor.editor_pose_locked=true;actor.brain_enabled=false
 actor.hide()
 DirAccess.make_dir_recursive_absolute(CACHE)
func drain()->void:
 if busy:return
 busy=true
 while not jobs.is_empty() and is_inside_tree():
  var job:Dictionary=jobs.pop_front()
  var card=job.card.get_ref()
  if not is_instance_valid(card):continue
  var entry:Dictionary=job.entry.duplicate(true)
  var stamp:=str(FileAccess.get_modified_time(job.details)) if not str(job.details).is_empty() else ""
  for source in ["animation_resource","bvh_source"]:
   if entry.has(source):stamp+=str(FileAccess.get_modified_time(str(entry[source])))
  var signature:=(JSON.stringify(entry)+stamp).sha256_text()
  var path:=CACHE+signature+".png"
  var texture:Texture2D
  if FileAccess.file_exists(path):
   texture=ImageTexture.create_from_image(Image.load_from_file(path));cache_hits+=1
  else:
   if viewport==null:initialize_stage()
   var existing:PackedStringArray=actor.player.get_animation_list()
   if entry.has("_detail_offset"):
    entry=preload("res://scripts/animation_store_index.gd").load_entry(job.details,int(entry._detail_offset),int(entry._detail_size))
   if entry.is_empty() or not preload("res://scripts/animation_store_backend.gd")._ensure_animation_source(self,entry):
    card.tooltip_text+="\nScreenshot unavailable";continue
   entry["step"]=entry.get("step","Imported Motion")
   preload("res://scripts/spell_cast_motion.gd").pose(actor,entry,0.5)
   var lo:=Vector3(INF,INF,INF);var hi:=-lo
   for bone in ["Head","hand_l","hand_r","foot_l","foot_r","pelvis","upperarm_l","upperarm_r","calf_l","calf_r"]:
    var index:int=actor.skeleton.find_bone(bone)
    if index<0:continue
    var point:Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(index).origin
    lo=lo.min(point);hi=hi.max(point)
   var center:Vector3=(lo+hi)*0.5
   camera.size=maxf(1.0,maxf(hi.y-lo.y,(hi.x-lo.x)*0.8))*1.5
   camera.position=center+Vector3(3,1,4);camera.look_at(center)
   # A posed mesh copy renders without the actor's live AnimationPlayer updating it.
   var model=actor.model.duplicate();viewport.add_child(model);model.show()
   await get_tree().process_frame
   viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
   await RenderingServer.frame_post_draw
   if not is_inside_tree():return
   var image:=viewport.get_texture().get_image()
   image.save_png(path);texture=ImageTexture.create_from_image(image);rendered_count+=1
   model.queue_free()
   # Keep only the base rig's clips; browsing thousands of pages must not retain
   # every imported Animation resource in this preview actor.
   for clip in actor.player.get_animation_list():
    if clip not in existing:
     actor.player.get_animation_library(str(clip).get_slice("/",0)).remove_animation(str(clip).get_slice("/",1))
  card=job.card.get_ref()
  if is_instance_valid(card) and int(job.generation)==generation:
   card.find_child("PreviewImage",true,false).texture=texture
  await get_tree().process_frame
 busy=false
func _show_library_notice(_message:String)->void:pass
func _log_store_action(action:String,entry:Dictionary,details:Dictionary={})->void:
 GameDiagnostics.log_event("thumbnail_"+action,{"title":entry.get("title",""),"details":details})

