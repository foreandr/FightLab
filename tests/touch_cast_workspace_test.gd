extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder;var actor=e.actor
 b.draft_path="user://logs/touch_draft.cfg";b.preview_preferences_path="user://logs/touch_preview.cfg"
 assert(not b.delivery_choices.Touch.disabled and b.delivery_choices.Beam.disabled and b.delivery_choices.Targeted.disabled)
 b.select_demo_choice("cross",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Touch");b.stop_preview_controls(true);b.confirm_delivery_type()
 assert(b.creation_step=="touch" and b.touch_authoring.visible and b.demo_timing_panel.visible)
 assert(b.touch_authoring.selected==["hand_l"] and not b.touch_authoring.confirmed and b.projectile_preview_button.disabled)
 assert(b.spell_sections["Animation type"].visible)
 b.touch_authoring.confirm_contacts()
 assert(b.previews_touch() and not b.projectile_preview_button.disabled)
 var single=b.demo_preview_spec()
 b.touch_authoring.toggle("hand_r");b.touch_authoring.confirm_contacts()
 var two=b.demo_preview_spec()
 assert(is_equal_approx(two.stamina_cost,single.stamina_cost*1.25))
 b.touch_authoring.toggle("hand_r");b.touch_authoring.confirm_contacts()
 var target=b.practice_human
 target.practice_return_enabled=false
 b.set_third_person_focus(target)
 target.global_position=e.field.surface_placement(actor.global_position+actor.global_basis.z*0.9)
 target.invulnerability=0.0
 for i in 5:await physics_frame
 var old:float=target.damage_taken;var serial:int=e.field.shot_serial
 b.play_projectile_once()
 var limit:=Time.get_ticks_msec()+3000
 while target.damage_taken==old and Time.get_ticks_msec()<limit:await process_frame
 assert(target.damage_taken>old,"Touch animation never dealt contact damage")
 assert(e.field.shot_serial==serial,"Touch cast spawned a projectile")
 var once:float=target.damage_taken
 while b.playing:await process_frame
 assert(target.damage_taken==once and e.field.combat().touch_casts.is_empty(),"Touch repeated or remained armed after cast")
 # The same fist animation cannot hit through a head-only Touch selection.
 b.touch_authoring.toggle("hand_l");b.touch_authoring.toggle("Head");b.touch_authoring.confirm_contacts()
 b.reset_practice_scene();target.practice_return_enabled=false
 target.global_position=e.field.surface_placement(actor.global_position+actor.global_basis.z*0.9)
 b.set_third_person_focus(target);target.invulnerability=0.0
 for i in 5:await physics_frame
 old=target.damage_taken
 b.play_projectile_once()
 while b.playing:await process_frame
 assert(target.damage_taken==old,"An unselected fist triggered head-only Touch")
 # Misses at distance and interrupts disarm the shared runtime state.
 b.touch_authoring.toggle("Head");b.touch_authoring.toggle("hand_l");b.touch_authoring.confirm_contacts()
 target.global_position=e.field.surface_placement(actor.global_position+actor.global_basis.z*5.0)
 target.invulnerability=0.0
 for i in 3:await physics_frame
 old=target.damage_taken;b.play_projectile_once()
 while b.playing:await process_frame
 assert(target.damage_taken==old and e.field.shot_serial==serial)
 b.stop_preview_controls(true)
 assert(e.field.combat().touch_casts.is_empty())
 b.play_projectile_once();b.show_creation_step("delivery")
 assert(b.creation_step=="delivery" and not b.touch_authoring.visible and e.field.combat().touch_casts.is_empty(),"Leaving Touch kept its hit window alive")
 # The delivery chooser intentionally previews its default Projectile choice.
 b.stop_preview_controls(true)
 b.process_demo_preview(1.0)
 assert(e.field.shot_serial==serial and e.field.combat().touch_casts.is_empty())
 print("TOUCH WORKSPACE PASS: enabled, contact parts/confirmation, animation type, extra-limb stamina, real animated contact damage, selected parts only, one hit, no projectile, miss at range, cast cleanup")
 quit()
