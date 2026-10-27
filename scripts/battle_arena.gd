extends "res://scripts/duel_arena.gd"
const BattleActor = preload("res://scripts/battle_actor.gd")
const BattleVFX = preload("res://scripts/battle_vfx.gd")
const CombatAudio = preload("res://scripts/combat_audio.gd")
const Boundary = preload("res://scripts/arena_boundary.gd")
const OverdriveAura = preload("res://scripts/overdrive_aura.gd")
const FrozenLegEffect = preload("res://scripts/frozen_leg_effect.gd")
const BattleFighterTag = preload("res://scripts/fighter_overhead_tag.gd")
const OVERDRIVE_DURATION := 14.0
const KITS := [
	[{"id":"fireball","name":"Fireball","effect":"orb","animation":"palm_fireball","hand":"hand_r","release":0.68}, {"id":"fire_slash","name":"Cinder Slash","effect":"slash","animation":"cleaving_flick","hand":"hand_r","release":0.64}],
	[{"id":"ice_armor","name":"Glacial Armor","effect":"armor","animation":"twin_push","hand":"both","release":1.0}, {"id":"ice_beam","name":"Freezing Ray","effect":"ice_beam","animation":"flame_channel","hand":"both","release":0.8}],
	[{"id":"overdrive","name":"Overdrive","effect":"haste","animation":"self_mend","hand":"both","release":0.95}, {"id":"flash_step","name":"Flash Step","effect":"burst","animation":"palm_fireball","hand":"hand_r","release":0.68}]]
var audio: Node3D
var armor_meshes: Array = []
var freeze_effects: Array[Node3D]=[]
var status_labels: Array = []
var eliminated := {}
var target_timer := 0.0
var beam_clashes := 0
var ending := false
var storm_aura: Node3D

func _ready() -> void:
	rng.seed = 715391
	wins = [0,0,0]
	shield_hit_age = [2.0,2.0,2.0]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):
			duration = float(arg.trim_prefix("--duration="))
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
		if arg.begins_with("--report-file="):
			report_file = arg.trim_prefix("--report-file=")
	build_colosseum_stage()
	add_child(Boundary.new())
	hud.get_parent().queue_free()
	vfx = BattleVFX.new()
	add_child(vfx)
	vfx.camera = camera
	water_material = vfx.water
	audio = CombatAudio.new()
	add_child(audio)
	for i in 3:
		var f := BattleActor.new()
		f.team = i
		f.arena = self
		add_child(f)
		fighters.append(f)
		BattleFighterTag.attach(f,element_name(i)+" FIGHTER")
		var charge_node: MeshInstance3D = vfx.projectile(i, "orb", 0.10)
		add_child(charge_node)
		charge_node.visible = false
		charges.append(charge_node)
		var shield: MeshInstance3D = vfx.shield(i)
		add_child(shield)
		shields.append(shield)
		var pieces := []
		for bone in ["spine_03","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","pelvis"]:
			var piece := MeshInstance3D.new()
			var mesh_ := SphereMesh.new()
			mesh_.radius = 0.14
			mesh_.height = 0.32
			mesh_.radial_segments = 6
			mesh_.rings = 3
			piece.mesh = mesh_
			piece.material_override = water_material
			piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(piece)
			pieces.append([piece,bone])
		armor_meshes.append(pieces)
		var freeze_visual:=FrozenLegEffect.new()
		freeze_visual.fighter=f
		add_child(freeze_visual)
		freeze_effects.append(freeze_visual)
	for f in fighters:
		f.rival = fighters[(f.team+1)%3]
	storm_aura=OverdriveAura.new()
	storm_aura.fighter=fighters[2]
	add_child(storm_aura)
	build_fight_ui()
	begin_round()

