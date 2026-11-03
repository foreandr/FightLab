extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.animation_browser
 while not b.ready_catalog:await process_frame
 var deadline=Time.get_ticks_msec()+90000
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():
  assert(Time.get_ticks_msec()<deadline,"Thumbnail queue stalled")
  await process_frame
 assert(b.grid.get_child_count()==9)
 var images=[]
 for card in b.grid.get_children():
  var texture=card.find_child("PreviewImage",true,false).texture
  assert(texture!=null,"Real thumbnail missing: "+card.name)
  images.append(texture.get_image().get_data().hex_encode().sha256_text())
 assert(images[0]!=images[1],"Different animations rendered identical thumbnails")
 var position=s.actor.position;var stamina=s.actor.stamina
 var cache_before=b.thumbnails.cache_hits
 b.show_page()
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():await process_frame
 assert(b.thumbnails.cache_hits>=cache_before+9,"Cached page was not reused")
 assert(s.actor.position.distance_to(position)<0.001 and is_equal_approx(s.actor.stamina,stamina),"Thumbnail render changed live actor")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/sandbox_thumbnail_review.png")
 b.source_filter.select(3);b.search.text="cartwheel";b.apply_filters()
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():await process_frame
 assert(b.grid.get_child_count()>0,"Community filter empty")
 for card in b.grid.get_children():assert(card.find_child("PreviewImage",true,false).texture!=null,"Community screenshot missing")
 b.turn_page(1);b.set_type("Head");b.set_type("All")
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():await process_frame
 print("THUMBNAILS PASS: 9 real poses, different images, persistent cache, live actor unchanged")
 quit()
