extends SceneTree
const Conditioner=preload("res://scripts/animation_motion_conditioning.gd")
func _initialize():call_deferred("run")
func run():
 var model=load("res://assets/characters/base/Superhero_Male_FullBody.gltf").instantiate();root.add_child(model)
 var rig:Skeleton3D=model.find_child("Skeleton3D")
 var a:=Animation.new();a.length=1.0
 for index in 13:
  var track:=a.add_track(Animation.TYPE_ROTATION_3D)
  a.track_set_path(track,NodePath("Skeleton3D:pelvis"))
  for key in 31:
   var angle:=0.0
   if index==0 and key==15:angle=100.0
   if index==1:angle=key*0.4+(2.0 if key%2==1 else -2.0)
   if index==2 and key in [14,15,16,17]:angle=80.0
   a.rotation_track_insert_key(track,key/30.0,Quaternion(Vector3.UP,deg_to_rad(angle)))
 var result:=Conditioner.prepare(a,rig)
 assert(result.ok,str(result))
 assert(result.report.repaired_spikes==1)
 var cleaned:Animation=result.animation
 assert(is_equal_approx(cleaned.length,a.length))
 assert(cleaned.track_get_key_count(0)==a.track_get_key_count(0))
 assert(cleaned.track_get_key_time(0,15)==a.track_get_key_time(0,15))
 assert((cleaned.track_get_key_value(0,15) as Quaternion).angle_to(Quaternion.IDENTITY)<0.001)
 assert((a.track_get_key_value(0,15) as Quaternion).angle_to(Quaternion.IDENTITY)>1.0,"Mutated source")
 assert((cleaned.track_get_key_value(2,15) as Quaternion).angle_to(Quaternion.IDENTITY)>1.0,"Erased a sustained fast strike")
 assert(result.report.max_joint_degrees_per_second_after<result.report.max_joint_degrees_per_second_before)
 a.track_set_key_value(0,15,Quaternion(0,0,0,0))
 assert(not Conditioner.prepare(a,rig).ok)
 var limits:=preload("res://scripts/held_cast_preview.gd").duration_range({"source_duration":2.0,"min_duration":1.2,"max_duration":3.0})
 assert(limits==Vector2(1.2,3.0))
 var air=preload("res://scripts/animation_jump_motion.gd")
 assert(air.requires_air({"title":"Dive Kick"}))
 assert(not air.with_airborne_takeoff({"title":"Dive Kick"}).has("jump_motion"))
 print("CONDITIONING PASS: isolated snap removed, jitter reduced, source/timing preserved, invalid rotations rejected; authored hold range and Dive Kick air metadata")
 quit()