func build_colosseum_stage() -> void:
	var world:=WorldEnvironment.new()
	var environment:=Environment.new()
	var sky:=Sky.new()
	var sky_material:=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("50789c")
	sky_material.sky_horizon_color=Color("ded1b6")
	sky_material.ground_horizon_color=Color("b9a17b")
	sky.sky_material=sky_material
	environment.background_mode=Environment.BG_SKY
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("e7dcc8")
	environment.ambient_light_energy=0.55
	world.environment=environment
	add_child(world)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-52,-32,0)
	sun.light_color=Color("fff0d5")
	sun.light_energy=0.95
	sun.shadow_enabled=true
	add_child(sun)
	camera=Camera3D.new()
	camera.position=Vector3(0,6,13)
	camera.fov=48
	add_child(camera)
	camera.look_at(Vector3(0,1,0))
	camera.current=true
	var layer:=CanvasLayer.new()
	add_child(layer)
	hud=Label.new()
	layer.add_child(hud)

func element_color(team: int) -> Color:
	return [Color("ff641b"),Color("8ee9ff"),Color("ffdb51")][clampi(team,0,2)]

func element_name(team: int) -> String:
	return ["FIRE","ICE","STORM"][clampi(team,0,2)]

func profile_spells(team: int) -> Array:
	return KITS[team]

func enemy_hurt_mask(team: int) -> int:
	return (8 | 16 | 32) ^ (8 << team)

func spell_name(spec: Dictionary, _team: int) -> String:
	return spec.get("name", spec.id)

func begin_round() -> void:
	clear_battle_effects()
	eliminated.clear()
	round_number += 1
	round_time = 0
	round_active = false
	warmup = 1.0
	intermission = 0
	var positions := [Vector3(-3.464,0.02,-2),Vector3(3.464,0.02,-2),Vector3(0,0.02,4)]
	for i in 3:
		positions[i].x*=Boundary.RADIUS/10.0
		positions[i].z*=Boundary.RADIUS/10.0
		fighters[i].reset_fighter(positions[i])
		fighters[i].rival = fighters[(i+1)%3]
	status = "FIRE  ×  ICE  ×  STORM"
	events.append({"time":elapsed,"event":"round_start","round":round_number})

func finish_round(_winner: int) -> void:
	if not round_active:
		return
	var alive := []
	for f in fighters:
		if f.health > 0:
			alive.append(f)
		elif not eliminated.has(f.team):
			eliminated[f.team] = true
			events.append({"time":elapsed,"event":"eliminated","team":f.team})
	if alive.size() > 1:
		return
	round_active = false
	intermission = 3.8
	if alive.size() == 1:
		wins[alive[0].team] += 1
		status = element_name(alive[0].team) + " WINS"
	else:
		status = "DRAW"
	events.append({"time":elapsed,"event":"round_end","winner":alive[0].team if alive.size()==1 else -1})

func choose_targets() -> void:
	for f in fighters:
		if f.health <= 0:
			continue
		var best: CharacterBody3D
		var best_score := INF
		for candidate in fighters:
			if candidate == f or candidate.health <= 0:
				continue
			var score: float = f.focus_position().distance_to(candidate.focus_position())
			if candidate == f.rival:
				score *= 0.85
			if candidate.team == f.last_attacker:
				score *= 0.80
			if is_instance_valid(candidate.ragdoll):
				score += 4.0
			if score < best_score:
				best_score = score
				best = candidate
		if best != null:
			if f.rival != best:
				events.append({"time":elapsed,"event":"target","team":f.team,"target":best.team})
			f.rival = best

