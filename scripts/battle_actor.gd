extends "res://scripts/duel_actor.gd"
const Channels=preload("res://scripts/animation_channels.gd")
const AimPose=preload("res://scripts/character_aim_pose.gd")
const Ragdoll = preload("res://scripts/combat_ragdoll.gd")
const FLASH_STEP_SPEED := 34.0
const OVERDRIVE_MOVE_SPEED := FLASH_STEP_SPEED*0.75
const FLASH_CHARGE_TIME := 0.28
const CombatTactics = preload("res://scripts/combat_tactics.gd")
var tactics := CombatTactics.new()
var flash_aura_time := 0.0
var custom_jump_frames: Array = []
var custom_idle_frames: Array = []
var custom_idle_elapsed := 0.0
var custom_idle_duration := 3.0
var custom_motion_frames: Array = []
var custom_motion_step := ""
var editor_pose_locked:=false
var practice_immortal:=false
var practice_damageable_dummy:=false
var practice_god_mode:=false
var practice_wooden_dummy:=false
var practice_dummy_visual:Node3D

var practice_spell_animation:Dictionary={}
var practice_projectile_spec:Dictionary={}
var practice_return_enabled:=false
var practice_home:=Vector3.ZERO
var return_state:=""
var air_remaining:=8.0
var drowned:=false
var ice_trapped:=false
var ice_pose:Dictionary={}
var swim_cooldown:=0.0
var water_depth:=0.0
var surface_slippery:=false
var burn_damage:=1.5
var stun_time:=0.0
var practice_release_fraction:=0.35
var custom_jump_elapsed := 0.0
var custom_jump_native := false
var custom_jump_source_duration := 1.121818
var editor_animation_profile:Dictionary={}
var pending_editor_land_profile:Dictionary={}
var has_pending_editor_land_profile := false
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
const TWIST_DELAY := 0.12
const TWIST_DURATION := 0.54
const BACKFLIP_DURATION := 0.68
var twist_age := -1.0
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
var queued_story_punch := ""
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
var story_spell_dispatching := false
var story_strikes: Dictionary = {}
var story_punch_previews: Dictionary = {}
var story_calibration_aim_enabled := false
var story_calibration_aim_target := Vector3.ZERO
var story_torso_calibration_yaw := 0.0
var story_torso_calibration_pitch := 0.0
var story_torso_recovery_yaw := 0.0
var story_torso_recovery_pitch := 0.0
var story_torso_recovery_elapsed := 0.0
var story_torso_recovery_duration := 0.18
var story_torso_recovery_pending := false
var story_torso_aim_blend := 0.0
var story_torso_aim_blend_elapsed := 0.0
var story_torso_aim_blend_duration := 0.10
var story_torso_aim_was_active := false
var story_limb_reservations: Dictionary = {}
var story_limb_players: Dictionary = {}
var story_limb_animation_cache: Dictionary = {}
var story_limb_clip_serial := 0
var story_diagonal_locomotion_side := ""
var story_diagonal_locomotion_clips: Dictionary = {}
var story_strafe_hand_clips: Dictionary = {}
var story_enemy_charge_active := false
var story_enemy_charge_side := ""
var story_enemy_charge_elapsed := 0.0
var story_enemy_charge_duration := 0.0
var story_enemy_charge_resolving := false

func bone_point(bone:String,offset:=Vector3.ZERO) -> Vector3:
	if practice_wooden_dummy and is_instance_valid(practice_dummy_visual):return practice_dummy_visual.aim_point(bone)+global_basis*offset
	return super.bone_point(bone,offset)

func story_spells_for_animation(animation_id: String) -> Array[Dictionary]:
	var attached_spells:Array[Dictionary]=[]
	var equipped: Dictionary = story_profile.get("story_part_gear", {})
	var inventory: Array = story_profile.get("gear_inventory", [])
	var spells: Array = story_profile.get("spell_inventory", story_profile.get("crystal_inventory", []))
	for part_id in equipped:
		for item in inventory:
			if not item is Dictionary or str(item.get("id", "")) != str(equipped[part_id]):continue
			var links: Dictionary = item.get("crystal_links", {})
			var linked_ids:Array=[]
			var linked_value:Variant=links.get(animation_id, [])
			if linked_value is Array:linked_ids=linked_value.duplicate()
			elif not str(linked_value).is_empty():linked_ids.append(str(linked_value))
			for pair in item.get("animation_slots", []):
				if str(pair.get("animation", "")) == animation_id:
					for spell_id in pair.get("spell_ids",[]):
						if not linked_ids.has(str(spell_id)):linked_ids.append(str(spell_id))
					var legacy_id:=str(pair.get("spell_id",""))
					if not legacy_id.is_empty() and not linked_ids.has(legacy_id):linked_ids.append(legacy_id)
					break
			for linked_id in linked_ids:
				if str(linked_id).is_empty():continue
				for spell in spells:
					if spell is Dictionary and str(spell.get("id", "")) == str(linked_id):
						attached_spells.append(spell)
		return attached_spells
	return attached_spells

func story_spell_for_animation(animation_id: String) -> Dictionary:
	var spells:=story_spells_for_animation(animation_id)
	return spells[0] if not spells.is_empty() else {}

func has_story_barrier() -> bool:
	if not arena.story_mode:return true
	for spell in story_spells_for_animation("block"):
		var barrier_name := str(spell.get("name", "")).to_lower()
		var barrier_id := str(spell.get("id", "")).to_lower()
		if str(spell.get("effect", "")).to_lower() == "barrier" or barrier_name.contains("barrier") or barrier_id.contains("barrier"):
			return true
	return false

func shield_active() -> bool:
	return super.shield_active() and has_story_barrier()

func shield_intersection(from: Vector3, to: Vector3, radius: float = 0.0) -> Dictionary:
	if not arena.story_mode or not has_story_barrier():
		return super.shield_intersection(from,to,radius)
	if not super.shield_active():return {}
	# Story Barrier is a close-fitting shell around the entire body, so sweep the
	# incoming segment against a vertical capsule rather than a front-facing disc.
	var look_scale:Vector3=model.scale if is_instance_valid(model) else Vector3.ONE
	var shell_radius_x:=0.36*absf(look_scale.x)+radius
	var shell_radius_z:=0.28*absf(look_scale.z)+radius
	var shell_radius_y:=0.49*absf(look_scale.y)+radius
	var model_offset:Vector3=model.position if is_instance_valid(model) else Vector3.ZERO
	var shell_center:=global_position+model_offset+Vector3.UP*(0.91*look_scale.y)
	var axis_half:=0.42*absf(look_scale.y)
	var distance:=from.distance_to(to)
	var steps:=maxi(1,ceili(distance/0.045))
	for step in range(steps+1):
		var point:=from.lerp(to,float(step)/float(steps))
		var nearest_y:=clampf(point.y,shell_center.y-axis_half,shell_center.y+axis_half)
		var dx:float=(point.x-shell_center.x)/shell_radius_x
		var dz:float=(point.z-shell_center.z)/shell_radius_z
		var dy:=point.y-nearest_y
		if dx*dx+dz*dz+(dy/shell_radius_y)*(dy/shell_radius_y)<=1.0:
			return {"point":point}
	return {}

