extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 while current_scene==null or not current_scene.default_unit_ready or is_instance_valid(current_scene.loading_layer):await process_frame
 var e=current_scene;var b=e.spell_builder
 e.select_group("Spells");b.stop_preview_controls(true)
 b.set_process(false);b.set_physics_process(false);e.set_process(false);e.set_physics_process(false);e.field.set_physics_process(false)
 var actor=e.actor
 actor.set_process(false);actor.set_physics_process(false)
 var vp:=SubViewport.new();vp.size=Vector2i(320,220);vp.own_world_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("392c22");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=0.65;vp.add_child(env)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-35,0);light.light_energy=1.5;vp.add_child(light)
 var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;vp.add_child(camera);camera.current=true
 actor.reparent(vp);actor.show();actor.model.show();actor.position=Vector3.ZERO;actor.rotation=Vector3.ZERO
 for child in actor.get_children():
  if child.name=="OverheadHealthTag":child.hide()
 actor.practice_god_mode=false;actor.hide()
 DirAccess.make_dir_recursive_absolute("res://assets/ui/spell_demos")
 for choice in b.DEMO_ANIMATIONS:
  var entry:Dictionary=b.demo_source_cache[choice].duplicate(true)
  e._ensure_animation_source(entry)
  preload("res://scripts/spell_cast_motion.gd").pose(actor,entry,{"dismantle":0.57,"knee":0.48,"hook":0.5,"cross":0.48,"roundhouse":0.5,"mend":0.5,"block":0.5,"headbutt":0.5}.get(choice,0.5))
  var lo:=Vector3(INF,INF,INF);var hi:=-lo
  for name in ["Head","hand_r","hand_l","foot_r","foot_l","pelvis","upperarm_l","upperarm_r","calf_l","calf_r"]:
   var i:int=actor.skeleton.find_bone(name)
   if i<0:continue
   var point:Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(i).origin
   lo=lo.min(point);hi=hi.max(point)
  var center:Vector3=(lo+hi)*0.5
  camera.size=maxf(hi.y-lo.y,(hi.x-lo.x)*0.8)*1.55
  var rendered=actor.model.duplicate()
  vp.add_child(rendered);rendered.show()
  camera.position=center+Vector3(3,1.0,4);camera.look_at(center)
  await process_frame;await RenderingServer.frame_post_draw
  vp.get_texture().get_image().save_png("res://assets/ui/spell_demos/"+choice+".png")
  rendered.queue_free();await process_frame
  print("DEMO CARD RENDERED ",choice)
 quit()