func _physics_process(delta: float) -> void:
	if ending:
		return
	elapsed += delta
	if warmup > 0:
		warmup -= delta
		if warmup <= 0:
			round_active = true
			status = "FIGHT"
	elif intermission > 0:
		intermission -= delta
		if intermission <= 0:
			begin_round()
	target_timer -= delta
	if target_timer <= 0:
		target_timer = 0.7
		choose_targets()
	if round_active:
		round_time += delta
	for f in fighters:
		var incoming: Vector3=f.velocity
		if Vector3(f.drive_velocity.x+f.knockback.x,f.velocity.y,f.drive_velocity.z+f.knockback.z).length()>incoming.length():
			incoming=Vector3(f.drive_velocity.x+f.knockback.x,f.velocity.y,f.drive_velocity.z+f.knockback.z)
		f.tick(delta)
		if not is_instance_valid(f.ragdoll) and f.health>0:
			for i in f.get_slide_collision_count():
				var contact: KinematicCollision3D=f.get_slide_collision(i)
				if contact.get_collider().has_meta("arena_wall"):
					var speed:=maxf(0,-incoming.dot(contact.get_normal()))
					if speed>4.5 and (f.knockback.length()>1.5 or not f.is_on_floor() or speed>10):
						f.wall_crash(contact.get_position(),contact.get_normal(),speed,incoming)
						break
		f.update_targets()
		max_radius = maxf(max_radius, Vector2(f.focus_position().x,f.focus_position().z).length())
	for f in fighters:
		f.resolve_melee(delta)
	for i in 3:
		var f = fighters[i]
		for j in range(i+1,3):
			if f.health > 0 and fighters[j].health > 0:
				minimum_spacing = minf(minimum_spacing,f.focus_position().distance_to(fighters[j].focus_position()))
		shield_hit_age[i] += delta
		shields[i].visible = f.shield_active() and not is_instance_valid(f.ragdoll)
		if shields[i].visible:
			shields[i].position = f.shield_center()
			shields[i].basis = f.global_basis
			shields[i].material_override.set_shader_parameter("hit_age",shield_hit_age[i])
		charges[i].visible = round_active and f.mode in ["cast","melee_charge","burst_charge"] and not f.did_release
		if charges[i].visible:
			charges[i].position = fighter_hand(f,f.current_spell.get("hand","hand_r"))
			charges[i].scale = Vector3.ONE * (0.7+f.charge_value*2.5)
			if int(elapsed*60)%5 == 0:
				vfx.puff(charges[i].position,"magic_01",i,Vector2.ONE*(0.45+f.charge_value),Vector3.ZERO,0.2,Color(element_color(i),0.65),0.2,5)
		for piece in armor_meshes[i]:
			piece[0].visible = f.armor_hp > 0 and f.health > 0
			if piece[0].visible:
				piece[0].position = f.bone_point(piece[1])
				piece[0].scale = Vector3(1.4,1.2,0.7) if piece[1]=="spine_03" else Vector3.ONE
		freeze_effects[i].step()
		if int(elapsed*60)%8 == 0 and f.health > 0:
			if f.mode=="punch" and f.strike_augmented:
				vfx.puff(f.bone_point(f.melee_spec[2]),"flame_04" if i==0 else "spark_05",i,Vector2.ONE*0.4,Vector3.UP*0.4,0.2,Color(element_color(i),0.8),0.4)
			if f.burn_time > 0:
				vfx.puff(f.bone_point("spine_03"),"flame_04",0,Vector2(0.45,0.7),Vector3.UP,0.35,Color(1,0.5,0.1,0.65),0.5)
			if f.chill_time > 0:
				vfx.puff(f.bone_point("calf_l").lerp(f.bone_point("calf_r"),0.5),"smoke_04",1,Vector2.ONE*0.65,Vector3.UP*0.3,0.4,Color(0.6,0.9,1,0.4),0.3)
			if f.haste_time > 0:
				vfx.puff(f.bone_point("calf_r"),"trace_02",2,Vector2(0.2,0.8),Vector3.UP,0.16,Color("fff1a3"),0.3)
	step_shots(delta)
	storm_aura.step(delta)
	step_channels(delta)
	step_particles(delta)
	vfx.step(delta)
	update_camera(delta)
	update_fight_ui()
	peak_effects = maxi(peak_effects,shots.size()+channels.size()+vfx.motes.size()+vfx.chips.size())
	if not capture_dir.is_empty() and elapsed >= next_capture and capture_count < 40:
		next_capture += 1.5
		capture_count += 1
		capture.call_deferred("battle_%03d.png"%capture_count)
	if duration > 0 and elapsed >= duration:
		write_report()
		finish_run()

func finish_run() -> void:
	if ending:
		return
	ending=true
	audio.stop_all()
	for f in fighters:
		if is_instance_valid(f.ragdoll):
			f.ragdoll.restore_pose()
			f.ragdoll.queue_free()
			f.ragdoll=null
	get_tree().create_timer(0.15).timeout.connect(get_tree().quit)

