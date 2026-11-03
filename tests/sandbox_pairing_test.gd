extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var browser=s.animation_browser;var b=s.spell_builder
 while not browser.ready_catalog:await process_frame
 assert(browser.grid.get_child_count()==9)
 browser.set_type("Movement");browser.set_air("Airborne");browser.search.text="tkd jump front kick";browser.apply_filters()
 assert(not browser.matches_.is_empty())
 b.stop_preview_controls(true)
 for i in 100:b.move_caster(0.016,Vector2.ZERO,false)
 assert(s.actor.is_on_floor(),"Preview actor never grounded")
 var ground:float=s.actor.position.y
 assert(browser.select_animation(browser.matches_[0]))
 assert(not b.demo_enter_pose.is_empty(),"No smooth entry blend")
 var duration:float=b.demo_duration
 b.process_demo_preview(0.016)
 assert(s.actor.velocity.y>0 and s.actor.authored_jump_launched,"Airborne move did not jump first")
 b.move_caster(0.1,Vector2.ZERO,false)
 assert(s.actor.position.y>ground+0.1,"Jump did not leave floor")
 b.process_demo_preview(duration)
 assert(not b.playing and not b.demo_exit_pose.is_empty(),"No smooth exit blend")
 b.process_demo_preview(0.25)
 assert(b.demo_exit_pose.is_empty(),"Exit never finished")
 browser.spell_selector.select(2);browser.select_spell(2)
 assert(b.previews_projectile() and b.preview_effect=="Fire" and b.demo_timing_panel.visible)
 assert(b.get_meta("cast_timeline").is_ancestor_of(b.get_meta("cast_timeline").duration_handle))
 b.get_meta("cast_length_input").value=2.4
 assert(is_equal_approx(b.demo_duration,2.4),"Timeline is not connected to shared duration")
 b.stop_preview_controls(true)
 for i in 160:b.move_caster(0.016,Vector2.ZERO,false)
 b.play_projectile_once()
 var shots:int=s.field.shot_serial
 for i in 160:
  b.process_demo_preview(0.016);b.move_caster(0.016,Vector2.ZERO,false)
 assert(s.field.shot_serial>shots,"Selected spell never launched with the chosen animation")
 browser.search.text="motifect";browser.apply_filters()
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 await process_frame
 var scroll=browser.grid.get_parent()
 assert(browser.grid.get_combined_minimum_size().y<=scroll.size.y+2,"Nine animation cards do not fit")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/sandbox_pairing_review.png")
 print("SANDBOX PAIRING PASS: nine cards, shared duration/release controls, spell selection/RHS, physical airborne launch, entry/exit blends")
 quit()
