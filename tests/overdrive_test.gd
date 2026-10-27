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
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(-5,0.02,0) if f.team==2 else (Vector3(0,0.02,0) if f.team==1 else Vector3(0,0.02,-6)))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
	field.fighters[2].rival=field.fighters[1]
	await frames(6)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	await prepare()
	var f=field.fighters[2]
	field.cast_magic(f,field.KITS[2][0].duplicate(true),false)
	check(f.haste_time==14 and f.mana==82,"Funded Overdrive must last fourteen seconds for the existing mana cost")
	await frames(2)
	check(field.storm_aura.visible,"Active Overdrive must have a persistent visible aura")
	var health: float=f.health
	f.receive_magic(20,Vector3.RIGHT,field.fighters[0],f.bone_point("spine_03"),"chest","spine_03",Vector3.RIGHT*70)
	check(is_equal_approx(health-f.health,15),"The powered mantle must reduce direct damage by one quarter without negating it")
	f.invulnerability=0
	var knees:=0
	var kicks:=0
	var fists:=0
	f.melee_sequence=0
	f.mana=0
	for i in 24:
		f.stamina=100
		f.start_punch()
		check(f.stamina>86 and f.strike_damage>10,"Powered strikes must gain stamina efficiency and impact damage")
		knees+=int(f.attack_kind=="knee")
		kicks+=int(f.attack_kind in ["front_kick","round_kick"])
		fists+=int(f.attack_kind in ["left_jab","right_cross","left_hook"])
		if f.attack_kind in ["knee","front_kick","round_kick"]:
			check(f.strike_augmented,"An already funded Overdrive must power its leg attacks without another mana payment")
	check(knees>kicks*2 and fists>0 and kicks>0,"Overdrive must favor knees while keeping fists and occasional kicks")
	f.mode="review"
	f.mode_length=999
	await frames(850)
	check(f.haste_time==0 and not field.storm_aura.visible,"The aura must expire with the real fourteen-second buff")
	f.haste_time=10
	f.health=0
	await frames(2)
	check(not field.storm_aura.visible,"A dead fighter must not retain a powered aura")
	await prepare()
	check(not field.storm_aura.visible,"Round reset must clear Overdrive visuals")
	field.cast_magic(f,field.KITS[2][0].duplicate(true),false)
	f.melee_sequence=0
	f.rotation.y=PI/2
	var before: int=f.dash_combo_hits
	f.start_burst()
	await frames(100)
	check(f.dash_combo_hits>before and f.actions.get("knee",0)>0,"A powered dash must physically connect its knee combo rather than stopping outside knee range")
	if failures.is_empty():
		print("PASS: fourteen-second funded Overdrive, knee-heavy mix, funded augmentation, aura lifetime/death/reset and actual dash-to-knee contact")
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
