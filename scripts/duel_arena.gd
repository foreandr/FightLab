extends "res://scripts/spell_arena.gd"
## Elemental arena combat composed from the meadow, spell VFX and licensed humanoids.
const Fighter = preload("res://scripts/duel_actor.gd")
const VFX = preload("res://scripts/elemental_vfx.gd")
const FighterTag = preload("res://scripts/fighter_overhead_tag.gd")
const WATER := Color(0.16, 0.67, 1.0)
var fighters: Array = []
var charges: Array = []
var pulses: Array = []
var channels: Array = []
var health_bars: Array = []
var health_labels: Array = []
var round_label: Label
var round_active := false
var round_number := 0
var warmup := 0.8
var intermission := 0.0
var wins := [0, 0]
var round_time := 0.0
var shot_serial := 0
var shake := 0.0
var water_material: ShaderMaterial
var minimum_spacing := INF
var max_radius := 0.0
var next_capture := 2.0
var peak_effects := 0
var view_axis := Vector3(0, 0, 1)
var clashes := 0
var vfx: Node3D
var shields: Array = []
var guard_bars: Array = []
var shield_hit_age := [2.0, 2.0]
var mana_bars: Array = []
var stamina_bars: Array = []
var resource_labels: Array = []
var review_camera := false

func _ready() -> void:
	rng.seed = 715391
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):
			duration = float(arg.trim_prefix("--duration="))
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
		if arg.begins_with("--report-file="):
			report_file = arg.trim_prefix("--report-file=")
	build_grassland()
	hud.get_parent().queue_free()
	vfx = VFX.new()
	add_child(vfx)
	vfx.camera = camera
	water_material = vfx.water
	for i in 2:
		var f = Fighter.new()
		f.team = i
		f.arena = self
		add_child(f)
		fighters.append(f)
		FighterTag.attach(f,element_name(i)+" FIGHTER")
		var light = vfx.projectile(i, "orb", 0.09)
		add_child(light)
		light.visible = false
		charges.append(light)
		var shield = vfx.shield(i)
		add_child(shield)
		shields.append(shield)
	fighters[0].rival = fighters[1]
	fighters[1].rival = fighters[0]
	build_fight_ui()
	begin_round()

func element_color(team: int) -> Color:
	return FIRE if team == 0 else WATER

func element_name(team: int) -> String:
	return "FIRE" if team == 0 else "WATER"

func spell_name(spec: Dictionary, team: int) -> String:
	if team == 0:
		return spec.name
	var names := {"palm_fireball":"Aqua Bolt", "cleaving_flick":"Razor Current", "overhead_cleave":"Tidal Cleave", "self_mend":"Restoring Mist", "twin_push":"Crashing Wave", "offhand_spark":"Water Dart", "sun_spear":"Water Lance", "ground_sigil":"Geyser Sigil", "solar_nova":"Tidal Surge", "flame_channel":"Torrent"}
	return names.get(spec.id, spec.name)

func begin_round() -> void:
	clear_battle_effects()
	round_number += 1
	round_time = 0
	round_active = false
	warmup = 0.8
	intermission = 0
	for i in 2:
		fighters[i].reset_fighter(Vector3(-2.8 if i == 0 else 2.8, 0.02, 0))
	status = "FIRE vs WATER"
	events.append({"time":elapsed, "event":"round_start", "round":round_number})

func finish_round(winner: int) -> void:
	if not round_active:
		return
	round_active = false
	intermission = 3.2
	wins[winner] += 1
	status = "%s WINS" % element_name(winner)
	events.append({"time":elapsed, "event":"knockout", "winner":winner, "round":round_number})
	print("KNOCKOUT t=%.2f " % elapsed, element_name(winner))

func clear_battle_effects() -> void:
	if vfx:
		vfx.clear()
	for shot in shots:
		shot.node.queue_free()
	shots.clear()
	for item in particles:
		item.node.queue_free()
	particles.clear()
	for item in pulses:
		item.node.queue_free()
	pulses.clear()
	for item in channels:
		item.node.queue_free()
	channels.clear()

