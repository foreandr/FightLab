extends SceneTree
var field: Node3D
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func run() -> void:
	root.size=Vector2i(1152,720)
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	var bounded:=true
	var synchronized:=true
	var finite:=true
	var contained:=true
	var visible:=0
	var samples:=0
	var max_bodies:=0
	var max_body_speed:=0.0
	var quiet:=0.0
	var maximum_quiet:=0.0
	var dealt:=0.0
	for i in 10800:
		await physics_frame
		for f in field.fighters:
			bounded=bounded and f.health>=0 and f.health<=f.MAX_HEALTH and f.mana>=0 and f.mana<=f.MAX_MANA and f.stamina>=0 and f.stamina<=f.MAX_STAMINA and f.guard_energy>=0 and f.guard_energy<=f.MAX_GUARD
			synchronized=synchronized and absf(field.health_bars[f.team].value-f.health)<0.011 and absf(field.mana_bars[f.team].value-f.mana)<0.011
			finite=finite and f.focus_position().is_finite() and f.velocity.is_finite()
			contained=contained and Vector2(f.focus_position().x,f.focus_position().z).length()<field.Boundary.RADIUS+0.75
			if is_instance_valid(f.ragdoll):
				for body in f.ragdoll.bodies.values():
					max_body_speed=maxf(max_body_speed,body.linear_velocity.length())
					finite=finite and body.global_position.is_finite() and body.linear_velocity.length()<65
					contained=contained and Vector2(body.global_position.x,body.global_position.z).length()<field.Boundary.RADIUS+0.75
			if field.elapsed>2 and f.health>0:
				samples+=1
				if field.camera.is_position_in_frustum(f.bone_point("Head")):
					visible+=1
		var total_damage:=0.0
		for fighter in field.fighters:
			total_damage+=fighter.damage_dealt
		if field.round_active and field.elapsed>3:
			quiet=0.0 if total_damage>dealt+0.1 else quiet+1.0/60.0
			maximum_quiet=maxf(maximum_quiet,quiet)
		else:
			quiet=0
		dealt=total_damage
		if i%120==0:
			max_bodies=maxi(max_bodies,field.find_children("*","RigidBody3D",true,false).size())
	print("COMBAT longest interval without damage=",maximum_quiet)
	check(maximum_quiet<20,"Autonomous combat must keep making damage progress instead of falling into prolonged action/resource loops")
	check(bounded and synchronized,"All three health/resource pools must remain bounded and agree with their HUD")
	check(finite,"Rigid-body and animation state must remain finite with bounded physical velocities")
	check(contained,"All fighters and ragdoll parts must remain inside the finite arena")
	print("RAGDOLL max body speed=",max_body_speed)
	check(max_bodies<=33,"Ragdoll bodies must be cleaned up rather than accumulate across rounds")
	var coverage:=float(visible)/maxi(1,samples)
	print("TRIAD CAMERA coverage=",coverage)
	check(coverage>0.93,"Camera must keep living fighters in view through launches and target changes")
	check(field.round_number>=2,"Free-for-all must finish and automatically start another round")
	check(field.audio.played.get("punch",0)>0 and field.audio.played.get("kick",0)>0,"Actual fist and leg contacts must produce Foley")
	check(field.casts.get("FIRE/fireball",0)>0 and field.casts.get("FIRE/fire_slash",0)>0,"Fire must use only its fireball/slash kit")
	check(field.casts.get("ICE/ice_armor",0)>0 and field.casts.get("ICE/ice_beam",0)>0,"Ice must use armor and freezing beam")
	check(field.fighters[2].actions.get("forward_burst",0)>2 and field.fighters[2].dash_combo_hits>0,"Storm must land momentum-enhanced dash combos")
	check(field.fighters[1].burns_applied+field.fighters[2].burns_applied>0,"Fire impacts must apply lasting burn")
	check(field.fighters[0].freezes+field.fighters[2].freezes>0,"Ice beam must freeze an enemy in autonomous combat")
	check(field.fighters[0].charged_casts+field.fighters[1].charged_casts>0,"Autonomous casters must use held charges")
	var recoveries:=0
	for f in field.fighters:
		check(f.damage_dealt>40 and f.melee_hits>0,"Each of the three enemies must participate in the fight")
		recoveries+=f.recoveries_count
	check(recoveries>0,"Living launched fighters must recover from real ragdoll")
	check(field.peak_effects<400,"Transient spell visuals must stay bounded")
	field.write_report()
	if failures.is_empty():
		print("PASS: 180-second three-way combat, targeting, all kits, charge/status effects, physical combos, ragdoll recovery/cleanup, audio, rounds and camera")
	field.audio.stop_all()
	field.queue_free()
	for i in 3:
		await physics_frame
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
