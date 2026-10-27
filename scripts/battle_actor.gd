extends "res://scripts/duel_actor.gd"
const Ragdoll = preload("res://scripts/combat_ragdoll.gd")
const FLASH_STEP_SPEED := 34.0
const OVERDRIVE_MOVE_SPEED := FLASH_STEP_SPEED*0.75
const FLASH_CHARGE_TIME := 0.28
const CombatTactics = preload("res://scripts/combat_tactics.gd")
var tactics := CombatTactics.new()
var flash_aura_time := 0.0
var ragdoll: Node3D
var burn_time := 0.0
var burn_clock := 0.0
var burn_source: CharacterBody3D
var chill_time := 0.0
var freeze_time := 0.0
var freeze_immunity := 0.0
var frost := 0.0
var armor_time := 0.0
var armor_hp := 0.0
var haste_time := 0.0
var burst_direction := Vector3.ZERO
var burst_left := 0.0
var combo_time := 0.0
var combo_speed := 0.0
var motion_direction := Vector3.ZERO
var motion_speed := 0.0
var air_trick := ""
var charge_goal := 0.0
var charge_held := 0.0
var charge_value := 0.0
var cast_phase := "windup"
var cast_rate := 2.9
var beam_clock := 0.0
var melee_charge := 0.0
var last_hit_charge := 0.0
var last_guard_shattered := false
var last_hit_launch := false
var target_clock := 0.0
var last_attacker := -1
var ragdoll_count := 0
var recoveries_count := 0
var ragdoll_peak := 0.0
var freezes := 0
var burns_applied := 0
var charged_casts := 0
var dash_combo_hits := 0
var attack_kind := "jab"
var strike_augmented := false
var strike_damage := 8.0
var strike_cost := 8.0
var strike_reach := 1.0
var charge_requested := -1.0
var death_age := INF
var death_impulse := Vector3.ZERO
var wall_crash_cooldown := 0.0
var wall_crashes := 0
const RECOVERY_BLEND := 0.45
const RECOVERY_GATHER := 0.25
var recovery_source := {}
var recovery_target := {}
var air_body_passthrough := false

func _ready() -> void:
	var actual := team
	if team == 2:
		team = 0
	super._ready()
	team = actual
	rng.seed = 27531 + team * 1381
	player.add_animation_library("battle", load(BASE + "animations/battle.res"))
	collision_layer = 128 << team
	collision_mask = 1 | 128 | 256 | 512 | 1024
	for item in targets:
		item[0].collision_layer = 8 << team
	if team == 2:
		for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material = mesh.get_surface_override_material(surface)
				if material is StandardMaterial3D and material.albedo_color.r > material.albedo_color.g * 1.4:
					material = material.duplicate()
					material.albedo_color = Color("bd9629")
					mesh.set_surface_override_material(surface, material)
	decision = team * 2
	spell_cursor = team

func reset_fighter(location: Vector3) -> void:
	recovery_source.clear()
	recovery_target.clear()
	air_body_passthrough=false
	if is_instance_valid(ragdoll):
		ragdoll.restore_pose()
		ragdoll.queue_free()
		ragdoll = null
	super.reset_fighter(location)
	# A reset can interrupt the ragdoll/get-up blend. Clear untracked root/bone
	# offsets before the idle clip, which only animates the pelvis position.
	skeleton.reset_bone_poses()
	clip="spells/idle"
	player.play(clip,0,1)
	player.advance(0)
	tactics.reset(self)
	flash_aura_time=0
	collision_layer = 128 << team
	get_child(0).set_deferred("disabled", false)
	burn_time = 0
	burn_clock=0
	burn_source=null
	chill_time = 0
	freeze_time = 0
	freeze_immunity = 0
	frost = 0
	armor_time = 0
	armor_hp = 0
	haste_time = 0
	combo_time = 0
	motion_direction=Vector3.ZERO
	motion_speed=0
	air_trick=""
	melee_charge = 0
	last_guard_shattered = false
	last_hit_charge = 0
	last_attacker=-1
	mode_length=0.25+team*0.1
	death_age=INF
	death_impulse=Vector3.ZERO
	wall_crash_cooldown=0

func focus_position() -> Vector3:
	return ragdoll.location() - Vector3.UP * 0.65 if is_instance_valid(ragdoll) else global_position

func movement_multiplier() -> float:
	return (1.45 if team == 2 else 1.0) * (1.35 if haste_time > 0 else 1.0) * (0.60 if chill_time > 0 else 1.0)