func cast_magic(f: CharacterBody3D, spec: Dictionary, _air: bool) -> void:
	if spec.effect=="burst" and f.stamina<f.flash_stamina_requirement():
		return
	if not round_active or f.health <= 0 or not f.spend_mana(mana_cost(spec)):
		return
	var key := "%s/%s"%[element_name(f.team),spec.id]
	casts[key] = casts.get(key,0)+1
	status = element_name(f.team)+"  •  "+spec.name+ ("  CHARGED" if spec.get("charge",0)>0.1 else "")
	events.append({"time":elapsed,"event":"cast","team":f.team,"spell":spec.id,"charge":spec.get("charge",0),"mana":f.mana})
	if spec.effect == "armor":
		f.armor_time = 6.5
		f.armor_hp = 50
		audio.impact("ice",f.global_position,0.5)
	elif spec.effect == "haste":
		f.haste_time = OVERDRIVE_DURATION
		audio.impact("dash",f.global_position,0.6)
	elif spec.effect == "burst":
		f.start_burst(true)
	elif spec.effect == "ice_beam":
		var node := MeshInstance3D.new()
		node.material_override = vfx.ribbon_materials[1]
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		channels.append({"node":node,"caster":f,"age":0.0,"spec":spec.duplicate(),"tick":0.0,"trail":0.0})
		audio.impact("ice",fighter_hand(f,"both"),0.5)
	else:
		spawn_projectile(f,spec,fighter_hand(f,spec.hand))
		audio.impact("dash",fighter_hand(f,spec.hand),0.45)

func mana_cost(spec: Dictionary) -> float:
	var base: float = {"orb":14.0,"slash":12.0,"armor":20.0,"ice_beam":22.0,"haste":18.0,"burst":9.0}.get(spec.effect,12.0)
	return base*(1.0+float(spec.get("charge",0))*0.8)

func damage_for(spec: Dictionary) -> float:
	if spec.has("damage"):
		return spec.damage
	var base := 18.0 if spec.effect=="orb" else (16.0 if spec.effect=="slash" else 4.5)
	return base*(1.0+float(spec.get("charge",0))*1.2)

func spawn_projectile(f: CharacterBody3D, spec: Dictionary, origin: Vector3) -> void:
	var q: float = clampf(spec.get("charge",0),0,1)
	var speed := (14.0 if spec.effect=="orb" else 17.0)*(1+q*0.7)
	var radius := (0.16 if spec.effect=="orb" else 0.13)*(1+q*0.9)
	var node: MeshInstance3D = vfx.projectile(f.team,"slash" if spec.effect=="slash" else "orb",radius)
	add_child(node)
	node.position = origin
	if spec.effect=="slash":
		node.scale = Vector3.ONE*(1+q*0.6)
	var target: Vector3 = f.rival.bone_point("spine_03")+f.rival.velocity*minf(0.4,origin.distance_to(f.rival.bone_point("spine_03"))/speed)
	var velocity_: Vector3 = (target-origin).normalized()*speed
	shot_serial += 1
	shots.append({"id":shot_serial,"node":node,"velocity":velocity_,"mass":(13.0 if spec.effect=="orb" else 10.0)*(1+q*1.8),"caster":f,"age":0.0,"trail":0.0,"spec":spec.duplicate(),"radius":radius})

func step_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var shot: Dictionary = shots[i]
		var from: Vector3 = shot.node.position
		var to: Vector3 = from+shot.velocity*delta
		var ground := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
		if not ground.is_empty():
			to=ground.position
		shot.age += delta
		shot.trail += delta
		var hit := false
		var contact := {}
		var blocked_by: CharacterBody3D
		for enemy in fighters:
			if enemy.team==shot.caster.team or enemy.health<=0:
				continue
			var shield_contact: Dictionary = enemy.shield_intersection(from,to,shot.radius)
			if not shield_contact.is_empty() and (contact.is_empty() or from.distance_to(shield_contact.point)<from.distance_to(contact.point)):
				contact=shield_contact
				blocked_by=enemy
		if not contact.is_empty():
			hit=apply_impact(shot.caster,blocked_by,shot.spec,contact.point,shot.velocity.normalized(),null,shot.velocity*shot.mass)
		var shape := SphereShape3D.new()
		shape.radius=shot.radius
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape=shape
		query.collision_mask=enemy_hurt_mask(shot.caster.team)
		query.collide_with_areas=true
		query.collide_with_bodies=false
		var samples := maxi(1,ceili(from.distance_to(to)/0.06))
		for sample in range(samples+1):
			if hit:
				break
			var point := from.lerp(to,float(sample)/samples)
			query.transform=Transform3D(Basis.IDENTITY,point)
			var results := get_world_3d().direct_space_state.intersect_shape(query,12)
			for result in results:
				var victim = result.collider.get_meta("fighter")
				if victim.health>0:
					apply_impact(shot.caster,victim,shot.spec,victim.contact_surface(result.collider,point),shot.velocity.normalized(),result.collider,shot.velocity*shot.mass)
					hit=true
					break
		if not hit and not ground.is_empty():
			impact_burst(ground.position,shot.caster.team,false)
			hit=true
		if hit or shot.age>2.2:
			shot.node.queue_free()
			shots.remove_at(i)
		else:
			shot.node.position=to
			if shot.trail>0.035:
				shot.trail=0
				vfx.flight(shot.node,shot.velocity,shot.caster.team,shot.spec.effect,shot.age)

