extends SceneTree
const Camera=preload("res://scripts/third_person_camera.gd")
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder
 b.draft_path="user://logs/free_camera_draft.cfg";b.preview_preferences_path="user://logs/free_camera_preview.cfg"
 b.select_demo_choice("cross",false);b.stop_preview_controls(true)
 b.set_physics_process(false);b.set_process(false)
 for stage in ["demo","delivery","projectile","barrier","shield"]:
  b.stop_preview_controls(true);b.demo_choice_selected=true
  b.delivery_type="Barrier" if stage in ["barrier","shield"] else "Projectile"
  b.preview_delivery_type=b.delivery_type
  b.show_creation_step(stage)
  if is_instance_valid(b.barrier_tester):b.barrier_tester.set_physics_process(false)
  # Isolate camera/input from mannequin body collisions and incoming test shots.
  e.actor.collision_mask=1|1024
  e.actor.global_position=Vector3.ZERO;b.set_third_person_focus(null)
  e.field.story_camera_base_yaw=0.4;e.field.camera_orbit_yaw=0.0;e.field.camera_orbit_pitch=0.35;e.field.camera_zoom=1.2
  for i in 100:b.update_third_person_view(1.0/60.0)
  for axis in [Vector2(0,1),Vector2(1,0),Vector2(0,-1),Vector2(-1,0)]:
   var offset:Vector3=e.field.camera.global_position-e.actor.global_position
   var heading:Vector3=Camera.movement_heading(e.field,e.actor)
   var start:Vector3=e.actor.global_position
   var expected:Vector3=Camera.movement_direction(e.field,e.actor,axis)
   for i in 24:
    b.move_caster(1.0/60.0,axis,false);b.update_third_person_view(1.0/60.0)
    await physics_frame
   var actual:Vector3=e.actor.global_position-start
   assert(actual.length()>0.3 and actual.normalized().dot(expected)>0.999,"Free movement changed direction in %s axis %s: actual %s expected %s position %s"%[stage,axis,actual,expected,e.actor.global_position])
   var drift:Vector3=e.field.camera.global_position-e.actor.global_position-offset
   assert(Vector2(drift.x,drift.z).length()<0.02,"Camera failed to follow player in "+stage)
   assert(heading.angle_to(Camera.movement_heading(e.field,e.actor))<0.001,"Movement changed orbit heading")
 print("SPELL FREE CAMERA PASS: W/A/S/D track player without horizontal camera drift or curved headings across demo, delivery, projectile, Barrier and Shield")
 quit()