func arena_roam_radius() -> float:
	return float(arena.Boundary.RADIUS)-2.0

func locomotion_velocity(desired: Vector3) -> Vector3:
	if tactics.banking and mode=="recover":
		var away:=flat_direction(rival.position,position)
		return away*(1.8 if flat_distance()<4.5 else 0.0)+Vector3(-away.z,0,away.x)*0.7
	if team!=2 or haste_time<=0:
		return super.locomotion_velocity(desired)
	var speed:=minf(1,desired.length()/4.8)*OVERDRIVE_MOVE_SPEED*(0.6 if chill_time>0 else 1.0)
	if mode=="chase":
		speed=minf(speed,maxf(0,flat_distance()-0.75)*20)
		if drive_velocity.length()>speed:
			drive_velocity=drive_velocity.limit_length(speed)
	return desired.normalized()*speed

func play_recovery(distance: float) -> void:
	if tactics.banking:
		play("duel/walk_back" if distance<4.5 else "duel/strafe_left",0.9)
	else:
		super.play_recovery(distance)

func choose_spell(air: bool) -> Dictionary:
	var list: Array = arena.profile_spells(team)
	var spec: Dictionary = list[spell_cursor % list.size()].duplicate(true)
	spell_cursor += 1
	return spec

func start_cast(air: bool) -> void:
	air=air or not is_on_floor()
	current_spell = choose_spell(air)
	if current_spell.effect=="burst" and stamina<flash_stamina_requirement():
		start_recovery()
		return
	if mana < arena.mana_cost(current_spell):
		set_close_combat(true)
		mode = "air" if air else "idle"
		mode_time = 0
		mode_length = 0.08
		return
	if current_spell.effect!="burst":
		tactics.attack(self,current_spell.id)
	charge_goal = 0
	if current_spell.effect in ["orb", "slash", "ice_beam"] and not air:
		charge_goal = (1.0 if (int(actions.get("cast",0))+team) % 3 == 0 else 0.0) if charge_requested < 0 else charge_requested
		charge_goal = minf(charge_goal, maxf(0, (mana / arena.mana_cost(current_spell) - 1.0) / 0.8))
	charge_requested = -1
	charge_held = 0
	charge_value = 0
	cast_phase = "windup"
	beam_clock = 0
	cast_rate = 2.9 if current_spell.effect in ["orb", "slash"] else 2.1
	if air:
		cast_rate=1.65
	mode = "cast"
	mode_time = 0
	cast_time = 0
	did_release = false
	clip = ""
	var animation: String = "battle/air_" + current_spell.animation if air else "spells/" + current_spell.animation
	# These clips are driven by seek; a timed crossfade never advances with seek.
	clip=animation
	player.play(animation,0,1.0)
	player.advance(0)
	mode_length = player.get_animation(animation).length
	count_action("air_cast" if air else "cast")
	if air:
		air_casts += 1

func tick_cast(delta: float) -> bool:
	face_rival(delta)
	if did_release and current_spell.effect=="ice_beam" and beam_clock<0.95+charge_value*0.4:
		beam_clock+=delta
		cast_time=current_spell.release+0.08
		return false
	var hold_at: float = current_spell.release * 0.55
	if cast_phase == "hold":
		charge_held += delta
		charge_value = minf(charge_goal, charge_held / 1.25)
		if charge_held >= charge_goal * 1.25:
			cast_phase = "release"
		return false
	cast_time += delta * cast_rate
	if not did_release and charge_goal > 0 and cast_phase == "windup" and cast_time >= hold_at:
		cast_time = hold_at
		cast_phase = "hold"
		return false
	var release := false
	if not did_release and cast_time >= current_spell.release:
		did_release = true
		current_spell.charge = charge_value
		if charge_value > 0.1:
			charged_casts += 1
		release = true
	if cast_time >= mode_length:
		mode = "idle" if is_on_floor() else "air"
		mode_time = 0
		mode_length = 0.12
	return release

func advance_animation(delta: float) -> void:
	if freeze_time > 0:
		return
	if mode == "cast":
		player.seek(minf(cast_time, mode_length), true)
	elif mode == "melee_charge":
		player.seek(0.02, true)
	elif mode=="burst_charge":
		player.seek(0.15+minf(1,mode_time/FLASH_CHARGE_TIME)*0.3,true)
	else:
		if mode in ["run", "chase", "dash"]:
			player.speed_scale = clampf(Vector2(velocity.x,velocity.z).length()/7.0,0.7,3.5) if team==2 and haste_time>0 else movement_multiplier()
		player.advance(delta)

