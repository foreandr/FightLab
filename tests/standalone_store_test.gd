extends SceneTree
class DownloadProbe:
 extends RefCounted
 var taken:Dictionary={}
 var blocked:Dictionary={}
 var last_taken_entry:Dictionary={}
 func is_taken(_entry:Dictionary)->bool:return false
 var received:Dictionary={}
 func take(entry:Dictionary,group:String,category:String,existing_names:Array=[],animation:Animation=null)->bool:
  received={"entry":entry,"group":group,"category":category,"names":existing_names,"animation":animation}
  last_taken_entry=entry.duplicate(true)
  return true
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var result:=change_scene_to_file("res://scenes/animation_store.tscn")
 if not check(result==OK,"Store scene failed to load"):return
 var deadline:=Time.get_ticks_msec()+120000
 while (current_scene==null or not current_scene.get("store_screen_ready")) and Time.get_ticks_msec()<deadline:await process_frame
 var store=current_scene
 if not check(store!=null and store.store_screen_ready,"Standalone Store never ready"):return
 if not check(not ResourceLoader.has_cached("res://scripts/animation_editor.gd") and not ResourceLoader.has_cached("res://scripts/spell_builder.gd"),"Store loaded editor/custom authoring code"):return
 if not check(store.field.fighters.size()==1 and store.store_panel.get_script()==null and is_equal_approx(store.store_panel.anchor_right,0.57) and store.store_panel.offset_top==54,"Preview world or fixed panel is wrong"):return
 if not check(store.animation_store_list.get_child_count()>0 and store.animation_store_list.get_child_count()<=20,"Page is blank or too large"):return
 # Exercise real keyboard events, physics movement, shared sprint costs and text focus.
 var start:Vector3=store.actor.global_position
 var camera_start:Vector3=store.camera_control.focus
 var press:=InputEventKey.new();press.keycode=KEY_W;press.pressed=true;store._input(press)
 for i in 18:await physics_frame
 press.pressed=false;store._input(press);await physics_frame
 if not check(store.actor.global_position.distance_to(start)>0.4,"WASD did not move Store actor"):return
 if not check((store.camera_control.focus-camera_start).distance_to(store.actor.global_position-start)<0.02,"Inspection camera lost moving preview actor"):return
 var stamina:float=store.actor.stamina
 for key in [KEY_D,KEY_SHIFT]:
  var key_event:=InputEventKey.new();key_event.keycode=key;key_event.pressed=true;store._input(key_event)
 for i in 18:await physics_frame
 store.movement_keys.clear()
 if not check(store.actor.stamina<stamina,"Store sprint bypassed shared stamina cost"):return
 store.animation_store_search.grab_focus();start=store.actor.global_position
 store.movement_keys[KEY_W]=true
 for i in 8:await physics_frame
 store.movement_keys.clear();store.animation_store_search.release_focus()
 if not check(Vector2(store.actor.global_position.x-start.x,store.actor.global_position.z-start.z).length()<0.02,"Typing search moved the actor"):return
 var saved_search:String=store.animation_store_search.text
 var saved_creator:int=store.store_creator_filter.selected
 var saved_view:int=store.store_view_filter.selected
 var saved_type:int=store.store_body_filter.selected
 store.animation_store_search.set_block_signals(true)
 store.animation_store_search.text="";store.store_creator_filter.select(0);store.store_view_filter.select(3)
 var counts:Dictionary={}
 for record in store.store_index_records:
  var kind:String=str(record.get("store_animation_type",""))
  counts[kind]=int(counts.get(kind,0))+1
 for kind in ["Arm","Leg","Head","Movement"]:
  if not check(int(counts.get(kind,0))>0,"Missing catalog type: "+kind):return
 for index in range(1,5):
  store.store_body_filter.select(index)
  await store._populate_animation_store()
  if not check(store.animation_store_list.get_child_count()>0,"Empty type page: "+store.store_body_filter.get_item_text(index)):return
  for row in store.animation_store_list.get_children():
   var entry:Dictionary=row.get_child(0).get("entry")
   if not check(preload("res://scripts/animation_store_types.gd").kind(entry)==store.store_body_filter.get_item_text(index),"Wrong animation type on filtered page: %s expected %s got %s"%[entry.get("title"),store.store_body_filter.get_item_text(index),preload("res://scripts/animation_store_types.gd").kind(entry)]):return
 store.animation_store_search.text=saved_search;store.store_creator_filter.select(saved_creator);store.store_view_filter.select(saved_view);store.store_body_filter.select(saved_type)
 store.animation_store_search.set_block_signals(false)
 await store._populate_animation_store()
 print("STORE MOVEMENT/TYPES PASS: WASD, follow, sprint cost, typing guard; catalog counts ",counts)
 var button:Button=store.animation_store_list.find_child("StorePlay",true,false)
 button.pressed.emit();await process_frame
 if not check(store.row_preview_unit==store.actor,"Store Play failed"):return
 # The originally broken Ohio State clip must still produce real bone motion.
 var cartwheel:Dictionary={}
 for record in store.store_index_records:
  if str(record.get("title",""))=="Female1 D6 CartWheel":cartwheel=store._resolve_store_record(record);break
 if not check(not cartwheel.is_empty(),"Cartwheel source missing"):return
 store._play_store_animation(cartwheel)
 var baseline:Array[Quaternion]=[]
 for i in store.actor.skeleton.get_bone_count():baseline.append(store.actor.skeleton.get_bone_pose_rotation(i))
 var max_angle:=0.0
 for fraction in [0.2,0.4,0.6,0.8]:
  store.preview_elapsed=store.preview_duration*fraction;store._process(0.0)
  for i in baseline.size():max_angle=maxf(max_angle,rad_to_deg(baseline[i].angle_to(store.actor.skeleton.get_bone_pose_rotation(i))))
 if not check(max_angle>15.0,"Retargeted cartwheel is static in standalone Store"):return
 var account=store.store_library
 var probe:=DownloadProbe.new();probe.taken=account.taken.duplicate(true);probe.blocked=account.blocked.duplicate(true)
 store.store_library=probe
 var sample:Dictionary=store.Library.entries().filter(func(e):return e.title=="Left cross")[0].duplicate(true)
 store.take_store_animation(sample,"Attack","Downloaded")
 if not check(not probe.received.is_empty() and probe.received.category=="Downloaded" and probe.received.animation is Animation and probe.received.animation.get_track_count()>0,"Download did not reach unchanged project-copy backend"):return
 store.store_library=account
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/standalone_store.png")
 # Download logic stays in the shared backend and uses the same account library.
 if not check(store.store_library.path=="user://animation_store_library.cfg","Store uses another account library"):return
 store.return_to_main_menu();await process_frame;await process_frame
 if not check(current_scene.scene_file_path=="res://scenes/home.tscn","Home icon failed"):return
 print("STANDALONE STORE PASS: no editor/spell authoring resources loaded, one preview actor, fixed LHS, 20-record page, preview and cartwheel motion, same download backend/account storage and Main Menu")
 quit()
