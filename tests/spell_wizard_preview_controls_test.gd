extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error(message);Engine.time_scale=1.0;quit(1);return false
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/spell_wizard_controls_test.cfg"
 b.draft_path="user://logs/spell_wizard_controls_draft_test.cfg"
 e.select_group("Spells")
 b.set_process(false);b.set_physics_process(false)
 e.actor.practice_god_mode=true
 if not check(b.creation_step=="demo" and b.spell_playback_panel.is_visible_in_tree(),"Initial demo step hides playback toolbar"):return
 if not check(not b.demo_choice_selected and not b.playing and b.projectile_preview_button.disabled and b.projectile_repeat_button.disabled and b.demo_confirm_button.disabled,"Play enabled or default animation running before selection"):return
 if not check(b.offset_bottom== -60 and b.demo_timing_panel.offset_bottom== -60,"Early panels overlap bottom toolbar"):return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/spell_wizard_initial.png")
 b.play_projectile_once();b.set_demo_duration(1.0)
 if not check(not b.playing,"Play or duration edit starts unselected demo"):return
 # Slow mo and scene/debug tools are accessible even before picking a clip.
 b.projectile_slow_button.toggled.emit(true)
 if not check(b.preview_slow and Engine.time_scale==0.25,"Early Slow mo is unavailable"):return
 b.projectile_slow_button.toggled.emit(false)
 b.demo_choices.cross.pressed.emit()
 if not check(b.demo_choice_selected and b.playing and not b.projectile_preview_button.disabled and not b.projectile_repeat_button.disabled,"Choosing a demo does not enable playback"):return
 b.projectile_repeat_button.toggled.emit(true)
 b.process_demo_preview(1.01)
 b.process_demo_preview(b.REPEAT_DELAY+b.DEMO_TRANSITION_SECONDS+0.01)
 if not check(b.playing and b.preview_repeating,"Repeat cannot replay initial demo"):return
 b.stop_preview_controls(true)
 b.demo_confirm_button.pressed.emit()
 if not check(b.creation_step=="delivery" and b.spell_playback_panel.is_visible_in_tree() and b.delivery_confirm_button.disabled,"Delivery controls/initial Confirm wrong"):return
 b.delivery_type=""
 b.save_draft()
 var before:=FileAccess.get_file_as_string(b.draft_path)
 b.delivery_choices.Projectile.pressed.emit()
 if not check(b.creation_step=="delivery" and b.preview_delivery_type=="Projectile" and b.delivery_type.is_empty() and not b.delivery_confirm_button.disabled,"Clicking type advances or commits before Confirm"):return
 if not check(FileAccess.get_file_as_string(b.draft_path)==before,"Type preview saved unconfirmed draft"):return
 b.set_demo_duration(2.0);b.set_release_fraction(0.4)
 b.delivery_choices.Projectile.pressed.emit()
 if not check(b.demo_duration==2.0 and is_equal_approx(b.release_fraction,0.4),"Replaying type reset timing settings"):return
 b.process_demo_preview(0.81)
 if not check(b.released and not e.field.shots.is_empty(),"Projectile type preview does not actually cast"):return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/spell_type_preview.png")
 b.delivery_confirm_button.pressed.emit()
 if not check(b.creation_step=="projectile" and b.delivery_type=="Projectile" and b.demo_duration==2.0 and is_equal_approx(b.release_fraction,0.4),"Confirm fails or resets preview settings"):return
 var cfg:=ConfigFile.new();cfg.load(b.draft_path)
 if not check(cfg.get_value("spell","delivery_type","")=="Projectile","Confirm does not save committed type"):return
 if not check(b.delivery_confirm_button.focus_mode==Control.FOCUS_ALL and b.projectile_preview_button.focus_mode==Control.FOCUS_ALL,"New controls lack keyboard route"):return
 b.stop_preview_controls(true);b.show_creation_step("demo")
 var key:=InputEventKey.new();key.keycode=KEY_1;key.pressed=true
 b._input(key)
 if not check(b.playing,"Play [1] shortcut unavailable on demo step"):return
 b.stop_preview_controls(true);b.set_preview_slow(true)
 e.select_group("Motion")
 if not check(not b.spell_playback_panel.is_visible_in_tree() and not b.preview_slow and Engine.time_scale==1.0,"Leaving Spells leaves toolbar or Slow mo active"):return
 print("SPELL WIZARD CONTROLS PASS: toolbar from entry, disabled unselected playback, demo Play/Repeat/Slow mo and 1 shortcut, type preview casts without navigation/save, explicit Confirm preserves timing and commits, clean mode exit")
 quit()