func step_channels(delta: float) -> void:
	for i in range(channels.size()-1,-1,-1):
		var item: Dictionary=channels[i]
		var f: CharacterBody3D=item.caster
		item.age+=delta
		item.tick-=delta
		item.trail+=delta
		if item.age>0.95+float(item.spec.get("charge",0))*0.4 or f.health<=0 or f.mode!="cast":
			item.node.queue_free()
			channels.remove_at(i)
			continue
		var from:=fighter_hand(f,"both")
		var end: Vector3=f.rival.bone_point("spine_03")
		var query:=PhysicsRayQueryParameters3D.create(from,end+(end-from).normalized()*0.4,enemy_hurt_mask(f.team)|1)
		query.collide_with_areas=true
		query.collide_with_bodies=true
		var result:=get_world_3d().direct_space_state.intersect_ray(query)
		var blocker: CharacterBody3D
		for enemy in fighters:
			if enemy.team==f.team or enemy.health<=0:
				continue
			var shield: Dictionary=enemy.shield_intersection(from,end)
			if not shield.is_empty() and (result.is_empty() or from.distance_to(shield.point)<from.distance_to(result.position)):
				end=shield.point
				blocker=enemy
		if blocker!=null:
			if item.tick<=0:
				apply_impact(f,blocker,item.spec,end,(end-from).normalized())
				item.tick=0.18
		elif not result.is_empty():
			end=result.position
			if item.tick<=0 and result.collider.has_meta("fighter") and result.collider.get_meta("fighter").health>0:
				apply_impact(f,result.collider.get_meta("fighter"),item.spec,end,(end-from).normalized(),result.collider,(end-from).normalized()*35)
				item.tick=0.18
		var path:=[]
		for segment in 14:
			path.append(from.lerp(end,segment/13.0)+Vector3.UP*sin(segment*1.5+elapsed*30)*0.025)
		vfx.update_ribbon(item.node,path,0.22+float(item.spec.get("charge",0))*0.18)
		if item.trail>0.1:
			item.trail=0
			vfx.puff(end,"smoke_04",1,Vector2.ONE*0.65,Vector3.UP*0.4,0.4,Color(0.75,0.95,1,0.55),0.6)