func _physics_process(delta: float) -> void:
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
	if round_active:
		round_time += delta
	for f in fighters:
		f.tick(delta)
	for f in fighters:
		f.update_targets()
		max_radius = maxf(max_radius, Vector2(f.position.x, f.position.z).length())
	for f in fighters:
		f.resolve_melee(delta)
	minimum_spacing = minf(minimum_spacing, fighters[0].position.distance_to(fighters[1].position))
	for i in 2:
		var f = fighters[i]
		shield_hit_age[i] += delta
		shields[i].visible = f.shield_active()
		if shields[i].visible:
			shields[i].position = f.shield_center()
			shields[i].basis = f.global_basis
			shields[i].material_override.set_shader_parameter("strength", minf(1.0, f.mode_time * 5.0))
			shields[i].material_override.set_shader_parameter("hit_age", shield_hit_age[i])
		charges[i].visible = round_active and f.mode == "cast" and not f.did_release
		if charges[i].visible:
			charges[i].position = fighter_hand(f, f.current_spell.hand)
			charges[i].scale = Vector3.ONE * (0.65 + minf(1, f.cast_time / maxf(0.1, f.current_spell.release)) * 0.7)
			if int(elapsed * 60) % 4 == 0:
				vfx.puff(charges[i].position, "magic_01", i, Vector2.ONE * 0.45, Vector3.ZERO, 0.19, Color(element_color(i), 0.55), 0.0, 5.0)
	clash_projectiles(delta)
	step_shots(delta)
	step_pulses(delta)
	step_channels(delta)
	step_particles(delta)
	vfx.step(delta)
	update_camera(delta)
	update_fight_ui()
	peak_effects = maxi(peak_effects, shots.size() + particles.size() + channels.size() + pulses.size())
	if not capture_dir.is_empty() and elapsed >= next_capture and capture_count < 32:
		next_capture += 1.25
		capture_count += 1
		capture.call_deferred("duel_%03d.png" % capture_count)
	if duration > 0 and elapsed >= duration:
		write_report()
		get_tree().quit()

func fighter_hand(f: CharacterBody3D, hand: String) -> Vector3:
	return (f.bone_point("hand_l") + f.bone_point("hand_r")) * 0.5 if hand == "both" else f.bone_point(hand)

func cast_magic(f: CharacterBody3D, spec: Dictionary, air: bool) -> void:
	if not round_active or f.health <= 0:
		return
	if not f.spend_mana(mana_cost(spec)):
		f.set_close_combat(true)
		return
	var key := "%s/%s" % [element_name(f.team), spec.id]
	casts[key] = casts.get(key, 0) + 1
	status = "%s  •  %s%s" % [element_name(f.team), "AERIAL " if air else "", spell_name(spec, f.team)]
	events.append({"time":elapsed, "event":"cast", "team":f.team, "spell":spec.id, "airborne":air, "mana":f.mana})
	var color := element_color(f.team)
	if spec.effect == "heal":
		var restored: float = minf(22, f.MAX_HEALTH - f.health)
		f.health += restored
		f.healed_this_round = true
		heals += 1
		for i in 3:
			vfx.puff(f.position + Vector3.UP * (0.35 + i * 0.4), "magic_01", f.team, Vector2.ONE * 0.8, Vector3.UP * 0.4, 0.8, Color(color.lightened(0.3), 0.75), 0.6, 3)
		events.append({"time":elapsed, "event":"heal", "team":f.team, "amount":restored})
	elif spec.effect == "nova":
		var node := make_ring(color)
		node.material_override = vfx.ribbon_materials[f.team]
		node.position = f.position + Vector3.UP * 0.10
		pulses.append({"node":node, "age":0.0, "trail":0.0, "caster":f, "hit":false, "spec":spec})
	elif spec.effect == "beam":
		var node := MeshInstance3D.new()
		node.material_override = vfx.ribbon_materials[f.team]
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		channels.append({"node":node, "caster":f, "age":0.0, "hit":false, "spec":spec, "trail":0.0})
	else:
		var origin := fighter_hand(f, spec.hand)
		if spec.effect == "ground" and f.is_on_floor():
			ring(f.position + Vector3.UP * 0.04, 0.6, color, 0.55)
			origin = f.position + Vector3.UP * 0.30
		spawn_projectile(f, spec, origin)

func damage_for(spec: Dictionary) -> float:
	if spec.effect == "melee":
		return spec.damage
	return {"orb":16.0, "spark":12.0, "slash":18.0, "cleave":22.0, "heavy":24.0, "spear":22.0, "ground":18.0, "nova":20.0, "beam":24.0}.get(spec.effect, 16.0)

