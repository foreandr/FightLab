extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func home_ready()->void:
 while current_scene==null or current_scene.scene_file_path!="res://scenes/home.tscn":await process_frame
 await process_frame
func editor_ready()->void:
 while current_scene==null or current_scene.scene_file_path!="res://scenes/combat_sandbox.tscn" or not current_scene.default_unit_ready or is_instance_valid(current_scene.loading_layer):await process_frame
 await process_frame
func run():
 change_scene_to_file("res://scenes/home.tscn");await home_ready()
 var settings=preload("res://scripts/game_settings_access.gd").service()
 if not check(current_scene.navigation_buttons.has("Store") and not settings.cog.visible,"Home Store missing or cog remains"):return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/home_store_menu.png")
 current_scene.show_page("Options");current_scene.navigation_buttons.Settings.pressed.emit()
 if not check(settings.opened,"Home Options lacks shared settings"):return
 settings.close();current_scene.navigation_buttons.Controls.pressed.emit()
 if not check(current_scene.controls_dialog.visible,"Controls legend missing from Home Options"):return
 current_scene.controls_dialog.hide()
 current_scene.show_page("Create");current_scene.navigation_buttons.Animation.pressed.emit();await editor_ready()
 var editor=current_scene
 if not check(editor.base_ui.find_child("WorkspaceNavigation",true,false)==null and not editor.options_button.visible and not settings.cog.visible,"Create top icons remain"):return
 if not check(editor.added_units.size()==1 and editor.focused_unit==editor.added_units[0],"Create does not start with one selected bot"):return
 editor.return_to_main_menu();await home_ready()
 current_scene.navigation_buttons.Store.pressed.emit()
 while current_scene==null or current_scene.scene_file_path!="res://scenes/animation_store.tscn" or not current_scene.store_screen_ready:await process_frame
 editor=current_scene
 if not check(editor.store_panel.visible and editor.store_panel.get_script()==null and editor.get_node_or_null("SpellBuilder")==null,"Home Store exposes authoring panels"):return
 var deadline:=Time.get_ticks_msec()+120000
 while (not editor.store_loaded or editor.store_loading_in_progress or editor.animation_store_list.get_child_count()==0) and Time.get_ticks_msec()<deadline:await process_frame
 if not check(editor.store_loaded and editor.animation_store_list.get_child_count()>0,"Home Store did not load paginated records"):return
 if not check(editor.animation_store_list.get_child_count()<=20,"Home Store loaded too many rows"):return
 var play:Button=editor.animation_store_list.find_child("StorePlay",true,false)
 if not check(play!=null,"Home Store lacks original play controls"):return
 play.pressed.emit()
 await process_frame
 if not check(editor.row_preview_unit==editor.focused_unit,"Store cannot preview on default bot"):return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/home_store_workspace.png")
 editor.close_animation_store();await home_ready()
 if not check(current_scene.page=="Home","Store Close did not return to Home"):return
 print("HOME STORE PASS: shared paginated Store and preview bot, no editor chrome, Home Options settings/controls, no top icons, one default bot, Close returns Home")
 quit()
