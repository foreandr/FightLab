extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder
 b.draft_path="user://logs/reactions_draft.cfg";b.preview_preferences_path="user://logs/reactions_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 b.choose_barrier_kind("Shield");b.confirm_barrier_kind()
 assert(b.barrier_test_controls.get_parent().get_parent()==b.spell_playback_panel,"Tester controls are not in the bottom bar")
 e.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 for tester in [b.barrier_tester,b.barrier_puncher]:tester.set_physics_process(false)
 var a=e.actor;var puncher=b.barrier_puncher.unit
 assert(not a.practice_immortal and a.editor_pose_locked)
 # Returning after a jab must keep facing the player, without turning to base.
 puncher.position.x+=0.35
 var before_yaw:float=puncher.rotation.y
 puncher.tick(1.0/60.0)
 assert(absf(angle_difference(before_yaw,puncher.rotation.y))<0.2,"Tester snapped toward its home")
 for i in 50:puncher.tick(1.0/60.0)
 var toward:Vector3=(a.global_position-puncher.global_position).normalized()
 assert(puncher.global_basis.z.dot(toward)>0.98,"Tester turned away between jabs")
 # Shared nonlethal head/body reactions must retain their pose and advance.
 for zone in ["chest","head"]:
  a.invulnerability=0.0
  assert(a.receive_magic(5.0,Vector3.FORWARD,puncher,a.bone_point("spine_03"),zone))
  assert(a.mode=="hit" and a.clip==("ual1/Hit_Head" if zone=="head" else "ual1/Hit_Chest"))
  var clip:String=a.clip
  a.tick(0.1);b.process_demo_preview(0.1)
  assert(a.mode=="hit" and a.mode_time>0.0 and a.clip==clip,"Preview overwrote the shared hit reaction")
  var pos:Vector3=a.global_position
  b.move_caster(0.1,Vector2(0,1),true)
  assert(a.global_position.is_equal_approx(pos),"Preview movement overrode hit reaction")
  a.tick(0.5)
  b.process_demo_preview(0.01)
 a.invulnerability=0.0
 assert(a.receive_magic(999.0,Vector3.FORWARD,puncher))
 assert(a.health==0 and is_instance_valid(a.ragdoll),"Lethal hit did not create shared ragdoll")
 a.tick(0.05);b.process_demo_preview(0.05);b.play_demo_preview();b.reset_caster_pose()
 assert(a.mode=="ragdoll" and not b.playing and is_instance_valid(a.ragdoll),"Editor overwrote death")
 b.reset_practice_scene()
 assert(a.health==a.MAX_HEALTH and not is_instance_valid(a.ragdoll),"Reset did not restore player")
 print("SPELL REACTIONS PASS: bottom tester controls, stable facing, shared head/body hit reactions, lethal ragdoll, no preview/movement override, reset restores player")
 quit()