func mana_cost(spec: Dictionary) -> float:
	return {"orb":14.0, "spark":10.0, "slash":16.0, "cleave":18.0, "heavy":22.0, "spear":20.0, "ground":18.0, "nova":28.0, "beam":26.0, "heal":24.0}.get(spec.effect, 14.0)

func predictive_aim(f: CharacterBody3D, origin: Vector3, speed: float, target_bone := "spine_03") -> Vector3:
	var enemy: CharacterBody3D = f.rival
	var offset := Vector3(0, -0.08, 0) if target_bone == "spine_03" else Vector3.ZERO
	var aim: Vector3 = enemy.bone_point(target_bone, offset)
	var travel := origin.distance_to(aim) / speed
	for i in 3:
		var lead: Vector3 = enemy.velocity * travel
		if not enemy.is_on_floor():
			lead.y -= 0.5 * enemy.GRAVITY * travel * travel
		aim = enemy.bone_point(target_bone, offset) + lead
		aim.y = maxf(0.18 if target_bone.begins_with("calf_") else 0.85, aim.y)
		travel = minf(0.9, origin.distance_to(aim) / speed)
	return aim

func spawn_projectile(f: CharacterBody3D, spec: Dictionary, origin: Vector3) -> void:
	var speed := 15.0 if spec.effect == "spear" else 12.5
	if spec.effect == "heavy":
		speed = 10.5
	var color := element_color(f.team)
	var radius := 0.18 if spec.effect == "heavy" else 0.12
	var node: MeshInstance3D = vfx.projectile(f.team, spec.effect, radius)
	add_child(node)
	node.position = origin
	var target_bone := "spine_03"
	if spec.effect == "ground":
		target_bone = "calf_l" if shot_serial % 2 == 0 else "calf_r"
	elif spec.effect == "spear":
		target_bone = "Head"
	var aim := predictive_aim(f, origin, speed, target_bone)
	var velocity_ := (aim - origin).normalized() * speed
	node.look_at(camera.global_position if spec.effect in ["slash", "cleave"] else origin + velocity_)
	if spec.effect == "cleave":
		node.rotate_object_local(Vector3.FORWARD, PI / 2)
	if spec.effect == "spear":
		node.scale = Vector3(0.60, 0.60, 3.6)
	shot_serial += 1
	var mass: float = {"spark":8.0, "orb":13.0, "heavy":24.0, "spear":14.0, "slash":11.0, "cleave":17.0, "ground":15.0}.get(spec.effect, 13.0)
	shots.append({"id":shot_serial, "node":node, "velocity":velocity_, "mass":mass, "caster":f, "age":0.0, "trail":0.0, "spec":spec, "radius":radius})

func incoming_threat(f: CharacterBody3D) -> int:
	for shot in shots:
		if shot.caster.team == f.team:
			continue
		var toward: Vector3 = f.position + Vector3.UP - shot.node.position
		if toward.length() < 5.0 and shot.velocity.normalized().dot(toward.normalized()) > 0.65:
			return shot.id
	return -1

func clash_projectiles(delta: float) -> void:
	if not round_active:
		return
	var consumed := {}
	for i in shots.size():
		var a: Dictionary = shots[i]
		if consumed.has(a.id):
			continue
		for j in range(i + 1, shots.size()):
			var b: Dictionary = shots[j]
			if a.caster.team == b.caster.team or consumed.has(b.id):
				continue
			# Continuous relative sphere sweep prevents fast projectiles passing through.
			var relative: Vector3 = a.node.position - b.node.position
			var movement: Vector3 = (a.velocity - b.velocity) * delta
			var t := clampf(-relative.dot(movement) / maxf(0.0001, movement.length_squared()), 0, 1)
			if (relative + movement * t).length() > a.radius + b.radius:
				continue
			var point: Vector3 = (a.node.position + a.velocity * delta * t + b.node.position + b.velocity * delta * t) * 0.5
			consumed[a.id] = true
			consumed[b.id] = true
			clashes += 1
			events.append({"time":elapsed, "event":"clash"})
			impact_burst(point, 0, true)
			impact_burst(point, 1, true)
			for steam in 8:
				var node := sphere(0.075, Color("d7f2f5"))
				node.material_override = glow(Color("d7f2f5"), 0.22)
				node.position = point
				particles.append({"node":node, "velocity":Vector3(rng.randf_range(-0.8, 0.8), 1.1, rng.randf_range(-0.8, 0.8)), "age":0.0, "life":0.5, "scale":Vector3.ONE, "grow":true, "fade":true})
			status = "FIRE × WATER  •  STEAM CLASH"
			shake = 0.16
			break
	for i in range(shots.size() - 1, -1, -1):
		if consumed.has(shots[i].id):
			shots[i].node.queue_free()
			shots.remove_at(i)

