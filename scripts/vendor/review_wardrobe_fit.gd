extends SceneTree
## Scriptable multi-angle review on the actual shared character, not source thumbnails.
const Character=preload("res://scripts/story_character.gd")
const Pool=preload("res://scripts/clothing_pool.gd")
var viewport: SubViewport
var actor: Node3D
var camera: Camera3D
var report: Array=[]
func _initialize():call_deferred("run")
func run():
 var manifest=preload("res://scripts/curated_wardrobe.gd").MANIFEST
 var output="res://work/wardrobe_review"
 var body="Masculine"
 var pose=""
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--manifest="):manifest=arg.trim_prefix("--manifest=")
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
  if arg.begins_with("--body="):body=arg.trim_prefix("--body=")
  if arg.begins_with("--pose="):pose=arg.trim_prefix("--pose=")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 viewport=SubViewport.new();viewport.size=Vector2i(384,480);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("102433");world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_energy=0.8;world.environment.ambient_light_color=Color.WHITE;viewport.add_child(world)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.4;viewport.add_child(light)
 var fill:=OmniLight3D.new();fill.position=Vector3(0,2,-2);fill.light_energy=0.8;fill.omni_range=8;viewport.add_child(fill)
 camera=Camera3D.new();camera.fov=34;viewport.add_child(camera)
 actor=Character.new();viewport.add_child(actor);actor.gear_transitions_enabled=false;actor.prepared_preview_enabled=true
 var items: Array=JSON.parse_string(FileAccess.get_file_as_string(manifest))
 for item in items:Pool.value_index[str(item.value)]=item
 for index in items.size():
  var item:Dictionary=items[index]
  var profile={"body":"Masculine","skin":"Dark","skin_color":Color("925438"),"hair":"Short","hair_color":Color("30211d"),"wardrobe_shirt":"Peasant","wardrobe_pants":"Peasant","wardrobe_arms":"Bare","wardrobe_boots":"Peasant","shirt_color":Color("426c91"),"bottoms_color":Color("34383e")}
  profile.body=body
  profile[str(item.slot)]=str(item.value)
  var keys={"wardrobe_shirt":"shirt_color","wardrobe_pants":"bottoms_color","wardrobe_boots":"footwear_color","wardrobe_hands":"handwear_color"}
  profile[str(keys.get(item.slot,str(item.slot).trim_prefix("wardrobe_")+"_color"))]=Color.WHITE
  if item.kind=="outfit":profile.wardrobe_pants="Underclothes"
  var start=Time.get_ticks_usec();actor.set_profile(profile);var first=(Time.get_ticks_usec()-start)/1000.0
  if not pose.is_empty():
   actor.play_preview_animation(pose)
   actor.animator.play(pose,0)
   actor.animator.advance(0)
  actor.animator.seek(0.25 if not pose.is_empty() else 0.1,true);actor.animator.pause()
  await process_frame
  for view in 3:
   var center=Vector3(0,1.0,0);var distance=3.4
   camera.position=center+Vector3(sin(view*PI*0.5)*distance,0.08,cos(view*PI*0.5)*distance);camera.look_at(center)
   await process_frame;await RenderingServer.frame_post_draw
   viewport.get_texture().get_image().save_png(output.path_join(str(item.id)+"_"+str(view)+".png"))
  start=Time.get_ticks_usec();actor.set_profile(profile);var repeat=(Time.get_ticks_usec()-start)/1000.0
  report.append({"id":item.id,"name":item.name,"slot":item.slot,"kind":item.kind,"first_ms":first,"repeat_ms":repeat,"failures":actor.get_meta("wardrobe_fit_failures",[])})
  var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
  print("WARDROBE REVIEW ",index+1,"/",items.size()," ",item.id," first_ms=",first," repeat_ms=",repeat)
 print("WARDROBE REVIEW COMPLETE ",items.size())
 quit()
