extends RefCounted
## Shared Story/Create third-person framing. Selection never changes this camera.
const BASE_DISTANCE:=5.4
const MIN_ZOOM:=0.55
const MAX_ZOOM:=3.8

static func adopt(state:Node,player:Node3D) -> void:
	var back:Vector3=state.camera.global_position-(player.focus_position()+Vector3.UP*0.58)
	state.camera_zoom=clampf(back.length()/BASE_DISTANCE,MIN_ZOOM,MAX_ZOOM)
	state.story_camera_base_yaw=atan2(back.x,back.z)
	state.camera_orbit_yaw=0.0
	state.camera_orbit_pitch=clampf(asin(clampf(back.normalized().y,-1.0,1.0)),0.06,1.32)

static func set_focus(state:Node,player:Node3D,target:Node3D) -> void:
	var back:Vector3=state.camera.global_position-(player.focus_position()+Vector3.UP*0.58)
	var current_yaw:=atan2(back.x,back.z)
	if is_instance_valid(target) and target!=player:
		var toward:Vector3=target.global_position-player.global_position
		state.camera_orbit_yaw=wrapf(current_yaw-atan2(-toward.x,-toward.z),-PI,PI)
	else:
		target=null
		state.story_camera_base_yaw=current_yaw
		state.camera_orbit_yaw=0.0
	state.camera_focus_target=target

static func world_yaw(state:Node,player:Node3D) -> float:
	var target:Node3D=state.camera_focus_target
	if is_instance_valid(target) and target!=player and float(target.get("health"))>0.0:
		var toward:Vector3=target.global_position-player.global_position
		return atan2(-toward.x,-toward.z)+float(state.camera_orbit_yaw)
	return float(state.story_camera_base_yaw)+float(state.camera_orbit_yaw)

static func orbit(state:Node,relative:Vector2) -> void:
	state.camera_orbit_yaw-=relative.x*0.0065
	state.camera_orbit_pitch=clampf(state.camera_orbit_pitch+relative.y*0.004,0.06,1.32)

static func zoom(state:Node,zoom_in:bool) -> void:
	state.camera_zoom=clampf(state.camera_zoom*(0.90 if zoom_in else 1.11),MIN_ZOOM,MAX_ZOOM)
static func update(camera:Camera3D,player:Node3D,target:Node3D,yaw:float,pitch:float,distance:float,delta:float) -> void:
	var locked:=is_instance_valid(target) and target!=player and float(target.get("health"))>0.0
	var pivot:Vector3=player.focus_position()+Vector3.UP*0.58
	var forward:=Vector3(-sin(yaw),0.0,-cos(yaw))
	# Aim ahead at chest height, keeping the player below the free crosshair.
	var look_point:=pivot+Vector3.UP*0.5+forward*3.5
	if locked:look_point=player.focus_position().lerp(target.focus_position(),0.58)+Vector3.UP*0.72
	var backward:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	var goal:=pivot+backward*distance
	var weight:=1.0-exp(-10.0*delta)
	camera.global_position=camera.global_position.lerp(goal,weight)
	var desired:=Transform3D(Basis.IDENTITY,camera.global_position).looking_at(look_point)
	camera.quaternion=camera.quaternion.slerp(desired.basis.get_rotation_quaternion(),weight)
	camera.fov=lerpf(camera.fov,48.0 if locked else 58.0,weight)

static func next_target(current:Node3D,selected:Node3D,player:Node3D) -> Node3D:
	if is_instance_valid(selected) and selected!=player and selected!=current and float(selected.get("health"))>0.0:return selected
	return null
