extends SceneTree
func _initialize() -> void:
	set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PHYSICAL CONTACT VFX FAILED: "+message)
	quit(1)
	return false
func neutral_contact(vfx:Node) -> bool:
	if vfx.motes.size()!=13:return false
	for mote in vfx.motes:
		var texture:String=mote.node.texture.resource_path.get_file()
		if texture not in ["light_02.png","trace_02.png"] or mote.life>0.18 or mote.grow!=0.0:return false
	return true
func run() -> void:
	change_scene_to_file("res://scenes/cpu_duel.tscn")
	await process_frame
	await process_frame
	var field=current_scene
	field.set_physics_process(false)
	field.round_active=true
	var actor=field.fighters[0]
	var victim=field.fighters[1]
	actor.velocity=Vector3.ZERO
	victim.practice_god_mode=true
	victim.practice_immortal=true
	victim.practice_damageable_dummy=true
	for spec in [{"id":"contact_punch","effect":"melee","damage":10.0},{"id":"contact_projectile","effect":"orb","projectile_element":"None","damage":10.0}]:
		field.vfx.clear()
		victim.guard_energy=0;victim.armor_hp=0;victim.invulnerability=0
		var before:float=victim.damage_taken
		var point:Vector3=victim.bone_point("spine_03")
		if not check(field.apply_impact(actor,victim,spec,point,Vector3.BACK),"Actual physical impact failed"):return
		if not check(is_equal_approx(victim.damage_taken-before,10.0),"Presentation change altered physical damage"):return
		if not check(neutral_contact(field.vfx),"Actual physical hit still spawns elemental/explosion particles"):return
		field.vfx.step(0.2)
		if not check(field.vfx.motes.is_empty(),"Neutral contact lingers after impact"):return
	field.vfx.clear()
	field.spell_impact_burst(Vector3.ZERO,0,{"effect":"orb","projectile_element":"None"},false)
	if not check(neutral_contact(field.vfx),"Elementless ground contact uses fire"):return
	field.vfx.clear()
	field.vfx.burst(Vector3.ZERO,0,true)
	var flames:=0
	for mote in field.vfx.motes:
		if mote.node.texture.resource_path.get_file()=="flame_04.png":flames+=1
	if not check(flames>0,"Elemental particle implementation lost its fire burst"):return
	# The reusable base mode also supplies physical contact without a Story host.
	var world=load("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.setup_combat_services()
	world.spell_impact_burst(Vector3.ZERO,0,{"effect":"melee"},true)
	if not check(neutral_contact(world.vfx),"New-mode shared physical contact differs"):return
	print("PHYSICAL CONTACT VFX PASSED: actual melee/elementless hits keep damage and neutral contact, no flame/smoke/blast ring, quick cleanup, neutral ground impact, fire spell preserved and shared new-mode API")
	quit()
