extends RefCounted
## Per-world combat execution. The host supplies actors, targeting and presentation.
## No Story/Create checks: all callers submit the same specs and requests.
const Momentum=preload("res://scripts/physical_momentum.gd")
const Projectile=preload("res://scripts/basic_projectile.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
var field:Node
var cast_attempts:Dictionary={}
var cast_recoveries:Dictionary={}
var touch_casts:Dictionary={}

func cast_committed(actor:CharacterBody3D) -> bool:
	var key:=actor.get_instance_id()
	var recovery:Dictionary=cast_recoveries.get(key,{})
	if recovery.is_empty():return false
	if recovery.actor.get_ref()!=actor or actor.health<=0 or actor.mode!=recovery.mode:
		cast_recoveries.erase(key)
		return false
	return true

func finish_cast(actor:CharacterBody3D) -> void:
	if is_instance_valid(actor.touch_contact_visual):actor.touch_contact_visual.clear_runtime()
	touch_casts.erase(actor.get_instance_id())
	cast_recoveries.erase(actor.get_instance_id())

func _init(host:Node) -> void:
	field=host

func begin_cast_attempt(actor:CharacterBody3D,spec:Dictionary,time_to_release:float,mode_owned:bool=true) -> bool:
	if cast_committed(actor):return false
	for key in cast_recoveries.keys():
		if cast_recoveries[key].actor.get_ref()==null:cast_recoveries.erase(key)
	interrupt_cast_attempt(actor)
	if not can_start_cast(actor,spec):return false
	for key in cast_attempts.keys():
		if cast_attempts[key].actor.get_ref()==null:cast_attempts.erase(key)
	cast_attempts[actor.get_instance_id()]={"actor":weakref(actor),"stamina":maxf(0.0,float(spec.get("stamina_cost",0.0))),"time_to_release":maxf(0.0,time_to_release),"elapsed":0.0,"mode_owned":mode_owned}

	if str(spec.get("effect",""))=="touch":actor.ensure_touch_contact_visual().set_runtime(spec)
	return true

func resource_notice(actor:CharacterBody3D,message:String) -> void:
	var label:=actor.get_node_or_null("CastResourceNotice") as Label3D
	if label==null:
		label=Label3D.new()
		label.name="CastResourceNotice"
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test=true
		label.font_size=30
		label.pixel_size=0.008
		label.outline_size=6
		actor.add_child(label)
		label.position=Vector3(0,3.1,0)
	label.text=message
	label.modulate=Color("ffcf78")
	label.visible=true
	var serial:=int(label.get_meta("serial",0))+1
	label.set_meta("serial",serial)
	label.get_tree().create_timer(1.8).timeout.connect(func():
		if is_instance_valid(label) and int(label.get_meta("serial",0))==serial:label.visible=false)
	preload("res://scripts/combat_diagnostics.gd").event(field,"cast_resource_failure",{"actor":str(actor.name),"reason":message})

func can_start_cast(actor:CharacterBody3D,spec:Dictionary) -> bool:
	var required:=maxf(0.0,float(spec.get("stamina_cost",0.0)))
	if str(spec.get("effect",""))=="burst" and actor.has_method("flash_stamina_requirement"):required=maxf(required,actor.flash_stamina_requirement())
	if not actor.practice_god_mode and actor.stamina+0.0001<required:
		resource_notice(actor,"Not enough stamina")
		return false
	return true

func advance_cast_attempt(actor:CharacterBody3D,elapsed:float) -> void:
	var attempt:Dictionary=cast_attempts.get(actor.get_instance_id(),{})
	if not attempt.is_empty():attempt.elapsed=maxf(float(attempt.elapsed),maxf(0.0,elapsed))

func interrupt_cast_attempt(actor:CharacterBody3D) -> float:
	var key:=actor.get_instance_id()
	var attempt:Dictionary=cast_attempts.get(key,{})
	if attempt.is_empty():return 0.0
	cast_attempts.erase(key)
	if is_instance_valid(actor.touch_contact_visual):actor.touch_contact_visual.clear_runtime()
	var progress:=clampf(float(attempt.elapsed)/maxf(0.001,float(attempt.time_to_release)),0.0,1.0)
	var cost:=minf(actor.stamina,float(attempt.stamina)*progress)
	var before:float=actor.stamina
	if cost>0.0:actor.spend_stamina(cost)
	var paid:float=maxf(0.0,before-actor.stamina)
	preload("res://scripts/combat_diagnostics.gd").event(field,"cast_interrupted",{"actor":str(actor.name),"progress":progress,"stamina":paid})
	return paid

func _cancel_exited_cast(actor:CharacterBody3D) -> void:
	var attempt:Dictionary=cast_attempts.get(actor.get_instance_id(),{})
	if not attempt.is_empty() and attempt.mode_owned and actor.mode!="cast":interrupt_cast_attempt(actor)

func discard_cast_attempt(actor:CharacterBody3D) -> void:
	cast_attempts.erase(actor.get_instance_id())
	finish_cast(actor)

func authorize_cast(actor:CharacterBody3D,spec:Dictionary,profile:Dictionary={}) -> bool:
	if cast_committed(actor):return false
	if not field.round_active or actor.health<=0:
		interrupt_cast_attempt(actor)
		return false
	if actor.has_method("can_cast_with") and not actor.can_cast_with(spec,profile):
		interrupt_cast_attempt(actor)
		return false
	if str(spec.get("effect",""))=="burst" and actor.has_method("flash_stamina_requirement") and not actor.practice_god_mode and actor.stamina<actor.flash_stamina_requirement():
		interrupt_cast_attempt(actor)
		return false
	if not actor.practice_god_mode:
		if actor.stamina+0.0001<float(spec.get("stamina_cost",0.0)):resource_notice(actor,"Not enough stamina")
		elif actor.mana+0.0001<Rules.mana_cost(spec,actor.MAX_MANA,field.combat_defaults):resource_notice(actor,"Not enough mana")
	var paid:bool=actor.spend_cast_resources(float(spec.get("stamina_cost",0.0)),Rules.mana_cost(spec,actor.MAX_MANA,field.combat_defaults))
	if paid:cast_attempts.erase(actor.get_instance_id())
	else:interrupt_cast_attempt(actor)
	return paid

func release(actor:CharacterBody3D,spec:Dictionary,origin:Vector3,profile:Dictionary={}) -> bool:
	var attempt:Dictionary=cast_attempts.get(actor.get_instance_id(),{})
	var animated:bool=not attempt.is_empty() and (not attempt.mode_owned or actor.mode=="cast")
	if not authorize_cast(actor,spec,profile):return false
	if animated:cast_recoveries[actor.get_instance_id()]={"actor":weakref(actor),"mode":actor.mode}
	field.combat_cast_feedback(actor,spec)
	dispatch(actor,spec,origin,profile)
	return true

func cast(actor:CharacterBody3D,spec:Dictionary,profile:Dictionary={}) -> bool:
	return release(actor,spec,field.fighter_hand(actor,str(spec.get("hand","hand_r"))),profile)

func dispatch(actor:CharacterBody3D,spec:Dictionary,origin:Vector3,profile:Dictionary={}) -> void:
	match str(spec.get("effect","orb")):
		"summon_earth":field.summon_earth(actor,spec)
		"heal":
			var recipient:CharacterBody3D=field.heal_target(actor)
			if not is_instance_valid(recipient):return
			var restored:=minf(float(spec.get("heal_amount",22.0)),recipient.MAX_HEALTH-recipient.health)
			recipient.health+=restored
			recipient.healed_this_round=true
			field.heals+=1
			field.combat_heal_feedback(actor,recipient,spec,restored)
			if is_instance_valid(field.vfx):
				for i in 5:field.vfx.puff(recipient.global_position+Vector3.UP*(0.35+i*0.24),"magic_01",recipient.team,Vector2.ONE*0.48,Vector3.UP*0.42,0.75,Color("85ffc1"),0.55,4)
			field.combat_sound("ice",recipient.global_position,0.45)
		"touch":
			actor.ensure_touch_contact_visual().set_runtime(spec)
			field.combat_cast_sound(spec,origin,0.45,profile)
			var previous:Dictionary={}
			for bone in spec.get("touch_contacts",[spec.get("hand","hand_l")]):
				if bone in Rules.TOUCH_CONTACT_BONES:previous[bone]=actor.bone_point(bone)
			touch_casts[actor.get_instance_id()]={"actor":weakref(actor),"mode":actor.mode,"spec":preload("res://scripts/combat_spec.gd").copy(spec),"previous":previous,"connected":false}
		"self_barrier":
			actor.self_barrier.activate(actor,float(spec.get("shield_strength",10.0)),float(spec.get("shield_duration",1.0)),float(spec.get("parry_mana_refund",5.0)))
			field.combat_sound("shield",actor.global_position,0.6)
		"armor":
			pass # Legacy armor content is cosmetic; it grants no combat benefit.
		"haste":
			actor.haste_time=float(spec.get("haste_duration",14.0))
			field.combat_sound("dash",actor.global_position,0.6)
		"burst":actor.start_burst(true)
		"beam","ice_beam":
			var node:=MeshInstance3D.new()
			if is_instance_valid(field.vfx):node.material_override=field.vfx.ribbon_materials[1 if spec.effect=="ice_beam" else actor.team]
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			field.add_child(node)
			field.channels.append({"node":node,"caster":actor,"age":0.0,"spec":preload("res://scripts/combat_spec.gd").copy(spec),"tick":0.0,"trail":0.0,"hit":false})
			field.combat_sound("ice",origin,0.5)
		"nova":
			var node:=MeshInstance3D.new()
			var mesh:=TorusMesh.new()
			mesh.inner_radius=0.90;mesh.outer_radius=1.0
			node.mesh=mesh
			field.add_child(node)
			node.position=actor.position+Vector3.UP*0.10
			field.pulses.append({"node":node,"age":0.0,"trail":0.0,"caster":actor,"hit":false,"spec":preload("res://scripts/combat_spec.gd").copy(spec)})
		_:
			if spec.effect=="ground" and actor.is_on_floor():origin=actor.position+Vector3.UP*0.30
			spawn_projectile(actor,spec,origin)
			field.combat_cast_sound(spec,origin,0.45,profile)

func aim_target(actor:CharacterBody3D) -> CharacterBody3D:
	return field.combat_target(actor)

func damage_for(spec:Dictionary) -> float:
	return Rules.damage(spec,field.combat_defaults)

func projectile_launch_state(caster:CharacterBody3D,spec:Dictionary,origin:Vector3) -> Dictionary:
	var motion:Dictionary=Rules.motion(spec,field.combat_defaults)
	var target:Vector3=field.projectile_aim_target(caster,spec,origin,float(motion.speed))
	var direction:Vector3=(target-origin).normalized()
	var launch:=Momentum.projectile(spec,caster.velocity,direction,float(motion.speed),damage_for(spec))
	launch["target"]=target
	launch["radius"]=motion.radius
	return launch

func predict_projectile_impact(caster:CharacterBody3D,spec:Dictionary,origin:Vector3) -> Dictionary:
	var launch:=projectile_launch_state(caster,spec,origin)
	var age:float=preload("res://scripts/basic_projectile.gd").lifetime(origin.distance_to(launch.target),float(launch.radius),float(launch.speed))
	return field.projectile_impact_predictor.predict(field,caster,origin,origin+launch.velocity*age,float(launch.radius),launch.spec)

func spawn_projectile(f: CharacterBody3D, spec: Dictionary, origin: Vector3) -> void:
	var q: float = clampf(spec.get("charge",0),0,1)
	var launch:=projectile_launch_state(f,spec,origin)
	var speed:float=launch.speed
	var radius:float=launch.radius
	var node:MeshInstance3D=field.projectile_visual(f,spec,radius)
	field.add_child(node)
	node.position = origin
	field.orient_projectile(node,spec,origin,launch.velocity)
	var target:Vector3=launch.target
	var velocity_:Vector3=launch.velocity
	if node.has_meta("look") and not velocity_.is_zero_approx():
		node.look_at_from_position(origin,origin+velocity_,Vector3.FORWARD if absf(velocity_.normalized().dot(Vector3.UP))>0.95 else Vector3.UP)
		if node.get_meta("look").shape in ["Shard","Ring","Cone","Disc","Capsule","Diamond"]:node.rotate_object_local(Vector3.RIGHT,PI/2)
	field.shot_serial += 1
	field.shots.append({"max_age":preload("res://scripts/basic_projectile.gd").lifetime(origin.distance_to(target),radius,speed),"id":field.shot_serial,"node":node,"velocity":velocity_,"mass":float(spec.get("mass",(13.0 if spec.effect=="orb" else 10.0)*(1+q*1.8))),"caster":f,"age":0.0,"trail":0.0,"spec":launch.spec,"radius":radius})
	preload("res://scripts/combat_diagnostics.gd").event(field,"projectile_launch",{"shot":field.shot_serial,"speed":speed,"movement_speed":launch.spec.movement_speed,"physical_damage":launch.spec.damage})
	field._update_projectile_hitbox(field.shots.back())

func step_shots(delta: float) -> void:
	clash_projectiles(delta)
	for i in range(field.shots.size()-1,-1,-1):
		var shot: Dictionary = field.shots[i]
		var from: Vector3 = shot.node.position
		var to: Vector3 = from+shot.velocity*delta
		var ground:Dictionary = field.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
		if not ground.is_empty():
			to=ground.position
		if shot.spec.get("projectile_element","") in ["Ice","Lightning","Fire"] and ground.is_empty() and is_instance_valid(field.spell_environment):
			var surface:Dictionary=field.spell_environment.water_contact(from,to,shot.radius)
			if not surface.is_empty():
				to=surface.position
				ground=surface
		if ground.has("collider") and (ground.collider.has_meta("spell_ice") or ground.collider.has_meta("spell_earth")):
			shot["hit_structure"]=true
			ground.collider.take_damage(damage_for(shot.spec)+shot.velocity.length()*shot.mass*0.015)
		if shot.spec.has("projectile_element"):
			preload("res://scripts/spell_appearance.gd").step(shot.node,shot.age,delta)
		shot.age += delta
		shot.trail += delta
		var hit := false
		var impact_center:=to
		var primary:CharacterBody3D
		var primary_area:Area3D
		var contact := {}
		var blocked_by: CharacterBody3D
		for enemy in field.fighters:
			if enemy.team==shot.caster.team or enemy.health<=0:
				continue
			var shield_contact: Dictionary = enemy.shield_intersection(from,to,shot.radius)
			if not shield_contact.is_empty() and (contact.is_empty() or from.distance_to(shield_contact.point)<from.distance_to(contact.point)):
				contact=shield_contact
				blocked_by=enemy
		if not contact.is_empty():
			shot["impact_position"]=blocked_by.global_position
			to=contact.point
			impact_center=contact.point
			primary=blocked_by
			hit=true
		var shape := SphereShape3D.new()
		shape.radius=shot.radius
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape=shape
		query.collision_mask=field.enemy_hurt_mask(shot.caster.team)
		query.collide_with_areas=true
		query.collide_with_bodies=false
		var samples := maxi(1,ceili(from.distance_to(to)/0.06))
		for sample in range(samples+1):
			if hit:
				break
			var point := from.lerp(to,float(sample)/samples)
			query.transform=Transform3D(Basis.IDENTITY,point)
			var results:Array = field.get_world_3d().direct_space_state.intersect_shape(query,12)
			for result in results:
				var victim = result.collider.get_meta("fighter")
				if victim.health>0:
					shot["impact_position"]=victim.global_position
					to=point
					impact_center=victim.contact_surface(result.collider,point)
					primary=victim
					primary_area=result.collider
					hit=true
					break
		if not hit and not ground.is_empty():
			shot["impact_position"]=ground.position
			shot["impact_normal"]=ground.get("normal",Vector3.UP)
			shot["impact_surface"]=ground.get("collider")
			field.spell_impact_burst(ground.position,shot.caster.team,shot.spec,false)
			if ground.has("normal") and ground.get("collider") is CollisionObject3D:
				field.surface_impact(ground.collider,ground.position,ground.normal,damage_for(shot.spec),shot.velocity*shot.mass)
			impact_center=ground.position
			hit=true
		if hit:field.projectile_area_impact.apply(field,shot,impact_center,primary,primary_area)
		shot["hit_character"]=is_instance_valid(primary)
		if shot.spec.has("projectile_element") and is_instance_valid(field.spell_environment):
			field.spell_environment.projectile_step(shot,from,to,hit)
		if hit or shot.age>float(shot.get("max_age",2.2)):
			shot.node.queue_free()
			field.shots.remove_at(i)
		else:
			shot.node.position=to
			field._update_projectile_hitbox(shot)
			if shot.trail>0.035 and is_instance_valid(field.vfx):
				shot.trail=0
				if shot.spec.has("projectile_element"):
					var element:String=shot.spec.projectile_element
					var look:Dictionary=preload("res://scripts/spell_appearance.gd").settings(element,shot.spec.get("appearance",{}))
					var color:Color=look.color
					if float(look.trail)<=0 or look.trail_style=="None":continue
					if look.trail_style=="Drawn" and look.drawn_trail.size()>=3:
						var key:String="drawn_"+str(hash(look.drawn_trail))
						if not field.vfx.textures.has(key):
							var drawn_keys:Array=field.vfx.textures.keys().filter(func(item):return str(item).begins_with("drawn_"))
							if drawn_keys.size()>=24:field.vfx.textures.erase(drawn_keys[0])
						field.vfx.textures[key]=preload("res://scripts/spell_draw_mesh.gd").trail_texture(look.drawn_trail)
						field.vfx.puff(shot.node.position,key,0,Vector2.ONE*shot.radius*2,-shot.velocity*0.03,0.2+float(look.trail)*0.8,Color(color,0.7),0.15)
						continue
					var trail_texture:String={"Sparks":"spark_05","Smoke":"smoke_04","Wisps":"flame_04"}.get(look.trail_style,"flame_04" if element=="Fire" else ("spark_05" if element=="Lightning" else "smoke_04"))
					if look.trail_texture!="Element style":
						var selected:Texture2D=preload("res://scripts/spell_textures.gd").texture(look.trail_texture)
						if selected!=null:
							trail_texture=look.trail_texture
							field.vfx.textures[trail_texture]=selected
					field.vfx.puff(shot.node.position,trail_texture,0,Vector2.ONE*shot.radius*2,-shot.velocity*0.04,0.1+float(look.trail)*0.8,Color(color,0.65),0.25,5)
				else:field.vfx.flight(shot.node,shot.velocity,shot.caster.team,shot.spec.effect,shot.age)

func clash_projectiles(delta:float)->void:
	preload("res://scripts/projectile_clashes.gd").resolve(field,delta)

func apply_impact(attacker: CharacterBody3D,victim: CharacterBody3D,spec: Dictionary,point: Vector3,direction: Vector3,hit_area: Area3D=null,incoming_impulse:=Vector3.ZERO)->bool:
	if victim==attacker or victim.health<=0 or not field.round_active or victim.invulnerability>0:
		return false
	var amount:=damage_for(spec)*Momentum.melee_multiplier(attacker.velocity,direction,spec)
	var q: float=clampf(spec.get("charge",0),0,1)
	var impulse: Vector3=incoming_impulse if not incoming_impulse.is_zero_approx() else direction*amount*9
	if spec.get("projectile_element","")=="Wind":
		impulse+=Vector3.UP*330*float(spec.get("potency",1.0))
	if q>0.6 and spec.effect!="melee" and spec.effect!="ice_beam":
		impulse+=Vector3.UP*900*q
	var pressure:=amount*(1+q*1.8)+maxf(0,impulse.length()-250)/65.0
	var absorbed: float=victim.absorb_magic(pressure,point-direction*2,point)
	var fraction:=clampf(absorbed/maxf(0.1,pressure),0,1)
	var shattered: bool=absorbed>0 and victim.guard_energy<=0
	if fraction>0:
		victim.apply_physical_impact(point,impulse*fraction*0.12,"shield","lowerarm_r")
		amount*=1-fraction
		impulse*=1-fraction
		field.combat_sound("shatter" if shattered else "shield",point,0.85)
	if amount<=0.05:
		return true
	if shattered and q>0.6:
		impulse+=Vector3.UP*450*q
	var area: Area3D=hit_area if hit_area!=null else victim.nearest_hurtbox(point)
	if not is_instance_valid(area):return fraction>0
	var zone: String=area.get_meta("zone","chest")
	var bone: String=area.get_meta("bone","spine_03")
	var physical_multiplier:=preload("res://scripts/combat_hit_regions.gd").physical_multiplier(zone)
	var contact_damage:=amount
	amount*=physical_multiplier
	if victim.self_barrier.active():
		var block_result:Dictionary=victim.self_barrier.resolve_hit(amount,direction)
		var parry_ready:bool=block_result.parry
		var shield_absorbed:float=block_result.absorbed
		if block_result.broken:
			field.combat_sound("shatter",point,0.65)
			field.events.append({"time":field.elapsed,"event":"self_block_break","victim":victim.team,"attacker":attacker.team,"stamina_spent":block_result.stamina_spent,"incoming_physical":amount})
		if shield_absorbed>0.0:
			impulse*=maxf(0.0,1.0-shield_absorbed/maxf(0.001,amount))
			amount-=shield_absorbed
			field.combat_sound("shield",point,0.65)
			field.show_hit_region(area)
			if amount<=0.0001:
				if not parry_ready and victim.has_method("receive_status"):victim.receive_status(attacker,spec)
				preload("res://scripts/block_tier_feedback.gd").show_for(victim,int(block_result.tier))
				field.events.append({"time":field.elapsed,"event":"directional_parry" if int(block_result.tier)==3 else ("parry" if parry_ready else "self_block"),"tier":block_result.tier,"tier_name":block_result.tier_name,"victim":victim.team,"attacker":attacker.team,"physical_blocked":shield_absorbed,"effects_blocked":parry_ready,"stamina_spent":block_result.stamina_spent,"mana_refund":block_result.mana_refund,"spell":str(spec.get("id","unknown")),"delivery_type":str(spec.get("delivery_type","Projectile")),"incoming_direction":str(direction)})
				return true
	var health_before: float=victim.health
	var damage_before:float=victim.damage_taken
	if victim.has_method("set_hit_context"):victim.set_hit_context(q,shattered,bool(spec.get("launch",false)))
	if not victim.receive_magic(amount,direction,attacker,point,zone,bone,impulse.limit_length(1400)):
		return fraction>0
	if preload("res://scripts/combat_hit_regions.gd").is_head(zone) and victim.health<=0 and victim.has_method("sever_head") and victim.sever_head(impulse):
		field.events.append({"time":field.elapsed,"event":"headshot_kill","victim":victim.team,"attacker":attacker.team})
	field.show_combat_number(victim,"physical",maxf(0.0,victim.damage_taken-damage_before),preload("res://scripts/combat_hit_regions.gd").is_head(zone))
	field.show_hit_region(area)
	if victim.has_method("receive_status"):victim.receive_status(attacker,spec)
	if is_instance_valid(field.spell_environment):field.spell_environment.damage_ice_near(point,contact_damage,0.8)
	if spec.effect=="melee":
		attacker.melee_hits+=1
		attacker.melee_damage+=health_before-victim.health
	field.combat_impact_feedback(attacker,victim,spec,point,direction,hit_area,{"zone":zone,"bone":bone,"damage":health_before-victim.health,"physical_multiplier":physical_multiplier,"charge":q,"impulse":impulse,"shattered":shattered})
	return true

func step_channels(delta: float) -> void:
	for i in range(field.channels.size()-1,-1,-1):
		var item: Dictionary=field.channels[i]
		var f: CharacterBody3D=item.caster
		item.age+=delta
		item.tick-=delta
		item.trail+=delta
		if item.age>float(item.spec.get("channel_duration",0.65 if item.spec.effect=="beam" else 0.95+float(item.spec.get("charge",0))*0.4)) or f.health<=0 or f.mode!="cast":
			item.node.queue_free()
			field.channels.remove_at(i)
			continue
		var from:Vector3=field.fighter_hand(f,"both")
		var beam_target:=aim_target(f)
		if not is_instance_valid(beam_target):
			item.node.queue_free()
			field.channels.remove_at(i)
			continue
		var end: Vector3=beam_target.bone_point("spine_03")
		var query:=PhysicsRayQueryParameters3D.create(from,end+(end-from).normalized()*0.4,field.enemy_hurt_mask(f.team)|1)
		query.collide_with_areas=true
		query.collide_with_bodies=true
		var result:Dictionary=field.get_world_3d().direct_space_state.intersect_ray(query)
		var blocker: CharacterBody3D
		for enemy in field.fighters:
			if enemy.team==f.team or enemy.health<=0:
				continue
			var shield: Dictionary=enemy.shield_intersection(from,end)
			if not shield.is_empty() and (result.is_empty() or from.distance_to(shield.point)<from.distance_to(result.position)):
				end=shield.point
				blocker=enemy
		if blocker!=null:
			if item.tick<=0 and not (item.spec.effect=="beam" and item.hit):
				apply_impact(f,blocker,item.spec,end,(end-from).normalized())
				item.tick=0.18
				item.hit=true
		elif not result.is_empty():
			end=result.position
			if item.tick<=0 and not (item.spec.effect=="beam" and item.hit) and result.collider.has_meta("fighter") and result.collider.get_meta("fighter").health>0:
				apply_impact(f,result.collider.get_meta("fighter"),item.spec,end,(end-from).normalized(),result.collider,(end-from).normalized()*35)
				item.tick=0.18
				item.hit=true
		var path:=[]
		for segment in 14:
			path.append(from.lerp(end,segment/13.0)+Vector3.UP*sin(segment*1.5+field.elapsed*30)*0.025)
		if is_instance_valid(field.vfx):field.vfx.update_ribbon(item.node,path,0.22+float(item.spec.get("charge",0))*0.18)
		if item.trail>0.1 and is_instance_valid(field.vfx):
			item.trail=0
			field.vfx.puff(end,"smoke_04",1,Vector2.ONE*0.65,Vector3.UP*0.4,0.4,Color(0.75,0.95,1,0.55),0.6)

func step_pulses(delta: float) -> void:
	for i in range(field.pulses.size() - 1, -1, -1):
		var item: Dictionary = field.pulses[i]
		item.age += delta
		item.trail += delta
		var radius: float = 0.3 + item.age * 7.2
		item.node.scale = Vector3(radius, 0.6, radius)
		if not item.hit:
			var query := PhysicsShapeQueryParameters3D.new()
			if item.caster.team == 1:
				var shape := CylinderShape3D.new()
				shape.radius = radius
				shape.height = 0.65
				query.shape = shape
			else:
				var shape := SphereShape3D.new()
				shape.radius = radius
				query.shape = shape
			query.transform = Transform3D(Basis.IDENTITY, item.node.position + Vector3.UP * (0.35 if item.caster.team == 1 else 0.7))
			query.collision_mask = field.enemy_hurt_mask(item.caster.team)
			query.collide_with_bodies = false
			query.collide_with_areas = true
			var result:Array = field.get_world_3d().direct_space_state.intersect_shape(query, 16)
			if not result.is_empty():
				var area:Area3D = field.closest_hit_area(result, item.node.position)
				var victim = area.get_meta("fighter")
				var contact: Vector3 = victim.contact_surface(area, item.node.position)
				item.hit = apply_impact(item.caster, victim, item.spec, contact, (contact - item.node.position).normalized(), area)
		if item.trail > 0.11 and is_instance_valid(field.vfx):
			item.trail = 0
			for segment in 8:
				var angle: float = segment * TAU / 8 + item.age
				var point: Vector3 = item.node.position + Vector3(cos(angle), 0.1, sin(angle)) * radius
				field.vfx.puff(point, "flame_04" if item.caster.team == 0 else "twirl_02", item.caster.team, Vector2(0.5, 0.8), Vector3.UP * 1.4, 0.3, Color(field.element_color(item.caster.team), 0.8), 0.5, 3)
		if item.age >= 0.95:
			item.node.queue_free()
			field.pulses.remove_at(i)

func step_actors(delta:float) -> void:
	for f in field.fighters:
		_cancel_exited_cast(f)
		var incoming: Vector3=f.velocity
		if Vector3(f.drive_velocity.x+f.knockback.x,f.velocity.y,f.drive_velocity.z+f.knockback.z).length()>incoming.length():
			incoming=Vector3(f.drive_velocity.x+f.knockback.x,f.velocity.y,f.drive_velocity.z+f.knockback.z)
		f.tick(delta)
		_cancel_exited_cast(f)
		if not is_instance_valid(f.get("ragdoll")) and f.health>0:
			for i in f.get_slide_collision_count():
				var contact: KinematicCollision3D=f.get_slide_collision(i)
				if (contact.get_collider().has_meta("spell_ice") or contact.get_collider().has_meta("spell_earth")):
					var speed:float=maxf(0,-incoming.dot(contact.get_normal()))
					if speed>2.5:contact.get_collider().take_damage(speed*speed*0.4)
				elif field.is_impact_wall(contact.get_collider(),contact.get_normal()):
					var speed:=maxf(0,-incoming.dot(contact.get_normal()))
					if f.has_method("wall_crash") and speed>4.5 and (f.knockback.length()>1.5 or not f.is_on_floor() or speed>10):
						f.wall_crash(contact.get_position(),contact.get_normal(),speed,incoming,contact.get_collider())
						break
		f.update_targets()
	for f in field.fighters:
		f.resolve_melee(delta)
	step_touch_casts(delta)

func step_touch_casts(delta:float)->void:
	for key in touch_casts.keys():
		# A lethal contact can end the round and clear other casts in this loop.
		var contact:Dictionary=touch_casts.get(key,{})
		if contact.is_empty():continue
		var actor=contact.actor.get_ref()
		if not is_instance_valid(actor) or actor.health<=0.0 or actor.mode!=contact.mode or not field.round_active:
			if is_instance_valid(actor) and is_instance_valid(actor.touch_contact_visual):actor.touch_contact_visual.clear_runtime()
			touch_casts.erase(key);continue
		if contact.connected:continue
		for bone in contact.previous.keys():
			var limb:Vector3=actor.bone_point(bone)
			var strike:Dictionary={"id":str(contact.spec.get("id","physical_touch")),"clock":0.5,"begin":0.0,"end":1.0,"previous":contact.previous[bone],"limb":limb,"forward":actor.global_basis.z,"min_speed":0.0,"dynamic_damage":false,"pre_scaled":true,"radius":0.14,"damage":damage_for(contact.spec),"metadata":contact.spec}
			contact.previous[bone]=limb
			if preload("res://scripts/melee_contact.gd").resolve(actor,strike,delta):
				contact.connected=true;break
