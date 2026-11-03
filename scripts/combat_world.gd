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
var projectile_clash_count:=0
var vfx: Node3D
var shake := 0.0
var combat_numbers_visible:=false
var combat_numbers:Node3D
var surface_marks:Node3D
signal surface_impacted(surface:CollisionObject3D,point:Vector3,normal:Vector3,physical_damage:float,impulse:Vector3)

func surface_impact(surface:CollisionObject3D,point:Vector3,normal:Vector3,physical_damage:float,impulse:=Vector3.ZERO) -> MeshInstance3D:
	if not is_instance_valid(surface) or surface is CharacterBody3D or surface.has_meta("fighter") or normal.is_zero_approx() or not point.is_finite() or not normal.is_finite() or not is_finite(physical_damage):return null
	var damage:=maxf(0.0,physical_damage)
	surface_impacted.emit(surface,point,normal.normalized(),damage,impulse)
	if not preload("res://scripts/combat_defense_rules.gd").ragdolls(damage):return null
	if not is_instance_valid(surface_marks):
		surface_marks=preload("res://scripts/surface_impact_marks.gd").new()
		surface_marks.name="SurfaceImpactMarks"
		add_child(surface_marks)
	return surface_marks.add_impact(surface,point,normal,damage)

func clear_battle_effects()->void:
	clear_surface_impacts();clear_combat_numbers()
	if is_instance_valid(character_hitbox_overlays):character_hitbox_overlays.clear_hits()
	if is_instance_valid(vfx):vfx.clear()
	for collection in [shots,pulses,channels]:
		for item in collection:
			if is_instance_valid(item.get("node")):item.node.queue_free()
		collection.clear()

func clear_surface_impacts() -> void:
	if is_instance_valid(surface_marks):surface_marks.clear()

func set_combat_numbers(enabled:bool) -> void:
	combat_numbers_visible=enabled
	if not enabled:clear_combat_numbers()

func clear_combat_numbers() -> void:
	if is_instance_valid(combat_numbers):combat_numbers.clear()

func show_combat_number(actor:Node3D,kind:String,amount:float,headshot:bool=false) -> void:
	if not combat_numbers_visible or amount<=0.0001:return
	if not is_instance_valid(combat_numbers):
		combat_numbers=preload("res://scripts/combat_floating_numbers.gd").new()
		combat_numbers.name="CombatNumbers"
		add_child(combat_numbers)
	combat_numbers.show_amount(actor,kind,amount,headshot)

func fighter_hand(f: CharacterBody3D, hand: String) -> Vector3:
	return (f.bone_point("hand_l") + f.bone_point("hand_r")) * 0.5 if hand == "both" else f.bone_point(hand)

func spawn_projectile(f: CharacterBody3D, spec: Dictionary, origin: Vector3) -> void:
	combat().spawn_projectile(f,spec,origin)

func step_shots(delta: float) -> void:
	combat().step_shots(delta)

func projectile_clash_feedback(point:Vector3,result:Dictionary)->void:
	projectile_clash_count+=1
	var event:=result.duplicate();event["event"]="projectile_clash";event["time"]=elapsed;event["point"]=str(point);events.append(event)
	preload("res://scripts/combat_diagnostics.gd").event(self,"projectile_clash",event)
	if is_instance_valid(vfx):vfx.physical_contact(point)
	combat_sound("shield",point,0.55)

func apply_impact(attacker: CharacterBody3D, victim: CharacterBody3D, spec: Dictionary, point: Vector3, direction: Vector3, hit_area: Area3D = null, incoming_impulse := Vector3.ZERO) -> bool:
	return combat().apply_impact(attacker,victim,spec,point,direction,hit_area,incoming_impulse)

func damage_for(spec: Dictionary) -> float:
	return combat().damage_for(spec)

func mana_cost(spec: Dictionary) -> float:
	return preload("res://scripts/combat_spell_rules.gd").mana_cost(spec,100.0,combat_defaults)

func set_projectile_hitboxes(enabled:bool) -> void:
	set_combat_hitboxes(enabled)

func show_hit_region(area:Area3D) -> void:
	if is_instance_valid(character_hitbox_overlays):character_hitbox_overlays.flash_hit(area)

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
	if spec.effect=="spear" and not node.has_meta("look"):node.scale=Vector3(0.60,0.60,3.6)

func combat_sound(sound:String,point:Vector3,volume:float)->void:
	if is_instance_valid(audio):audio.impact(sound,point,volume)

func combat_cast_sound(spec:Dictionary,point:Vector3,volume:float=0.45,profile:Dictionary={})->void:
	if is_instance_valid(audio):audio.cast_accent(preload("res://scripts/spell_asset_library.gd").sound_for(spec),point,volume,preload("res://scripts/spell_audio_rules.gd").release_window(spec,profile))

