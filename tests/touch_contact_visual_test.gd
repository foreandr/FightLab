extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder;var actor=e.actor
 b.draft_path="user://logs/touch_visual_draft.cfg";b.preview_preferences_path="user://logs/touch_visual_preview.cfg"
 b.select_demo_choice("cross",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Touch");b.stop_preview_controls(true);b.confirm_delivery_type()
 var t=b.touch_authoring
 var originals:Dictionary={}
 for node in actor.skeleton.find_children("*","MeshInstance3D",true,false):
  if not node.get_meta("presentation_overlay",false):originals[node.get_instance_id()]=node.mesh
 assert(t.confirm.text=="Next" and t.grid.visible and not t.effect_panel.visible)
 t.toggle("hand_r");t._process(0.0)
 assert(t.selected==["hand_l","hand_r"])
 t.confirm.pressed.emit()
 assert(t.confirmed and not t.grid.visible and t.effect_panel.visible and t.effect_summary.text.contains("Left hand") and t.effect_summary.text.contains("Right hand"))
 t._process(0.0)
 var visual=actor.touch_contact_visual
 assert(visual.contacts.is_empty(),"Idle selection left a permanent contact highlight")
 b.play_projectile_once();t._process(0.0);visual._process(0.0)
 assert(not visual.runtime_spec.is_empty(),"Shared cast start did not activate contact presentation")
 assert(visual.white.get_shader_parameter("thickness")>visual.fire.get_shader_parameter("thickness"))
 assert(visual.contacts==["hand_l","hand_r"] and visual.element=="None")
 for bone in ["hand_l","hand_r"]:
  assert(not visual.regions[bone].records.is_empty(),"No skinned hand region was extracted")
  for record in visual.regions[bone].records:
   assert(record.outline.visible and record.outline.skin==record.source.skin)
   assert(record.outline.get_node(record.outline.skeleton)==actor.skeleton)
   assert(record.outline.material_override==visual.white and record.source.mesh==originals[record.source.get_instance_id()])
   assert(record.outline.mesh!=record.source.mesh)
  for flame in visual.regions[bone].flames:assert(not flame.visible)
 var physical:Dictionary=b.demo_preview_spec()
 b.stop_preview_controls(true);t._process(0.0);visual._process(0.0)
 assert(visual.contacts.is_empty(),"Stopping physical playback left its outline visible")
 t.effect_buttons.Fire.pressed.emit();t._process(0.0);visual._process(0.0)
 assert(visual.contacts.is_empty(),"Choosing Fire left permanent flames")
 b.play_projectile_once();t._process(0.0);visual._process(0.0)
 var fire:Dictionary=b.demo_preview_spec()
 assert(fire.projectile_element=="Fire" and fire.potency>0.0 and fire.mana>physical.mana and is_equal_approx(fire.damage,physical.damage))
 assert(actor.burn_time==0.0 and visual.element=="Fire")
 for bone in ["hand_l","hand_r"]:
  for flame in visual.regions[bone].flames:
   assert(flame.visible and flame.global_position.distance_to(actor.bone_point(bone))<0.3)
 var before:Vector3=visual.regions.hand_l.flames[0].global_position
 actor.global_position+=Vector3.RIGHT
 visual._process(0.0)
 assert(visual.regions.hand_l.flames[0].global_position.is_equal_approx(before+Vector3.RIGHT))
 t.effect_confirm.pressed.emit();assert(t.effect_confirmed)
 b.reset_practice_scene();t._process(0.0);visual._process(0.0)
 assert(visual.contacts.is_empty() and t.preview_effect=="Fire" and t.selected==["hand_l","hand_r"],"Reset should retain choices without idle flames")
 var target=b.practice_human;target.practice_return_enabled=false
 target.global_position=e.field.surface_placement(actor.global_position+actor.global_basis.z*0.9)
 b.set_third_person_focus(target);target.invulnerability=0.0
 for i in 4:await physics_frame
 var serial:int=e.field.shot_serial
 b.play_projectile_once()
 var limit:=Time.get_ticks_msec()+3500
 while target.burn_time==0.0 and Time.get_ticks_msec()<limit:await process_frame
 assert(target.damage_taken>0 and target.burn_time>0,"Fire touch did not apply shared burn on contact")
 assert(actor.burn_time==0.0 and e.field.shot_serial==serial)
 while b.playing:await process_frame
 t._process(0.0);visual._process(0.0)
 assert(visual.contacts.is_empty(),"Animation completion left contact effects visible")
 b.show_creation_step("delivery");b.stop_preview_controls(true);t._process(0.0);visual._process(0.0)
 assert(visual.contacts.is_empty(),"Leaving Touch leaked selected-limb effects")
 print("TOUCH CONTACT VISUAL PASS: Next then effects, left/right selection, playback-only thicker skinned white regions, original mesh intact, shared hand flames follow bones, no self-burn, fire contact applies burn without projectile, reset and exit cleanup")
 quit()
