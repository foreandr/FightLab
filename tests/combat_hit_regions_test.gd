extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
const Regions=preload("res://scripts/combat_hit_regions.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("HIT REGIONS FAILED: "+message)
	quit(1)
	return false
func area_for(actor:Node,zone:String) -> Area3D:
	for pair in actor.targets+actor.limb_targets:
		if str(pair[0].get_meta("zone",""))==zone:return pair[0]
	return null
func reset_victim(victim:Node) -> void:
	victim.guard_energy=0;victim.armor_hp=0;victim.invulnerability=0
	victim.burn_time=0;victim.burn_clock=0
	victim.impact_physics.reset(victim.skeleton)
func run() -> void:
	change_scene_to_file("res://scenes/fight.tscn")
	await process_frame
	await process_frame
	var field=current_scene
	field.set_physics_process(false)
	field.round_active=true
	var actor=field.fighters[0]
	var victim=field.fighters[1]
	actor.velocity=Vector3.ZERO
	victim.practice_god_mode=true;victim.practice_immortal=true;victim.practice_damageable_dummy=true
	field.set_combat_hitboxes(true)
	field.set_combat_numbers(true)
	var overlays=field.character_hitbox_overlays
	var spell:Dictionary={"id":"region_fire_test","effect":"orb","projectile_element":"Fire","potency":2.0,"damage":10.0}
	var spec_before:=spell.duplicate(true)
	var reactions:Dictionary={}
	for zone in ["chest","head","pelvis","arm_l","leg_r"]:
		reset_victim(victim)
		field.clear_combat_numbers()
		overlays.clear_hits()
		var area:=area_for(victim,zone)
		if not check(is_instance_valid(area),"Missing receiving area: "+zone):return
		var before:float=victim.damage_taken
		if not check(field.apply_impact(actor,victim,spell,area.global_position,Vector3.BACK,area,Vector3.BACK*20),"Actual hit rejected: "+zone):return
		var expected:=20.0 if zone=="head" else 10.0
		if not check(is_equal_approx(victim.damage_taken-before,expected),"Wrong physical damage: "+zone):return
		var numbers=field.combat_numbers
		if not check(numbers.entries.size()==1,"Hit created duplicate physical numbers"):return
		var entry:Dictionary=numbers.entries[0]
		if not check(entry.label.text==("HEADSHOT 20" if zone=="head" else "10.0 physical"),"Wrong headshot/ordinary hit text"):return
		if zone=="head":
			if not check(entry.label.font_size==30 and entry.color==numbers.HEADSHOT_COLOR,"Headshot does not stand out like a critical hit"):return
			numbers._process(0.6)
			if not check(entry.label.modulate.r==entry.color.r and entry.label.modulate.a<1.0,"Headshot loses its color while fading"):return
		if not check(victim.clip==Regions.reaction(zone),"Wrong head/body reaction clip: "+zone):return
		if not check(is_equal_approx(victim.burn_damage,2.0*Burn.TICK_DAMAGE) and victim.burn_time==5.0,"Head region changed Fire potency/duration"):return
		victim.update_status(0.5)
		if not check(is_equal_approx(victim.damage_taken-before-expected,2.0*Burn.TICK_DAMAGE),"Burn tick received headshot multiplier"):return
		var flashed:=0
		for record in overlays.outlines.values():
			if not record.fill.visible:continue
			flashed+=1
			if not check(record.area_id==area.get_instance_id(),"A different region lights up"):return
		if not check(flashed>0,"Struck region did not light up"):return
		if zone in ["head","chest"]:
			Pose.pose(victim,{"clip":Regions.reaction(zone),"store_raw":true},0.3)
			reactions[zone]=Pose.capture(victim)
	if not check(spell==spec_before,"Region multiplier mutates the spell and can stack"):return
	for zone in ["head","chest"]:
		reset_victim(victim)
		var area:=area_for(victim,zone)
		var before:float=victim.damage_taken
		field.apply_impact(actor,victim,{"id":"region_punch","effect":"melee","damage":10.0},area.global_position,Vector3.BACK,area,Vector3.BACK*20)
		if not check(is_equal_approx(victim.damage_taken-before,20.0 if zone=="head" else 10.0),"Melee physical head/body damage differs from projectile rules"):return
	var head_bone:int=victim.bones.Head
	var chest_bone:int=victim.bones.spine_03
	if not check(not reactions.head[head_bone].is_equal_approx(reactions.chest[head_bone]) and not reactions.head[chest_bone].is_equal_approx(reactions.chest[chest_bone]),"Head and body reactions have the same sampled motion"):return
	overlays._process(Regions.FLASH_SECONDS+0.01)
	for record in overlays.outlines.values():
		if not check(not record.fill.visible,"Highlight did not fade back to the normal hitbox"):return
	# Real projectile collision must pick the head/body shape, not just direct calls.
	for zone in ["head","chest"]:
		reset_victim(victim)
		Pose.pose(victim,{"clip":"duel/walk_back","store_raw":true},0.0)
		victim.update_targets()
		await physics_frame
		var area:=area_for(victim,zone)
		var origin:Vector3=area.global_position+(Vector3.UP*1.2 if zone=="head" else Vector3.FORWARD*1.2)
		var direction:Vector3=(area.global_position-origin).normalized()
		var shot_spec:Dictionary={"id":"region_projectile","effect":"orb","projectile_element":"None","damage":10.0,"projectile_radius":0.1,"projectile_velocity":10.0,"mass":0.1,"aim_direction":direction}
		var before:float=victim.damage_taken
		field.spawn_projectile(actor,shot_spec,origin)
		for step in 60:
			field.step_shots(1.0/60.0)
			if field.shots.is_empty():break
		if not check(is_equal_approx(victim.damage_taken-before,20.0 if zone=="head" else 10.0),"Real projectile picked the wrong region: "+zone):return
		if not check(Regions.is_head(victim.last_hit_zone)==(zone=="head"),"Real projectile reported the wrong head/body region: expected=%s actual=%s"%[zone,victim.last_hit_zone]):return
	var head_area:=area_for(victim,"head")
	var layer:int=head_area.collision_layer
	field.set_combat_hitboxes(false)
	if not check(overlays.flashes.is_empty() and head_area.collision_layer==layer,"Hiding hitboxes changes collision or leaves flashes"):return
	for record in overlays.outlines.values():
		if not check(not record.node.visible and not record.fill.visible and (not is_instance_valid(record.label) or not record.label.visible),"Hidden hitboxes leave meshes or labels visible"):return
	field.set_combat_hitboxes(true)
	overlays.flash_hit(head_area)
	field.clear_battle_effects()
	if not check(overlays.flashes.is_empty(),"Reset leaves a stale region highlight"):return
	print("HIT REGIONS PASSED: physical head x2, other regions x1, actual head/body projectile collisions, unchanged Fire/burn, distinct sampled reactions, exact hitbox highlighting/expiry/toggle/reset and immutable spells")
	quit()
