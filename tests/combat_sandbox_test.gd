extends SceneTree
var sandbox: Node3D
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
func select_move(id: String) -> void:
	for i in sandbox.moves.size():
		if sandbox.moves[i].id==id:
			sandbox.move_menu.select(i)
			sandbox.settings_changed()
			return
	check(false,"Missing menu move: "+id)
func clear_options() -> void:
	for toggle in [sandbox.jump_toggle,sandbox.charge_toggle]:
		toggle.set_pressed_no_signal(false)
	sandbox.block_menu.select(0)
	sandbox.settings_changed()
func play_case() -> Dictionary:
	sandbox.run_setup()
	await frames(545)
	return sandbox.results[-1]
func run() -> void:
	sandbox=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(sandbox)
	select_move("fireball_ground")
	await frames(65)
	check(not sandbox.started and not sandbox.armed and paused,"Sandbox must wait for Run instead of cycling attacks")
	for node in sandbox.field.shields+sandbox.field.charges:
		check(not node.visible,"Ready stage must hide uninitialized shared effect meshes")
	check(sandbox.moves.size()>=29,"Menu must include every current spell and physical/defense/movement actions")
	sandbox.distance_input.value=8.2
	check(absf(sandbox.actor.position.distance_to(sandbox.target.position)-8.2)<0.001,"Changing distance must spawn fighters that far apart")
	sandbox.distance_input.value=4.4
	var quick: Dictionary=await play_case()
	check(quick.damage>0,"Selected Fireball must use real projectile contact")
	sandbox.charge_toggle.set_pressed_no_signal(true)
	sandbox.settings_changed()
	var charged: Dictionary=await play_case()
	check(charged.damage>quick.damage,"Charge toggle must increase actual Fireball damage")
	sandbox.block_menu.select(1)
	sandbox.charge_toggle.set_pressed_no_signal(false)
	sandbox.settings_changed()
	var blocked: Dictionary=await play_case()
	check(blocked.blocks>0 and blocked.damage==0,"Partner block selection must absorb a real Fireball")
	clear_options()
	sandbox.jump_toggle.set_pressed_no_signal(true)
	sandbox.settings_changed()
	check(sandbox.charge_toggle.disabled,"Unsupported held jump charge must be clearly disabled")
	var airborne: Dictionary=await play_case()
	check(airborne.seen.air and airborne.damage>0,"Caster jump toggle must perform a real airborne Fireball")
	clear_options()
	sandbox.block_menu.select(4)
	sandbox.settings_changed()
	sandbox.run_setup()
	await frames(60)
	check(sandbox.target.position.y>0.8 and sandbox.partner_air_ready,"Partner jump toggle must lift the passive partner")
	check(sandbox.target.mode=="shield","A jumping partner must also be able to block")
	check(not sandbox.target.brain_enabled,"Jumping partner must stay passive")
	sandbox.toggle_pause()
	var held_age: float=sandbox.age
	await frames(20)
	check(is_equal_approx(held_age,sandbox.age),"Pause must stop the configured test")
	sandbox.reset_setup()
	check(paused and not sandbox.armed and sandbox.actor.health==sandbox.actor.MAX_HEALTH and sandbox.target.health==sandbox.target.MAX_HEALTH,"Reset must restore health and wait for Run, even when paused")
	for node in sandbox.field.shields+sandbox.field.charges+sandbox.field.freeze_effects:
		check(not node.visible,"Reset must hide stale shield, charge and frost visuals while paused")
	clear_options()
	sandbox.distance_input.value=26
	check(absf(sandbox.actor.position.distance_to(sandbox.target.position)-26)<0.001,"Maximum menu spacing must fit within the colosseum")
	sandbox.distance_input.value=4.4
	# Every selectable action must start through its real path, including airborne melee.
	for i in sandbox.moves.size():
		clear_options()
		select_move(sandbox.moves[i].id)
		sandbox.distance_input.value=float(sandbox.moves[i].distance)
		sandbox.run_setup()
		await frames(240)
		check(sandbox.started,"Menu action failed to start: "+str(sandbox.moves[i].id))
		if sandbox.moves[i].expect=="armor":check(sandbox.seen.armor,"Armor menu action must activate armor")
		if sandbox.moves[i].expect=="aura":check(sandbox.seen.aura,"Overdrive menu action must activate its aura")
		for fighter in sandbox.field.fighters:
			check(not fighter.brain_enabled,"Menu actions must never enable autonomous attacks")
	clear_options()
	select_move("melee_2")
	sandbox.jump_toggle.set_pressed_no_signal(true)
	sandbox.settings_changed()
	sandbox.run_setup()
	await frames(90)
	check(sandbox.seen.air and sandbox.actor.melee_attempts>0,"Jumping melee must jump and then perform the selected strike")
	clear_options()
	select_move("fireball_ground")
	sandbox.distance_input.value=4.4
	sandbox.run_setup()
	await frames(580)
	check(sandbox.finished and sandbox.age>=9,"A configured chain must play once without a Repeat Setup option")
	sandbox.reset_setup()
	await frames(20)
	check(not sandbox.armed and paused,"Reset must wait for the next Run")
	if failures.is_empty():print("PASS: configurable sandbox menu, all spells/actions, distance, real charge/block, partner jump menu, reset, pause and one-shot playback")
	paused=false
	sandbox.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
