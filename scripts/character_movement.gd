extends RefCounted
## Shared world-space movement and facing; modes supply input and animation poses.
const TURN_SPEED:=14.0
const DASH_SPEED_MULTIPLIER:=0.85
const JUMP_CHARGE_BRAKING:=14.0

static func jump_charge_velocity(actor:Node,requested:Vector3,delta:float)->Vector3:
	if not actor.has_method("jump_charge_active") or not actor.jump_charge_active():return requested
	var carry:Vector3=actor.get_meta("jump_charge_velocity",Vector3.ZERO)
	carry*=exp(-JUMP_CHARGE_BRAKING*maxf(0.0,delta))
	if carry.length()<0.05:carry=Vector3.ZERO
	actor.set_meta("jump_charge_velocity",carry)
	actor.air_momentum=carry
	return carry
const Exertion=preload("res://scripts/character_exertion.gd")

static func walking_only(actor:Node) -> bool:return Exertion.walking_only(actor)

static func gait_speed(actor:Node,sprinting:bool,run_speed:float,sprint_speed:float) -> float:
	if walking_only(actor):return run_speed*0.5
	return sprint_speed if sprinting and Exertion.can_sprint(actor) else run_speed

static func walking_velocity(actor:Node,desired:Vector3,run_speed:float) -> Vector3:
	if walking_only(actor) and actor.mode in ["idle","run","chase","strafe","retreat","approach","block_recoil"]:
		return desired.limit_length(run_speed*0.5)
	return desired

## Input uses positive Y forward. Interpolate by angle for analog controls.
static func directional_speed(input:Vector2,sprinting:bool=false) -> float:
	if input.is_zero_approx():return 1.0
	var angle:=acos(clampf(input.normalized().y,-1.0,1.0))/(PI/4.0)
	var rates:=[1.0,0.9,0.75,0.6,0.5] if sprinting else [1.0,0.9,0.8,0.7,0.6]
	var index:=mini(int(angle),3)
	return lerpf(rates[index],rates[index+1],angle-float(index))

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
