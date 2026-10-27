extends RefCounted
## Inspection camera; independent of combat pause and slow motion.
var manual := false
var focus := Vector3.ZERO
var yaw := 0.0
var pitch := 0.35
var distance := 8.0

func take_control(camera: Camera3D,center: Vector3) -> void:
	if manual:
		return
	manual=true
	focus=center
	var offset:=camera.global_position-focus
	distance=clampf(offset.length(),1.2,65)
	yaw=atan2(offset.x,offset.z)
	pitch=clampf(asin(clampf(offset.normalized().y,-1,1)),0.05,1.4)

func orbit(relative: Vector2) -> void:
	yaw=wrapf(yaw-relative.x*0.006,-PI,PI)
	pitch=clampf(pitch+relative.y*0.006,0.05,1.4)

func zoom(steps: float) -> void:
	distance=clampf(distance*pow(0.86,steps),1.2,65)

func move(direction: Vector3,delta: float,fast: bool=false) -> void:
	if direction.length_squared()==0:
		return
	var right:=Vector3(cos(yaw),0,-sin(yaw))
	var forward:=Vector3(-sin(yaw),0,-cos(yaw))
	var velocity:=right*direction.x+Vector3.UP*direction.y+forward*direction.z
	focus+=velocity.normalized()*clampf(distance*0.55,2.5,18)*delta*(2 if fast else 1)
	focus.x=clampf(focus.x,-50,50)
	focus.z=clampf(focus.z,-50,50)
	focus.y=clampf(focus.y,0.2,30)

func apply(camera: Camera3D) -> void:
	var back:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	camera.global_position=focus+back*distance
	camera.look_at(focus)
