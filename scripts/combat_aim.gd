extends RefCounted
## One source for cursor rays, target anchors and angle limits.
## Calibration deliberately uses its authored near-plane; live spells use physics.
static func emitter(profile:Dictionary,fallback:String="hand_r") -> String:
	var limb:=str(profile.get("attack_bone",fallback))
	if limb.is_empty():limb=fallback
	return "Head" if limb in ["mouth","head"] else limb

static func focused_chest(target:Node3D) -> Vector3:
	if not is_instance_valid(target):return Vector3.ZERO
	if target.has_method("bone_point"):return target.bone_point("spine_02")+Vector3.UP*0.04
	return target.global_position+Vector3.UP

static func angles(actor:Node3D,direction:Vector3) -> Dictionary:
	var local:Vector3=actor.global_basis.inverse()*direction.normalized()
	return {"yaw":atan2(local.x,local.z),"pitch":clampf(atan2(local.y,maxf(0.001,Vector2(local.x,local.z).length())),-deg_to_rad(80),deg_to_rad(80))}

static func ray_point(camera:Camera3D,actor:CharacterBody3D,pointer:Vector2,fighters:Array=[],projectile_radius:float=0.0) -> Vector3:
	var origin:=camera.project_ray_origin(pointer)
	var direction:=camera.project_ray_normal(pointer)
	var query:=PhysicsRayQueryParameters3D.create(origin,origin+direction*200.0,1|8|16|32)
	query.collide_with_areas=true
	var ignored:Array[RID]=[actor.get_rid()]
	for pair in actor.targets:ignored.append(pair[0].get_rid())
	for pair in actor.limb_targets:ignored.append(pair[0].get_rid())
	query.exclude=ignored
	var hit:Dictionary=actor.get_world_3d().direct_space_state.intersect_ray(query)
	var point:Vector3=hit.position if not hit.is_empty() else origin+direction*200.0
	# A near miss must converge at the nearby fighter's depth, not a distant wall.
	# Only depth changes: the destination remains exactly on the cursor ray.
	var depth:float=origin.distance_to(point)
	for fighter in fighters:
		if fighter==actor or not is_instance_valid(fighter) or not fighter.is_visible_in_tree() or fighter.health<=0.0:continue
		var bounds:Variant=hurt_bounds(fighter)
		if bounds==null:continue
		var nearby:AABB=bounds.grow(0.35+projectile_radius)
		if nearby.intersects_ray(origin,direction)==null:continue
		var center_depth:float=(bounds.get_center()-origin).dot(direction)
		var half:Vector3=bounds.size*0.5
		var front_depth:float=center_depth-half.dot(direction.abs())
		if front_depth<=0.1 or front_depth>=depth:continue
		depth=front_depth
		point=origin+direction*depth
	return point

static func hurt_bounds(fighter:Node3D) -> Variant:
	var bounds:Variant=null
	for pair in fighter.targets+fighter.limb_targets:
		var area:Area3D=pair[0]
		var collision:CollisionShape3D=area.get_child(0)
		var capsule:=collision.shape as CapsuleShape3D
		if capsule==null or collision.disabled:continue
		var half:=Vector3(capsule.radius,capsule.height*0.5,capsule.radius)
		var basis:=collision.global_basis
		var extent:Vector3=basis.x.abs()*half.x+basis.y.abs()*half.y+basis.z.abs()*half.z
		var box:=AABB(collision.global_position-extent,extent*2.0)
		bounds=box if bounds==null else bounds.merge(box)
	return bounds

static func calibration_point(camera:Camera3D,actor:CharacterBody3D,pointer:Vector2) -> Vector3:
	var facing:=actor.global_basis.z.normalized()
	var center:=actor.global_position+facing*1.8+Vector3.UP*1.25
	if is_instance_valid(camera):
		var origin:=camera.project_ray_origin(pointer)
		var ray:=camera.project_ray_normal(pointer).normalized()
		var denominator:=ray.dot(facing)
		if denominator>0.025:
			var distance:float=(center-origin).dot(facing)/denominator
			if distance>0.0:
				var point:=origin+ray*distance
				var local:Vector3=actor.global_basis.inverse()*(point-actor.bone_point("spine_03"))
				var yaw:=clampf(atan2(local.x,local.z),-deg_to_rad(89),deg_to_rad(89))
				var pitch:=clampf(atan2(local.y,maxf(0.001,Vector2(local.x,local.z).length())),-deg_to_rad(80),deg_to_rad(80))
				return actor.bone_point("spine_03")+actor.global_basis*(Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*4.0)
	return center

static func constrain_front(actor:Node3D,aim:Vector3) -> Vector3:
	var forward:=actor.global_basis.z
	forward.y=0.0
	if forward.is_zero_approx():return aim.normalized()
	forward=forward.normalized()
	var direction:=aim.normalized()
	var horizontal:=Vector3(direction.x,0.0,direction.z)
	if horizontal.is_zero_approx():return direction
	if horizontal.dot(forward)<0.0:
		var side:=actor.global_basis.x
		side.y=0.0
		side=side.normalized()
		var side_sign:=1.0 if horizontal.dot(side)>=0.0 else -1.0
		horizontal=(forward*0.015+side*side_sign).normalized()
		return (horizontal*sqrt(maxf(0.0,1.0-direction.y*direction.y))+Vector3.UP*direction.y).normalized()
	return direction

static func raised_direction(actor:Node3D,direction:Vector3,lift:float) -> Vector3:
	var safe:=constrain_front(actor,direction.normalized())
	var horizontal:=Vector3(safe.x,0.0,safe.z)
	if horizontal.is_zero_approx():return safe
	var pitch:=atan2(safe.y,horizontal.length())
	var raised:=clampf(pitch+lift,-0.05,deg_to_rad(82.0))
	return (horizontal.normalized()*cos(raised)+Vector3.UP*sin(raised)).normalized()