func step_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var from: Vector3 = shot.node.position
		var to: Vector3 = from + shot.velocity * delta
		shot.age += delta
		shot.trail += delta
		var shape := SphereShape3D.new()
		shape.radius = shot.radius * 0.85
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.collision_mask = 8 << (1 - shot.caster.team)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hit := false
		var victim: CharacterBody3D = fighters[1 - shot.caster.team]
		var shield_contact: Dictionary = victim.shield_intersection(from, to, shot.radius)
		if not shield_contact.is_empty():
			apply_impact(shot.caster, victim, shot.spec, shield_contact.point, shot.velocity.normalized(), null, shot.velocity * shot.mass)
			hit = true
		var samples := maxi(1, ceili(from.distance_to(to) / 0.07))
		for sample in range(samples + 1):
			if hit:
				break
			var point := from.lerp(to, float(sample) / samples)
			query.transform = Transform3D(Basis.IDENTITY, point)
			var result := get_world_3d().direct_space_state.intersect_shape(query, 4)
			if not result.is_empty():
				var target_ = result[0].collider.get_meta("fighter")
				apply_impact(shot.caster, target_, shot.spec, target_.contact_surface(result[0].collider, point), shot.velocity.normalized(), result[0].collider, shot.velocity * shot.mass)
				hit = true
				break
		var ground_hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
		if not hit and not ground_hit.is_empty():
			impact_burst(ground_hit.position, shot.caster.team, false)
			hit = true
		if hit or shot.age > 2.0:
			shot.node.queue_free()
			shots.remove_at(i)
		else:
			shot.node.position = to
			if shot.trail > 0.035:
				shot.trail = 0
				vfx.flight(shot.node, shot.velocity, shot.caster.team, shot.spec.effect, shot.age)

func step_pulses(delta: float) -> void:
	for i in range(pulses.size() - 1, -1, -1):
		var item: Dictionary = pulses[i]
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
			query.collision_mask = 8 << (1 - item.caster.team)
			query.collide_with_bodies = false
			query.collide_with_areas = true
			var result := get_world_3d().direct_space_state.intersect_shape(query, 16)
			if not result.is_empty():
				var area := closest_hit_area(result, item.node.position)
				var victim = area.get_meta("fighter")
				var contact: Vector3 = victim.contact_surface(area, item.node.position)
				item.hit = apply_impact(item.caster, victim, item.spec, contact, (contact - item.node.position).normalized(), area)
		if item.trail > 0.11:
			item.trail = 0
			for segment in 8:
				var angle: float = segment * TAU / 8 + item.age
				var point: Vector3 = item.node.position + Vector3(cos(angle), 0.1, sin(angle)) * radius
				vfx.puff(point, "flame_04" if item.caster.team == 0 else "twirl_02", item.caster.team, Vector2(0.5, 0.8), Vector3.UP * 1.4, 0.3, Color(element_color(item.caster.team), 0.8), 0.5, 3)
		if item.age >= 0.95:
			item.node.queue_free()
			pulses.remove_at(i)

func step_channels(delta: float) -> void:
	for i in range(channels.size() - 1, -1, -1):
		var item: Dictionary = channels[i]
		item.age += delta
		var f: CharacterBody3D = item.caster
		if item.age > 0.65 or f.health <= 0 or f.mode != "cast":
			item.node.queue_free()
			channels.remove_at(i)
			continue
		var from := fighter_hand(f, "both")
		var end: Vector3 = f.rival.bone_point("spine_03", Vector3(0, -0.06, 0))
		var shield_contact: Dictionary = f.rival.shield_intersection(from, end)
		var query := PhysicsRayQueryParameters3D.create(from, end + (end - from).normalized() * 0.4, 8 << (1 - f.team))
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		if not shield_contact.is_empty():
			end = shield_contact.point
			if not item.hit:
				item.hit = apply_impact(f, f.rival, item.spec, end, (end - from).normalized())
		elif not result.is_empty():
			end = result.position
			if not item.hit:
				item.hit = apply_impact(f, result.collider.get_meta("fighter"), item.spec, end, (end - from).normalized(), result.collider)
		var direction := end - from
		var path := []
		for segment in 12:
			path.append(from.lerp(end, segment / 11.0) + Vector3.UP * sin(segment * 1.4 + elapsed * 25) * 0.035)
		vfx.update_ribbon(item.node, path, 0.26 + sin(elapsed * 24) * 0.035)
		item.trail += delta
		if item.trail > 0.045:
			item.trail = 0
			for segment in 7:
				var at := from.lerp(end, segment / 7.0)
				vfx.puff(at, "flame_01" if f.team == 0 else "smoke_04", f.team, Vector2(0.45, 0.55), direction.normalized() * 1.5, 0.18, Color(element_color(f.team).lightened(0.25), 0.8), 0.1, 5)