func select_action() -> void:
	if not is_on_floor():
		mode="air"
		mode_time=0
		return
	if not is_instance_valid(rival) or rival.health <= 0:
		return
	if tactics.select(self):
		return
	if team == 2 and mana > 22 and haste_time < 0.2 and decision % 3 == 1:
		spell_cursor = 0
		decision += 1
		start_cast(false)
		return
	if team == 1 and mana > 28 and armor_time < 0.2 and decision % 4 == 1:
		spell_cursor = 0
		decision += 1
		start_cast(false)
		return
	if team == 2 and flat_distance() > 2.0 and stamina > 30 and mana > 10 and tactics.avoid_flash<=0:
		start_burst()
		decision += 1
		return
	if team==2 and haste_time>0 and flat_distance()>1.03 and stamina>=18:
		mode="chase"
		mode_time=0
		mode_length=0.3
		count_action("close_distance")
		return
	if flat_distance() < 1.35 and stamina >= 18:
		if melee_sequence % 5 == 4 and stamina >= 32:
			start_uppercut()
		else:
			start_punch()
		decision += 1
		return
	if mana < 16:
		set_close_combat(true)
	if mana > 58 and close_combat:
		set_close_combat(false)
		start_footwork("retreat")
		return
	if stamina < 16 or (catching_breath and stamina < 40):
		start_recovery()
		return
	catching_breath = false
	if close_combat:
		mode = "chase"
		mode_time = 0
		mode_length = 0.45
		count_action("close_distance")
		return
	var choice := decision % 9
	decision += 1
	if choice in [0, 3, 5, 8]:
		start_cast(false)
	elif choice == 1:
		start_footwork("strafe")
	elif choice == 2:
		start_jump("jump_cast")
	elif choice == 4 and mana > 15 and guard_energy > 16:
		start_shield()
	elif choice == 6:
		start_footwork("roll_back")
	else:
		start_jump("air_dash" if choice == 7 else "flip")

func start_jump(kind: String) -> void:
	if not is_on_floor():
		mode="air"
		mode_time=0
		return
	super.start_jump(kind)

func start_punch() -> void:
	melee_charge=0
	var index := melee_sequence % 6
	if team==2 and haste_time>0:
		index=[3,0,3,1,3,2][melee_sequence%6]
	melee_sequence += 1
	var moves := [
		["left_jab", "ual1/Punch_Jab", "hand_l", 0.12, 0.48, 8.0, 8.0, 1.0],
		["right_cross", "ual1/Punch_Cross", "hand_r", 0.16, 0.57, 11.0, 11.0, 1.0],
		["front_kick", "boxing/front_kick_r", "ball_r", 0.25, 0.48, 15.0, 15.0, 1.35],
		["knee", "battle/knee", "calf_r", 0.18, 0.52, 13.0, 13.0, 0.90],
		["left_hook", "boxing/hook_l", "hand_l", 0.14, 0.38, 12.0, 12.0, 1.0],
		["round_kick", "boxing/high_kick_l", "ball_l", 0.32, 0.52, 17.0, 17.0, 1.3]]
	begin_strike(moves[index])

func start_motion_dash(direction_index: int) -> bool:
	if health<=0 or freeze_time>0 or is_instance_valid(ragdoll) or not is_on_floor():
		return false
	if not spend_stamina(12):
		return false
	var angle:=float(posmod(direction_index,8))*PI/4
	# Forward, forward-right, right, back-right, back, back-left, left, forward-left.
	motion_direction=(global_basis.z*cos(angle)-global_basis.x*sin(angle)).normalized()
	motion_speed=12.0
	mode="motion_dash"
	mode_time=0
	mode_length=0.30
	combo_speed=0
	combo_time=0
	clip=""
	var animation: String="duel/dash" if direction_index in [0,1,7] else ("duel/dodge_back" if direction_index in [3,4,5] else ("duel/strafe_right" if direction_index==2 else "duel/strafe_left"))
	play(animation,1.35)
	count_action("motion_dash")
	arena.audio.impact("dash",global_position,0.5)
	return true

func start_motion_jump() -> bool:
	if not is_on_floor() or stamina<12 or health<=0:
		return false
	var carry:=motion_direction*minf(6,combo_speed) if combo_time>0 else drive_velocity.limit_length(6)
	start_jump("motion_jump")
	air_momentum=carry
	return mode=="takeoff"