func _ready() -> void:
	var actual := team
	if team == 2:
		team = 0
	super._ready()
	team = actual
	rng.seed = 27531 + team * 1381
	_create_story_limb_players()
	player.add_animation_library("battle", load(BASE + "animations/battle.res"))
	# Keep only the auxiliary clips used by this actor. The source library stays
	# intact on disk; a lean runtime registry avoids AnimationMixer cache failure.
	var auxiliary:AnimationLibrary=player.get_animation_library("ual2").duplicate()
	for name_ in auxiliary.get_animation_list():
		if name_ not in ["Idle_Shield_Break","LayToIdle"]:auxiliary.remove_animation(name_)
	player.remove_animation_library("ual2")
	player.add_animation_library("ual2",auxiliary)
	player.add_animation_library("editor_attacks",load(BASE+"animations/editor_attacks.res"))
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
	story_strikes.clear()
	story_punch_previews.clear()
	story_calibration_aim_enabled=false
	story_torso_recovery_yaw=0.0
	story_torso_recovery_pitch=0.0
	story_torso_recovery_elapsed=0.0
	story_torso_recovery_pending=false
	story_torso_aim_blend=0.0
	story_torso_aim_blend_elapsed=0.0
	story_torso_aim_was_active=false
	story_limb_reservations.clear()
	story_enemy_charge_active=false
	story_enemy_charge_side=""
	story_enemy_charge_elapsed=0.0
	for limb_player: AnimationPlayer in story_limb_players.values():limb_player.stop()
	stun_time=0
	recovery_source.clear()
	recovery_target.clear()
	air_body_passthrough=false
	air_remaining=8.0
	drowned=false
	ice_trapped=false
	ice_pose.clear()
	water_depth=0
	swim_cooldown=0
	if is_instance_valid(ragdoll):
		ragdoll.restore_pose()
		ragdoll.queue_free()
		ragdoll = null
	super.reset_fighter(location)
	set_editor_animation_profile({},"")
	# A reset can interrupt the ragdoll/get-up blend. Clear untracked root/bone
	# offsets before the idle clip, which only animates the pelvis position.
	skeleton.reset_bone_poses()
	clip=preload("res://scripts/default_idle.gd").resolve(self,player,story_profile.get("idle_animation"))
	player.play(clip,0,1)
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
	twist_age=-1
	model.rotation.y=0
	melee_charge = 0
	last_guard_shattered = false
	last_hit_charge = 0
	last_attacker=-1
	mode_length=0.25+team*0.1
	death_age=INF
	death_impulse=Vector3.ZERO
	wall_crash_cooldown=0

func prepare_post_fight_freeplay() -> void:
	# The result has already been recorded, so leave the player standing and
	# responsive in the arena even when they lost or ended the round ragdolled.
	var location: Vector3 = global_position
	var facing: float = rotation.y
	if is_instance_valid(ragdoll):
		location = ragdoll.location()
	location.y = arena.spell_environment.support_height(location) + 0.02
	reset_fighter(location)
	rotation.y = facing
	player_controlled = true
	brain_enabled = false
	GameDiagnostics.log_event("post_fight_player_recovered", {"position": location, "facing": facing})

func focus_position() -> Vector3:
	return ragdoll.location() - Vector3.UP * 0.65 if is_instance_valid(ragdoll) else global_position

func overhead_tag_position() -> Vector3:
	if practice_wooden_dummy:return global_position+Vector3.UP*2.8
	return ragdoll.location()+Vector3.UP*1.45 if is_instance_valid(ragdoll) else global_position+Vector3.UP*2.2

func movement_multiplier() -> float:
	return (1.45 if team == 2 else 1.0) * (1.35 if haste_time > 0 else 1.0) * (0.60 if chill_time > 0 else 1.0)

func arena_roam_radius() -> float:
	return float(arena.Boundary.RADIUS)-2.0

func locomotion_velocity(desired: Vector3) -> Vector3:
	if water_depth>0.15:
		return super.locomotion_velocity(desired)/(1.0+water_depth*1.8)
	if surface_slippery:
		return drive_velocity.lerp(desired*0.65,0.025)
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
	if not practice_projectile_spec.is_empty():return practice_projectile_spec.duplicate(true)
	if not practice_spell_animation.is_empty():return arena.profile_spells(0)[0].duplicate(true)
	var list: Array = arena.profile_spells(team)
	var spec: Dictionary = list[spell_cursor % list.size()].duplicate(true)
	spell_cursor += 1
	return spec

func start_cast(air: bool) -> void:
	if arena.story_mode:
		set_close_combat(true)
		return
	air=air or not is_on_floor()
	current_spell = choose_spell(air)
	if str(current_spell.get("hand","")) in ["mouth","head"]:current_spell.hand="Head"
	if not can_cast_with(current_spell,practice_spell_animation):return
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
	mode_length = player.get_animation(animation).length
	if not practice_spell_animation.is_empty():
		charge_goal=0
		cast_rate=1
		mode_length=float(practice_spell_animation.get("duration",preload("res://scripts/animation_source_pose.gd").duration(self,practice_spell_animation.step,practice_spell_animation.clip)))
		current_spell.release=mode_length*practice_release_fraction
		var hand:String=str(practice_spell_animation.get("attack_bone",current_spell.get("hand","hand_r")))
		current_spell.hand="Head" if hand in ["mouth","head"] else hand
	count_action("air_cast" if air else "cast")
	if air:
		air_casts += 1

func tick_cast(delta: float) -> bool:
	if not can_cast_with(current_spell,practice_spell_animation):
		mode="frozen"
		return false
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

func set_editor_animation_profile(profile:Dictionary,step:String) -> void:
	if step=="Land" and mode!="land" and (not is_on_floor() or mode in ["takeoff","air","air_trick","flip"]):
		pending_editor_land_profile=profile.duplicate(true)
		has_pending_editor_land_profile=true
		return
	apply_editor_animation_profile(profile,step)

func apply_editor_animation_profile(profile:Dictionary,step:String) -> void:
	var had_custom:=not custom_jump_frames.is_empty() or not custom_idle_frames.is_empty() or not custom_motion_frames.is_empty()
	custom_jump_frames=[]
	custom_idle_frames=[]
	custom_motion_frames=[]
	custom_motion_step=step
	custom_idle_elapsed=0
	custom_jump_elapsed=0
	custom_jump_native=false
	has_pending_editor_land_profile=false
	pending_editor_land_profile.clear()
	editor_animation_profile=profile.duplicate(true)
	if had_custom and is_instance_valid(skeleton):skeleton.reset_bone_poses()
	if not profile.has("frames") or profile.frames.size()<2:return
	match step:
		"Jump":
			custom_jump_frames=profile.frames.duplicate(true)
			custom_jump_native=profile.get("source_timing","legacy")=="native_v1"
			custom_jump_source_duration=float(profile.get("source_duration",1.121818))
		"Idle":
			custom_idle_frames=profile.frames.duplicate(true)
			custom_idle_duration=maxf(0.2,float(profile.get("duration",3.0)))
		_:custom_motion_frames=profile.frames.duplicate(true)

func advance_animation(delta: float) -> void:
	capture_ice_pose()
	advance_free_animation(delta)
	_advance_story_limb_animations(delta)
	_apply_story_punch_aim(delta)
	restore_ice_pose()

func _create_story_limb_players() -> void:
	story_limb_players.clear()
	for channel in ["arm_l", "arm_r", "leg_l", "leg_r", "face", "torso"]:
		var limb_player := AnimationPlayer.new()
		limb_player.name = "StoryLimb_" + channel
		player.get_parent().add_child(limb_player)
		limb_player.root_node = player.root_node
		limb_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		story_limb_players[channel] = limb_player

func _filtered_limb_animation(source_name: String, channel: String) -> String:
	if not player.has_animation(source_name):return ""
	var source:=player.get_animation(source_name)
	var cache_key:="%s|%s|%d"%[source_name,channel,Channels.revision(source)]
	if story_limb_animation_cache.has(cache_key):return str(story_limb_animation_cache[cache_key])
	var filtered:=Channels.filtered(source,source_name,channel)
	if filtered==null:return ""
	var animation_name:="limb_%d"%story_limb_clip_serial
	story_limb_clip_serial+=1
	var library:=AnimationLibrary.new()
	library.add_animation(animation_name,filtered)
	var library_name:="story_%d"%story_limb_clip_serial
	var limb_player:AnimationPlayer=story_limb_players[channel]
	limb_player.add_animation_library(library_name,library)
	var full_name:="%s/%s"%[library_name,animation_name]
	story_limb_animation_cache[cache_key]=full_name
	return full_name

func _play_story_limb_animation(channel: String, animation: String, speed: float = 1.0) -> bool:
	var animation_name := _filtered_limb_animation(animation, channel)
	if animation_name.is_empty():return false
	var limb_player: AnimationPlayer = story_limb_players[channel]
	limb_player.play(animation_name, 0.04, speed)
	return true

func preview_story_punch(side:String,yaw:float,pitch:float)->void:
	if not player_controlled or not arena.story_mode or side not in ["left","right"]:return
	var channel:="arm_l" if side=="left" else "arm_r"
	var source:="ual1/Punch_Jab" if side=="left" else "ual1/Punch_Cross"
	if story_strikes.has(channel):return
	var local_aim:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	var world_aim:=(global_basis*local_aim).normalized()
	if not _play_story_limb_animation(channel,source,1.75 if side=="right" else 1.95):return
	story_punch_previews[channel]={"aim_direction":world_aim,"aim_pitch":pitch,"clip":story_limb_players[channel].current_animation}

