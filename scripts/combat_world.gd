extends Node3D
## Minimal reusable host for a combat mode. Register actors, supply input/camera,
## call combat().release or cast_magic; this base advances combat automatically.
var story_mode := false
var story_profile: Dictionary = {}
var audio: Node3D
var camera_focus_target: CharacterBody3D
var story_stage := 1
var editor_animation_only:=false
var shots: Array = []
var elapsed := 0.0
var camera: Camera3D
var casts := {}
var hits := {}
var heals := 0
var events: Array = []
var status := "Preparing"
var combat_defaults:Dictionary=preload("res://scripts/combat_spell_rules.gd").BATTLE_DEFAULTS
var _combat_runtime:RefCounted
var spell_environment:Node3D
var projectile_hitboxes_visible:=false
var character_hitbox_overlays:Node
var projectile_impact_predictor=preload("res://scripts/projectile_impact_predictor.gd").new()
var projectile_area_impact=preload("res://scripts/projectile_area_impact.gd").new()
var fighters: Array = []
var channels: Array = []
var pulses: Array = []
var round_active := false
var shot_serial := 0
var vfx: Node3D
var shake := 0.0

func fighter_hand(f: CharacterBody3D, hand: String) -> Vector3:
	return (f.bone_point("hand_l") + f.bone_point("hand_r")) * 0.5 if hand == "both" else f.bone_point(hand)

func spawn_projectile(f: CharacterBody3D, spec: Dictionary, origin: Vector3) -> void:
	combat().spawn_projectile(f,spec,origin)

func step_shots(delta: float) -> void:
	combat().step_shots(delta)

func apply_impact(attacker: CharacterBody3D, victim: CharacterBody3D, spec: Dictionary, point: Vector3, direction: Vector3, hit_area: Area3D = null, incoming_impulse := Vector3.ZERO) -> bool:
	return combat().apply_impact(attacker,victim,spec,point,direction,hit_area,incoming_impulse)

func damage_for(spec: Dictionary) -> float:
	return combat().damage_for(spec)

func mana_cost(spec: Dictionary) -> float:
	return preload("res://scripts/combat_spell_rules.gd").mana_cost(spec,100.0,combat_defaults)

func set_projectile_hitboxes(enabled:bool) -> void:
	set_combat_hitboxes(enabled)

func set_combat_hitboxes(enabled:bool) -> void:
	projectile_hitboxes_visible=enabled
	for shot in shots:_update_projectile_hitbox(shot)
	if enabled and not is_instance_valid(character_hitbox_overlays):
		character_hitbox_overlays=preload("res://scripts/character_hitbox_overlays.gd").new()
		character_hitbox_overlays.name="CharacterHitboxOverlays"
		character_hitbox_overlays.field=self
		add_child(character_hitbox_overlays)
	if is_instance_valid(character_hitbox_overlays):character_hitbox_overlays.set_enabled(enabled)

func _update_projectile_hitbox(shot:Dictionary) -> void:
	if not is_instance_valid(shot.node):return
	var outline:MeshInstance3D=shot.get("hitbox_outline")
	if projectile_hitboxes_visible and not is_instance_valid(outline):
		outline=preload("res://scripts/projectile_hitbox_outline.gd").new()
		outline.configure(float(shot.radius))
		shot.node.add_child(outline)
		shot["hitbox_outline"]=outline
	if is_instance_valid(outline):
		outline.visible=projectile_hitboxes_visible
		outline.global_position=shot.node.global_position

func combat() -> RefCounted:
	if _combat_runtime==null:_combat_runtime=preload("res://scripts/combat_runtime.gd").new(self)
	return _combat_runtime

func projectile_launch_state(caster:CharacterBody3D,spec:Dictionary,origin:Vector3) -> Dictionary:
	return combat().projectile_launch_state(caster,spec,origin)

func predict_projectile_impact(caster:CharacterBody3D,spec:Dictionary,origin:Vector3) -> Dictionary:
	return combat().predict_projectile_impact(caster,spec,origin)

func enemy_hurt_mask(team:int) -> int:
	var mask:=0
	for fighter in fighters:
		if fighter.team!=team:mask|=8<<fighter.team
	return mask

func projectile_visual(_actor:CharacterBody3D,spec:Dictionary,radius:float) -> MeshInstance3D:
	return preload("res://scripts/basic_projectile.gd").visual(str(spec.get("projectile_element","None")),radius,spec.get("appearance",{}))

func orient_projectile(node:MeshInstance3D,spec:Dictionary,origin:Vector3,direction:Vector3) -> void:
	if spec.effect in ["slash","cleave"] and is_instance_valid(camera):node.look_at(camera.global_position)
	elif not direction.is_zero_approx():node.look_at(origin+direction,Vector3.FORWARD if absf(direction.normalized().dot(Vector3.UP))>0.95 else Vector3.UP)
	if spec.effect=="cleave":node.rotate_object_local(Vector3.FORWARD,PI/2)
	if spec.effect=="spear":node.scale=Vector3(0.60,0.60,3.6)

func combat_sound(sound:String,point:Vector3,volume:float) -> void:
	if is_instance_valid(audio):audio.impact(sound,point,volume)

func combat_impact_feedback(attacker:CharacterBody3D,victim:CharacterBody3D,spec:Dictionary,_point:Vector3,_direction:Vector3,_area:Area3D,result:Dictionary) -> void:
	var key:="%s/%s"%[attacker.team,spec.get("id","unknown")]
	hits[key]=hits.get(key,0)+1
	events.append({"time":elapsed,"event":"hit","team":attacker.team,"victim":victim.team,"spell":spec.get("id","unknown"),"zone":result.zone,"damage":result.damage})