func launch() -> void:
	if jump_kind!="motion_jump":
		super.launch()
		return
	velocity.y=10.8
	air_clock=0
	mode="air"
	mode_time=0
	clip=""
	play("duel/air")
	arena.movement_burst(self,false)

func tick_motion_dash(delta: float) -> void:
	impact_physics.restore(skeleton)
	mode_time+=delta
	recover_resources(delta)
	var speed:=motion_speed*(0.6 if chill_time>0 else 1.0)
	speed=minf(speed,maxf(0,mode_length-mode_time+delta)*motion_speed/delta)
	if is_instance_valid(rival):
		var toward:=flat_direction(position,rival.position)
		if motion_direction.dot(toward)>0.8:
			speed=minf(speed,maxf(0,flat_distance()-0.78)/delta)
	var before:=position
	var vertical:=velocity.y
	velocity=motion_direction*speed+knockback
	velocity.y=-0.1 if is_on_floor() else vertical-GRAVITY*delta
	move_and_slide()
	drive_velocity=motion_direction*speed
	knockback*=exp(-delta*4.2)
	distance_run+=before.distance_to(position)
	combo_speed=maxf(combo_speed,maxf(0,(position-before).dot(motion_direction)/delta))
	advance_animation(delta)
	impact_physics.step(delta)
	impact_physics.apply(skeleton,is_on_floor(),global_basis)
	if mode_time>=mode_length or speed<0.1 or get_slide_collision_count()>0 and before.distance_to(position)<0.001:
		mode="idle" if is_on_floor() else "air"
		mode_time=0
		mode_length=0.1
		combo_time=0.48
		drive_velocity=Vector3.ZERO
		velocity.x=0
		velocity.z=0

func start_air_trick(kind: String) -> bool:
	if kind not in ["Flip","Twist"] or is_on_floor() or health<=0 or freeze_time>0 or is_instance_valid(ragdoll):
		return false
	if not spend_stamina(8 if kind=="Flip" else 6):
		return false
	air_trick=kind
	mode="air_trick"
	mode_time=0
	mode_length=0.34 if kind=="Flip" else 0.28
	clip=""
	var animation: String="duel/backflip" if kind=="Flip" else "duel/air"
	play(animation,player.get_animation(animation).length/mode_length)
	count_action("air_"+kind.to_lower())
	return true

func tick_air_trick(delta: float) -> void:
	impact_physics.restore(skeleton)
	mode_time+=delta
	recover_resources(delta)
	velocity.x=air_momentum.x+knockback.x
	velocity.z=air_momentum.z+knockback.z
	velocity.y-=GRAVITY*delta
	var before:=position
	move_and_slide()
	knockback*=exp(-delta)
	distance_run+=before.distance_to(position)
	max_height=maxf(max_height,position.y)
	advance_animation(delta)
	if air_trick=="Twist":
		var pelvis: int=bones["pelvis"]
		var rotation_: Quaternion=skeleton.get_bone_pose_rotation(pelvis)
		skeleton.set_bone_pose_rotation(pelvis,Quaternion(Vector3.UP,TAU*clampf(mode_time/mode_length,0,1))*rotation_)
	impact_physics.step(delta)
	impact_physics.apply(skeleton,is_on_floor(),global_basis)
	if is_on_floor() or mode_time>=mode_length:
		mode="land" if is_on_floor() else "air"
		mode_time=0
		mode_length=0.24
		clip=""
		player.play("duel/land" if is_on_floor() else "duel/air",0)
		player.advance(0)
		if is_on_floor():
			count_action("land")
			arena.movement_burst(self,true)

func begin_strike(spec: Array) -> void:
	var linked_flash: bool=mode=="burst_dash"
	var powered: bool=team==2 and haste_time>0
	if not spend_stamina(float(spec[6])*(0.75 if powered else 1.0)):
		start_recovery()
		return
	if not linked_flash:
		tactics.attack(self,"melee")
	melee_spec = spec
	attack_kind = spec[0]
	strike_damage = float(spec[5])*(1.35 if powered else 1.0)
	strike_reach = spec[7]
	strike_augmented=false
	if spec[0] in ["front_kick","round_kick","knee"] and (mana>=5 or powered or linked_flash):
		if not powered and not linked_flash:
			spend_mana(5)
		strike_augmented=true
	mode = "punch"
	mode_time = 0
	melee_clock = 0
	melee_connected = false
	melee_attempts += 1
	clip = ""
	play(spec[1], 1.25)
	mode_length = player.get_animation(spec[1]).length / 1.25 + 0.08
	melee_previous = bone_point(spec[2])
	count_action(spec[0])

