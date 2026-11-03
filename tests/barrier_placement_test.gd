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
 for kind in ["Self","Follow","Place"]:
  setup.choices[kind].pressed.emit()
  assert(setup.attachment==kind and not setup.attachment_confirmed and setup.preview.visible)
  assert(not setup.size_card.visible,"Size opened before placement confirmation")
  assert(setup.choices[kind].icon!=null)
  setup.confirm.pressed.emit()
  assert(setup.attachment_confirmed and setup.size_card.visible)
  setup.size_slider.value=2.0
  setup.update_preview()
  var before:Vector3=setup.preview.global_position
  e.actor.global_position+=Vector3(1.0,0,0)
  setup.update_preview()
  var difference:Vector3=setup.preview.global_position-before
  assert(difference.is_equal_approx(Vector3.ZERO if kind=="Place" else Vector3.RIGHT),"Attachment moved incorrectly")
  assert(is_equal_approx(setup.preview.scale.x,1.0 if kind=="Self" else 2.0))
  assert(is_equal_approx(setup.preview.scale.z,1.0 if kind=="Self" else 2.0))
  assert(setup.preview.surface.visible==(kind!="Self"))
  assert(setup.size_slider.visible==(kind!="Self"))
  var overlays:Array=setup.preview.body_overlays
  assert(not overlays.is_empty())
  var body=preload("res://scripts/body_barrier_overlay.gd")
  assert(body.apply(e.actor.skeleton)==overlays,"Repeated preview stacked material passes")
  body.set_strength(overlays,0.0)
  # A runtime update must not erase the authoring coating.
  for overlay in overlays:assert(is_equal_approx(float(overlay.get_shader_parameter("barrier_strength")),1.0 if kind=="Self" else 0.0))
  if kind=="Place":
   setup.set_location(Vector3(2,0,4))
   setup.update_preview()
   assert(setup.preview.global_position.is_equal_approx(setup.placed_ground+Vector3.UP*2.0))
   setup.pick_button.pressed.emit()
   assert(setup.picking_location)
   var cancel:=InputEventKey.new();cancel.keycode=KEY_ESCAPE;cancel.pressed=true
   assert(setup.handle_input(cancel,null) and not setup.picking_location)
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
 print("BARRIER PLACEMENT PASS: Self block, following sphere, stationary placed sphere; preview/confirm; RHS size; location/cancel; Back and reset")
 quit()
