extends SceneTree
const Aim=preload("res://scripts/combat_aim.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func wall(world:Node,location:Vector3,size:Vector3)->StaticBody3D:
 var body:=StaticBody3D.new();body.collision_layer=1
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size;shape.shape=box;body.add_child(shape)
 world.add_child(body);body.global_position=location;return body
func run():
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO)
 var target:CharacterBody3D=world.spawn_combatant(1,Vector3(0,0,4))
 actor.set_physics_process(false);target.set_physics_process(false)
 var camera:=Camera3D.new();world.add_child(camera);camera.current=true;world.camera=camera
 var behind:=wall(world,Vector3(0,2,-2),Vector3(20,6,0.5))
 var emitter:=Vector3(-0.25,1.2,0.35)
 var hit:=Vector3(0,1.2,4)
 await physics_frame;await physics_frame
 var reproduced:=false
 for location in [Vector3(0,2,-5),Vector3(-3,2,-6),Vector3(0,2,-2),Vector3(0,4,-300)]:
  camera.global_position=location;camera.look_at(hit)
  var before:=camera.global_transform
  var pointer:=camera.unproject_position(hit)
  var ray:=camera.project_ray_normal(pointer)
  var origin:=camera.project_ray_origin(pointer)
  var query:=PhysicsRayQueryParameters3D.create(origin,origin+ray*400,1)
  var raw:Dictionary=actor.get_world_3d().direct_space_state.intersect_ray(query)
  if not raw.is_empty() and (raw.position-emitter).dot(ray)<0:reproduced=true
  var point:=Aim.ray_point(camera,actor,pointer,[target],0.03,emitter)
  var direction:Vector3=(Aim.safe_cursor_target(emitter,point,ray)-emitter).normalized()
  if not check(direction.z>0 and direction.dot(ray)>0,"Camera wall turns shot backwards: "+str(location)):return
  if not check(camera.unproject_position(point).distance_to(pointer)<0.1 and camera.global_transform.is_equal_approx(before),"Fix shifts cursor or camera"):return
 if not check(reproduced,"Fixture did not reproduce a camera-side wall destination"):return
 var front:=wall(world,Vector3(0,1.5,1.5),Vector3(5,4,0.2))
 await physics_frame;await physics_frame
 camera.global_position=Vector3(0,2,-5);camera.look_at(hit)
 var pointer:=camera.unproject_position(hit);var ray:=camera.project_ray_normal(pointer)
 var point:=Aim.ray_point(camera,actor,pointer,[target],0.03,emitter)
 if not check(point.z>emitter.z and point.z<2,"Real obstacle in front of the hand was skipped"):return
 var spec:=preload("res://scripts/combat_spell_rules.gd").neutral_projectile()
 spec.aim_direction=(point-emitter).normalized()
 var impact:Dictionary=world.predict_projectile_impact(actor,spec,emitter)
 if not check(impact.hit and impact.collider==front,"Forward wall no longer blocks actual projectile prediction"):return
 if not check(Aim.safe_cursor_target(Vector3.ZERO,Vector3(0,0,-1),Vector3.BACK).z>0,"Moving hand can still aim back at a stale hit"):return
 var valid:=Vector3(1,2,3)
 if not check(Aim.safe_cursor_target(Vector3.ZERO,valid,Vector3.BACK)==valid,"Valid aim point changed"):return
 print("CAMERA WALL AIM PASS: reproduced backwards ray hit; camera behind/inside wall, offset and 300m away; cursor/camera unchanged; front wall still blocks actual shot; stale-hand guard")
 quit()
