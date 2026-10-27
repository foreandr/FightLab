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
func prepare() -> void:
	field.clear_battle_effects()
	field.round_active=true
	field.warmup=0
	field.intermission=0
	field.target_timer=999
	field.eliminated.clear()
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(-5,0.02,0) if f.team==2 else (Vector3(0,0.02,0) if f.team==1 else Vector3(0,0.02,-6)))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
		f.rival=field.fighters[1 if f.team!=1 else 2]
	await frames(6)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	for sequence in [0,2,5]:
		await prepare()
		var f=field.fighters[2]
		f.melee_sequence=sequence
		f.start_burst()
		check(f.mode=="burst_charge" and f.flash_aura_time>0,"Flash Step must start with a brief charged power-up")
		await frames(10)
		check(f.mode=="burst_charge" and f.position.x<-4.9,"The charge must be visible before forward movement")
		var peak:=0.0
		var knee:=false
		for i in 80:
			await physics_frame
			peak=maxf(peak,Vector2(f.velocity.x,f.velocity.z).length())
			if f.mode=="punch":
				knee=knee or f.attack_kind=="knee"
		check(peak>33.9 and peak<34.1,"Flash Step must reach twice its previous speed")
		check(knee and f.dash_combo_hits>0,"Every Flash Step must automatically enter a real contacting knee regardless of move cursor")
		check(f.haste_time==0,"The brief Flash aura must not silently grant the fourteen-second Overdrive buff")
		await frames(100)
		check(not field.storm_aura.visible,"The temporary knee power-up aura must expire")
	await prepare()
	var storm=field.fighters[2]
	storm.position=Vector3(-10,0.02,0)
	storm.rival.position=Vector3(10,0.02,0)
	storm.haste_time=14
	storm.mode="chase"
	storm.mode_length=999
	var peak:=0.0
	for i in 90:
		await physics_frame
		peak=maxf(peak,Vector2(storm.velocity.x,storm.velocity.z).length())
	check(absf(peak-25.5)<0.1,"Real Overdrive locomotion must reach 75 percent of Flash Step speed")
	await prepare()
	storm=field.fighters[2]
	storm.stamina=20
	var mana: float=storm.mana
	field.cast_magic(storm,field.KITS[2][1].duplicate(true),false)
	check(storm.mana==mana and storm.mode=="review","An unfunded dash/knee chain must not consume spell mana")
	for team in 3:
		await prepare()
		var f=field.fighters[team]
		f.freeze_time=1
		await frames(2)
		check(field.freeze_effects[team].visible,"Frozen fighters need visible leg ice")
		for piece in field.freeze_effects[team].pieces:
			check(piece[1].begins_with("thigh_") or piece[1].begins_with("calf_") or piece[1].begins_with("foot_"),"Freeze casings must only attach to the legs and feet")
			check(piece[0].global_position.distance_to(f.bone_point(piece[1]).lerp(f.bone_point(piece[2]),0.5))<0.01,"Frozen leg ice must track the actual skeletal segment")
		for piece in field.armor_meshes[team]:
			check(not piece[0].visible,"Freeze must not display the torso armor effect")
		f.freeze_time=0
		f.armor_hp=50
		f.armor_time=6.5
		await frames(2)
		check(not field.freeze_effects[team].visible and field.armor_meshes[team][0][0].visible,"Glacial Armor and frozen leg casings must have separate lifetimes")
		check(field.freeze_effects[team].frost.shader!=field.water_material.shader,"Frozen legs must use a distinct frost material")
		# Recovery must not release at the cost of the next cheap attack.
		f.stamina=8
		f.mana=5
		f.mode="idle"
		f.select_action()
		check(f.tactics.banking and f.mode=="recover","Low resources must enter a committed recovery before attack shortcuts")
		await frames(12)
		check(f.player.current_animation_position>0.1,"Recovery walking must advance its animation instead of restarting the guard every frame")
		f.stamina=26
		f.select_action()
		check(f.tactics.banking and f.mode=="recover","Recovering fighters must keep saving instead of spending at the first cheap threshold")
		f.stamina=70
		f.select_action()
		check(not f.tactics.banking,"Recovery must end once a useful stamina reserve is ready")
	await prepare()
	var fire=field.fighters[0]
	fire.tactics.last_attack="fireball"
	fire.tactics.repeats=3
	fire.tactics.quiet_time=4
	fire.stamina=40
	fire.mana=20
	fire.select_action()
	check(fire.tactics.banking and fire.tactics.mana_target>=28,"Repeated ineffective attacks must save for a different funded action")
	fire.stamina=70
	fire.mana=35
	fire.select_action()
	check(not fire.tactics.banking and fire.mode=="cast" and fire.current_spell.id=="fire_slash" and fire.charge_goal>0,"After saving, the fighter must actually switch from repeated fireballs to a charged alternative")
	# Reproduce a genuine whiff loop: AI runs normally, but enemies cannot be hit.
	await prepare()
	fire=field.fighters[0]
	for enemy in field.fighters:
		if enemy==fire:
			continue
		for piece in enemy.targets:
			piece[0].collision_layer=0
		for piece in enemy.limb_targets:
			piece[0].collision_layer=0
	fire.brain_enabled=true
	fire.mode="idle"
	fire.mode_time=0
	fire.mode_length=0.01
	await frames(1440)
	check(fire.tactics.replans>0,"Real repeated misses must trigger saving and replanning during autonomous decisions")
	check(field.fighters[1].health==160 and field.fighters[2].health==160,"Replanning must not invent hits or force damage to create progress")
	if failures.is_empty():
		print("PASS: charged temporary Flash aura, 34m/s automatic knee, 25.5m/s Overdrive, funded chain, distinct leg-only freeze and resource/tactic hysteresis")
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