func apply_impact(attacker: CharacterBody3D,victim: CharacterBody3D,spec: Dictionary,point: Vector3,direction: Vector3,hit_area: Area3D=null,incoming_impulse:=Vector3.ZERO)->bool:
	if victim==attacker or victim.health<=0 or not round_active or victim.invulnerability>0:
		return false
	var amount:=damage_for(spec)
	var original:=amount
	var q: float=clampf(spec.get("charge",0),0,1)
	var impulse: Vector3=incoming_impulse if not incoming_impulse.is_zero_approx() else direction*amount*9
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
		audio.impact("shatter" if shattered else "shield",point,0.85)
	if amount<=0.05:
		return true
	if shattered and q>0.6:
		impulse+=Vector3.UP*450*q
	var area: Area3D=hit_area if hit_area!=null else victim.nearest_hurtbox(point)
	var zone: String=area.get_meta("zone","chest")
	var bone: String=area.get_meta("bone","spine_03")
	var health_before: float=victim.health
	victim.last_hit_charge=q
	victim.last_guard_shattered=shattered
	victim.last_hit_launch=spec.get("launch",false)
	if not victim.receive_magic(amount,direction,attacker,point,zone,bone,impulse.limit_length(1400)):
		return fraction>0
	victim.receive_status(attacker,spec)
	if spec.effect=="melee":
		attacker.melee_hits+=1
		attacker.melee_damage+=health_before-victim.health
	var key: String="%s/%s"%[element_name(attacker.team),spec.id]
	hits[key]=hits.get(key,0)+1
	var hit_label: String={"arm_l":"LEFT ARM","arm_r":"RIGHT ARM","leg_l":"LEFT LEG","leg_r":"RIGHT LEG","pelvis":"BODY"}.get(zone,zone.to_upper())
	status="%s  •  %s  •  %s"%[element_name(attacker.team),spell_name(spec,attacker.team),hit_label]
	events.append({"time":elapsed,"event":"hit","team":attacker.team,"victim":victim.team,"spell":spec.id,"zone":zone,"damage":health_before-victim.health,"charge":q,"impulse":impulse.length(),"shattered":shattered,"combo":spec.get("combo",false)})
	impact_burst(point,attacker.team,true)
	var sound: String="heavy" if impulse.length()>400 else ("ice" if attacker.team==1 and spec.effect!="melee" else ("kick" if spec.id in ["front_kick","round_kick","knee"] else "punch"))
	audio.impact(sound,point,minf(1,impulse.length()/400))
	shake=maxf(shake,0.08 if impulse.length()<400 else 0.20)
	return true

func update_camera(delta: float) -> void:
	if review_camera:
		return
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	for f in fighters:
		if f.health<=0 and round_active and f.death_age>1.4:
			continue
		var p: Vector3=f.focus_position()+Vector3.UP
		low=low.min(p-Vector3.ONE*0.8)
		high=high.max(p+Vector3.ONE*0.8)
	var center: Vector3=(low+high)*0.5
	var backward:=Vector3(0,0.38,1).normalized()
	var upward:=Vector3(0,1,-0.38).normalized()
	var distance:=8.5
	for f in fighters:
		if f.health<=0 and round_active and f.death_age>1.4:
			continue
		for height in [0.0,1.9]:
			var offset: Vector3=f.focus_position()+Vector3.UP*height-center
			var vertical_allowance:=0.58 if offset.dot(upward)>0 else 0.85
			var fit:=maxf(absf(offset.x)/(tan(deg_to_rad(24))*1.6*0.88),absf(offset.dot(upward))/(tan(deg_to_rad(24))*vertical_allowance))
			distance=maxf(distance,offset.dot(backward)+fit+1.1)
	var goal:=center+backward*distance
	camera.position=camera.position.lerp(goal,minf(1,delta*4))
	camera.fov=48
	shake=maxf(0,shake-delta)
	camera.look_at(center+Vector3(sin(elapsed*143),cos(elapsed*111),0)*shake)

func build_fight_ui() -> void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var backdrop:=ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_bottom=158
	backdrop.color=Color(0.02,0.04,0.065,0.78)
	root.add_child(backdrop)
	var row:=HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left=18
	row.offset_right=-18
	row.offset_top=10
	row.add_theme_constant_override("separation",24)
	root.add_child(row)
	for f in fighters:
		var column:=VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",2)
		row.add_child(column)
		var label:=Label.new()
		label.add_theme_font_size_override("font_size",19)
		label.add_theme_color_override("font_color",element_color(f.team))
		column.add_child(label)
		health_labels.append(label)
		var health:=resource_meter(column,"HEALTH",element_color(f.team),f.MAX_HEALTH)
		health_bars.append(health[0])
		var mana_row:=resource_meter(column,"MANA",Color("a493f2"),f.MAX_MANA)
		var stamina_row:=resource_meter(column,"STAMINA",Color("add46a"),f.MAX_STAMINA)
		var guard_row:=resource_meter(column,"GUARD",Color("c4e6f3"),f.MAX_GUARD)
		mana_bars.append(mana_row[0])
		stamina_bars.append(stamina_row[0])
		guard_bars.append(guard_row[0])
		var state:=Label.new()
		state.add_theme_font_size_override("font_size",12)
		column.add_child(state)
		status_labels.append(state)
		resource_labels.append([health[1],mana_row[1],stamina_row[1],guard_row[1]])
	subtitle=Label.new()
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top=166
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",17)
	subtitle.add_theme_color_override("font_shadow_color",Color.BLACK)
	subtitle.add_theme_constant_override("shadow_offset_x",1)
	subtitle.add_theme_constant_override("shadow_offset_y",1)
	root.add_child(subtitle)
	hud=Label.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud.offset_left=18
	hud.offset_top=-30
	hud.text="FREE-FOR-ALL  •  F2 Animations  •  Space slow  •  R restart  •  M sound  •  Esc Home"
	hud.add_theme_font_size_override("font_size",13)
	root.add_child(hud)
	round_label=Label.new()
	round_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	round_label.offset_left=-240
	round_label.offset_top=-30
	round_label.add_theme_font_size_override("font_size",13)
	root.add_child(round_label)