func start_uppercut() -> void:
	if not spend_stamina(28):
		start_recovery()
		return
	melee_sequence += 1
	mode = "melee_charge"
	mode_time = 0
	melee_charge = 0
	charge_value=0
	did_release=false
	current_spell={"hand":"hand_r"}
	clip = ""
	play("battle/uppercut")
	count_action("charged_uppercut")

func flash_stamina_requirement() -> float:
	return 14+13.0*(0.75 if team==2 and haste_time>0 else 1.0)

func start_burst(paid := false) -> void:
	if stamina<flash_stamina_requirement() or (not paid and mana<9):
		return
	if not paid:
		spend_mana(9)
	spend_stamina(14)
	mode = "burst_charge"
	mode_time = 0
	flash_aura_time=FLASH_CHARGE_TIME+0.2
	current_spell={"hand":"both"}
	did_release=false
	charge_value=0
	burst_direction = flat_direction(position, rival.position)
	combo_speed = FLASH_STEP_SPEED * (0.6 if chill_time > 0 else 1.0)
	burst_left = clampf((flat_distance() - 0.8) / combo_speed, 0.06, 0.48)
	clip = ""
	clip="spells/self_mend"
	player.play(clip,0,1)
	player.advance(0)
	tactics.attack(self,"flash_step")
	count_action("flash_charge")

func tick(delta: float) -> void:
	update_status(delta)
	# Airborne fighters must not treat another fighter's head as a landing platform.
	if position.y>0.25 or velocity.y>0.2:
		air_body_passthrough=true
	elif air_body_passthrough:
		var overlapping:=false
		for other in arena.fighters:
			if other!=self and Vector2(position.x-other.position.x,position.z-other.position.z).length()<0.65:
				overlapping=true
				break
		air_body_passthrough=overlapping
	collision_mask=1|1024 if air_body_passthrough else 1|128|256|512|1024
	if is_instance_valid(ragdoll):
		invulnerability=maxf(0,invulnerability-delta)
		mode = "ragdoll"
		var landed: bool = ragdoll.step(delta)
		ragdoll_peak = maxf(ragdoll_peak, ragdoll.peak_height)
		if landed and health > 0:
			finish_ragdoll()
		return
	if health <= 0:
		super.tick(delta)
		return
	if mode == "getup":
		invulnerability=maxf(0,invulnerability-delta)
		mode_time += delta
		advance_recovery(delta)
		if mode_time >= mode_length:
			mode = "idle"
			mode_time = 0
			collision_layer = 128 << team
			get_child(0).set_deferred("disabled", false)
			recovery_source.clear()
			recovery_target.clear()
		return
	if freeze_time > 0:
		mode = "frozen"
		drive_velocity=Vector3.ZERO
		velocity.x=0
		velocity.z=0
	elif mode == "frozen":
		mode = "idle"
		mode_time = 0
	if mode=="motion_dash" and freeze_time<=0:
		tick_motion_dash(delta)
		return
	if mode=="air_trick" and freeze_time<=0:
		tick_air_trick(delta)
		return
	if mode in ["burst_charge","burst_dash", "melee_charge"] and freeze_time <= 0:
		impact_physics.restore(skeleton)
		mode_time += delta
		recover_resources(delta)
		face_rival(delta)
		if mode=="burst_charge":
			charge_value=minf(1,mode_time/FLASH_CHARGE_TIME)
			drive_velocity=drive_velocity.move_toward(Vector3.ZERO,delta*65)
			velocity.x=drive_velocity.x+knockback.x
			velocity.z=drive_velocity.z+knockback.z
			velocity.y=-0.1 if is_on_floor() and position.y<0.15 and velocity.y<=0 else velocity.y-GRAVITY*delta
			move_and_slide()
			if mode_time>=FLASH_CHARGE_TIME:
				mode="burst_dash"
				mode_time=0
				did_release=true
				flash_aura_time=1.4
				burst_direction=flat_direction(position,rival.position)
				burst_left=clampf((flat_distance()-0.8)/combo_speed,0.06,0.48)
				clip=""
				play("duel/dash",2.8)
				count_action("forward_burst")
				arena.audio.impact("dash",global_position,0.7)
		elif mode == "melee_charge":
			melee_charge = minf(1, mode_time / 0.85)
			charge_value=melee_charge
			velocity.x = 0
			velocity.z = 0
			velocity.y=-0.1 if is_on_floor() and position.y<0.15 and velocity.y<=0 else velocity.y-GRAVITY*delta
			move_and_slide()
			if mode_time >= 0.85:
				begin_strike(["uppercut", "battle/uppercut", "hand_r", 0.15, 0.52, 23.0, 0.0, 1.1])
		else:
			var before := position
			var vertical:=velocity.y
			var speed:=minf(combo_speed,maxf(0,flat_distance()-0.8)/delta)
			velocity = burst_direction * speed
			velocity.y = -0.1 if is_on_floor() and position.y<0.15 and vertical<=0 else vertical - GRAVITY * delta
			move_and_slide()
			position.y = maxf(0, position.y)
			drive_velocity = burst_direction * combo_speed
			distance_run += before.distance_to(position)
			arena.speed_trail(self)
			if flat_distance() < 0.95 or mode_time > burst_left:
				combo_time = 0.48
				melee_charge=0
				melee_sequence+=1
				begin_strike(["knee","battle/knee","calf_r",0.18,0.52,13.0,13.0,0.90])
		advance_animation(delta)
		impact_physics.step(delta)
		impact_physics.apply(skeleton, is_on_floor(), global_basis)
		return
	var enabled := brain_enabled
	if mode=="punch" and attack_kind in ["knee","uppercut"] and mode_time<0.25:
		drive_velocity=flat_direction(position,rival.position)*clampf((flat_distance()-0.55)*9,0,3.0)
	if freeze_time > 0:
		brain_enabled = false
	super.tick(delta)
	brain_enabled = enabled

