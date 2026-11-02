extends SceneTree
const Catalog=preload("res://scripts/fire_style_catalog.gd")
const Textures=preload("res://scripts/spell_textures.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/fire_gallery_preview_test.cfg";b.draft_path="user://logs/fire_gallery_draft_test.cfg"
 e.select_group("Spells");b.open_projectile_workspace();b.stop_preview_controls(true);b.clear_shots()
 b.set_process(false);b.set_physics_process(false);e.field.set_physics_process(false)
 e.actor.practice_god_mode=true
 b.effect_choices.Fire.pressed.emit()
 var gallery=b.fire_style_gallery
 if not check(gallery.choices.is_empty() and gallery.previews.is_empty(),"Gallery renders previews before opening"):return
 var original:Dictionary=b.demo_projectile_stats()
 b.open_fire_shape_picker()
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 if not check(b.fire_shape_popup.visible and gallery.choices.size()==12 and gallery.previews.size()==12 and gallery.page==0,"First page does not show 12 images"):return
 if not check(gallery.previous_button.disabled and not gallery.next_button.disabled and gallery.page_count()==2,"Pagination bounds wrong"):return
 for viewport in gallery.previews:
  if not check(viewport.render_target_update_mode in [SubViewport.UPDATE_ONCE,SubViewport.UPDATE_DISABLED],"Static thumbnail keeps rendering"):return
 var preview:Image=gallery.previews[0].get_texture().get_image()
 var backdrop:=preview.get_pixel(0,0)
 var visible_fire:=false
 for x in range(6,138,6):
  for y in range(6,138,6):
   var color:=preview.get_pixel(x,y)
   if absf(color.r-backdrop.r)+absf(color.g-backdrop.g)+absf(color.b-backdrop.b)>0.3:visible_fire=true
 if not check(visible_fire,"Thumbnail is empty/background only"):return
 root.get_texture().get_image().save_png("res://work/fire_style_gallery_page1.png")
 gallery.next_button.pressed.emit()
 for i in 2:await process_frame
 if not check(gallery.page==1 and gallery.choices.size()==8 and gallery.previews.size()==8 and gallery.next_button.disabled,"Second page not lazily bounded"):return
 if not check(gallery.next_button.focus_mode==Control.FOCUS_ALL and gallery.choices.values()[0].focus_mode==Control.FOCUS_ALL,"Gallery has no keyboard route"):return
 gallery.choices.shape_star.pressed.emit()
 if not check(not b.fire_shape_popup.visible and b.appearances.Fire.shape=="Star","Choosing image does not activate its shape"):return
 b.play_projectile_once();b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
 if not check(e.field.shots.size()==1 and e.field.shots[0].node.get_meta("look").shape=="Star","Actual cast ignores selected gallery shape"):return
 var first=e.field.shots[0].node
 b.open_fire_shape_picker()
 if not check(gallery.page==1 and gallery.choices.shape_star.button_pressed,"Reopen loses active page/highlight"):return
 gallery.previous_button.pressed.emit()
 gallery.choices.flame_01.pressed.emit()
 if not check(e.field.shots.size()==1 and first.get_meta("look").shape=="Star","New choice casts or mutates/deletes old projectile"):return
 b.stop_preview_controls(true);b.play_projectile_once();b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
 var shot=e.field.shots.back()
 if not check(shot.node.get_meta("look").shape=="Flame" and shot.spec.appearance.texture=="flame_01","Chosen flame texture not attached to cast"):return
 if not check(shot.node.material_override.get_shader_parameter("mask_texture")==Textures.texture("flame_01"),"Gallery and real flame use different textures"):return
 var current:Dictionary=b.demo_projectile_stats()
 for key in ["mana","stamina","physical_damage","radius","velocity","burn_dps"]:
  if not check(is_equal_approx(float(current[key]),float(original[key])),"Visual choice changes mechanics: "+key):return
 b.save_draft();b.appearances={};b.load_draft();b.refresh_fire_shape()
 if not check(Catalog.active_id(b.appearances.Fire)=="flame_01" and b.fire_shape_button.text.contains("Flame 01"),"Flame choice not restored"):return
 b.stop_preview_controls(true);b.set_fire_shape("Cube")
 if not check(b.appearances.Fire.shape=="Cube","Legacy shape scripting no longer works"):return
 print("FIRE STYLE GALLERY PASS: 20 shared visual styles, 12/8 paged images, static actual-render thumbnails, lazy pages, active highlight/reopen, real cast texture/shape, independent old projectiles, unchanged shared stats and saved selection")
 quit()
