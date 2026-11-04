extends SceneTree
const Rules=preload("res://scripts/combat_defense_rules.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PHYSICAL RAGDOLL FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	var world=load("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.setup_combat_services()
	var actor=world.spawn_combatant(0,Vector3.ZERO)
	var victim=world.spawn_combatant(1,Vector3(0,0,3))
	for sample in [[10.0,1000.0,false,false,false],[23.9,20.0,false,false,false],[24.0,20.0,true,false,false],[12.0,20.0,true,true,false],[11.9,20.0,false,true,false],[20.0,20.0,false,false,false],[1.0,20.0,true,false,true]]:
		victim.reset_fighter(Vector3(0,0,3))
		world.round_active=true
		victim.guard_energy=0
		victim.invulnerability=0
		victim.armor_hp=1000;victim.armor_time=100
		if sample[4]:victim.health=1
		var area:Area3D
		for pair in victim.targets:
			if str(pair[0].get_meta("zone",""))==("head" if sample[3] else "chest"):area=pair[0];break
		var before:float=victim.damage_taken
		var spec:Dictionary={"id":"ragdoll_threshold","effect":"orb","projectile_element":"None","damage":sample[0],"launch":true}
		world.apply_impact(actor,victim,spec,area.global_position,Vector3.BACK,area,Vector3.BACK*sample[1])
		if not check(is_instance_valid(victim.ragdoll)==sample[2],"Ragdoll does not follow actual physical damage/death: "+str(sample)):return
		var expected:float=sample[0]*(2.0 if sample[3] else 1.0)
		if not check(is_equal_approx(victim.damage_taken-before,expected),"Cosmetic armor reduced physical damage: sample=%s expected=%s actual=%s"%[sample,expected,victim.damage_taken-before]):return
	# Compile and land the actual perfect-knee recipe, rather than a synthetic 24.
	var animation:Dictionary={"duration":1.0,"source_duration":1.0,"group":"Attack","animation_type":"Leg","attack_bone":"calf_r"}
	var definition=preload("res://scripts/spell_definition.gd")
	var recipe:Dictionary=definition.make("None","Touch",{"size":0.5,"speed":0.5},{})
	var knee:Dictionary=definition.compile(recipe,animation,{"hold_seconds":preload("res://scripts/animation_charge_timing.gd").charge_window(animation)*1.1})
	if not check(is_equal_approx(knee.damage,24.0) and Rules.ragdolls(knee.damage),"Perfect knee does not reach the threshold"):return
	victim.reset_fighter(Vector3(0,0,3));victim.guard_energy=0;victim.invulnerability=0;world.round_active=true
	var chest:Area3D
	for pair in victim.targets:
		if str(pair[0].get_meta("zone",""))=="chest":chest=pair[0];break
	world.apply_impact(actor,victim,knee,chest.global_position,Vector3.BACK,chest,Vector3.BACK*20.0)
	if not check(victim.health>0 and is_instance_valid(victim.ragdoll),"Perfect knee failed to ragdoll a living body target"):return
	actor.armor_hp=0;actor.armor_time=0
	world.combat().dispatch(actor,{"id":"legacy_armor","effect":"armor"},actor.global_position)
	if not check(actor.armor_hp==0 and actor.armor_time==0,"Legacy armor grants combat protection"):return
	if not check(Rules.prediction(11.9)=="Ragdoll: No" and Rules.prediction(12)=="Ragdoll: Yes (head only)" and Rules.prediction(24)=="Ragdoll: Yes","Authoring prediction disagrees with live head/body thresholds"):return
	if not check(preload("res://scripts/combat_hit_regions.gd").label("head")=="" and preload("res://scripts/combat_hit_regions.gd").label("chest")=="","Floating hitbox labels remain"):return
	print("PHYSICAL RAGDOLL PASSED: 24 damage threshold, headshots, weak high-force/launch hits stay animated, strong low-force hits ragdoll, death ragdolls, cosmetic armor ignored, legacy armor disabled and predictions match")
	quit()
