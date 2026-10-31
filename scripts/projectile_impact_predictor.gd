extends RefCounted
## Read-only forecast using the live projectile's collision policies and radius.
## World geometry uses the flight's center ray; fighters use its sphere volume.
var sphere:=SphereShape3D.new()
var query:=PhysicsShapeQueryParameters3D.new()

func predict(field:Node,caster:CharacterBody3D,origin:Vector3,end:Vector3,radius:float,spec:Dictionary={}) -> Dictionary:
	var space:=caster.get_world_3d().direct_space_state
	var motion:=end-origin
	var best:Dictionary={"hit":false,"position":end,"center":end,"distance":motion.length(),"collider":null}
	var ground_query:=PhysicsRayQueryParameters3D.create(origin,end,1)
	var ground:=space.intersect_ray(ground_query)
	if not ground.is_empty():
		best={"hit":true,"position":ground.position,"center":ground.position,"distance":origin.distance_to(ground.position),"collider":ground.collider}
	if str(spec.get("projectile_element","")) in ["Ice","Lightning","Fire"]:
		var water:Dictionary=field.spell_environment.water_contact(origin,end,radius)
		if not water.is_empty() and origin.distance_to(water.position)<float(best.distance):
			best={"hit":true,"position":water.position,"center":water.position,"distance":origin.distance_to(water.position),"collider":water.get("collider",null)}
	for enemy in field.fighters:
		if enemy.team==caster.team or enemy.health<=0.0:continue
		var shield:Dictionary=enemy.shield_intersection(origin,end,radius)
		if not shield.is_empty() and origin.distance_to(shield.point)<float(best.distance):
			best={"hit":true,"position":shield.point,"center":shield.point,"distance":origin.distance_to(shield.point),"collider":enemy}
	sphere.radius=maxf(0.001,radius)
	query.shape=sphere
	query.margin=0.0001
	query.collision_mask=field.enemy_hurt_mask(caster.team)
	query.collide_with_areas=true
	query.collide_with_bodies=false
	var ignored:Array[RID]=[]
	for fighter in field.fighters:
		if fighter.team!=caster.team and fighter.health>0.0:continue
		for pair in fighter.targets:ignored.append(pair[0].get_rid())
		for pair in fighter.limb_targets:ignored.append(pair[0].get_rid())
	query.exclude=ignored
	query.transform=Transform3D(Basis.IDENTITY,origin)
	query.motion=Vector3.ZERO
	var overlaps:=space.intersect_shape(query,12)
	var center:=origin
	if overlaps.is_empty():
		query.motion=motion
		var fractions:=space.cast_motion(query)
		if fractions.size()<2 or fractions[0]>=1.0:return best
		center=origin+motion*minf(1.0,float(fractions[1])+0.002/maxf(0.001,motion.length()))
		if origin.distance_to(center)>float(best.distance):return best
		query.motion=Vector3.ZERO
		query.transform.origin=center
		overlaps=space.intersect_shape(query,12)
	if overlaps.is_empty():return best
	var area:CollisionObject3D=overlaps[0].collider
	var point:=center
	var fighter=area.get_meta("fighter",null)
	if is_instance_valid(fighter):point=fighter.contact_surface(area,center)
	return {"hit":true,"position":point,"center":center,"distance":origin.distance_to(center),"collider":area}