func closest_hit_area(results: Array, point: Vector3) -> Area3D:
	var best: Area3D
	var distance := INF
	for result in results:
		var area: Area3D = result.collider
		var f = area.get_meta("fighter")
		var d: float = f.contact_surface(area, point).distance_to(point)
		if d < distance:
			distance = d
			best = area
	return best

func apply_impact(attacker: CharacterBody3D, victim: CharacterBody3D, spec: Dictionary, point: Vector3, direction: Vector3, hit_area: Area3D = null, incoming_impulse := Vector3.ZERO) -> bool:
	var amount := damage_for(spec)
	var health_before: float = victim.health
	var area: Area3D = hit_area if hit_area != null else victim.nearest_hurtbox(point)
	var zone: String = area.get_meta("zone", "chest")
	var bone: String = area.get_meta("bone", "spine_03")
	var power: float = {"beam":240.0, "nova":260.0, "melee":70.0}.get(spec.effect, 180.0)
	var impulse: Vector3 = incoming_impulse if not incoming_impulse.is_zero_approx() else direction.normalized() * power
	impulse = impulse.limit_length(650)
	var absorbed: float = victim.absorb_magic(amount, point - direction * 2.0, point)
	if absorbed > 0:
		victim.apply_physical_impact(point, impulse * (absorbed / amount) * 0.16, "shield", "lowerarm_r")
	impulse *= (amount - absorbed) / amount
	amount -= absorbed
	if amount <= 0:
		return true
	if not victim.receive_magic(amount, direction, attacker, point, zone, bone, impulse):
		return absorbed > 0
	if spec.effect == "melee":
		attacker.melee_hits += 1
		attacker.melee_damage += health_before - victim.health
	var key := "%s/%s" % [element_name(attacker.team), spec.id]
	hits[key] = hits.get(key, 0) + 1
	events.append({"time":elapsed, "event":"hit", "kind":"melee" if spec.effect == "melee" else "spell", "team":attacker.team, "victim":victim.team, "spell":spec.id, "health":victim.health, "zone":zone, "bone":bone, "point":[point.x, point.y, point.z], "impulse":[impulse.x, impulse.y, impulse.z]})
	print("HIT t=%.2f " % elapsed, element_name(attacker.team), " ", spec.id, " health=", victim.health)
	if spec.effect == "melee":
		status = "%s  •  %s" % [element_name(attacker.team), spec.id.replace("_", " ").to_upper()]
		vfx.puff(point, "spark_05", attacker.team, Vector2.ONE * 0.36, Vector3.ZERO, 0.16, Color("fff3cf"), 0.3)
		vfx.puff(point, "circle_03", attacker.team, Vector2.ONE * 0.18, Vector3.ZERO, 0.2, Color(1, 0.92, 0.72, 0.8), 1.2)
	else:
		status = "%s  •  %s  •  %s" % [element_name(attacker.team), spell_name(spec, attacker.team), zone.replace("_", " ").to_upper()]
		impact_burst(point, attacker.team, true)
	shake = maxf(shake, 0.10)
	return true

func impact_burst(point: Vector3, team: int, connected: bool) -> void:
	vfx.burst(point, team, connected)

func shield_impact(f: CharacterBody3D, point: Vector3, broken: bool) -> void:
	shield_hit_age[f.team] = 0
	vfx.burst(point, f.team, false)
	status = "%s  •  %s" % [element_name(f.team), "GUARD BREAK" if broken else "ABSORBED"]
	events.append({"time":elapsed, "event":"shield_break" if broken else "block", "team":f.team, "guard":f.guard_energy})
	shake = maxf(shake, 0.055)

