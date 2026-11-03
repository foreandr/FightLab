extends RefCounted
## Initial spell-preview composition. Orbit/focus behavior lives in ThirdPersonCamera.
static func frame(camera:Camera3D,subject:Node3D,human:Node3D,inspection)->void:
 var forward:Vector3=subject.global_basis.z.normalized()
 var side:Vector3=subject.global_basis.x.normalized()
 var back:Vector3=(-forward*0.9-side*0.65+Vector3.UP*0.28).normalized()
 var distance:=8.5
 var center:Vector3=subject.global_position+Vector3.UP*1.1+forward*1.3
 if is_instance_valid(human) and human.visible:
  distance=11.5
  center=subject.global_position+Vector3.UP*1.1+forward*1.7-side*0.9
 camera.h_offset=0.0;camera.v_offset=0.0;camera.fov=45.0
 camera.global_position=center+back*distance;camera.look_at(center)
 inspection.capture_view(camera,distance)
