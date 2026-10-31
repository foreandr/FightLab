extends Resource
## Level data, not combat rules. Geometry remains ordinary world collision.
enum Bounds { UNBOUNDED, CIRCLE, BOX }
@export var bounds:Bounds=Bounds.UNBOUNDED
@export var center:=Vector3.ZERO
@export var radius:=0.0
@export var half_extents:=Vector2.ZERO
@export var spawn_points:Array[Vector3]=[]
const GROUND_COLLISION_MASK:=1
@export var probe_up:=1.0
@export var probe_down:=1000.0
@export var fallback_elevation:=NAN
# Optional flat circular basin, explicitly supplied by a level; zero disables it.
@export var water_basin_radius:=0.0

func constrain(point:Vector3,frame:Transform3D=Transform3D.IDENTITY,margin:float=0.0) -> Vector3:
	if bounds==Bounds.UNBOUNDED:return point
	var local:=frame.affine_inverse()*point
	var offset:=Vector2(local.x-center.x,local.z-center.z)
	if bounds==Bounds.CIRCLE:offset=offset.limit_length(maxf(0.0,radius-margin))
	else:offset=offset.clamp(-Vector2(maxf(0.0,half_extents.x-margin),maxf(0.0,half_extents.y-margin)),Vector2(maxf(0.0,half_extents.x-margin),maxf(0.0,half_extents.y-margin)))
	local.x=center.x+offset.x;local.z=center.z+offset.y
	var result:=frame*local
	result.y=point.y
	return result

func inward(point:Vector3,frame:Transform3D=Transform3D.IDENTITY,margin:float=2.0,ratio:float=1.0) -> Vector3:
	if bounds==Bounds.UNBOUNDED:return Vector3.ZERO
	var edge_margin:=margin
	if ratio<1.0:edge_margin+=maxf(0.0,(radius if bounds==Bounds.CIRCLE else minf(half_extents.x,half_extents.y))-margin)*(1.0-ratio)
	return constrain(point,frame,edge_margin)-point

func ground(world:Node3D,point:Vector3,frame:Transform3D=Transform3D.IDENTITY) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*probe_up,point-Vector3.UP*probe_down,GROUND_COLLISION_MASK)
	query.collide_with_areas=false
	var result:=world.get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():return result
	var height:=point.y if is_nan(fallback_elevation) else (frame*Vector3(center.x,fallback_elevation,center.z)).y
	return {"position":Vector3(point.x,height,point.z),"normal":Vector3.UP,"missing":true}

func spawn(index:int,frame:Transform3D=Transform3D.IDENTITY,fallback:Vector3=Vector3.ZERO) -> Vector3:
	return frame*spawn_points[posmod(index,spawn_points.size())] if not spawn_points.is_empty() else fallback