func preview_story_animation(animation_id:String,yaw:float,pitch:float)->void:
	if animation_id in ["punch_left","punch_right"]:
		preview_story_punch("left" if animation_id=="punch_left" else "right",yaw,pitch)
		return
	var local_aim:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	var world_aim:=(global_basis*local_aim).normalized()
	var channel:=""
	var source:=""
	match animation_id:
		"front_kick":channel="leg_r";source="boxing/front_kick_r"
		"block":
			for arm_channel in ["arm_l","arm_r"]:
				if _play_story_limb_animation(arm_channel,"duel/shield_raise_brace",1.0):
					story_punch_previews[arm_channel]={"aim_direction":world_aim,"aim_pitch":pitch,"clip":story_limb_players[arm_channel].current_animation}
			return
		"dash":
			for leg_channel in ["leg_l","leg_r"]:
				if _play_story_limb_animation(leg_channel,"duel/dash",1.0):
					story_punch_previews[leg_channel]={"aim_direction":world_aim,"aim_pitch":pitch,"clip":story_limb_players[leg_channel].current_animation}
			return
		_:
			# Generic chest/hand actions use the nearest available full-arm motion clip.
			channel="arm_r"
			source="ual1/Punch_Cross"
	if not _play_story_limb_animation(channel,source,1.45):return
	story_punch_previews[channel]={"aim_direction":world_aim,"aim_pitch":pitch,"clip":story_limb_players[channel].current_animation}

func clear_story_punch_preview(side:String)->void:
	var channel:="arm_l" if side=="left" else "arm_r"
	var preview:Dictionary=story_punch_previews.get(channel,{})
	story_punch_previews.erase(channel)
	if story_limb_players.has(channel) and not story_strikes.has(channel):
		var limb_player:AnimationPlayer=story_limb_players[channel]
		if not str(preview.get("clip","" )).is_empty() and limb_player.current_animation==str(preview.get("clip","")):limb_player.stop()

func clear_story_animation_preview()->void:
	for channel in story_punch_previews.keys():
		if not story_limb_players.has(channel):continue
		var limb_player:AnimationPlayer=story_limb_players[channel]
		var preview:Dictionary=story_punch_previews[channel]
		if limb_player.current_animation==str(preview.get("clip","")):limb_player.stop()
	story_punch_previews.clear()

func update_story_diagonal_locomotion(side:String) -> void:
	if not player_controlled or not arena.story_mode:return
	if side not in ["left","right"]:
		for channel in ["leg_l","leg_r"]:
			var limb_player:AnimationPlayer=story_limb_players[channel]
			var owned_clip:=str(story_diagonal_locomotion_clips.get(channel,""))
			if not owned_clip.is_empty() and limb_player.current_animation==owned_clip and not story_strikes.has(channel) and not story_limb_reservations.has(channel):limb_player.stop()
		story_diagonal_locomotion_side=""
		story_diagonal_locomotion_clips.clear()
		return
	var animation:="duel/strafe_%s"%side
	for channel in ["leg_l","leg_r"]:
		if story_strikes.has(channel) or story_limb_reservations.has(channel):continue
		var full_name:=_filtered_limb_animation(animation,channel)
		if full_name.is_empty():continue
		var limb_player:AnimationPlayer=story_limb_players[channel]
		if limb_player.current_animation!=full_name:limb_player.play(full_name,0.10,1.0)
		story_diagonal_locomotion_clips[channel]=full_name
	story_diagonal_locomotion_side=side

func update_story_strafe_hands(side:String) -> void:
	if not player_controlled or not arena.story_mode:return
	if side not in ["left","right"] or story_block_held:
		for channel in ["arm_l","arm_r"]:
			var limb_player:AnimationPlayer=story_limb_players[channel]
			var owned_clip:=str(story_strafe_hand_clips.get(channel,""))
			if not owned_clip.is_empty() and limb_player.current_animation==owned_clip and not story_strikes.has(channel) and not story_limb_reservations.has(channel):limb_player.stop()
		story_strafe_hand_clips.clear()
		return
	for channel in ["arm_l","arm_r"]:
		if story_strikes.has(channel) or story_limb_reservations.has(channel):continue
		var clip_name:=_filtered_limb_animation("fight/walk_guard",channel)
		if clip_name.is_empty():continue
		var limb_player:AnimationPlayer=story_limb_players[channel]
		if limb_player.current_animation!=clip_name:limb_player.play(clip_name,0.12,1.0)
		story_strafe_hand_clips[channel]=clip_name

func _apply_story_punch_aim(delta:float) -> void:
	if not arena.story_mode or not player_controlled:return
	var active_channels:Array[String]=[]
	for channel in ["arm_l","arm_r","leg_l","leg_r","face"]:
		if story_strikes.has(channel) or story_limb_reservations.has(channel):active_channels.append(channel)
	if story_block_held and not active_channels.has("arm_l"):active_channels.append("arm_l")
	var cursor_action_active:=story_calibration_aim_enabled and not active_channels.is_empty()
	if cursor_action_active:
		if not story_torso_aim_was_active:
			story_torso_aim_blend_elapsed=0.0
			story_torso_recovery_elapsed=0.0
			story_torso_recovery_pending=true
		story_torso_aim_was_active=true
		var cursor_extent:=clampf(Vector2(story_torso_calibration_yaw/deg_to_rad(89.0),story_torso_calibration_pitch/deg_to_rad(80.0)).length(),0.0,1.0)
		story_torso_aim_blend_duration=lerpf(0.07,0.14,cursor_extent)
		story_torso_aim_blend_elapsed+=delta
		var blend_progress:=clampf(story_torso_aim_blend_elapsed/maxf(0.001,story_torso_aim_blend_duration),0.0,1.0)
		story_torso_aim_blend=blend_progress*blend_progress*(3.0-2.0*blend_progress)
		var torso_channel:="arm_l" if active_channels.has("arm_l") else ("arm_r" if active_channels.has("arm_r") else "")
		if not torso_channel.is_empty():
			_rotate_torso_punch_endpoint_to_facing_line(torso_channel)
		else:
			story_torso_recovery_yaw=story_torso_calibration_yaw
			story_torso_recovery_pitch=story_torso_calibration_pitch
			_apply_training_torso_pose(story_torso_calibration_yaw*story_torso_aim_blend,story_torso_calibration_pitch*story_torso_aim_blend)
	else:
		story_torso_aim_was_active=false
		story_torso_aim_blend=0.0
	for channel in ["leg_l","leg_r"]:
		if not story_strikes.has(channel) and not story_punch_previews.has(channel):continue
		var strike:Dictionary=story_strikes.get(channel,story_punch_previews.get(channel,{}))
		var aim:Vector3=strike.get("aim_direction",Vector3.ZERO)
		if aim.is_zero_approx():continue
		AimPose.aim_leg(self,channel.right(1),aim)
	if not cursor_action_active and story_torso_recovery_pending:
		story_torso_recovery_elapsed+=delta
		var progress:=clampf(story_torso_recovery_elapsed/maxf(0.001,story_torso_recovery_duration),0.0,1.0)
		var eased:=progress*progress*(3.0-2.0*progress)
		_apply_training_torso_pose(story_torso_recovery_yaw*(1.0-eased),story_torso_recovery_pitch*(1.0-eased))
		if progress>=1.0:
			story_torso_recovery_pending=false
			story_torso_recovery_yaw=0.0
			story_torso_recovery_pitch=0.0
	_apply_story_calibration_aim()

func _rotate_torso_punch_endpoint_to_facing_line(channel:String)->void:
	var correction:=AimPose.endpoint_angles(self,"hand_%s"%channel.right(1),story_calibration_aim_target)
	if correction.is_empty():return
	story_torso_recovery_yaw=correction.yaw
	story_torso_recovery_pitch=correction.pitch
	story_torso_recovery_duration=correction.recovery_duration
	AimPose.apply_torso(self,float(correction.yaw)*story_torso_aim_blend,float(correction.pitch)*story_torso_aim_blend)

func _apply_training_torso_pose(yaw:float,pitch:float)->void:
	AimPose.apply_torso(self,yaw,pitch)

func set_story_calibration_aim(target:Vector3, enabled:bool)->void:
	story_calibration_aim_target=target
	story_calibration_aim_enabled=enabled

