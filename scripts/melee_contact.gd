extends RefCounted
## Shared swept-limb hit resolution. Callers own animation clocks, not hit rules.
static func resolve(actor:CharacterBody3D,strike:Dictionary,delta:float) -> bool:
	if strike.get("connected",false) or actor.health<=0 or not actor.arena.round_active:return false
	var clock:=float(strike.clock)
	if clock<float(strike.begin) or clock>float(strike.end):return false
	var previous:Vector3=strike.previous
	var limb:Vector3=strike.limb
	var movement:=limb-previous
	var dt:=maxf(delta,0.0001)
	var forward:Vector3=strike.forward
	if movement.length()/dt<float(strike.get("min_speed",0.8)):return false
	if strike.get("require_forward",false) and movement.dot(forward)<=0.0005:return false
	if not movement.is_zero_approx():surface_contact(actor,strike,previous,limb,dt)
	var shape:=SphereShape3D.new()
	shape.radius=float(strike.get("radius",0.105))
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=actor.arena.enemy_hurt_mask(actor.team)
	query.collide_with_areas=true
	query.collide_with_bodies=false
	var samples:=maxi(1,ceili(movement.length()/0.04))
	for sample in range(samples+1):
		var point:=previous.lerp(limb,float(sample)/samples)
		if strike.get("break_ice",false) and is_instance_valid(actor.arena.spell_environment) and actor.arena.spell_environment.damage_ice_near(point,float(strike.damage),0.22):return true
		query.transform=Transform3D(Basis.IDENTITY,point)
		var results:=actor.get_world_3d().direct_space_state.intersect_shape(query,32)
		for result in results:
			var area:Area3D=result.collider
			var victim=area.get_meta("fighter",null)
			if not is_instance_valid(victim) or victim==actor or victim.team==actor.team or victim.health<=0:continue
			# Root movement is applied once by CombatRuntime, not again as limb speed.
			var speed:float=(movement/dt-actor.velocity-victim.velocity).length()
			speed=maxf(speed,float(strike.get("combo_speed",0.0)))
			var multiplier:=1.0+clampf((speed-5.0)/8.0,0,2.5) if strike.get("dynamic_damage",true) else 1.0
			var direction:Vector3=forward if strike.get("fixed_direction",false) else (victim.global_position-actor.global_position)*Vector3(1,0,1)
			direction=direction.normalized()
			var impulse:Vector3=(movement/dt*8.0).limit_length(float(strike.get("impulse_limit",180.0)))+direction*maxf(0,speed-5)*22 if strike.get("dynamic_damage",true) else (movement/dt*8.0).limit_length(120)
			var charge:=float(strike.get("charge",0.0))
			if charge>0:impulse+=Vector3.UP*1250*charge
			var spec:Dictionary=strike.get("metadata",{}).duplicate(true)
			spec["id"]=strike.id
			spec["name"]=str(strike.id).replace("_"," ").capitalize()
			spec["effect"]="melee"
			spec["charge"]=charge
			spec["damage"]=float(strike.damage)*multiplier*(1.0 if strike.get("pre_scaled",false) else 1.0+charge*0.7)
			if strike.get("manual_block",false) and actor.arena.has_method("apply_melee_block") and victim.shield_active() and not victim.shield_intersection(previous,limb,shape.radius).is_empty():
				actor.arena.apply_melee_block(actor,victim,point)
				return true
			if actor.arena.apply_impact(actor,victim,spec,point,direction,area,impulse):return true
	return false

static func surface_contact(actor:CharacterBody3D,strike:Dictionary,previous:Vector3,limb:Vector3,dt:float) -> void:
	var contacts:Dictionary=actor.get_meta("melee_surface_contacts",{})
	var key:String=str(strike.id)
	var entry:Dictionary=contacts.get(key,{"clock":INF,"marked":false})
	if float(strike.clock)<float(entry.clock) or actor.arena.elapsed-float(entry.get("time",-INF))>dt*2.5:entry.marked=false
	entry.clock=float(strike.clock)
	entry.time=actor.arena.elapsed
	contacts[key]=entry
	actor.set_meta("melee_surface_contacts",contacts)
	if entry.marked:return
	var motion:=limb-previous
	var query:=PhysicsRayQueryParameters3D.create(previous,limb+motion.normalized()*float(strike.get("radius",0.105)),1)
	var hit:=actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return
	var speed:float=(motion/dt-actor.velocity).length()
	speed=maxf(speed,float(strike.get("combo_speed",0.0)))
	var multiplier:=1.0+clampf((speed-5.0)/8.0,0,2.5) if strike.get("dynamic_damage",true) else 1.0
	var charge:=float(strike.get("charge",0.0))
	var damage:float=float(strike.damage)*multiplier*(1.0 if strike.get("pre_scaled",false) else 1.0+charge*0.7)
	damage*=preload("res://scripts/physical_momentum.gd").melee_multiplier(actor.velocity,motion,{"effect":"melee"})
	actor.arena.surface_impact(hit.collider,hit.position,hit.normal,damage,motion/dt*8.0)
	entry.marked=true
