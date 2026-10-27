extends "res://scripts/spell_arena.gd"
## Elemental arena combat composed from the meadow, spell VFX and licensed humanoids.
const Fighter = preload("res://scripts/duel_actor.gd")
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
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode blend_mix; void vertex(){VERTEX+=NORMAL*sin(VERTEX.y*32.0+TIME*14.0+VERTEX.x*25.0)*.008;} void fragment(){float f=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),2.0); float foam=pow(max(0.0,sin(UV.y*45.0-TIME*20.0)),10.0); ALBEDO=mix(vec3(.025,.24,.46),vec3(.55,.95,1.0),min(1.0,f+foam*.5)); ROUGHNESS=.12; METALLIC=.12; EMISSION=vec3(.04,.22,.30); ALPHA=.65+f*.25;}"
	water_material = ShaderMaterial.new()
	water_material.shader = shader
	for i in 2:
		var f = Fighter.new()
		f.team = i
		f.arena = self
		add_child(f)
		fighters.append(f)
		var light := sphere(0.09, element_color(i))
		add_core(light, 0.09, false)
		if i == 1:
			light.material_override = water_material
			light.get_node("Core").material_override = glow(Color("d2fbff"))
		light.visible = false
		charges.append(light)
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
	minimum_spacing = minf(minimum_spacing, fighters[0].position.distance_to(fighters[1].position))
	for i in 2:
		var f = fighters[i]
		charges[i].visible = round_active and f.mode == "cast" and not f.did_release
		if charges[i].visible:
			charges[i].position = fighter_hand(f, f.current_spell.hand)
	clash_projectiles(delta)
	step_shots(delta)
	step_pulses(delta)
	step_channels(delta)
	step_particles(delta)
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
	var key := "%s/%s" % [element_name(f.team), spec.id]
	casts[key] = casts.get(key, 0) + 1
	status = "%s  •  %s%s" % [element_name(f.team), "AERIAL " if air else "", spell_name(spec, f.team)]
	events.append({"time":elapsed, "event":"cast", "team":f.team, "spell":spec.id, "airborne":air})
	var color := element_color(f.team)
	if spec.effect == "heal":
		var restored: float = minf(22, f.MAX_HEALTH - f.health)
		f.health += restored
		f.healed_this_round = true
		heals += 1
		for i in 3:
			ring(f.position + Vector3.UP * (0.15 + i * 0.45), 0.5, color.lightened(0.3), 0.8)
		events.append({"time":elapsed, "event":"heal", "team":f.team, "amount":restored})
	elif spec.effect == "nova":
		var node := make_ring(color)
		node.position = f.position + Vector3.UP * 0.10
		pulses.append({"node":node, "age":0.0, "trail":0.0, "caster":f, "hit":false, "spec":spec})
	elif spec.effect == "beam":
		var node := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = 0.08
		tube.bottom_radius = 0.12
		tube.height = 1
		tube.radial_segments = 12
		node.mesh = tube
		node.material_override = water_material if f.team == 1 else glow(FIRE, 0.8)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		channels.append({"node":node, "caster":f, "age":0.0, "hit":false, "spec":spec})
	else:
		var origin := fighter_hand(f, spec.hand)
		if spec.effect == "ground" and f.is_on_floor():
			ring(f.position + Vector3.UP * 0.04, 0.6, color, 0.55)
			origin = f.position + Vector3.UP * 0.30
		spawn_projectile(f, spec, origin)

func damage_for(spec: Dictionary) -> float:
	return {"orb":16.0, "spark":12.0, "slash":18.0, "cleave":22.0, "heavy":24.0, "spear":22.0, "ground":18.0, "nova":20.0, "beam":24.0}.get(spec.effect, 16.0)

func predictive_aim(f: CharacterBody3D, origin: Vector3, speed: float) -> Vector3:
	var enemy: CharacterBody3D = f.rival
	var aim: Vector3 = enemy.bone_point("spine_03", Vector3(0, -0.08, 0))
	var travel := origin.distance_to(aim) / speed
	for i in 3:
		var lead: Vector3 = enemy.velocity * travel
		if not enemy.is_on_floor():
			lead.y -= 0.5 * enemy.GRAVITY * travel * travel
		aim = enemy.bone_point("spine_03", Vector3(0, -0.08, 0)) + lead
		aim.y = maxf(0.85, aim.y)
		travel = minf(0.9, origin.distance_to(aim) / speed)
	return aim

