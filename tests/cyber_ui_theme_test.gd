extends SceneTree
const Design=preload("res://scripts/ui_design.gd")
var inspected:=0
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func settle():
 for i in 12:await process_frame
func verify(node:Node):
 if node is Control and node.is_visible_in_tree():
  assert(node.get_theme_font("font").get_font_name().begins_with("Rajdhani"),"Old font at "+str(node.get_path()))
  inspected+=1
 for child in node.get_children():verify(child)
func capture(name_:String):
 await settle();verify(current_scene)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/cyber_"+name_+".png")
 print("CYBER UI VERIFIED ",name_)
func run():
 change_scene_to_file("res://scenes/home.tscn");await settle()
 var music=root.get_node("SharedMusic")
 assert(music.tracks.size()==2)
 for track in music.tracks:assert("synthwave" in track.tags and track.license=="CC0-1.0")
 var ui=root.get_node("CyberInterface")
 var panel:=PanelContainer.new();var field:=Button.new();field.text="Dynamic test";field.add_theme_color_override("font_color",Color("382c1c"));field.add_theme_stylebox_override("normal",Design.box(Color("d8c7a4"),Color("b5a27f")));panel.add_child(field);current_scene.add_child(panel)
 await settle()
 assert(field.get_theme_color("font_color")==Design.TEXT and field.get_theme_stylebox("normal").bg_color==Design.RAISED)
 var clicks:int=ui.last_click;field.pressed.emit();assert(ui.last_click>clicks,"UI activation had no electronic click")
 assert(ui.voices[0].stream is AudioStreamWAV and ui.voices[0].bus=="Master")
 panel.queue_free();await capture("home")
 current_scene.show_page("Create");await capture("create_menu")
 var settings=root.get_node("GameSettings");settings.open();await capture("settings");verify(settings.dialog);settings.close()
 for scene in ["story_character_select","story_character_creator","story_opponents","story_replays","clothing_pavlov"]:
  change_scene_to_file("res://scenes/"+scene+".tscn");await capture(scene)
 change_scene_to_file("res://scenes/animation_store.tscn");await process_frame
 while current_scene==null or not current_scene.store_screen_ready:await process_frame
 # Store retains its existing page query and layout behavior.
 await capture("store")
 change_scene_to_file("res://scenes/spell_creation.tscn");await settle()
 var b=current_scene.spell_builder
 b.draft_path="user://logs/cyber_test_draft.cfg";b.preview_preferences_path="user://logs/cyber_test_preview.cfg"
 await capture("spell_demo")
 b.select_demo_choice("hook",false);b.confirm_demo_choice();await capture("spell_types")
 b.open_projectile_workspace();b.preview_projectile_effect("Fire");await capture("spell_results")
 b.open_fire_shape_picker();await capture("fire_styles")
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 while current_scene==null or not current_scene.default_unit_ready or is_instance_valid(current_scene.loading_layer):await process_frame
 await capture("animation_editor")
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 while not current_scene.animation_browser.ready_catalog:await process_frame
 while current_scene.animation_browser.thumbnails.busy or not current_scene.animation_browser.thumbnails.jobs.is_empty():await process_frame
 await capture("sandbox")
 print("CYBER UI PASS: ",inspected," visible controls across menus, Store, Story, spell pages, animation editor and Sandbox; dynamic overrides, electronic click, synth-only shared music")
 quit()