func _apply_story_calibration_aim()->void:
	if not story_calibration_aim_enabled or not arena.story_mode or not player_controlled:return
	for channel in ["arm_l","arm_r"]:
		if story_punch_previews.has(channel):
			AimPose.align_forearm(self,channel.right(1),story_calibration_aim_target)
			return

func _add_story_aim_rotation(bone_name:String,world_axis:Vector3,angle:float) -> void:
	AimPose.rotate_bone(self,bone_name,world_axis,angle)

func _advance_story_limb_animations(delta: float) -> void:
	for channel in story_limb_reservations.keys():
		story_limb_reservations[channel] = float(story_limb_reservations[channel]) - delta
		if float(story_limb_reservations[channel]) <= 0:story_limb_reservations.erase(channel)
	for limb_player: AnimationPlayer in story_limb_players.values():
		if not limb_player.current_animation.is_empty():
			if not story_block_held and limb_player.current_animation.contains("shield_hold"):
				limb_player.stop()
				continue
			limb_player.advance(delta)
			if limb_player.current_animation.is_empty():continue
			var current:Animation=limb_player.get_animation(limb_player.current_animation)
			if current.loop_mode==Animation.LOOP_NONE and limb_player.current_animation_position >= limb_player.current_animation_length:limb_player.stop()
	if story_block_held:
		for channel in ["arm_l", "arm_r"]:
			var limb_player: AnimationPlayer = story_limb_players[channel]
			if limb_player.current_animation.is_empty():_play_story_limb_animation(channel, "duel/shield_hold_brace")

func play(name_:String,speed:=1.0) -> void:
	if name_ in ["ual1/Idle","spells/idle"] and editor_animation_profile.is_empty():
		name_=preload("res://scripts/default_idle.gd").resolve(self,player,story_profile.get("idle_animation"))
	super.play(name_,speed)

func advance_free_animation(delta:float) -> void:
	if mode=="land" and has_pending_editor_land_profile:
		var landing:=pending_editor_land_profile.duplicate(true)
		apply_editor_animation_profile(landing,"Land")
	var posing_custom_motion:=is_custom_motion_active()
	var posing_custom_jump:=mode in ["takeoff","air"] and jump_kind=="motion_jump" and custom_jump_frames.size()>=2
	if editor_animation_profile.get("mirrored",false) or posing_custom_motion or posing_custom_jump or clip=="spells/idle" and custom_idle_frames.size()>=2:
		skeleton.reset_bone_poses()
	if posing_custom_motion and custom_motion_step in ["Punch","Cross","Hook","Kick","Round Kick","Knee","Elbow","Sweep","Uppercut","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast"]:
		var recipe:=preload("res://scripts/animation_source_pose.gd").clip_at(self,custom_motion_step,str(editor_animation_profile.clip),editor_attack_progress(),float(editor_animation_profile.source_duration))
		player.seek(player.get_animation(recipe.name).length*float(recipe.blend),true)
	elif mode == "cast":
		player.seek(minf(cast_time, mode_length), true)
	elif mode == "melee_charge":
		player.seek(0.02, true)
	elif mode=="burst_charge":
		player.seek(0.15+minf(1,mode_time/FLASH_CHARGE_TIME)*0.3,true)
	else:
		if mode in ["run", "chase", "dash"]:
			player.speed_scale = clampf(Vector2(velocity.x,velocity.z).length()/7.0,0.7,3.5) if team==2 and haste_time>0 else movement_multiplier()
		player.advance(delta)
	if not editor_animation_profile.is_empty() and not player.current_animation.is_empty():
		preload("res://scripts/editor_rig_pose.gd").sample(self,player.current_animation,player.current_animation_position)
	if editor_animation_profile.get("mirrored",false):preload("res://scripts/animation_mirror.gd").apply(self)
	# Turn the rig independently of its arm/leg clip. Casting and melee keep
	# evaluating normally, including their actual limb hitboxes and emit points.
	model.rotation.y=TAU*smoothstep(0.0,1.0,clampf((twist_age-TWIST_DELAY)/TWIST_DURATION,0,1)) if twist_age>=0 else 0.0
	if posing_custom_jump:
		if mode=="air":custom_jump_elapsed+=delta
		if custom_jump_native:
			var time:float=mode_time if mode=="takeoff" else 0.14+custom_jump_elapsed
			apply_custom_jump_pose(time/custom_jump_source_duration,custom_jump_frames,true)
		elif mode=="air":apply_custom_jump_pose(custom_jump_elapsed/0.95)
	if clip=="spells/idle" and custom_idle_frames.size()>=2:
		custom_idle_elapsed=fposmod(custom_idle_elapsed+delta,custom_idle_duration)
		apply_custom_jump_pose(custom_idle_elapsed/custom_idle_duration,custom_idle_frames,true)
	if posing_custom_motion:
		var progress:=mode_time/maxf(0.001,mode_length)
		if custom_motion_step=="Uppercut":progress=editor_attack_progress()
		apply_custom_jump_pose(clampf(progress,0,0.99999),custom_motion_frames,true)
	if mode=="cast" and not practice_spell_animation.is_empty():
		preload("res://scripts/spell_cast_motion.gd").pose(self,practice_spell_animation,clampf(cast_time/maxf(0.001,mode_length),0,0.9999))

func editor_uppercut_charge_duration() -> float:
	return 0.85

func editor_attack_progress() -> float:
	return mode_time/maxf(0.001,mode_length)

func is_custom_motion_active() -> bool:
	if custom_motion_frames.size()<2:return false
	match custom_motion_step:
		"Punch","Cross","Hook","Kick","Round Kick","Knee","Elbow","Sweep","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast":return mode=="punch"
		"Uppercut":return mode=="punch"
		"Run","Sprint","Dash":return mode=="motion_dash"
		"Crouch":return mode=="motion_pose"
		"Block","Brace Block":return mode=="shield"
		"Dodge Back","Dodge Left","Dodge Right":return mode=="dodge_back"
		"Roll Back":return mode=="roll_back"
		"Land":return mode=="land"
		"Flip","Twist":return mode=="air_trick" and air_trick==custom_motion_step
	return false

func apply_custom_jump_pose(progress: float,frames: Array=[],looping:=false) -> void:
	if frames.is_empty():frames=custom_jump_frames
	if frames.size()<2:return
	var scaled:=clampf(progress,0.0,1.0)*float(frames.size() if looping else frames.size()-1)
	var first:=int(floor(scaled))
	first=mini(first,frames.size()-1)
	var second: int=(first+1)%frames.size() if looping else mini(first+1,frames.size()-1)
	var blend:=scaled-float(first)
	var a: Dictionary=frames[first]
	var b: Dictionary=frames[second]
	var pelvic:Vector3=(a.get("pelvis_offset",Vector3.ZERO) as Vector3).lerp(b.get("pelvis_offset",Vector3.ZERO),blend)
	var pelvis_index:int=bones["pelvis"]
	skeleton.set_bone_pose_position(pelvis_index,skeleton.get_bone_pose_position(pelvis_index)+pelvic)
	for bone_name in a:
		if bone_name=="hands":continue
		if not bones.has(bone_name):continue
		var angle_a: Vector3=Vector3(a[bone_name])
		var angle_b: Vector3=Vector3(b.get(bone_name,a[bone_name]))
		var offset:=Quaternion.from_euler(angle_a*PI/180.0).slerp(Quaternion.from_euler(angle_b*PI/180.0),blend)
		var base_pose: Quaternion=skeleton.get_bone_pose_rotation(bones[bone_name])
		skeleton.set_bone_pose_rotation(bones[bone_name],(base_pose*offset).normalized())
	preload("res://scripts/hand_pose.gd").apply(self,preload("res://scripts/hand_pose.gd").blend(a.get("hands",{}),b.get("hands",a.get("hands",{})),blend))

