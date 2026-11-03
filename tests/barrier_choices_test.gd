extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var screen=current_scene
 var b=screen.spell_builder
 b.draft_path="user://logs/barrier_choices_draft.cfg";b.preview_preferences_path="user://logs/barrier_choices_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 assert(b.creation_step=="barrier" and b.barrier_screen.visible and b.demo_timing_panel.visible)
 assert(b.barrier_choices.keys()==["Shield","Absorb","Reflect","Effect"])
 for kind in b.barrier_choices:
  var option:Button=b.barrier_choices[kind]
  assert(option.disabled==(kind!="Shield") and option.icon!=null)
 var shots:int=screen.field.shot_serial
 b.barrier_choices.Shield.pressed.emit()
 assert(b.barrier_kind=="Shield" and b.barrier_choices.Shield.button_pressed)
 for kind in ["Absorb","Reflect","Effect"]:b.choose_barrier_kind(kind)
 assert(b.barrier_kind=="Shield" and screen.field.shot_serial==shots,"Disabled choice or unintended projectile")
 b.show_creation_step("delivery");b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 assert(b.barrier_choices.Shield.button_pressed,"Back navigation lost selection")
 b.return_to_start()
 assert(b.barrier_kind.is_empty() and not b.barrier_choices.Shield.button_pressed)
 print("BARRIER CHOICES PASS: Shield enabled, Absorb/Reflect/Effect disabled and guarded, icons, selection/back/start behavior; no projectile or shield mechanics added")
 quit()
