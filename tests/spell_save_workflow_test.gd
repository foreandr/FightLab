extends SceneTree
const Definition=preload("res://scripts/spell_definition.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
 var e=current_scene;var b=e.spell_builder
 b.draft_path="user://logs/spell_save_ui_draft.cfg";b.preview_preferences_path="user://logs/spell_save_ui_preview.cfg"
 b.saved_spells.directory="user://logs/spell_save_ui_"+Crypto.new().generate_random_bytes(4).hex_encode()
 e.select_group("Spells");b.select_demo_choice("cross",false);b.open_projectile_workspace();b.stop_preview_controls(true)
 b.set_process(false);b.set_physics_process(false);e.field.set_physics_process(false)
 b.preview_projectile_effect("Fire");b.stop_preview_controls(true)
 var fire=preload("res://assets/spells/fire/library.gd")
 b.set_fire_style(fire.styles()[0].id);b.confirm_fire_style();b.set_fire_sound("lentikula_fire_4");b.confirm_fire_sound()
 if not check(b.spell_save_screen.is_visible_in_tree() and not b.fire_sound_screen.is_visible_in_tree(),"Sound Confirm does not advance to name/save tier"):return
 b.projectile_allocations.Fire={"size":0.2,"speed":0.3,"effect":0.5}
 b.demo_duration=4.0;b.casting_animation.duration=4.0;b.total_power=0.15;b.release_fraction=0.55
 b.spell_save_screen.name_input.text="My flame"
 b.spell_save_screen.save_button.pressed.emit()
 var entries:Array=b.saved_spells.entries()
 if not check(entries.size()==1 and entries[0].name=="My flame" and b.spell_save_screen.status.text.contains("Saved:"),"Name/Save button failed"):return
 var saved:Dictionary=entries[0]
 if not check(not saved.has("total_power") and not saved.has("animation_duration") and not saved.has("release") and saved.appearance.sound_id=="lentikula_fire_4","Save retains demo context or drops assets"):return
 # Enter key saves safely as another named definition rather than overwriting.
 b.spell_save_screen.name_input.text_submitted.emit("My flame")
 if not check(b.saved_spells.entries().size()==2 and b.saved_spells.entries()[1].name=="My flame (1)","Keyboard save or duplicate name suffix failed"):return
 b.demo_duration=2.0;b.casting_animation.duration=2.0;b.total_power=0.7;b.release_fraction=0.1
 var profile:Dictionary=b.casting_animation.duplicate(true)
 b.projectile_allocations.Fire={"size":0.8,"speed":0.1,"effect":0.1}
 b.fire_sound_preview_id="fire_roar"
 if not check(b.load_named_spell(saved.id),"Saved spell cannot load"):return
 if not check(b.demo_duration==2.0 and b.total_power==0.7 and b.release_fraction==0.1 and b.casting_animation==profile,"Load overwrites animation timing/power/binding"):return
 if not check(b.projectile_allocations.Fire==saved.allocation and b.appearances.Fire.sound_id==saved.appearance.sound_id and b.projectile_spec().sound_id==saved.appearance.sound_id,"Load lost distribution/styles/sounds"):return
 b.limiter_enabled=false
 var blocked:Dictionary=b.save_named_spell("Blocked")
 if not check(not blocked.ok and b.saved_spells.entries().size()==2,"Limiter-off save allowed"):return
 b.limiter_enabled=true;b.refresh_spell_save_controls()
 b.spell_save_screen.name_input.text="My flame"
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/spell_save_workspace.png")
 if not check(b.spell_save_screen.save_button.get_global_rect().end.y<b.spell_playback_panel.get_global_rect().position.y,"Save is below the toolbar"):return
 for record in b.saved_spells.entries():DirAccess.remove_absolute(b.saved_spells.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(b.saved_spells.directory)
 print("SPELL SAVE UI PASS: inline name/save after sound, keyboard save, unique names, load keeps animation/power/release, saved choices and limiter guard")
 quit()