func resolve_melee(delta: float) -> void:
	if mode != "punch" or melee_spec.is_empty() or not arena.round_active or health <= 0:
		return
	var limb := bone_point(melee_spec[2])
	var movement := limb - melee_previous
	if not melee_connected and melee_clock >= melee_spec[3] and melee_clock <= melee_spec[4] and movement.length() / delta > 0.8:
		var shape := SphereShape3D.new()
		shape.radius = 0.22 if attack_kind in ["knee", "front_kick", "round_kick"] else 0.105
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.collision_mask = arena.enemy_hurt_mask(team)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var samples := maxi(1, ceili(movement.length() / 0.04))
		for i in range(samples + 1):
			var point := melee_previous.lerp(limb, float(i) / samples)
			query.transform = Transform3D(Basis.IDENTITY, point)
			var results := get_world_3d().direct_space_state.intersect_shape(query, 8)
			if results.is_empty():
				continue
			var area: Area3D = results[0].collider
			var victim = area.get_meta("fighter")
			if victim.health <= 0:
				continue
			var speed: float = (movement / delta - victim.velocity).length()
			var momentum_speed := maxf(speed, combo_speed * clampf(combo_time / 0.48, 0, 1))
			var multiplier := 1.0 + clampf((momentum_speed - 5.0) / 8.0, 0, 2.5)
			var impulse := (movement / delta * 8.0).limit_length(180) + flat_direction(position, victim.position) * maxf(0, momentum_speed - 5) * 22
			var q := melee_charge if attack_kind == "uppercut" else 0.0
			if q > 0:
				impulse += Vector3.UP * 1250 * q
			var spec := {"id":attack_kind, "name":attack_kind.replace("_", " ").capitalize(), "effect":"melee", "damage":strike_damage * multiplier * (1+q*0.7), "charge":q, "launch":q>0.6, "combo":combo_time>0, "augment":strike_augmented or haste_time>0 or armor_time>0}
			melee_connected = arena.apply_impact(self, victim, spec, point, flat_direction(position, victim.position), area, impulse)
			if melee_connected:
				if combo_time > 0:
					dash_combo_hits += 1
				break
	melee_previous = limb

func update_status(delta: float) -> void:
	tactics.tick(self,delta)
	flash_aura_time=maxf(0,flash_aura_time-delta)
	wall_crash_cooldown=maxf(0,wall_crash_cooldown-delta)
	if health<=0:
		death_age+=delta
	chill_time = maxf(0, chill_time - delta)
	freeze_time = maxf(0, freeze_time - delta)
	freeze_immunity = maxf(0, freeze_immunity - delta)
	armor_time = maxf(0, armor_time - delta)
	haste_time = maxf(0, haste_time - delta)
	combo_time = maxf(0, combo_time - delta)
	if armor_time <= 0:
		armor_hp = 0
	if burn_time > 0 and health > 0 and arena.round_active:
		burn_time = maxf(0, burn_time - delta)
		burn_clock += delta
		if burn_clock >= 0.5:
			burn_clock -= 0.5
			var damage := minf(health, 1.5)
			health -= damage
			damage_taken += damage
			if is_instance_valid(burn_source):
				burn_source.damage_dealt += damage
			arena.events.append({"time":arena.elapsed,"event":"burn_tick","victim":team,"damage":damage})
			if health <= 0:
				enter_death(burn_source,Vector3.ZERO,bone_point("pelvis"))

