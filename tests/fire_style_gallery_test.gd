extends SceneTree
const Catalog=preload("res://scripts/fire_style_catalog.gd")
const Appearance=preload("res://scripts/spell_appearance.gd")
const Textures=preload("res://scripts/spell_textures.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var ids:Dictionary={}
 var signatures:Dictionary={}
 for entry in Catalog.entries():
  if not check(not ids.has(entry.id),"Duplicate style ID"):return
  ids[entry.id]=true
  var visual:=entry.duplicate();visual.erase("id");visual.erase("title")
  var signature:=JSON.stringify(visual,"",true)
  if not check(not signatures.has(signature),"Duplicate preset settings"):return
  signatures[signature]=true
 var expected:int=Catalog.GALLERY_STYLES.size()+preload("res://scripts/community_fire_library.gd").ENTRIES.size()
 var pages:int=ceili(expected/12.0)
 var last_count:int=expected-(pages-1)*12
 if not check(ids.size()==expected,"Expanded style catalog size wrong"):return
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/inline_fire_gallery_test.cfg";b.draft_path="user://logs/inline_fire_gallery_draft_test.cfg"
 e.select_group("Spells");b.open_projectile_workspace();b.stop_preview_controls(true);b.clear_shots()
 b.set_process(false);b.set_physics_process(false);e.field.set_physics_process(false)
 e.actor.practice_god_mode=true
 var gallery=b.fire_style_gallery
 if not check(gallery.choices.is_empty(),"Images loaded before Fire tier"):return
 b.effect_choices.Fire.pressed.emit()
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 if not check(gallery.is_visible_in_tree() and gallery.choices.size()==12 and gallery.page_count()==pages and b.fire_style_confirm_button.is_visible_in_tree(),"Fire does not open inline paginated tier"):return
 if not check(e.get_viewport().get_embedded_subwindows().is_empty() and not preload("res://scripts/combat_pointer.gd").dialog_open(root),"Fire gallery is still modal"):return
 var original:Dictionary=b.demo_projectile_stats()
 var committed:Dictionary=b.appearances.get("Fire",{}).duplicate(true)
 gallery.page_input.value=pages
 for i in 2:await process_frame
 if not check(gallery.page==pages-1 and gallery.choices.size()==last_count and gallery.previews.size()==last_count and gallery.next_button.disabled,"Last page bounds or lazy preview count wrong"):return
 var chosen:Dictionary=Catalog.find("style_flame_04_natural_crimson")
 var chosen_page:int=floori(Catalog.entries().find(chosen)/12.0)
 gallery.set_page(chosen_page)
 gallery.choices[chosen.id].pressed.emit()
 if not check(b.fire_style_preview_id==chosen.id and not b.fire_style_confirm_button.disabled and b.appearances.get("Fire",{})==committed,"Clicking preview commits or loses selection"):return
 b.save_draft()
 var cfg:=ConfigFile.new();cfg.load(b.draft_path)
 if not check(cfg.get_value("appearance","elements",{}).get("Fire",{})==committed,"Unconfirmed preview leaked into saved draft"):return
 b.play_projectile_once();b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
 if not check(e.field.shots.size()==1 and e.field.shots[0].spec.appearance.fire_style_id==chosen.id,"Play does not cast unconfirmed preview"):return
 var shot=e.field.shots[0]
 var look:Dictionary=shot.node.get_meta("look")
 if not check(look.flame_flow==chosen.flame_flow and look.color.is_equal_approx(chosen.color),"Variant structure/motion ignored by actual cast"):return
 if not check(shot.node.material_override.get_shader_parameter("flame_turbulence")==chosen.flame_turbulence,"Actual shader ignores selected silhouette"):return
 var current:Dictionary=b.demo_projectile_stats()
 for key in ["mana","stamina","physical_damage","radius","velocity","burn_dps"]:
  if not check(is_equal_approx(float(current[key]),float(original[key])),"Style changes combat stats: "+key):return
 b.fire_style_confirm_button.pressed.emit()
 if not check(b.fire_style_confirmed and b.fire_style_confirm_button.disabled and Catalog.active_id(b.appearances.Fire)==chosen.id and b.fire_sound_screen.is_visible_in_tree() and not gallery.is_visible_in_tree(),"Confirm does not advance to sound selection"):return
 cfg.load(b.draft_path)
 if not check(Catalog.active_id(cfg.get_value("appearance","elements",{}).Fire)==chosen.id,"Saved structure/form preset fails round trip"):return
 b.stop_preview_controls(true)
 gallery.set_page(floori(Catalog.entries().find(Catalog.find("flame_04"))/12.0));gallery.choices.flame_04.pressed.emit()
 if not check(e.field.shots.size()==1 and shot.node.get_meta("look").fire_style_id==chosen.id,"Preview mutates/removes existing shot"):return
 b.leave_fire_styles()
 if not check(not gallery.is_visible_in_tree() and Catalog.active_id(b.appearances.Fire)==chosen.id and not b.fire_style_editing,"Back does not discard unconfirmed choice"):return
 b.effect_choices.Fire.pressed.emit()
 if not check(gallery.page==chosen_page and gallery.choices[chosen.id].button_pressed,"Reenter loses confirmed page/highlight"):return
 # Imported sheets are cast through the same preview and retain their origin.
 b.stop_preview_controls(true)
 gallery.set_page(floori(Catalog.entries().find(Catalog.find("soluna_fire"))/12.0));gallery.choices.soluna_fire.pressed.emit()
 b.play_projectile_once();b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
 var imported:Dictionary=e.field.shots.back()
 if not check(imported.spec.appearance.author=="Soluna Software" and imported.spec.appearance.source.begins_with("https://opengameart.org/") and imported.node.material_override.get_shader_parameter("flame_sheet_frames")==32,"Imported sheet loses source or animation layout during actual cast"):return
 b.fire_style_confirm_button.pressed.emit();cfg.load(b.draft_path)
 if not check(Catalog.active_id(cfg.get_value("appearance","elements",{}).Fire)=="soluna_fire","Imported style fails save/reload"):return
 if not check(not Catalog.look("flame_01",b.appearances.Fire).has("author"),"Switching style retains unrelated artist credit"):return
 # New community assets use the same real click/Play/Confirm/save pipeline.
 b.stop_preview_controls(true)
 var community:Dictionary=preload("res://scripts/community_fire_library.gd").ENTRIES[0]
 gallery.set_page(0);gallery.choices[community.id].pressed.emit()
 b.play_projectile_once();b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
 var community_shot:Dictionary=e.field.shots.back()
 if not check(community_shot.spec.appearance.source==community.source and community_shot.spec.appearance.author==community.author and community_shot.node.material_override.get_shader_parameter("flame_sheet_frames")==community.frames and community_shot.node.material_override.get_shader_parameter("flame_soft_alpha")==true,"Community cast loses original motion, credits or alpha"):return
 b.fire_style_confirm_button.pressed.emit();cfg.load(b.draft_path)
 if not check(Catalog.active_id(cfg.get_value("appearance","elements",{}).Fire)==community.id,"Community style fails save/reload"):return
 if not check(not Catalog.look("flame_04",b.appearances.Fire).has("origin"),"Origin metadata leaks into another style"):return
 # Representative forms all create nonempty geometry using the shared renderer.
 for form in Catalog.FORMS:
  var id:String="style_flame_02_%s_blue"%form.id
  var node:=Appearance.visual("Fire",0.3,Catalog.look(id))
  if not check(node.mesh!=null and node.mesh.get_aabb().size.length()>0.1,"Empty variant mesh"):return
  node.free()
 b.open_fire_shape_picker()
 gallery.page_input.value=1
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/inline_fire_gallery.png")
 if not check(b.fire_style_confirm_button.get_global_rect().end.y<b.spell_playback_panel.get_global_rect().position.y,"Gallery Confirm is below bottom toolbar"):return
 print("INLINE FIRE GALLERY PASS: ",expected," styles / ",pages," pages, only 12 previews, community artwork casts and saves with original credits, Back discards, existing shots and combat stats preserved")
 quit()