func update_fight_ui() -> void:
	for i in 3:
		var f= fighters[i]
		health_bars[i].value=f.health
		mana_bars[i].value=f.mana
		stamina_bars[i].value=f.stamina
		guard_bars[i].value=f.guard_energy
		health_labels[i].text="%s  %d / %d"%[element_name(i),ceili(f.health),f.MAX_HEALTH]
		for j in 4:
			resource_labels[i][j].text=str(ceili(f.health) if j==0 else floori([f.health,f.mana,f.stamina,f.guard_energy][j]))
		var states:=[]
		if f.health<=0: states.append("OUT")
		elif is_instance_valid(f.ragdoll): states.append("RAGDOLL")
		elif f.freeze_time>0: states.append("FROZEN")
		elif f.mode=="burst_charge": states.append("FLASH CHARGE")
		elif f.tactics.banking: states.append("RECOVERING")
		elif f.mode=="cast" and f.cast_phase=="hold": states.append("CHARGING %d%%"%int(f.charge_value*100))
		elif f.mode=="melee_charge": states.append("UPPERCUT %d%%"%int(f.melee_charge*100))
		else: states.append("FISTS" if f.close_combat else "MAGIC")
		if f.armor_hp>0: states.append("ARMOR %d"%int(f.armor_hp))
		if f.haste_time>0: states.append("OVERDRIVE %ds"%ceili(f.haste_time))
		if f.chill_time>0: states.append("SLOWED")
		if f.burn_time>0: states.append("BURNING")
		status_labels[i].text=" · ".join(states)
	subtitle.text=status
	round_label.text="ROUND %d   %d / %d / %d"%[round_number,wins[0],wins[1],wins[2]]

func write_report() -> void:
	var stats:=[]
	for f in fighters:
		stats.append({"team":f.team,"element":element_name(f.team),"health":f.health,"mana":f.mana,"stamina":f.stamina,"actions":f.actions,"melee_hits":f.melee_hits,"charged_casts":f.charged_casts,"ragdolls":f.ragdoll_count,"recoveries":f.recoveries_count,"ragdoll_peak":f.ragdoll_peak,"freezes":f.freezes,"burns_applied":f.burns_applied,"dash_combo_hits":f.dash_combo_hits,"damage_dealt":f.damage_dealt,"tactical_replans":f.tactics.replans})
	var report:={"seconds":elapsed,"rounds":round_number,"wins":wins,"fighters":stats,"casts":casts,"hits":hits,"events":events,"audio":audio.played,"peak_effects":peak_effects,"fps":Engine.get_frames_per_second()}
	var summary:=report.duplicate()
	summary.erase("events")
	print("REPORT ",JSON.stringify(summary))
	var destination:=report_file if not report_file.is_empty() else capture_dir.path_join("report.json")
	if not report_file.is_empty() or not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var file:=FileAccess.open(destination,FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F2:
		audio.stop_all()
		Engine.time_scale=1
		get_tree().change_scene_to_file("res://scenes/combat_sandbox.tscn")
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		audio.stop_all()
		Engine.time_scale=1
		get_tree().change_scene_to_file("res://scenes/home.tscn")
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_M:
		audio.muted=not audio.muted
		if audio.muted:audio.stop_all()
	else:
		super._unhandled_key_input(event)