func receive_status(attacker: CharacterBody3D, spec: Dictionary) -> void:
	if attacker.team == 0 and (spec.effect != "melee" or spec.get("augment",false)):
		burn_time = minf(6, maxf(burn_time, 4.0 + float(spec.get("charge",0))*2))
		burn_source = attacker
		burns_applied += 1
	if attacker.team == 1 and (spec.effect == "ice_beam" or (spec.effect=="melee" and spec.get("augment",false))):
		chill_time = 3.5
		frost = minf(1.2, frost + 0.38 + float(spec.get("charge",0))*0.5)
		if frost >= 1.0 and freeze_immunity <= 0 and not is_instance_valid(ragdoll):
			freeze_time = 1.25
			freeze_immunity = 3.5
			frost = 0.2
			freezes += 1
			arena.events.append({"time":arena.elapsed,"event":"freeze","victim":team})

func receive_magic(amount: float, direction: Vector3, attacker: CharacterBody3D, point := Vector3.INF, zone := "chest", bone := "spine_03", impulse := Vector3.ZERO) -> bool:
	if health<=0 or invulnerability>0 or not arena.round_active:
		return false
	if not point.is_finite():
		point=bone_point("spine_03")
	if impulse.is_zero_approx():
		impulse=direction.normalized()*amount*12.0
	last_attacker = attacker.team
	if team==2 and haste_time>0:
		amount*=0.75
	if armor_hp > 0:
		var absorbed := minf(armor_hp, amount * 0.55)
		armor_hp -= absorbed
		amount -= absorbed
		impulse *= 0.65
	if is_instance_valid(ragdoll):
		if invulnerability > 0 or health <= 0:
			return false
		var applied := minf(health, amount)
		health -= applied
		damage_taken += applied
		attacker.damage_dealt += applied
		attacker.hits_scored += 1
		ragdoll.add_impulse(impulse,point)
		invulnerability = 0.18
		if health <= 0:
			enter_death(attacker,impulse,point)
		return true
	if amount>=health:
		var applied:=health
		health=0
		damage_taken+=applied
		attacker.damage_dealt+=applied
		attacker.hits_scored+=1
		invulnerability=0.16
		apply_physical_impact(point,impulse,zone,bone)
		enter_death(attacker,impulse,point)
		return true
	var landed := super.receive_magic(amount, direction, attacker, point, zone, bone, impulse)
	if landed and (impulse.length() >= 440 or (last_guard_shattered and impulse.length() >= 280) or last_hit_launch or health <= 0):
		start_ragdoll(impulse, point)
	return landed

func enter_death(attacker: CharacterBody3D,impulse: Vector3,point: Vector3) -> void:
	ko_count+=1
	death_age=0
	death_impulse=impulse
	freeze_time=0
	if not is_instance_valid(ragdoll):
		start_ragdoll(impulse,point)
	mode="ragdoll"
	arena.events.append({"time":arena.elapsed,"event":"death","team":team,"impulse":[impulse.x,impulse.y,impulse.z],"point":[point.x,point.y,point.z]})
	arena.finish_round(attacker.team if is_instance_valid(attacker) else -1)

func wall_crash(point: Vector3,normal: Vector3,speed: float,incoming: Vector3) -> void:
	if wall_crash_cooldown>0 or speed<4.5:
		return
	wall_crash_cooldown=0.65
	wall_crashes+=1
	arena.events.append({"time":arena.elapsed,"event":"wall_crash","team":team,"speed":speed,"point":[point.x,point.y,point.z]})
	arena.audio.impact("heavy",point,clampf(speed/9,0.5,1.3))
	for i in 8:
		arena.vfx.puff(point,"smoke_04",team,Vector2.ONE*0.65,normal*(0.4+i*0.12)+Vector3.UP*(0.2+i*0.05),0.45,Color(0.65,0.73,0.72,0.45),0.1)
	if health<=0 or not arena.round_active:
		return
	var damage:=clampf((speed-4.0)*1.8,0,22)
	var applied:=minf(health,damage)
	health-=applied
	damage_taken+=applied
	stamina=maxf(0,stamina-damage*0.8)
	minimum_stamina=minf(minimum_stamina,stamina)
	stamina_delay=maxf(stamina_delay,0.65)
	guard_energy=maxf(0,guard_energy-damage*0.6)
	var attacker: CharacterBody3D=arena.fighters[last_attacker] if last_attacker>=0 else null
	if is_instance_valid(attacker) and attacker!=self:
		attacker.damage_dealt+=applied
	if not is_instance_valid(ragdoll):
		velocity=incoming.bounce(normal)*0.3+normal*0.5+Vector3.UP*1.2
		start_ragdoll(-normal*speed*impact_physics.BODY_MASS,point)
	if health<=0:
		enter_death(attacker,-normal*speed*impact_physics.BODY_MASS,point)