func projectile_aim_target(actor:CharacterBody3D,spec:Dictionary,origin:Vector3,_speed:float) -> Vector3:
	var direction:Vector3=spec.get("aim_direction",actor.global_basis.z)
	return origin+direction.normalized()*preload("res://scripts/basic_projectile.gd").AIM_DISTANCE

func impact_burst(_point:Vector3,_team:int,_connected:bool) -> void:
	pass

func heal_target(actor:CharacterBody3D) -> CharacterBody3D:
	return actor

func combat_target(actor:CharacterBody3D) -> CharacterBody3D:
	if is_instance_valid(actor.rival) and actor.rival.health>0:return actor.rival
	for other in fighters:
		if other!=actor and other.team!=actor.team and other.health>0:return other
	return null

func element_color(_team:int) -> Color:
	return Color("ff7138")

func closest_hit_area(results:Array,point:Vector3) -> Area3D:
	var best:Area3D
	var distance:=INF
	for result in results:
		var area:Area3D=result.collider
		var fighter=area.get_meta("fighter")
		var current:float=fighter.contact_surface(area,point).distance_to(point)
		if current<distance:
			distance=current
			best=area
	return best

func combat_cast_feedback(actor:CharacterBody3D,spec:Dictionary) -> void:
	var key:="%s/%s"%[actor.team,spec.get("id","unknown")]
	casts[key]=casts.get(key,0)+1
	events.append({"time":elapsed,"event":"cast","team":actor.team,"spell":spec.get("id","unknown"),"mana":actor.mana})

func combat_heal_feedback(_caster:CharacterBody3D,_recipient:CharacterBody3D,_spec:Dictionary,_restored:float) -> void:
	pass

func cast_magic(actor:CharacterBody3D,spec:Dictionary,_air:bool) -> void:
	combat().cast(actor,spec)

func summon_earth(caster:CharacterBody3D,spec:Dictionary) -> StaticBody3D:
	if not is_instance_valid(spell_environment):return null
	return spell_environment.summon_earth_wall(caster.global_position+caster.global_basis.z*3.0,caster.global_basis.z,float(spec.get("summon_radius",1.0)),float(spec.get("potency",1.0)))

func tick_combat(delta:float) -> void:
	elapsed+=delta
	combat().step_actors(delta)
	combat().step_shots(delta)
	combat().step_channels(delta)
	combat().step_pulses(delta)

func _physics_process(delta:float) -> void:
	tick_combat(delta)

func apply_melee_block(attacker: CharacterBody3D, defender: CharacterBody3D, point: Vector3) -> void:
	var cost:=6.0+float(attacker.get("melee_charge"))*4.0
	attacker.spend_stamina(cost)
	attacker.stamina_delay=0.9
	attacker.minimum_stamina=minf(attacker.minimum_stamina,attacker.stamina)
	defender.guard_energy=maxf(0,defender.guard_energy-8.0)
	defender.guard_recovery=1.1
	defender.blocks+=1
	defender.shield_recoil=0.24
	defender.clip=""
	defender.play("duel/shield_hit_brace",1.25)
	if defender.guard_energy<=0:
		defender.guard_breaks+=1
		defender.guard_cooldown=2.2
		defender.mode="hit"
		defender.mode_time=0
		defender.mode_length=0.24
	if attacker.has_method("start_block_recoil"):attacker.start_block_recoil(0.30)
	preload("res://scripts/combat_diagnostics.gd").event(self,"melee_block",{"attacker":str(attacker.name),"defender":str(defender.name),"stamina_cost":cost,"guard_remaining":defender.guard_energy})
	impact_burst(point,defender.team,false)

func incoming_threat(f: CharacterBody3D) -> int:
	for shot in shots:
		if shot.caster.team == f.team:
			continue
		var toward: Vector3 = f.position + Vector3.UP - shot.node.position
		if toward.length() < 5.0 and shot.velocity.normalized().dot(toward.normalized()) > 0.65:
			return shot.id
	return -1

signal combat_finished(winner:int)
var combat_radius:float=preload("res://scripts/gladiatorial_pit_config.gd").FLOOR_RADIUS

func _ready() -> void:
	setup_combat_services()

func setup_combat_services() -> void:
	if not is_instance_valid(vfx):
		vfx=preload("res://scripts/battle_vfx.gd").new()
		add_child(vfx)
		vfx.camera=camera
	if not is_instance_valid(audio):
		audio=preload("res://scripts/combat_audio.gd").new()
		add_child(audio)
	if not is_instance_valid(spell_environment):
		spell_environment=preload("res://scripts/spell_environment.gd").new()
		spell_environment.arena=self
		add_child(spell_environment)

func spawn_combatant(team:int,location:Vector3,profile:Dictionary={}) -> CharacterBody3D:
	setup_combat_services()
	var actor=load("res://scripts/battle_actor.gd").new()
	actor.arena=self
	actor.team=team
	actor.story_profile=profile.duplicate(true)
	actor.position=location
	add_child(actor)
	fighters.append(actor)
	actor.reset_fighter(location)
	for fighter in fighters:fighter.rival=combat_target(fighter)
	return actor

func profile_spells(_team:int) -> Array:
	return [preload("res://scripts/combat_spell_rules.gd").neutral_projectile()]

func finish_round(winner:int) -> void:
	round_active=false
	combat_finished.emit(winner)

func movement_burst(_actor:CharacterBody3D,_landing:bool) -> void:
	pass

func speed_trail(_actor:CharacterBody3D) -> void:
	pass

func shield_impact(actor:CharacterBody3D,point:Vector3,broken:bool) -> void:
	combat_sound("shatter" if broken else "shield",point,0.85)
	impact_burst(point,actor.team,false)

func step_channels(delta:float) -> void:
	combat().step_channels(delta)

func step_pulses(delta:float) -> void:
	combat().step_pulses(delta)
