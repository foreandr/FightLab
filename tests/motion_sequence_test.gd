extends SceneTree
var lab: Node3D
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:await physics_frame
func run() -> void:
	lab=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(lab)
	lab.camera_input_enabled=false
	check(lab.moves[lab.move_menu.selected].kind=="sequence","Sandbox should open on motion/combo testing")
	lab.distance_input.value=12
	for quick in [false,true]:
		for direction in 8:
			lab.set_motion_preset(false)
			lab.quick_dash_toggle.set_pressed_no_signal(quick)
			lab.dash_direction_menu.select(direction)
			lab.settings_changed()
			lab.run_setup()
			var origin: Vector3=lab.actor.position
			var facing: Basis=lab.actor.basis
			var victim_health: float=lab.target.health
			while lab.actor.mode!="motion_dash":await physics_frame
			while lab.actor.mode=="motion_dash":
				check(lab.actor.basis.z.dot(facing.z)>0.99,"Strafing/backward dashes must preserve facing during the dash")
				await physics_frame
			await frames(3)
			var delta: Vector3=lab.actor.position-origin
			delta.y=0
			var angle:=direction*PI/4
			var expected: Vector3=(facing.z*cos(angle)-facing.x*sin(angle)).normalized()
			check(delta.length()>2.8 and delta.length()<4.5,"Dash must move physically about 3.6m, direction="+str(direction))
			check(absf(delta.length()-3.6)<0.06,"Normal and quick dashes should cover the same distance")
			check(delta.normalized().dot(expected)>0.97,"Dash must travel in the selected relative direction "+str(direction))
			check(lab.target.health==victim_health,"A bare dash must not invent a contact hit")
			check(lab.sequence.history==["Dash"] and not lab.sequence.active,"Dash-only preset must not append an attack")
	# Watch the actual dash duration instead of an animation's post-dash idle time.
	var dash_durations: Array[float]=[]
	for quick in [false,true]:
		lab.set_motion_preset(false)
		lab.quick_dash_toggle.set_pressed_no_signal(quick)
		lab.settings_changed()
		lab.run_setup()
		while lab.actor.mode!="motion_dash":await physics_frame
		var duration:=0.0
		while lab.actor.mode=="motion_dash":
			duration+=1.0/60
			await physics_frame
		dash_durations.append(duration)
	check(dash_durations[1]<dash_durations[0]*0.75,"Quick dash must cover its distance faster")
	lab.set_motion_preset(false)
	lab.distance_input.value=0.7
	lab.settings_changed()
	lab.run_setup()
	await frames(80)
	check(lab.actor.combo_speed<1,"A dash blocked at its starting point must not gain free momentum")
	for quick in [false,true]:
		lab.set_motion_preset(true)
		lab.quick_dash_toggle.set_pressed_no_signal(quick)
		lab.distance_input.value=4.4
		lab.settings_changed()
		lab.run_setup()
		await frames(180)
		check(lab.sequence.history==["Dash","Knee"],"Dash must hand off into the selected knee in order")
		check(lab.target.damage_taken-lab.marks.damage>0,"Forward dash into knee must make a real animated-limb hit")
		check(lab.actor.dash_combo_hits>0,"Dash knee must retain momentum for physical impact")
		print("MOTION knee quick=",quick," damage=",lab.target.damage_taken-lab.marks.damage)
	lab.block_menu.select(2)
	lab.settings_changed()
	lab.run_setup()
	await frames(180)
	check(lab.target.blocks-lab.marks.blocks>0,"Dash knee must also interact with a real shield")
	lab.block_menu.select(0)
	lab.distance_input.value=12
	lab.settings_changed()
	lab.run_setup()
	await frames(180)
	check(lab.target.damage_taken==lab.marks.damage,"Distant dash knee must miss rather than award a proximity hit")
	lab.chain_menu[1].select(2)
	lab.distance_input.value=4.2
	lab.settings_changed()
	lab.run_setup()
	await frames(180)
	check(lab.sequence.history==["Dash","Punch"] and lab.target.damage_taken>lab.marks.damage,"Builder must chain dash into an actual punch")
	lab.chain_menu[1].select(4)
	lab.settings_changed()
	lab.run_setup()
	await frames(100)
	check(lab.sequence.history==["Dash","Jump"] and lab.seen.air,"Builder must chain dash into a plain jump")
	check(lab.actor.current_spell.is_empty() or lab.actor.mode!="cast","Plain jump must not secretly cast a spell")
	lab.chain_menu[2].select(2)
	lab.chain_menu[3].select(3)
	lab.settings_changed()
	lab.run_setup()
	await frames(500)
	check(lab.sequence.history==["Dash","Jump","Punch","Knee"] and not lab.sequence.active,"All four builder slots must execute in order and finish")
	lab.reset_setup()
	check(not lab.sequence.active and lab.sequence.history.is_empty() and paused,"Reset must clear queued combo steps and wait")
	lab.set_motion_preset(true)
	lab.run_setup()
	await frames(40)
	lab.actor.mode="hit"
	lab.sequence.tick(lab.actor,1.0/60)
	check(not lab.sequence.active and lab.sequence.status=="Combo interrupted","Hit reaction must interrupt queued steps")
	paused=false
	lab.queue_free()
	await frames(3)
	if failures.is_empty():print("PASS: eight-direction normal/quick physical dashes, facing, real dash knee/punch contacts, block/miss, jump chaining, reset and interruption")
	quit(0 if failures.is_empty() else 1)
