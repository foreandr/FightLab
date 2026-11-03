extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder
 b.draft_path="user://logs/barrier_placement_draft.cfg";b.preview_preferences_path="user://logs/barrier_placement_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 var setup=b.barrier_authoring
 assert(not setup.visible and not setup.size_card.visible)
 b.choose_barrier_kind("Shield");b.confirm_barrier_kind()
 for tester in [b.barrier_tester,b.barrier_puncher]:tester.set_paused(true)
 b.set_process(false);b.set_physics_process(false)
 assert(setup.visible and setup.attachment.is_empty() and setup.confirm.disabled)
 assert(not setup.size_card.visible)
 for disabled_kind in ["Follow","Place"]:
  assert(setup.choices[disabled_kind].disabled)
  setup.choose(disabled_kind)
  assert(setup.attachment.is_empty(),"Disabled placement was selectable")
 setup.choices.Self.pressed.emit()
 assert(setup.attachment=="Self" and not setup.attachment_confirmed)
 assert(not setup.preview.visible and not e.actor.self_barrier.active())
 assert(not setup.size_card.visible)
 setup.confirm.pressed.emit()
 assert(setup.attachment_confirmed and setup.size_card.visible)
 assert(not setup.size_slider.visible and setup.strength_slider.visible and setup.lifetime_slider.visible)
 setup.strength_slider.value=30.0;setup.lifetime_slider.value=3.0
 assert(setup.definition().shield_strength==30.0 and setup.definition().shield_duration==3.0)
 setup.confirm.pressed.emit()
 assert(setup.size_confirmed and setup.confirm.disabled)
 b.barrier_back()
 assert(b.creation_step=="shield" and not setup.attachment_confirmed and not setup.size_card.visible)
 b.barrier_back()
 setup.update_preview()
 assert(b.creation_step=="barrier" and not setup.preview.visible)
 for overlay in setup.preview.body_overlays:assert(is_zero_approx(float(overlay.get_shader_parameter("barrier_strength"))))
 b.return_to_start()
 assert(setup.attachment.is_empty() and not setup.attachment_confirmed)
 print("BARRIER PLACEMENT PASS: only Self Block selectable; Follow and Place disabled; timed shield settings/confirm, Back and reset")
 quit()
