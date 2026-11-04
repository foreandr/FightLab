extends SceneTree
const Pool = preload("res://scripts/clothing_pool.gd")
func _initialize():call_deferred("run")
func settle():
 for i in 8:await process_frame
func run():
 set_meta("story_create_new",true)
 change_scene_to_file("res://scenes/story_character_creator.tscn")
 await settle()
 var c=current_scene
 c.preview.gear_transitions_enabled=false
 c.open_appearance_section("wardrobe_hat")
 var library=root.get_node("WardrobeLibrary")
 var frames=0
 while not library.loaded: frames+=1;await process_frame
 await settle()
 assert(frames>0 and library.total>23000)
 assert(c.appearance_slots.size()==14)
 print("LIBRARY READY ",library.total," background frames ",frames," unwanted ",library.unwanted)
 var decisions=Pool.decisions()
 for slot in library.slots:
  assert(c.appearance_slots.has(slot),"Missing section "+slot)
  for item in library.for_slot(slot):assert(decisions.get_value("decisions",item.id,"pending")!="unwanted")
 # Stable ID values, human names, search, selection, actual mesh attachment and size.
 for slot in ["wardrobe_hat","wardrobe_boots","wardrobe_pants","wardrobe_shirt","wardrobe_hands","wardrobe_necklace","wardrobe_back"]:
  c.open_appearance_section(slot)
  await settle()
  var item:Dictionary=library.for_slot(slot)[0]
  c.appearance_picker.search.text=str(item.name)
  c.appearance_picker.search.text_changed.emit(str(item.name))
  assert(c.appearance_picker.filtered.size()>0)
  c.choose_appearance(slot,str(item.value))
  assert(c.profile[slot]==item.value)
  assert(c.preview.get_meta("wardrobe_fit_failures",[]).is_empty(),"Failed fit "+str(item))
  assert(c.preview.set_wardrobe_size(slot,1.3),"No live resize target for "+slot)
  c.appearance_picker.size_slider.value=1.3
  c.close_appearance_section();c.open_appearance_section(slot)
  assert(is_equal_approx(c.appearance_picker.size_slider.value,1.3))
  # Avoid stacking all test garments into the next test's fitting scene.
  c.profile[slot]="None"
 # Explicit PVM torso regression: size changes the fitted mesh immediately.
 var garment:Dictionary={}
 for item in library.for_slot("wardrobe_shirt"):
  if item.get("format","")=="pvm":garment=item;break
 c.choose_appearance("wardrobe_shirt",str(garment.value))
 var fitted=c.preview.skeleton.find_child("PavlovShirt_*",false,false)
 assert(fitted!=null)
 var old_size:Vector3=fitted.mesh.get_aabb().size
 assert(c.preview.set_wardrobe_size("wardrobe_shirt",1.45))
 assert(fitted.mesh.get_aabb().size.x>old_size.x)
 c.profile["wardrobe_shirt"]="Peasant";c._refresh_preview()
 c.open_appearance_section("wardrobe_hat")
 c.appearance_picker.search.text="hat";c.appearance_picker.search.text_changed.emit("hat")
 await settle()
 while c.appearance_picker.thumbnails.busy or not c.appearance_picker.thumbnails.jobs.is_empty():await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/downloaded_wardrobe_test.png")
 print("DOWNLOADED WARDROBE PASS: 14 sections, searchable local library, unwanted excluded, stable selection, real attachments, accessory and fitted garment resizing")
 quit()