func select_action() -> void:
	if arena.story_mode:
		if not is_on_floor():
			mode = "air"
			mode_time = 0
			return
		if not is_instance_valid(rival) or rival.health <= 0:
			return
		set_close_combat(true)
		if stamina < 14:
			start_recovery()
		elif flat_distance() > 1.05:
			mode = "chase"
			mode_time = 0
			mode_length = 0.45
			count_action("close_distance")
		elif has_story_ability("block") and guard_energy > 8.0 and rng.randf() < 0.16:
			GameDiagnostics.log_event("combat_action", {"fighter":str(rival.story_profile.get("name", "Rival")), "action":"block"})
			start_shield()
		elif has_story_ability("front_kick") and rng.randf() < 0.28:
			GameDiagnostics.log_event("combat_action", {"fighter":str(rival.story_profile.get("name", "Rival")), "action":"front_kick"})
			start_story_front_kick()
		else:
			var side := "left" if rng.randf() < 0.5 else "right"
			GameDiagnostics.log_event("combat_action", {"fighter":str(rival.story_profile.get("name", "Rival")), "action":"%s_punch" % side})
			start_story_punch(side)
		return
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
	if water_depth>0.5:
		swim_up()
		return
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

func has_story_ability(ability: String) -> bool:
	var abilities: Variant = story_profile.get("combat_abilities", [])
	return abilities is Array and abilities.has(ability)

func start_story_punch(side: String, charge: float=0.0, charge_profile:Dictionary={}, aim_direction:Vector3=Vector3.ZERO, aim_pitch:float=0.0) -> void:
	if not arena.story_mode:
		start_punch()
		return
	if health <= 0 or freeze_time > 0 or ice_trapped or stun_time > 0 or is_instance_valid(ragdoll):return
	if not player_controlled:
		if story_enemy_charge_active:
			if side!=story_enemy_charge_side and queued_story_punch.is_empty():queued_story_punch=side
			return
		if mode=="punch":
			if queued_story_punch.is_empty():queued_story_punch=side
			return
		if mode not in ["idle","run"]:return
		if not story_enemy_charge_resolving:
			story_enemy_charge_active=true
			story_enemy_charge_side=side
			story_enemy_charge_elapsed=0.0
			story_enemy_charge_duration=rng.randf_range(0.52,0.92)
			GameDiagnostics.log_event("rival_punch_charge_started",{"rival":story_profile.get("name","Rival"),"side":side,"duration":story_enemy_charge_duration})
			return
		begin_strike(["right_cross", "ual1/Punch_Cross", "hand_r", 0.16, 0.57, 11.0, 11.0, 1.0],charge) if side=="right" else begin_strike(["left_jab", "ual1/Punch_Jab", "hand_l", 0.12, 0.48, 8.0, 8.0, 1.0],charge)
		return
	var channel:="arm_r" if side=="right" else "arm_l"
	if story_block_held or story_limb_busy("right_arm" if side=="right" else "left_arm"):
		GameDiagnostics.log_event("combat_action_blocked", {"fighter":"player","action":"%s_punch"%side,"reason":"limb_busy" if story_limb_busy("right_arm" if side=="right" else "left_arm") else "blocking"})
		return
	var spec: Array = ["right_cross", "ual1/Punch_Cross", "hand_r", 0.16, 0.57, 11.0, 11.0, 1.0] if side=="right" else ["left_jab", "ual1/Punch_Jab", "hand_l", 0.12, 0.48, 8.0, 8.0, 1.0]
	var rate := 1.75 if side=="right" else 1.95
	var charge_value := clampf(charge, 0.0, 1.0)
	var stamina_cost := (5.0 if side=="right" else 3.5) * (1.0 + charge_value * 0.8)
	if not spend_stamina(stamina_cost):
		GameDiagnostics.log_event("combat_action_blocked", {"fighter":"player","action":"%s_punch"%side,"reason":"low_stamina"})
		return
	if not _play_story_limb_animation(channel, str(spec[1]), rate):return
	var damage_multiplier:=float(charge_profile.get("damage_multiplier",1.0))
	var critical:=bool(charge_profile.get("critical",false))
	var damage:=float(spec[5])*damage_multiplier*(2.0 if critical else 1.0)
	story_strikes[channel] = {"spec":spec,"clock":0.0,"rate":rate,"previous":bone_point(str(spec[2])),"connected":false,"damage":damage,"charge":charge_value,"length":player.get_animation(str(spec[1])).length,"charged_profile":charge_profile.duplicate(true),"pre_scaled":not charge_profile.is_empty(),"aim_direction":aim_direction,"aim_pitch":aim_pitch}
	melee_attempts += 1
	stamina_delay = minf(stamina_delay,0.28)
	count_action(str(spec[0]))
	GameDiagnostics.log_event("limb_action_started", {"limb":"right_arm" if side=="right" else "left_arm","action":spec[0],"locomotion_mode":mode,"airborne":not is_on_floor()})

func story_limb_busy(limb: String) -> bool:
	if story_block_held and limb in ["left_arm", "right_arm"]:return true
	var channel: String={"left_arm":"arm_l","right_arm":"arm_r","left_leg":"leg_l","right_leg":"leg_r","face":"face"}.get(limb,limb)
	if limb.ends_with("_leg") and is_on_floor() and (story_strikes.has("leg_l") or story_strikes.has("leg_r") or story_limb_reservations.has("leg_l") or story_limb_reservations.has("leg_r")):return true
	if story_strikes.has(channel) or story_limb_reservations.has(channel):return true
	return false

func start_story_limb_animation(limb: String, animation: String, speed: float = 1.0) -> bool:
	var channel: String={"left_arm":"arm_l","right_arm":"arm_r","left_leg":"leg_l","right_leg":"leg_r","face":"face"}.get(limb,limb)
	if not story_limb_players.has(channel) or story_limb_busy(limb):return false
	if not _play_story_limb_animation(channel,animation,speed):return false
	var source:Animation=player.get_animation(animation)
	story_limb_reservations[channel]=source.length/maxf(0.01,speed)
	GameDiagnostics.log_event("limb_action_started", {"limb":limb,"action":animation,"locomotion_mode":mode,"airborne":not is_on_floor()})
	return true

func start_story_block() -> bool:
	if not player_controlled or story_block_held or story_limb_busy("left_arm") or story_limb_busy("right_arm"):return false
	if not spend_stamina(7.0):return false
	story_block_held = true
	story_block_time = 0.0
	stamina_delay = 0.65
	for channel in ["arm_l", "arm_r"]:_play_story_limb_animation(channel, "duel/shield_hold_brace")
	GameDiagnostics.log_event("limb_action_started", {"limb":"both_arms","action":"block","locomotion_mode":mode,"airborne":not is_on_floor()})
	return true

func start_story_front_kick(charge_profile:Dictionary={},aim_direction:Vector3=Vector3.ZERO,aim_pitch:float=0.0) -> void:
	if not has_story_ability("front_kick"):
		return
	if player_controlled:
		var channel:="leg_r"
		if story_limb_busy("right_leg") or (is_on_floor() and story_limb_busy("left_leg")):
			GameDiagnostics.log_event("combat_action_blocked", {"fighter":"player","action":"front_kick","reason":"leg_busy"})
			return
		var spec:Array=["front_kick","boxing/front_kick_r","ball_r",0.25,0.48,15.0,15.0,1.35]
		if not spend_stamina(float(spec[6])):return
		if not _play_story_limb_animation(channel,str(spec[1]),1.45):return
		var multiplier:=float(charge_profile.get("damage_multiplier",1.0))
		var critical:=bool(charge_profile.get("critical",false))
		story_strikes[channel]={"spec":spec,"clock":0.0,"rate":1.45,"previous":bone_point(str(spec[2])),"connected":false,"damage":float(spec[5])*multiplier*(2.0 if critical else 1.0),"charge":0.0,"length":player.get_animation(str(spec[1])).length,"charged_profile":charge_profile.duplicate(true),"pre_scaled":not charge_profile.is_empty(),"aim_direction":aim_direction,"aim_pitch":aim_pitch}
		count_action("front_kick")
		GameDiagnostics.log_event("limb_action_started", {"limb":"right_leg","action":"front_kick","locomotion_mode":mode,"airborne":not is_on_floor()})
		return
	begin_strike(["front_kick", "boxing/front_kick_r", "ball_r", 0.25, 0.48, 15.0, 15.0, 1.35])

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
	if water_depth>0.5:
		swim_up()
		return not ice_trapped and freeze_time<=0 and stun_time<=0 and not drowned
	if not is_on_floor() or stamina<12 or health<=0:
		return false
	var carry:=motion_direction*minf(6,combo_speed) if combo_time>0 else drive_velocity.limit_length(6)
	start_jump("motion_jump")
	air_momentum=carry
	return mode=="takeoff"

