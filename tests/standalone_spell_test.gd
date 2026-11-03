extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 if not check(change_scene_to_file("res://scenes/spell_creation.tscn")==OK,"Could not open spell creation scene"):return
 var until:=Time.get_ticks_msec()+90000
 while (current_scene==null or not current_scene.get("workspace_ready")) and Time.get_ticks_msec()<until:await process_frame
 var screen=current_scene
 if not check(screen!=null and screen.workspace_ready,"Standalone spell host failed to initialize"):return
 if not check(not ResourceLoader.has_cached("res://scripts/animation_editor.gd") and not ResourceLoader.has_cached("res://scripts/combat_testing_sandbox.gd"),"Spell creation loaded animation editor"):return
 var b=screen.spell_builder
 b.draft_path="user://logs/standalone_spell_draft.cfg";b.preview_preferences_path="user://logs/standalone_spell_preview.cfg"
 b.saved_spells.directory="user://logs/standalone_spells_"+Crypto.new().generate_random_bytes(4).hex_encode()
 if not check(screen.field.fighters.size()==3 and b.creation_step=="demo" and is_equal_approx(b.demo_duration,1.5) and not b.demo_timing_panel.visible,"Initial standalone wizard differs from Create"):return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/standalone_spell.png")
 for choice in b.DEMO_ANIMATIONS:
  b.select_demo_choice(choice,false);b.stop_preview_controls(true)
  if not check(str(b.casting_animation.get("demo_choice",""))==choice and screen.actor.player.has_animation(str(b.casting_animation.clip)),"Demo source fails: "+choice):return
 b.select_demo_choice("cross",false);b.stop_preview_controls(true);b.confirm_demo_choice();b.stop_preview_controls(true)
 b.choose_delivery_type("Projectile");b.stop_preview_controls(true);b.confirm_delivery_type();b.stop_preview_controls(true)
 b._update_resize_grips()
 if not check(not b.allow_panel_resize and b.resize_grips.all(func(grip):return not grip.visible),"Standalone spell panels still have resize handles"):return
 if not check(b.demo_timing_panel.visible and b.creation_step=="projectile","Confirmed spell settings missing"):return
 b.set_demo_duration(1.0);b.set_release_fraction(0.4);b.stop_preview_controls(true)
 b.set_third_person_focus(screen.target)
 screen.actor.stamina=100;screen.actor.mana=100
 var old_mana:float=screen.actor.mana;var old_stamina:float=screen.actor.stamina
 var old_serial:int=screen.field.shot_serial
 b.play_projectile_once()
 until=Time.get_ticks_msec()+3500
 while Time.get_ticks_msec()<until and screen.field.shot_serial==old_serial:await process_frame
 if not check(screen.field.shot_serial>old_serial and screen.actor.mana<old_mana and screen.actor.stamina<old_stamina,"Shared cast/resources do not run in standalone world"):return
 b.stop_preview_controls(true)
 until=Time.get_ticks_msec()+3000
 while screen.target.damage_taken<=0.0 and Time.get_ticks_msec()<until:await process_frame
 if not check(screen.target.damage_taken>0.0,"Projectile did not hit/damage the practice dummy"):return
 var pos:Vector3=screen.actor.position
 b.move_caster(0.1,Vector2(1,0),false)
 if not check(screen.actor.position.distance_to(pos)>0.01,"Standalone movement broken"):return
 screen.target.health=1;b.reset_practice_scene()
 if not check(screen.target.health==screen.target.MAX_HEALTH and screen.field.shots.is_empty(),"Reset scene does not heal/clear shots"):return
 b.open_spell_save();var saved:Dictionary=b.save_named_spell("Standalone test")
 if not check(saved.ok and b.creation_step=="demo","Spell saving/reset flow changed"):return
 for record in b.saved_spells.entries():DirAccess.remove_absolute(b.saved_spells.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(b.saved_spells.directory)
 screen.return_to_main_menu();await process_frame;await process_frame
 if not check(current_scene.scene_file_path=="res://scenes/home.tscn","Main Menu failed"):return
 print("STANDALONE SPELL PASS: no animation editor, eight demo sources, same wizard, shared combat/resources, movement, reset and named saves")
 quit()