func element_mote(point: Vector3, team: int, velocity_: Vector3, life: float, radius: float) -> void:
	vfx.puff(point, "spark_05", team, Vector2(radius * 3, radius * 7), velocity_, life, element_color(team).lightened(0.3), 0.0)

func step_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var item: Dictionary = particles[i]
		item.age += delta
		if item.age >= item.life:
			item.node.queue_free()
			particles.remove_at(i)
		else:
			item.velocity += item.get("gravity", Vector3.ZERO) * delta
			item.node.position += item.velocity * delta
			var progress_: float = item.age / item.life
			item.node.scale = item.scale * (0.2 + 2.6 * progress_ if item.get("grow", false) else maxf(0.02, 1 - progress_))
			if item.get("fade", false):
				item.node.material_override.albedo_color.a = 0.4 * (1 - progress_)

func movement_burst(f: CharacterBody3D, landing: bool) -> void:
	ring(Vector3(f.position.x, 0.04, f.position.z), 0.45 if landing else 0.30, element_color(f.team), 0.24)
	for i in 5:
		element_mote(f.position + Vector3.UP * 0.08, f.team, Vector3(rng.randf_range(-1, 1), 0.8, rng.randf_range(-1, 1)), 0.22, 0.025)

func speed_trail(f: CharacterBody3D) -> void:
	var node := sphere(0.08, element_color(f.team))
	node.position = f.position + Vector3.UP * 0.9
	var direction: Vector3 = f.velocity.normalized()
	if direction.length() > 0.1:
		node.basis = Basis(Quaternion(Vector3.UP, direction))
	node.scale = Vector3(0.4, 4.0, 0.4)
	particles.append({"node":node, "velocity":Vector3.ZERO, "age":0.0, "life":0.16, "scale":node.scale})

func update_camera(delta: float) -> void:
	if review_camera:
		return
	var center: Vector3 = (fighters[0].position + fighters[1].position) * 0.5 + Vector3.UP * 1.0
	var spread: float = fighters[0].position.distance_to(fighters[1].position)
	var distance := 7.1 + maxf(0, spread - 4.0) * 0.7
	var separation: Vector3 = fighters[1].position - fighters[0].position
	separation.y = 0
	if separation.length() > 0.5:
		var side := Vector3(-separation.z, 0, separation.x).normalized()
		if side.dot(view_axis) < 0:
			side = -side
		view_axis = view_axis.slerp(side, minf(1, delta * 1.4)).normalized()
	var goal := center + view_axis * distance + Vector3.UP * (2.7 + maxf(0, center.y - 1.3) * 0.25)
	camera.position = camera.position.lerp(goal, minf(1, delta * 3.5))
	camera.fov = lerpf(camera.fov, 43.0, delta * 2)
	shake = maxf(0, shake - delta * 0.7)
	var jitter := Vector3(sin(elapsed * 147), cos(elapsed * 113), 0) * shake
	camera.look_at(center + jitter)

func build_fight_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_bottom = 152
	backdrop.color = Color(0.025, 0.05, 0.075, 0.7)
	root.add_child(backdrop)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = 12
	row.offset_bottom = 140
	row.add_theme_constant_override("separation", 38)
	root.add_child(row)
	for i in 2:
		if i == 1:
			round_label = Label.new()
			round_label.custom_minimum_size = Vector2(180, 0)
			round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			round_label.add_theme_font_size_override("font_size", 18)
			row.add_child(round_label)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 21)
		label.add_theme_color_override("font_color", element_color(i).lightened(0.3))
		column.add_child(label)
		health_labels.append(label)
		var bar := ProgressBar.new()
		bar.max_value = fighters[i].MAX_HEALTH
		bar.value = bar.max_value
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 17)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("1b2a32")
		var fill := StyleBoxFlat.new()
		fill.bg_color = element_color(i)
		bar.add_theme_stylebox_override("background", background)
		bar.add_theme_stylebox_override("fill", fill)
		column.add_child(bar)
		health_bars.append(bar)
		var mana_row := resource_meter(column, "MANA", Color("9c8cf0"), fighters[i].MAX_MANA)
		var stamina_row := resource_meter(column, "STAMINA", Color("acd66c"), fighters[i].MAX_STAMINA)
		var guard_row := resource_meter(column, "GUARD", Color("c1e6f5"), fighters[i].MAX_GUARD)
		mana_bars.append(mana_row[0])
		stamina_bars.append(stamina_row[0])
		guard_bars.append(guard_row[0])
		resource_labels.append([mana_row[1], stamina_row[1], guard_row[1]])
	hud = Label.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud.offset_left = 24
	hud.offset_top = -42
	hud.text = "AUTOMATIC DUEL   •   Space slow motion   •   R restart   •   Esc quit"
	hud.add_theme_font_size_override("font_size", 15)
	root.add_child(hud)
	subtitle = Label.new()
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 160
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_shadow_color", Color.BLACK)
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(subtitle)

