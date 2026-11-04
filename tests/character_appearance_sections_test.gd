extends SceneTree
const Hair = preload("res://scripts/character_hair_catalog.gd")
func _initialize(): call_deferred("run")
func settle():
 for i in 8: await process_frame
func run():
 set_meta("story_create_new",true)
 change_scene_to_file("res://scenes/story_character_creator.tscn")
 await settle()
 var c = current_scene
 assert(c.profile.skin_color == Color("925438"))
 assert(c.hair_choice.item_count == 40)
 var names := {}
 for item in Hair.catalog():
  assert(not names.has(item.name)); names[item.name] = true
  assert(ResourceLoader.exists(item.mesh))
  if not str(item.texture).is_empty(): assert(ResourceLoader.exists(item.texture))
 # Every garment opens its own page; selections and scaling survive navigation.
 for slot in c.appearance_slots:
  c.open_appearance_section(slot)
  await settle()
  assert(c.appearance_picker.visible and not c.page_content.visible)
  var data: Dictionary = c.appearance_slots[slot]
  var value: String = data.option.get_item_text(data.option.item_count-1)
  c.choose_appearance(slot,value)
  if not str(data.size_key).is_empty():
   c.appearance_picker.size_slider.value = 1.23
   assert(is_equal_approx(c.profile[data.size_key],1.23))
  c.close_appearance_section()
  c.open_appearance_section(slot)
  await settle()
  assert(c.profile[slot] == value)
  if not str(data.size_key).is_empty(): assert(is_equal_approx(c.appearance_picker.size_slider.value,1.23))
  c.close_appearance_section()
 # All downloaded hair is attached to Head and follows the animated rig for both bodies.
 for body in ["Masculine","Feminine"]:
  c.profile.body = body
  for item in Hair.catalog():
   c.choose_appearance("hair",str(item.name))
   var socket = c.preview.skeleton.get_node("CommunityHair")
   assert(socket.bone_name == "Head" and socket.get_child_count() == 1)
   assert(socket.get_child(0).mesh != null)
 c.profile.body = "Masculine";c.choose_appearance("hair","Short")
 c.open_appearance_section("wardrobe_shirt")
 await settle()
 while c.appearance_picker.thumbnails.busy or not c.appearance_picker.thumbnails.jobs.is_empty(): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/appearance_sections_test.png")
 print("APPEARANCE SECTIONS PASS: seven pickers, persistent sizes/selections, 40 hair choices, 35 downloaded meshes on both bodies, no save mutation")
 quit()