func start_editor_motion(kind: String) -> bool:
	if not is_on_floor() or health<=0 or freeze_time>0 or is_instance_valid(ragdoll):return false
	if kind in ["Run","Sprint"]:
		if not spend_stamina(6 if kind=="Run" else 10):return false
		mode="motion_dash"
		mode_time=0
		mode_length=0.8
		motion_direction=global_basis.z.normalized()
		motion_speed=3.5 if kind=="Run" else 6.5
		combo_speed=0
		combo_time=0
		clip=""
		play("ual1/Jog_Fwd" if kind=="Run" else "duel/run",1.0 if kind=="Run" else 1.75)
	elif kind in ["Idle","Crouch"]:
		mode="motion_pose"
		mode_time=0
		mode_length=3.0 if kind=="Idle" else 0.9
		custom_idle_elapsed=0.0
		clip=""
		play("spells/idle" if kind=="Idle" else "ual1/Crouch_Idle")
	elif kind in ["Block","Brace Block"]:
		start_shield()
		if mode!="shield":return false
		guard_style="palm" if kind=="Block" else "brace"
		mode_length=1.0
		clip=""
		play("duel/shield_raise_"+guard_style)
	else:
		var cost:=18.0 if kind=="Roll Back" else 10.0
		if stamina<cost:return false
		start_footwork("roll_back" if kind=="Roll Back" else "dodge_back")
		if kind in ["Dodge Left","Dodge Right"]:
			air_momentum=global_basis.x*(7.8 if kind=="Dodge Left" else -7.8)
			clip=""
			play("duel/strafe_left" if kind=="Dodge Left" else "duel/strafe_right",3.0)
	count_action("editor_"+kind.to_snake_case())
	return true

func tick_motion_pose(delta: float) -> void:
	impact_physics.restore(skeleton)
	mode_time+=delta
	recover_resources(delta)
	velocity=Vector3(0,-0.1 if is_on_floor() else velocity.y-GRAVITY*delta,0)
	move_and_slide()
	advance_animation(delta)
	impact_physics.step(delta)
	impact_physics.apply(skeleton,is_on_floor(),global_basis)
	if mode_time>=mode_length:
		mode="idle"
		mode_time=0
		mode_length=0.1

func launch() -> void:
	if jump_kind!="motion_jump":
		super.launch()
		return
	velocity.y=10.8
	air_clock=0
	custom_jump_elapsed=0.0
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
	if clip=="ual1/Jog_Fwd":
		var pelvis: int=bones["pelvis"]
		var origin: Vector3=skeleton.get_bone_pose_position(pelvis)
		var rest: Vector3=skeleton.get_bone_rest(pelvis).origin
		origin.x=rest.x
		origin.z=rest.z
		skeleton.set_bone_pose_position(pelvis,origin)
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
	mode_length=BACKFLIP_DURATION if kind=="Flip" else TWIST_DELAY+TWIST_DURATION
	if kind=="Twist":twist_age=0
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
	impact_physics.step(delta)
	impact_physics.apply(skeleton,is_on_floor(),global_basis)
	if is_on_floor() or mode_time>=mode_length:
		mode="land" if is_on_floor() else "air"
		mode_time=0
		mode_length=0.24
		clip=""
		player.play("duel/land" if is_on_floor() else "duel/air",0)
		if is_on_floor():
			count_action("land")
			arena.movement_burst(self,true)

func begin_strike(spec: Array, charge: float=0.0) -> void:
	if editor_animation_profile.get("category","") in ["Punch","Kick","Knee","Elbow","Uppercut","Sweep","Slash"]:
		spec=spec.duplicate()
		spec[1]=editor_animation_profile.clip
		spec[2]=editor_animation_profile.get("attack_bone",spec[2])
	var linked_flash: bool=mode=="burst_dash"
	var powered: bool=team==2 and haste_time>0
	var story_punch: bool=arena.story_mode and str(spec[0]) in ["left_jab","right_cross"]
	var stamina_cost: float=float(spec[6])*(0.75 if powered else 1.0)
	if story_punch:
		stamina_cost=3.5 if str(spec[0])=="left_jab" else 5.0
		stamina_cost*=1.0+clampf(charge,0.0,1.0)*0.8
	if not spend_stamina(stamina_cost):
		start_recovery()
		return
	if story_punch:
		# Let a jab-cross combination happen without the recovery delay making
		# the player wait between every hand strike.
		stamina_delay=minf(stamina_delay,0.28)
	if not linked_flash:
		tactics.attack(self,"melee")
	melee_spec = spec
	attack_kind = spec[0]
	strike_damage = float(spec[5])*(1.35 if powered else 1.0)
	melee_charge=clampf(charge,0.0,1.0) if story_punch else 0.0
	if story_punch:strike_damage*=1.0+melee_charge*0.70
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
	melee_clock_rate=1.95 if story_punch and spec[0]=="left_jab" else (1.75 if story_punch else 1.25)
	play(spec[1], melee_clock_rate)
	mode_length = player.get_animation(spec[1]).length / melee_clock_rate + (0.035 if story_punch else 0.08)
	if custom_motion_frames.size()>=2 and custom_motion_step in ["Punch","Cross","Hook","Kick","Round Kick","Knee","Elbow","Sweep","Uppercut","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast"]:
		var original_length:=mode_length
		mode_length=maxf(0.08,float(editor_animation_profile.get("duration",mode_length)))
		melee_spec=melee_spec.duplicate()
		melee_spec[3]=float(melee_spec[3])*mode_length/original_length
		melee_spec[4]=float(melee_spec[4])*mode_length/original_length
	melee_previous = bone_point(spec[2])
	count_action(spec[0])

func start_uppercut(charged:=false) -> void:
	if not charged:
		melee_charge=0
		melee_sequence+=1
		begin_strike(["uppercut","battle/uppercut","hand_r",0.15,0.52,16.0,18.0,1.1])
		return
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
	if editor_animation_profile.get("category","")=="Uppercut":current_spell.hand=editor_animation_profile.get("attack_bone","hand_r")
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
	tactics.attack(self,"flash_step")
	count_action("flash_charge")

func tick(delta: float) -> void:
	if practice_wooden_dummy and health<=0.0:
		mode="ko"
		velocity=Vector3.ZERO
		return
	if drowned:
		if is_instance_valid(ragdoll):ragdoll.step(delta)
		return
	# Preview and live-practice controllers own the rig while this is set.
	if editor_pose_locked:return
	update_status(delta)
	if practice_immortal and (not practice_damageable_dummy or practice_god_mode) and not drowned and air_remaining>0:health=MAX_HEALTH
	stun_time=maxf(0,stun_time-delta)
	if stun_time>0 and health>0 and not is_instance_valid(ragdoll):
		invulnerability=maxf(0,invulnerability-delta)
		return_state="STUNNED  -  trying to return" if practice_return_enabled else ""
		mode="hit"
		mode_time=0
		mode_length=0.05
		drive_velocity=Vector3.ZERO
		velocity.x=move_toward(velocity.x,0,delta*20)
		velocity.z=move_toward(velocity.z,0,delta*20)
		velocity.y=-0.5 if is_on_floor() else velocity.y-GRAVITY*delta
		move_and_slide()
		play("fight/guard")
		advance_animation(delta)
		return
	if (freeze_time>0 or ice_trapped) and not is_instance_valid(ragdoll):
		tick_restrained(delta)
		return
	if twist_age>=0:
		if health<=0 or is_on_floor() or mode in ["hit","ragdoll","frozen","getup","ko"] or freeze_time>0:
			twist_age=-1
			model.rotation.y=0
		else:
			twist_age+=delta
			if twist_age>=TWIST_DELAY+TWIST_DURATION:
				twist_age=-1
				model.rotation.y=0
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
	if water_depth>1.1:
		tick_swimming(delta)
		return
	if practice_return_enabled and not brain_enabled and mode not in ["hit","cast","punch"]:
		tick_return_home(delta)
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
	if mode=="motion_pose" and freeze_time<=0:
		tick_motion_pose(delta)
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
			melee_charge = minf(1, mode_time / editor_uppercut_charge_duration())
			charge_value=melee_charge
			velocity.x = 0
			velocity.z = 0
			velocity.y=-0.1 if is_on_floor() and position.y<0.15 and velocity.y<=0 else velocity.y-GRAVITY*delta
			move_and_slide()
			if mode_time >= editor_uppercut_charge_duration():
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
	if story_enemy_charge_active:
		if freeze_time>0 or health<=0:
			story_enemy_charge_active=false
			GameDiagnostics.log_event("rival_punch_charge_cancelled",{"rival":story_profile.get("name","Rival"),"reason":"interrupted"})
		else:
			story_enemy_charge_elapsed+=delta
			if story_enemy_charge_elapsed>=story_enemy_charge_duration:
				var side:=story_enemy_charge_side
				var charged:=clampf(story_enemy_charge_elapsed,0.0,1.0)
				story_enemy_charge_active=false
				story_enemy_charge_side=""
				story_enemy_charge_resolving=true
				GameDiagnostics.log_event("rival_punch_charge_released",{"rival":story_profile.get("name","Rival"),"side":side,"elapsed":story_enemy_charge_elapsed})
				start_story_punch(side,charged)
				story_enemy_charge_resolving=false
	var finishing_story_punch: bool=arena.story_mode and mode=="punch"
	super.tick(delta)
	if finishing_story_punch and mode=="idle" and not queued_story_punch.is_empty() and health>0 and freeze_time<=0:
		var next_side:=queued_story_punch
		queued_story_punch=""
		start_story_punch(next_side)
	brain_enabled = enabled