func combat_impact_feedback(attacker:CharacterBody3D,victim:CharacterBody3D,spec:Dictionary,point:Vector3,_direction:Vector3,_area:Area3D,result:Dictionary) -> void:
	var key:="%s/%s"%[attacker.team,spec.get("id","unknown")]
	hits[key]=hits.get(key,0)+1
	events.append({"time":elapsed,"event":"hit","team":attacker.team,"victim":victim.team,"spell":spec.get("id","unknown"),"zone":result.zone,"damage":result.damage})
	spell_impact_burst(point,attacker.team,spec,true)

func spell_impact_burst(point:Vector3,team:int,spec:Dictionary,connected:bool) -> void:
	if str(spec.get("effect",""))=="melee" or str(spec.get("projectile_element",""))=="None":
		if is_instance_valid(vfx):vfx.physical_contact(point)
	else:impact_burst(point,team,connected)

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
		preload("res://scripts/block_shatter_effect.gd").show_for(defender)
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
var level:Resource=preload("res://scripts/combat_level.gd").new()
var level_root:Node3D
# Compatibility adapter for older scripts; new code uses the level interface.
var combat_radius:float:
	get:return float(level.radius) if level.bounds==preload("res://scripts/combat_level.gd").Bounds.CIRCLE else INF
	set(value):
		level=level.duplicate(true)
		level.bounds=preload("res://scripts/combat_level.gd").Bounds.CIRCLE
		level.radius=value

func use_level(root:Node3D,definition:Resource=null) -> void:
	level_root=root
	if definition==null and is_instance_valid(root) and root.has_method("combat_level_definition"):definition=root.combat_level_definition()
	level=definition.duplicate(true) if definition!=null else preload("res://scripts/combat_level.gd").new()

func level_frame() -> Transform3D:
	return level_root.global_transform if is_instance_valid(level_root) else Transform3D.IDENTITY

func ground_contact(point:Vector3) -> Dictionary:
	return level.ground(self,point,level_frame())

func ground_height(point:Vector3) -> float:
	return float(ground_contact(point).position.y)

func constrain_to_level(point:Vector3,margin:float=0.4) -> Vector3:
	return level.constrain(point,level_frame(),margin)

func level_inward(point:Vector3,ratio:float=1.0) -> Vector3:
	return level.inward(point,level_frame(),2.0,ratio)

func level_spawn(index:int,fallback:Vector3=Vector3.ZERO) -> Vector3:
	return level.spawn(index,level_frame(),fallback)

func level_point(offset:Vector3=Vector3.ZERO) -> Vector3:
	return level_frame()*(level.center+offset)

func surface_placement(point:Vector3,margin:float=0.4) -> Vector3:
	var result:=constrain_to_level(point,margin)
	result.y=ground_height(result)+0.02
	return result

func pick_level_surface(camera_:Camera3D,pointer:Vector2) -> Variant:
	var origin:=camera_.project_ray_origin(pointer)
	var end:=origin+camera_.project_ray_normal(pointer)*2000.0
	var query:=PhysicsRayQueryParameters3D.create(origin,end,level.GROUND_COLLISION_MASK)
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else null

func move_character(actor:CharacterBody3D,direction:Vector3,speed:float,delta:float) -> void:
	actor.velocity.x=direction.x*speed
	actor.velocity.z=direction.z*speed
	actor.velocity.y=-0.1 if actor.is_on_floor() and actor.velocity.y<=0 else actor.velocity.y-actor.GRAVITY*delta
	actor.move_and_slide()
	actor.global_position=constrain_to_level(actor.global_position,1.0)
	settle_actor_on_ground(actor)

func is_impact_wall(collider:Object,normal:Vector3) -> bool:
	return collider is CollisionObject3D and (collider.collision_layer&int(level.GROUND_COLLISION_MASK))!=0 and absf(normal.y)<0.5 and not collider.get_meta("combat_no_wall_impact",false)

func settle_actor_on_ground(actor:CharacterBody3D) -> void:
	if actor.velocity.y>0:return
	var contact:=ground_contact(actor.global_position)
	var penetration:float=contact.position.y-actor.global_position.y
	if not contact.get("missing",false) and contact.normal.y>0.7 and penetration>0.0 and penetration<0.08:
		actor.global_position.y=contact.position.y
		actor.velocity.y=0.0
		actor.apply_floor_snap()

func moving_surface_contact(point:Vector3,velocity:Vector3) -> Dictionary:
	if velocity.length_squared()<0.0001:return ground_contact(point)
	var direction:=velocity.normalized()
	var query:=PhysicsRayQueryParameters3D.create(point-direction*0.65,point+direction*0.4,level.GROUND_COLLISION_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query)

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

func _enter_tree()->void:
	call_deferred("_enter_music_context")

func _enter_music_context()->void:
	if not is_inside_tree():return
	var music:=get_tree().root.get_node_or_null("SharedMusic")
	if music:music.enter_context("combat",self)
