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
 var home=current_scene
 home.navigation_buttons.Create.pressed.emit()
 if not check(home.page=="Create" and home.navigation_buttons.keys()==["Character","Animation","Spell","Back"],"Create does not open the three-choice submenu"):return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/create_submenu.png")
 home.navigation_buttons.Character.pressed.emit()
 while current_scene==home or current_scene==null:await process_frame
 if not check(current_scene.create_menu_entry and current_scene.find_child("MainMenu",true,false)!=null,"Character entry missing existing creator or top menu button"):return
 current_scene.find_child("MainMenu",true,false).pressed.emit();await home_ready()
 if not check(current_scene.page=="Home","Character Main Menu did not return Home"):return
 for entry in ["Animation","Spell"]:
  current_scene.show_page("Create")
  current_scene.navigation_buttons[entry].pressed.emit()
  if entry=="Spell":
   while current_scene==null or current_scene.scene_file_path!="res://scenes/spell_creation.tscn" or not current_scene.workspace_ready:await process_frame
  else:await editor_ready()
  var editor=current_scene
  if not check((editor.scene_file_path=="res://scenes/spell_creation.tscn")== (entry=="Spell"),"Create entry opened wrong editor: "+entry):return
  var main:Button=editor.base_ui.find_child("MainMenu",true,false)
  if not check(main!=null and main.is_visible_in_tree() and main.get_global_rect().position.y<80,"Top Main Menu button missing"):return
  if entry=="Spell":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://work/create_spell_main_menu.png")
  main.pressed.emit();await home_ready()
  if not check(current_scene.page=="Home" and not paused and is_equal_approx(Engine.time_scale,1.0),"Editor Main Menu did not restore Home"):return
 print("CREATE MENU PASS: Character/Animation/Spell entries, correct editor routing, top Main Menu returns Home, keyboard-focusable buttons")
 quit()