func resource_meter(column: VBoxContainer, name_: String, color: Color, maximum: float) -> Array:
	var row := HBoxContainer.new()
	column.add_child(row)
	var title := Label.new()
	title.text = name_
	title.custom_minimum_size.x = 66
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", color)
	row.add_child(title)
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.step = 0.01
	bar.value = maximum
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = 8
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background := StyleBoxFlat.new()
	background.bg_color = Color("1b2a32")
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	row.add_child(bar)
	var number := Label.new()
	number.custom_minimum_size.x = 28
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.add_theme_font_size_override("font_size", 11)
	row.add_child(number)
	return [bar, number]

func update_fight_ui() -> void:
	for i in 2:
		health_bars[i].value = fighters[i].health
		guard_bars[i].value = fighters[i].guard_energy
		mana_bars[i].value = fighters[i].mana
		stamina_bars[i].value = fighters[i].stamina
		resource_labels[i][0].text = str(floori(fighters[i].mana))
		resource_labels[i][1].text = str(floori(fighters[i].stamina))
		resource_labels[i][2].text = str(floori(fighters[i].guard_energy))
		var tactic := "RECOVER" if fighters[i].catching_breath else ("FISTS" if fighters[i].close_combat else "MAGIC")
		health_labels[i].text = "%s  %d / %d  ·  %s" % [element_name(i), ceili(fighters[i].health), fighters[i].MAX_HEALTH, tactic]
	round_label.text = "ROUND %d\n%d — %d" % [round_number, wins[0], wins[1]]
	subtitle.text = status + ("  •  next round %.1f" % intermission if intermission > 0 else "")

func write_report() -> void:
	var stats: Array = []
	for f in fighters:
		stats.append({"team":f.team, "element":element_name(f.team), "health":f.health, "impact_zones":f.impact_physics.by_zone, "physical_impacts":f.impact_physics.impacts, "peak_joint_angle":f.impact_physics.peak_angle, "mana":f.mana, "stamina":f.stamina, "minimum_mana":f.minimum_mana, "minimum_stamina":f.minimum_stamina, "mana_spent":f.mana_spent, "stamina_spent":f.stamina_spent, "melee_attempts":f.melee_attempts, "melee_hits":f.melee_hits, "melee_damage":f.melee_damage, "tactic_changes":f.tactic_changes, "guard":f.guard_energy, "blocks":f.blocks, "absorbed_damage":f.absorbed_damage, "guard_breaks":f.guard_breaks, "actions":f.actions, "distance_run":f.distance_run, "max_height":f.max_height, "air_casts":f.air_casts, "hits":f.hits_scored, "damage_dealt":f.damage_dealt, "damage_taken":f.damage_taken, "knockouts":f.ko_count})
	var report := {"seconds":elapsed, "rounds":round_number, "wins":wins, "fighters":stats, "casts":casts, "hits":hits, "heals":heals, "clashes":clashes, "events":events, "minimum_spacing":minimum_spacing, "maximum_radius":max_radius, "peak_effects":peak_effects, "fps":Engine.get_frames_per_second(), "renderer":RenderingServer.get_video_adapter_name()}
	var summary := report.duplicate()
	summary.erase("events")
	print("REPORT ", JSON.stringify(summary))
	var destination := report_file if not report_file.is_empty() else capture_dir.path_join("report.json")
	if not report_file.is_empty() or not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var file := FileAccess.open(destination, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		if event.keycode == KEY_R:
			Engine.time_scale = 1
			get_tree().reload_current_scene()
		if event.keycode == KEY_SPACE:
			Engine.time_scale = 0.35 if Engine.time_scale == 1 else 1.0
