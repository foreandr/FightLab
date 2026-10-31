extends RefCounted
## One impact area per projectile, one application per enemy, regardless of limbs.
const SPLASH_RADIUS_MULTIPLIER:=2.0
var sphere:=SphereShape3D.new()
var query:=PhysicsShapeQueryParameters3D.new()

func apply(field:Node,shot:Dictionary,center:Vector3,primary:CharacterBody3D=null,primary_area:Area3D=null) -> void:
	sphere.radius=maxf(0.0001,float(shot.radius)*SPLASH_RADIUS_MULTIPLIER)
	query.shape=sphere
	query.transform=Transform3D(Basis.IDENTITY,center)
	query.collision_mask=field.enemy_hurt_mask(shot.caster.team)
	query.collide_with_areas=true
	query.collide_with_bodies=false
	var capacity:=1
	for fighter in field.fighters:capacity+=fighter.targets.size()+fighter.limb_targets.size()
	var contacts:Dictionary={}
	if is_instance_valid(primary):
		contacts[primary.get_instance_id()]={"fighter":primary,"area":primary_area,"point":center}
	var space:PhysicsDirectSpaceState3D=field.get_world_3d().direct_space_state
	for result in space.intersect_shape(query,capacity):
		var area:Area3D=result.collider
		var victim=area.get_meta("fighter",null)
		if not is_instance_valid(victim) or victim==shot.caster or victim.team==shot.caster.team or victim.health<=0.0:continue
		var id:int=victim.get_instance_id()
		if victim==primary:continue
		var point:Vector3=victim.contact_surface(area,center)
		if not contacts.has(id) or point.distance_squared_to(center)<contacts[id].point.distance_squared_to(center):
			contacts[id]={"fighter":victim,"area":area,"point":point}
	var direction:Vector3=shot.velocity.normalized()
	var affected:Array=[]
	for contact in contacts.values():
		var victim=contact.fighter
		if victim.health<=0.0:continue
		# A large radius does not grant damage through arena walls or spell cover.
		if victim!=primary and center.distance_to(contact.point)>0.005:
			var visibility:=PhysicsRayQueryParameters3D.create(center-direction*0.002,contact.point,1)
			if not space.intersect_ray(visibility).is_empty():continue
		if field.apply_impact(shot.caster,victim,shot.spec,contact.point,direction,contact.area,shot.velocity*shot.mass):
			affected.append(str(victim.name))
	shot["aoe_targets"]=affected
	GameDiagnostics.log_event("projectile_area_impact",{"shot":shot.id,"radius":shot.radius,"splash_radius":sphere.radius,"center":str(center),"targets":affected})