func start_ragdoll(impulse: Vector3, point: Vector3) -> void:
	if is_instance_valid(ragdoll):
		return
	impact_physics.saved_pose.clear()
	mode = "ragdoll"
	collision_layer = 0
	get_child(0).set_deferred("disabled", true)
	ragdoll = Ragdoll.new()
	arena.add_child(ragdoll)
	ragdoll.build(self, impulse, point)
	ragdoll_count += 1
	arena.events.append({"time":arena.elapsed,"event":"ragdoll","team":team,"impulse":impulse.length()})
	arena.audio.impact("heavy", point, 1)

func finish_ragdoll() -> void:
	var location: Vector3 = ragdoll.location()
	var world_pose: Array[Transform3D]=[]
	for i in skeleton.get_bone_count():
		world_pose.append(skeleton.global_transform*skeleton.get_bone_global_pose(i))
	var lying_direction: Vector3=bone_point("Head")-bone_point("pelvis")
	lying_direction.y=0
	ragdoll_peak = maxf(ragdoll_peak, ragdoll.peak_height)
	ragdoll.restore_pose()
	ragdoll.queue_free()
	ragdoll = null
	impact_physics.reset(skeleton)
	position = Vector3(location.x, 0.02, location.z)
	velocity = Vector3.ZERO
	drive_velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	model.position = Vector3.ZERO
	mode = "getup"
	mode_time = 0
	clip="ual2/LayToIdle"
	player.play(clip,0,1.05)
	player.advance(0)
	var target_direction:=bone_point("Head")-bone_point("pelvis")
	target_direction.y=0
	if lying_direction.length()>0.15 and target_direction.length()>0.15:
		rotation.y+=target_direction.signed_angle_to(lying_direction,Vector3.UP)
	var pelvis_offset:=bone_point("pelvis")-global_position
	position.x=location.x-pelvis_offset.x
	position.z=location.z-pelvis_offset.z
	var flat:=Vector2(position.x,position.z).limit_length(float(arena.Boundary.RADIUS)-0.4)
	position.x=flat.x
	position.z=flat.y
	mode_length=RECOVERY_GATHER+player.get_animation(clip).length/1.05
	invulnerability=mode_length
	recovery_source.clear()
	recovery_target.clear()
	var inverse:=skeleton.global_transform.affine_inverse()
	for i in skeleton.get_bone_count():
		var parent:=skeleton.get_bone_parent(i)
		var source: Transform3D=(inverse*world_pose[parent]).affine_inverse()*(inverse*world_pose[i]) if parent>=0 else inverse*world_pose[i]
		recovery_source[i]=[source.origin,source.basis.orthonormalized().get_rotation_quaternion()]
		recovery_target[i]=[skeleton.get_bone_pose_position(i),skeleton.get_bone_pose_rotation(i)]
	apply_recovery_blend(0)
	recoveries_count += 1
	arena.events.append({"time":arena.elapsed,"event":"ragdoll_recovery","team":team})

func advance_recovery(delta: float) -> void:
	for i in recovery_target:
		skeleton.set_bone_pose_position(i,recovery_target[i][0])
		skeleton.set_bone_pose_rotation(i,recovery_target[i][1])
	if mode_time>RECOVERY_GATHER:
		player.advance(minf(delta,mode_time-RECOVERY_GATHER))
	for i in recovery_target:
		recovery_target[i]=[skeleton.get_bone_pose_position(i),skeleton.get_bone_pose_rotation(i)]
	var weight:=smoothstep(0,RECOVERY_BLEND,mode_time)
	apply_recovery_blend(weight)

func apply_recovery_blend(weight: float) -> void:
	for i in recovery_source:
		skeleton.set_bone_pose_position(i,recovery_source[i][0].lerp(recovery_target[i][0],weight))
		skeleton.set_bone_pose_rotation(i,recovery_source[i][1].slerp(recovery_target[i][1],weight))
