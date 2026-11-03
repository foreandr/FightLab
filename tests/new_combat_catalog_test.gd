extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.animation_browser
 while not b.ready_catalog:await process_frame
 assert(b.records.filter(func(record):return str(record.get("source_name",""))=="Motifect Martial Arts").size()==38,"New combat pack missing from picker")
 b.set_type("Leg");b.search.text="motifect";b.apply_filters()
 assert(not b.matches_.is_empty())
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():await process_frame
 for card in b.grid.get_children():assert(card.find_child("PreviewImage",true,false).texture!=null,"New combat thumbnail missing")
 assert(b.select_animation(b.matches_[0]))
 var before=s.actor.bone_point("hand_r")
 s.spell_builder.process_demo_preview(0.3)
 assert(before.distance_to(s.actor.bone_point("hand_r"))>0.001,"New combat animation does not play")
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/new_combat_pack_review.png")
 print("NEW COMBAT PACK PASS: 38 imported clips searchable, thumbnails populated, selected animation actually moves")
 quit()