func resolve_melee(delta: float) -> void:
	if arena.story_mode and player_controlled:
		_resolve_story_limb_strikes(delta)
		if mode != "punch":return
	if mode != "punch" or melee_spec.is_empty() or not arena.round_active or health <= 0:
		return
	var limb := bone_point(melee_spec[2])
	var movement := limb - melee_previous
	if not melee_connected and melee_clock >= melee_spec[3] and melee_clock <= melee_spec[4] and movement.length() / delta > 0.8:
		var shape := SphereShape3D.new()
		shape.radius = 0.22 if attack_kind in ["knee", "front_kick", "round_kick","sweep","stomp"] else 0.105
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.collision_mask = arena.enemy_hurt_mask(team)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var samples := maxi(1, ceili(movement.length() / 0.04))
		for i in range(samples + 1):
			var point := melee_previous.lerp(limb, float(i) / samples)
			if arena.spell_environment.damage_ice_near(point,strike_damage,0.22):
				melee_connected=true
				break
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
			var q := melee_charge if attack_kind in ["uppercut","left_jab","right_cross"] else 0.0
			if q > 0:
				impulse += Vector3.UP * 1250 * q
			var spec := {"id":attack_kind, "name":attack_kind.replace("_", " ").capitalize(), "effect":"melee", "damage":strike_damage * multiplier * (1+q*0.7), "charge":q, "launch":q>0.6, "combo":combo_time>0, "augment":strike_augmented or haste_time>0 or armor_time>0}
			if arena.story_mode and victim.shield_active() and victim.shield_intersection(melee_previous,limb,shape.radius).size()>0:
				arena.apply_melee_block(self,victim,point)
				melee_connected=true
				break
			melee_connected = arena.apply_impact(self, victim, spec, point, flat_direction(position, victim.position), area, impulse)
			if melee_connected:
				if combo_time > 0:
					dash_combo_hits += 1
				break
	melee_previous = limb

func _resolve_story_limb_strikes(delta: float) -> void:
	if health <= 0:return
	for side in story_strikes.keys():
		var strike: Dictionary = story_strikes[side]
		strike.clock = float(strike.clock) + delta * float(strike.rate)
		var spec: Array = strike.spec
		var limb: Vector3 = bone_point(str(spec[2]))
		var previous: Vector3 = strike.previous
		var movement := limb - previous
		var forward:Vector3=strike.get("aim_direction",global_basis.z)
		forward.y = 0
		forward = forward.normalized()
		var action_id := str(spec[0])
		var contact_radius:=0.22 if str(side).begins_with("leg_") else 0.105
		if arena.round_active and not strike.connected and float(strike.clock) >= float(spec[3]) and float(strike.clock) <= float(spec[4]) and movement.length() / maxf(delta, 0.0001) > 0.8 and movement.dot(forward) > 0.0005:
			var shape := SphereShape3D.new()
			shape.radius = contact_radius
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.collision_mask = arena.enemy_hurt_mask(team)
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var samples := maxi(1, ceili(movement.length() / 0.04))
			for sample in range(samples + 1):
				var point := previous.lerp(limb, float(sample) / float(samples))
				query.transform = Transform3D(Basis.IDENTITY, point)
				var results := get_world_3d().direct_space_state.intersect_shape(query, 8)
				if results.is_empty():continue
				var area: Area3D = results[0].collider
				var victim = area.get_meta("fighter")
				if victim.health <= 0:continue
				var speed: float = (movement / maxf(delta, 0.0001) - victim.velocity).length()
				var multiplier := 1.0 + clampf((speed - 5.0) / 8.0, 0, 2.5)
				var impulse := (movement / maxf(delta, 0.0001) * 8.0).limit_length(180) + forward * maxf(0, speed - 5) * 22
				var charge_value := float(strike.charge)
				if charge_value > 0:impulse += Vector3.UP * 1250 * charge_value
				var charged_profile:Dictionary=strike.get("charged_profile",{})
				var damage:=float(strike.damage)*multiplier if not bool(strike.get("pre_scaled",false)) else float(strike.damage)*multiplier
				if not bool(strike.get("pre_scaled",false)):damage*=1.0+charge_value*0.7
				var hit_spec := {"id":action_id,"name":action_id.replace("_", " ").capitalize(),"effect":"melee","damage":damage,"charge":charge_value,"critical":bool(charged_profile.get("critical",false)),"crit_chance":float(charged_profile.get("crit_chance",0.0)),"charge_tier":str(charged_profile.get("tier","NORMAL")),"launch":charge_value>0.6 or float(charged_profile.get("damage_multiplier",1.0))>=1.5,"combo":combo_time>0,"augment":strike_augmented or haste_time>0 or armor_time>0}
				if victim.shield_active() and victim.shield_intersection(previous, limb, shape.radius).size() > 0:
					arena.apply_melee_block(self, victim, point)
					strike.connected = true
					break
				strike.connected = arena.apply_impact(self, victim, hit_spec, point, forward, area, impulse)
				if strike.connected:
					melee_hits += 1
					melee_damage += float(hit_spec.damage)
					break
		strike.previous = limb
		if float(strike.clock) >= float(strike.length):
			var side_name:String={"arm_l":"left_arm","arm_r":"right_arm","leg_l":"left_leg","leg_r":"right_leg","face":"face"}.get(str(side),str(side))
			GameDiagnostics.log_event("limb_action_finished", {"limb":side_name,"action":spec[0],"connected":strike.connected})
			story_strikes.erase(side)
		else:
			story_strikes[side] = strike

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
			var damage := minf(health, burn_damage)
			health -= damage
			damage_taken += damage
			if is_instance_valid(burn_source):
				burn_source.damage_dealt += damage
			arena.events.append({"time":arena.elapsed,"event":"burn_tick","victim":team,"damage":damage})
			if health <= 0:
				enter_death(burn_source,Vector3.ZERO,bone_point("pelvis"))

func receive_status(attacker: CharacterBody3D, spec: Dictionary) -> void:
	# Story stage one is straight hand-to-hand combat; enemy team identity must
	# never accidentally apply its elemental freeze effect through augmented hits.
	if arena.story_mode:
		return
	if spec.has("projectile_element"):
		var potency:float=float(spec.get("potency",1.0))
		if potency<=0.0:return
		match str(spec.projectile_element):
			"Fire":
				burn_damage=1.5*potency
				burn_time=maxf(burn_time,4.0)
				burn_source=attacker
				burns_applied+=1
			"Ice":
				chill_time=3.5
				frost=minf(1.2,frost+0.4*potency)
				if frost>=1 and freeze_immunity<=0:
					freeze_time=1.25*potency
					freeze_immunity=1.25*potency+0.6
					frost=0.2
					freezes+=1
			"Lightning":stun_time=maxf(stun_time,0.7*potency)
		return
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
	if not practice_immortal:return receive_magic_impact(amount,direction,attacker,point,zone,bone,impulse)
	# Keep damage, guard, status and physical reactions; prevent lethal branches.
	var previous_health:=health
	var previous_damage:=damage_taken
	health=maxf(MAX_HEALTH,maxf(0,amount)+MAX_HEALTH+1)
	var landed:=receive_magic_impact(amount,direction,attacker,point,zone,bone,impulse)
	health=maxf(0.0,previous_health-(damage_taken-previous_damage)) if practice_damageable_dummy and not practice_god_mode else MAX_HEALTH
	return landed

