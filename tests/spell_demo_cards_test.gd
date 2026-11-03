extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 set_meta("create_workspace_entry","Spell")
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 while current_scene==null or not current_scene.default_unit_ready or is_instance_valid(current_scene.loading_layer):await process_frame
 var e=current_scene;var b=e.spell_builder
 if not check(not b.demo_timing_panel.visible and not b.demo_choice_selected,"RHS is visible before selecting a demo"):return
 var grid:GridContainer=b.demo_screen.find_child("DemoAnimationGrid",true,false)
 if not check(grid.get_child_count()==9 and b.grab_demo_button.get_parent()==grid and b.grab_demo_button.disabled,"Grab is not part of the same card grid"):return
 for card in grid.get_children():
  var preview:TextureRect=card.find_child("PreviewImage",true,false)
  if not check(preview!=null and preview.texture!=null and card.focus_mode==Control.FOCUS_ALL,"Missing image or keyboard focus"):return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/demo_cards_initial.png")
 b.demo_choices.knee.pressed.emit()
 if not check(b.demo_choice_selected and b.creation_step=="demo" and b.demo_timing_panel.visible and b.demo_choices.knee.button_pressed and not b.demo_confirm_button.disabled,"Selection fails to preview/reveal RHS without advancing"):return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/demo_cards_selected.png")
 b.stop_preview_controls(true);b.confirm_demo_choice()
 if not check(b.creation_step=="delivery","Confirm no longer advances"):return
 b.return_to_start()
 if not check(not b.demo_timing_panel.visible,"Back to start exposes RHS before choosing"):return
 var spinner=preload("res://scripts/loading_spinner.gd").new();root.add_child(spinner)
 spinner.size=Vector2(320,36);spinner.position=Vector2(700,850)
 spinner.value=45
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/demo_loading_wheel.png")
 if not check(spinner.value==45 and spinner.get_theme_stylebox("fill") is StyleBoxEmpty,"Loading wheel lost progress diagnostics or still paints a bar"):return
 print("SPELL DEMO CARDS PASS: actual pose images, uniform disabled Grab, RHS revealed on choice, explicit Confirm, start hides RHS, shared spinner preserves diagnostics")
 quit()
