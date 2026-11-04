extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in 10:await process_frame
func capture(file: String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/"+file+".png")
func run():
 set_meta("story_create_new",true)
 change_scene_to_file("res://scenes/story_character_creator.tscn")
 await settle()
 var c=current_scene
 var model=c.preview.model
 c.choose_appearance("wardrobe_shirt","Traveler")
 assert(c.preview.gear_transition.active)
 assert(not c.preview.gear_transition.surfaces.is_empty())
 await create_timer(0.12).timeout
 assert(c.preview.model==model,"Out transition replaced garment too early")
 await capture("gear_digitize_out")
 await create_timer(0.19).timeout
 assert(c.preview.model!=model,"New garment not built at midpoint")
 await capture("gear_digitize_in")
 c.preview.set_wardrobe_size("wardrobe_shirt",1.21)
 await create_timer(0.6).timeout
 assert(not c.preview.gear_transition.active and c.preview.profile.wardrobe_shirt=="Traveler")
 assert(is_equal_approx(c.preview.profile.top_size,1.21))
 await capture("gear_digitize_finished")
 # Rapid selection keeps latest request and restores normal materials.
 c.choose_appearance("wardrobe_shirt","Peasant")
 await create_timer(0.07).timeout
 c.choose_appearance("wardrobe_shirt","Guard castoff")
 await create_timer(0.8).timeout
 assert(c.preview.profile.wardrobe_shirt=="Guard castoff")
 assert(not c.preview.gear_transition.active and c.preview.gear_transition.surfaces.is_empty())
 # Editing/loadout uses the same shared renderer and leaves the preview visible.
 current_scene.queue_free()
 var edit=load("res://tests/fixtures/gear_edit_preview_host.gd").new()
 root.add_child(edit);current_scene=edit
 await settle()
 var profile:Dictionary=edit.preview.profile.duplicate(true)
 profile.wardrobe_shirt="Traveler" if profile.get("wardrobe_shirt","")!="Traveler" else "Peasant"
 edit.preview.set_profile_animated(profile)
 assert(edit.preview.gear_transition.active)
 await create_timer(0.8).timeout
 assert(not edit.preview.gear_transition.active)
 assert(edit.preview.skeleton.has_meta("body_barrier_overlays"))
 print("GEAR DIGITIZE PASS: old/out and new/in, real shader render, size during swap, latest selection wins, creator and edit share effect, materials restored")
 quit()