func spawn_projectile(f: CharacterBody3D, spec: Dictionary, origin: Vector3) -> void:
	var speed := 15.0 if spec.effect == "spear" else 12.5
	if spec.effect == "heavy":
		speed = 10.5
	var color := element_color(f.team)
	var radius := 0.18 if spec.effect == "heavy" else 0.12
	var node: MeshInstance3D
	if spec.effect in ["slash", "cleave"]:
		node = crescent()
		node.material_override = glow(color.lightened(0.2), 0.85)
		(node.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
		add_child(node)
	else:
		node = sphere(radius, color)
		add_core(node, radius, false)
		if f.team == 1:
			node.material_override = water_material
			node.get_node("Core").material_override = glow(Color("c4f4ff"), 0.55)
	node.position = origin
	var aim := predictive_aim(f, origin, speed)
	var velocity_ := (aim - origin).normalized() * speed
	node.look_at(camera.global_position if spec.effect in ["slash", "cleave"] else origin + velocity_)
	if spec.effect == "cleave":
		node.rotate_object_local(Vector3.FORWARD, PI / 2)
	if spec.effect == "spear":
		node.scale = Vector3(0.60, 0.60, 3.6)
	shot_serial += 1
	shots.append({"id":shot_serial, "node":node, "velocity":velocity_, "caster":f, "age":0.0, "trail":0.0, "spec":spec, "radius":radius})

func incoming_threat(f: CharacterBody3D) -> int:
	for shot in shots:
		if shot.caster.team == f.team:
			continue
		var toward: Vector3 = f.position + Vector3.UP - shot.node.position
		if toward.length() < 2.8 and shot.velocity.normalized().dot(toward.normalized()) > 0.65:
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
		var samples := maxi(1, ceili(from.distance_to(to) / 0.07))
		for sample in range(samples + 1):
			var point := from.lerp(to, float(sample) / samples)
			query.transform = Transform3D(Basis.IDENTITY, point)
			var result := get_world_3d().direct_space_state.intersect_shape(query, 4)
			if not result.is_empty():
				var victim = result[0].collider.get_meta("fighter")
				apply_impact(shot.caster, victim, shot.spec, point, shot.velocity.normalized())
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
				element_mote(to, shot.caster.team, -shot.velocity * 0.035 + Vector3.UP * 0.45, 0.22, 0.045)

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
				shape.height = 1.6
				query.shape = shape
			else:
				var shape := SphereShape3D.new()
				shape.radius = radius
				query.shape = shape
			query.transform = Transform3D(Basis.IDENTITY, item.node.position + Vector3.UP * 0.7)
			query.collision_mask = 8 << (1 - item.caster.team)
			query.collide_with_bodies = false
			query.collide_with_areas = true
			var result := get_world_3d().direct_space_state.intersect_shape(query, 1)
			if not result.is_empty():
				var victim = result[0].collider.get_meta("fighter")
				item.hit = apply_impact(item.caster, victim, item.spec, victim.bone_point("spine_03"), (victim.position - item.node.position).normalized())
		if item.trail > 0.11:
			item.trail = 0
			for segment in 8:
				var angle: float = segment * TAU / 8 + item.age
				var point: Vector3 = item.node.position + Vector3(cos(angle), 0.1, sin(angle)) * radius
				element_mote(point, item.caster.team, Vector3.UP * 1.8, 0.35, 0.04)
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
		var query := PhysicsRayQueryParameters3D.create(from, end + (end - from).normalized() * 0.4, 8 << (1 - f.team))
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		if not result.is_empty():
			end = result.position
			if not item.hit:
				item.hit = apply_impact(f, result.collider.get_meta("fighter"), item.spec, end, (end - from).normalized())
		var direction := end - from
		item.node.position = (from + end) * 0.5
		item.node.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
		item.node.scale = Vector3(1 + sin(elapsed * 24) * 0.15, maxf(0.01, direction.length()), 1)

func apply_impact(attacker: CharacterBody3D, victim: CharacterBody3D, spec: Dictionary, point: Vector3, direction: Vector3) -> bool:
	if not victim.receive_magic(damage_for(spec), direction, attacker):
		return false
	var key := "%s/%s" % [element_name(attacker.team), spec.id]
	hits[key] = hits.get(key, 0) + 1
	events.append({"time":elapsed, "event":"hit", "team":attacker.team, "victim":victim.team, "spell":spec.id, "health":victim.health})
	print("HIT t=%.2f " % elapsed, element_name(attacker.team), " ", spec.id, " health=", victim.health)
	impact_burst(point, attacker.team, true)
	shake = maxf(shake, 0.10)
	return true

func impact_burst(point: Vector3, team: int, connected: bool) -> void:
	if connected:
		var flash := sphere(0.20, element_color(team).lightened(0.6))
		flash.position = point
		particles.append({"node":flash, "velocity":Vector3.ZERO, "age":0.0, "life":0.13, "scale":Vector3.ONE * 1.5})
		var shock := make_ring(element_color(team).lightened(0.2))
		shock.position = point
		shock.basis = Basis(Quaternion(Vector3.UP, (camera.position - point).normalized()))
		particles.append({"node":shock, "velocity":Vector3.ZERO, "age":0.0, "life":0.30, "scale":Vector3.ONE * 0.45, "grow":true, "fade":true})
	for i in (12 if connected else 6):
		var velocity_ := Vector3(rng.randf_range(-1.7, 1.7), rng.randf_range(0.5, 2.5), rng.randf_range(-1.7, 1.7))
		element_mote(point, team, velocity_, 0.40, 0.035)
	ring(Vector3(point.x, 0.05, point.z), 0.45 if connected else 0.30, element_color(team), 0.35)

func element_mote(point: Vector3, team: int, velocity_: Vector3, life: float, radius: float) -> void:
	var node := sphere(radius, element_color(team).lightened(0.2))
	node.position = point
	node.scale = Vector3(0.6, 1.6, 0.6)
	if team == 1:
		node.material_override = glow(Color("a5efff"), 0.65)
	particles.append({"node":node, "velocity":velocity_, "age":0.0, "life":life, "scale":node.scale, "gravity":Vector3.DOWN * 4 if team == 1 else Vector3.UP * 0.8})

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
	backdrop.offset_bottom = 116
	backdrop.color = Color(0.025, 0.05, 0.075, 0.7)
	root.add_child(backdrop)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = 18
	row.offset_bottom = 96
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
		bar.custom_minimum_size = Vector2(0, 20)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("1b2a32")
		var fill := StyleBoxFlat.new()
		fill.bg_color = element_color(i)
		bar.add_theme_stylebox_override("background", background)
		bar.add_theme_stylebox_override("fill", fill)
		column.add_child(bar)
		health_bars.append(bar)
	hud = Label.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud.offset_left = 24
	hud.offset_top = -42
	hud.text = "AUTOMATIC DUEL   •   Space slow motion   •   R restart   •   Esc quit"
	hud.add_theme_font_size_override("font_size", 15)
	root.add_child(hud)
	subtitle = Label.new()
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 125
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_shadow_color", Color.BLACK)
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(subtitle)

func update_fight_ui() -> void:
	for i in 2:
		health_bars[i].value = fighters[i].health
		health_labels[i].text = "%s  %d / %d" % [element_name(i), ceili(fighters[i].health), fighters[i].MAX_HEALTH]
	round_label.text = "ROUND %d\n%d — %d" % [round_number, wins[0], wins[1]]
	subtitle.text = status + ("  •  next round %.1f" % intermission if intermission > 0 else "")

func write_report() -> void:
	var stats: Array = []
	for f in fighters:
		stats.append({"team":f.team, "element":element_name(f.team), "health":f.health, "actions":f.actions, "distance_run":f.distance_run, "max_height":f.max_height, "air_casts":f.air_casts, "hits":f.hits_scored, "damage_dealt":f.damage_dealt, "damage_taken":f.damage_taken, "knockouts":f.ko_count})
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
