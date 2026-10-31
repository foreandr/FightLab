extends RefCounted
## Shared world-space movement and facing; modes supply input and animation poses.
const TURN_SPEED:=14.0

static func flat(direction:Vector3) -> Vector3:
	direction.y=0.0
	return direction.normalized()

static func camera_forward(camera:Camera3D,fallback:Vector3=Vector3.FORWARD) -> Vector3:
	return flat(-camera.global_basis.z if is_instance_valid(camera) else fallback)

static func direction_from_forward(input:Vector2,forward:Vector3) -> Vector3:
	forward=flat(forward)
	return (forward*input.y+forward.cross(Vector3.UP)*input.x).limit_length(1.0)

static func camera_direction(input:Vector2,camera:Camera3D,fallback:Vector3=Vector3.FORWARD) -> Vector3:
	return direction_from_forward(input,camera_forward(camera,fallback))

static func facing(actor:Node3D,camera:Camera3D,target:Node3D=null) -> Vector3:
	if is_instance_valid(target) and target!=actor:return flat(target.global_position-actor.global_position)
	return camera_forward(camera,actor.global_basis.z)

static func turn(actor:Node3D,direction:Vector3,delta:float,speed:float=TURN_SPEED) -> void:
	if Vector2(direction.x,direction.z).length_squared()<0.000001:return
	actor.rotation.y=lerp_angle(actor.rotation.y,atan2(direction.x,direction.z),minf(1.0,delta*speed))
