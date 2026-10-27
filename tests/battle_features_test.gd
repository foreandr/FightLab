extends SceneTree
var field: Node3D
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func prepare(distance:=4.0) -> void:
	field.clear_battle_effects()
	field.warmup=0
	field.intermission=0
	field.round_active=true
	field.target_timer=999
	field.eliminated.clear()
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(-distance/2,0.02,0) if f.team==0 else (Vector3(distance/2,0.02,0) if f.team==1 else Vector3(0,0.02,7)))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
		f.rival=field.fighters[1 if f.team==0 else 0]
		f.rotation.y=PI/2 if f.team==0 else -PI/2
	await frames(6)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	await prepare()
	var a=field.fighters[0]
	var b=field.fighters[1]
	var c=field.fighters[2]
	check(field.fighters.size()==3 and field.enemy_hurt_mask(2)==24,"Free-for-all must expose every opponent and exclude own hurtboxes")
	for team in 3:
		check(field.profile_spells(team).size()==2,"Each fighter needs its own two-spell kit")
	a.mana=0
	var no_casts: int=field.casts.get("FIRE/fireball",0)
	field.cast_magic(a,field.KITS[0][0].duplicate(true),false)
	check(field.shots.is_empty() and field.casts.get("FIRE/fireball",0)==no_casts,"Empty mana must not create a free quick or held spell")
	a.mana=a.MAX_MANA
	# Quick release is faster than the previous 0.68/1.65 second windup.
	a.spell_cursor=0
	a.charge_requested=0
	var before: int=field.casts.get("FIRE/fireball",0)
	a.start_cast(false)
	await frames(20)
	check(field.casts.get("FIRE/fireball",0)==before+1,"Quick fireball must release within a third of a second")
	await prepare()
	a.spell_cursor=0
	a.charge_requested=1
	before=field.casts.get("FIRE/fireball",0)
	a.start_cast(false)
	await frames(35)
	check(a.cast_phase=="hold" and not a.did_release and a.charge_value>0.1,"A held cast must pause the gathering pose and build charge")
	check(field.casts.get("FIRE/fireball",0)==before,"Holding must not emit an early projectile")
	await frames(75)
	check(field.casts.get("FIRE/fireball",0)==before+1 and a.charged_casts>0,"Held spell must release exactly once with charge")
	await prepare()
	var quick: Dictionary=field.KITS[0][0].duplicate(true)
	quick.charge=0.0
	field.spawn_projectile(a,quick,a.bone_point("hand_r"))
	var small: Dictionary=field.shots[-1].duplicate()
	var charged: Dictionary=quick.duplicate()
	charged.charge=1.0
	field.spawn_projectile(a,charged,a.bone_point("hand_r"))
	var large: Dictionary=field.shots[-1]
	check(large.velocity.length()>small.velocity.length()*1.5 and large.radius>small.radius and large.mass>small.mass,"Charge must increase projectile speed, size and effective mass")
	check(field.damage_for(charged)>field.damage_for(quick) and field.mana_cost(charged)>field.mana_cost(quick),"Charge must increase damage and mana cost")
	# True rigid-body launch through a shattered forward guard.
	await prepare()
	b.start_shield()
	await frames(15)
	var recovery_before: int=b.recoveries_count
	field.apply_impact(a,b,charged,b.shield_center(),Vector3.RIGHT,null,Vector3.RIGHT*800)
	check(b.guard_energy==0 and is_instance_valid(b.ragdoll),"Charged impact must shatter an insufficient guard and enter ragdoll")
	if is_instance_valid(b.ragdoll):
		check(b.ragdoll.bodies.size()==11,"Ragdoll must contain eleven actual rigid bodies")
		for body in b.ragdoll.bodies.values():
			check(body is RigidBody3D,"Ragdoll body must be simulated by the physics server")
	var peak:=0.0
	for i in 420:
		await physics_frame
		if is_instance_valid(b.ragdoll):
			peak=maxf(peak,b.ragdoll.location().y)
	check(peak>2.0 and peak<15.0,"Charged launch must rise into the air and remain physically bounded")
	check(b.recoveries_count>recovery_before and not is_instance_valid(b.ragdoll),"A living ragdoll must collide, settle and get up")
	# Armor mitigates health damage without granting immunity.
	await prepare()
	field.cast_magic(b,field.KITS[1][0].duplicate(true),false)
	check(b.armor_hp==50 and b.mana==80,"Ice armor must be a funded temporary self-augmentation")
	var fist:={"id":"test_punch","name":"test punch","effect":"melee","damage":20.0,"charge":0.0}
	field.apply_impact(a,b,fist,b.bone_point("spine_03"),Vector3.RIGHT,null,Vector3.RIGHT*70)
	check(b.health>b.MAX_HEALTH-20 and b.health<b.MAX_HEALTH and b.armor_hp<50,"Armor must absorb part of an actual impact")
	await prepare()
	var health: float=b.health
	field.apply_impact(a,b,quick,b.bone_point("spine_03"),Vector3.RIGHT,null,Vector3.RIGHT*130)
	var after_hit: float=b.health
	await frames(75)
	check(b.burn_time>0 and b.health<after_hit and after_hit<health,"Fire must cause a lasting burn after impact")
	await prepare()
	var ray: Dictionary=field.KITS[1][1].duplicate(true)
	for i in 3:
		a.invulnerability=0
		field.apply_impact(b,a,ray,a.bone_point("spine_03"),Vector3.LEFT,null,Vector3.LEFT*35)
		await frames(13)
	check(a.chill_time>0 and a.freeze_time>0 and a.movement_multiplier()<1,"Repeated ice-beam contact must slow and freeze")
	await frames(120)
	check(a.freeze_time==0,"Freeze must expire rather than permanently lock the fighter")
	# Speed augmentation, dash-to-strike momentum, actual knees/kicks.
	await prepare()
	var base_speed: float=c.movement_multiplier()
	field.cast_magic(c,field.KITS[2][0].duplicate(true),false)
	check(c.movement_multiplier()>base_speed and c.movement_multiplier()>a.movement_multiplier(),"Storm overdrive must increase sprint speed")
	c.position=Vector3(-5,0.02,0)
	a.position=Vector3(0,0.02,0)
	c.rival=a
	c.rotation.y=PI/2
	var combos: int=c.dash_combo_hits
	c.melee_sequence=0
	c.start_burst()
	await frames(100)
	check(c.actions.get("forward_burst",0)>0 and c.dash_combo_hits>combos,"A forward dash must combo into a physically contacting strike")
	for index in [2,3]:
		await prepare(0.78 if index==3 else 1.15)
		a.melee_sequence=index
		var hits_before: int=a.melee_hits
		a.start_punch()
		await frames(75)
		check(a.melee_hits>hits_before,"Animated kick/knee must physically connect: "+str(index))
	await prepare(0.78)
	a.start_uppercut()
	await frames(105)
	check(a.mode!="melee_charge" and a.actions.get("uppercut",0)>0,"Charged uppercut must hold, then release into the real skeletal attack")
	check(b.ragdoll_count>0 and is_instance_valid(b.ragdoll),"A contacting charged uppercut must launch the victim into real ragdoll")
	# Audio buffers are non-silent signed PCM, with a bounded polyphonic pool.
	check(field.audio.voices.size()==12 and field.audio.played.size()>0,"Physical impacts need a bounded positional audio pool")
	for stream in field.audio.streams.values():
		check(stream.data.size()>2000 and stream.mix_rate==22050,"Synthesized Foley must contain reusable audio samples")
		var nonzero:=false
		for i in range(0,stream.data.size(),100):
			nonzero=nonzero or stream.data.decode_s16(i)!=0
		check(nonzero,"Impact sound must not be silent")
	await prepare()
	a.health=0
	field.finish_round(1)
	check(field.round_active,"One elimination must leave the two remaining enemies fighting")
	b.health=0
	field.finish_round(2)
	check(not field.round_active and field.wins[2]>0,"Only the last survivor wins the free-for-all")
	var round_before: int=field.round_number
	await frames(240)
	check(field.round_number==round_before+1 and a.health==a.MAX_HEALTH and a.mana==a.MAX_MANA,"Rematch must reset all three resource pools and status effects")
	if failures.is_empty():
		print("PASS: triad kits, quick/held casts, charge scaling/costs, guard shatter, rigid-body launch/recovery, armor, burn/freeze, dash combo, knees/kicks, audio and last-survivor rounds")
	field.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