func receive_magic_impact(amount: float, direction: Vector3, attacker: CharacterBody3D, point := Vector3.INF, zone := "chest", bone := "spine_03", impulse := Vector3.ZERO) -> bool:
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
	if practice_immortal and not drowned:
		health=0.0 if practice_damageable_dummy and not practice_god_mode else MAX_HEALTH
		return
	ko_count+=1
	death_age=0
	death_impulse=impulse
	freeze_time=0
	if not is_instance_valid(ragdoll):
		start_ragdoll(impulse,point)
	mode="ragdoll"
	arena.events.append({"time":arena.elapsed,"event":"death","team":team,"impulse":[impulse.x,impulse.y,impulse.z],"point":[point.x,point.y,point.z]})
	GameDiagnostics.log_event("fighter_death", {"team":team, "name":story_profile.get("name", "Fighter"), "attacker_team":attacker.team if is_instance_valid(attacker) else -1, "fight":arena.story_stage if arena.story_mode else 0})
	if not practice_immortal and not practice_damageable_dummy:arena.finish_round(attacker.team if is_instance_valid(attacker) else -1)

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
	if practice_wooden_dummy:return
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
	position = Vector3(location.x, arena.spell_environment.support_height(location)+0.02, location.z)
	velocity = Vector3.ZERO
	drive_velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	model.position = Vector3.ZERO
	mode = "getup"
	mode_time = 0
	clip="ual2/LayToIdle"
	player.play(clip,0,1.05)
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

func tick_return_home(delta:float) -> void:
	invulnerability=maxf(0,invulnerability-delta)
	var offset:Vector3=practice_home-global_position
	offset.y=0
	var blocked:bool=freeze_time>0
	return_state="FROZEN  -  trying to return" if blocked else ("SLIPPING  -  returning" if surface_slippery else "Returning to base")
	if offset.length()<0.12 and not blocked:
		return_state="At base"
		mode="idle"
		drive_velocity=Vector3.ZERO
		play("ual1/Idle" if practice_damageable_dummy else "fight/guard")
	else:
		mode="frozen" if blocked else "returning"
		rotation.y=lerp_angle(rotation.y,atan2(offset.x,offset.z),minf(1,delta*8))
		var desired:Vector3=offset.normalized()*minf(2.0,offset.length()*3)*(0.6 if chill_time>0 else 1.0)
		drive_velocity=Vector3.ZERO if blocked else drive_velocity.move_toward(desired,delta*(0.7 if surface_slippery else 12.0))
		play("fight/guard" if blocked else "duel/walk_forward",0.7 if chill_time>0 else 1.0)
	velocity.x=drive_velocity.x+knockback.x
	velocity.z=drive_velocity.z+knockback.z
	velocity.y=-0.5 if is_on_floor() else velocity.y-GRAVITY*delta
	knockback*=exp(-delta*(0.4 if surface_slippery else 4.2))
	move_and_slide()
	advance_animation(delta)

func tick_swimming(delta:float) -> void:
	invulnerability=maxf(0,invulnerability-delta)
	swim_cooldown=maxf(0,swim_cooldown-delta)
	if drowned or ice_trapped:return
	var desired:=Vector3.ZERO
	var blocked:bool=freeze_time>0 or stun_time>0
	if not blocked:
		var goal:Vector3=practice_home if practice_return_enabled else (rival.global_position if is_instance_valid(rival) else global_position)
		desired=(goal-global_position)*Vector3(1,0,1)
		desired=desired.limit_length(1.0)
	return_state="FROZEN" if freeze_time>0 else ("STUNNED" if stun_time>0 else "Swimming to base")
	mode="frozen" if freeze_time>0 else "swimming"
	if not blocked and water_depth>1.65 and swim_cooldown<=0:start_jump("swim")
	drive_velocity=drive_velocity.move_toward(desired,delta*2)
	velocity.x=drive_velocity.x+knockback.x
	velocity.z=drive_velocity.z+knockback.z
	velocity.y=clampf(velocity.y+(water_depth-1.25)*12*delta,-3,3)*exp(-delta*3)
	knockback*=exp(-delta*2)
	move_and_slide()
	play("fight/guard")
	advance_animation(delta)

func swim_up() -> void:
	if ice_trapped or freeze_time>0 or stun_time>0 or drowned:return
	velocity.y=maxf(velocity.y,4.0)
	swim_cooldown=0.65
	return_state="Swimming upward"

func update_breath(delta:float,submerged:bool) -> void:
	if drowned or health<=0:return
	if not submerged:
		air_remaining=minf(8.0,air_remaining+delta*3)
		return
	air_remaining=maxf(0,air_remaining-delta)
	if air_remaining>0:return
	var damage:float=minf(health,MAX_HEALTH*0.3*delta)
	health-=damage
	damage_taken+=damage
	# Environmental suffocation stays lethal in the immortal spell preview.
	if health<=0:
		drowned=true
		return_state="DROWNED"
		enter_death(null,Vector3.ZERO,bone_point("pelvis"))

func frozen_bones() -> Dictionary:
	var locked:Dictionary={}
	if freeze_time<=0 and not ice_trapped:return locked
	for index in skeleton.get_bone_count():
		var bone:String=skeleton.get_bone_name(index)
		if freeze_time>0 and (bone=="pelvis" or bone.begins_with("thigh_") or bone.begins_with("calf_") or bone.begins_with("foot_") or bone.begins_with("ball_")):locked[index]=true
		if not ice_trapped:continue
		var point:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(index).origin
		for block in arena.spell_environment.ice.values():
			if self not in block.trapped:continue
			var half:Vector3=block.get_child(0).shape.size*0.5
			var local:Vector3=block.to_local(point)
			if absf(local.x)<=half.x+0.05 and absf(local.z)<=half.z+0.05 and absf(local.y)<=half.y+0.05:locked[index]=true
	return locked

func capture_ice_pose() -> void:
	var locked:Dictionary=frozen_bones()
	for index in ice_pose.keys():
		if not locked.has(index):ice_pose.erase(index)
	for index in locked:
		if not ice_pose.has(index):ice_pose[index]=skeleton.get_bone_pose(index)

func restore_ice_pose() -> void:
	for index in ice_pose:skeleton.set_bone_pose(index,ice_pose[index])
	skeleton.force_update_all_bone_transforms()

func can_cast_with(spec:Dictionary,profile:Dictionary={}) -> bool:
	if drowned or health<=0 or stun_time>0:return false
	var emitter:String=str(spec.get("cast_limb",profile.get("attack_bone",spec.get("hand","hand_r"))))
	var required:Array=[]
	if emitter in ["mouth","head","Head"]:required=["Head"]
	elif emitter in ["both","hands"]:required=["upperarm_l","lowerarm_l","hand_l","upperarm_r","lowerarm_r","hand_r"]
	elif emitter.contains("leg") or emitter.contains("foot") or emitter.contains("calf") or emitter.contains("thigh"):
		var side:String="l" if emitter.ends_with("_l") else "r"
		required=["thigh_"+side,"calf_"+side,"foot_"+side]
	else:
		var side:String="l" if emitter.ends_with("_l") else "r"
		required=["upperarm_"+side,"lowerarm_"+side,"hand_"+side]
	var locked:Dictionary=frozen_bones()
	for bone in required:
		if locked.has(skeleton.find_bone(bone)):return false
	return true

func tick_restrained(delta:float) -> void:
	invulnerability=maxf(0,invulnerability-delta)
	capture_ice_pose()
	velocity=Vector3.ZERO
	drive_velocity=Vector3.ZERO
	knockback=Vector3.ZERO
	return_state="Ice restrains trapped limbs"
	mode_time+=delta
	recover_resources(delta)
	if mode=="cast":
		var anchored_rotation:Vector3=rotation
		var release:bool=tick_cast(delta)
		rotation=anchored_rotation
		if release:arena.cast_magic(self,current_spell,false)
	elif brain_enabled and mode_time>1.0:
		start_cast(false)
		mode_time=0
	else:
		mode="frozen"
	advance_animation(delta)
