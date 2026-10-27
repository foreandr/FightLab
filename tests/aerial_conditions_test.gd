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
	check(lab.chain_menu[0].is_item_disabled(5) and lab.chain_menu[0].is_item_disabled(6),"Grounded first slot must not allow aerial flips or twists")
	lab.set_chain(["Jump","Flip","Twist","Land"])
	check(not lab.chain_menu[1].is_item_disabled(5) and not lab.chain_menu[1].is_item_disabled(6),"Jump must unlock aerial choices in the next slot")
	check(lab.chain_menu[1].is_item_disabled(1) and lab.chain_menu[1].is_item_disabled(4),"Airborne slots must require Land before ground dash or another jump")
	lab.chain_menu[2].select(7)
	lab.chain_menu[3].select(3)
	lab.settings_changed()
	check(not lab.chain_menu[3].is_item_disabled(3) and lab.chain_menu[3].is_item_disabled(5),"Land must restore grounded choices in the next slot")
	lab.set_chain(["Jump","Flip","Twist","Land"])
	lab.chain_menu[0].select(1)
	lab.settings_changed()
	check(lab.chain_menu[1].selected==0 and lab.chain_menu[2].disabled,"Changing an earlier condition must clear invalid later steps")
	lab.set_chain(["Jump","Flip","Twist","Land"])
	lab.run_setup()
	var observed: Dictionary={}
	var maximum_height:=0.0
	var rotated:=false
	for i in 240:
		await physics_frame
		maximum_height=maxf(maximum_height,lab.actor.position.y)
		if lab.actor.mode=="air_trick":
			observed[lab.actor.air_trick]=true
			check(not lab.actor.is_on_floor(),"Air trick must execute only in actual flight")
			if lab.actor.air_trick=="Twist" and absf(lab.actor.model.rotation.y)>0.3:rotated=true
	check(observed.has("Flip") and observed.has("Twist") and rotated,"Preset must execute a visible backflip and a rotating body twist")
	check(lab.sequence.history==["Jump","Flip","Twist","Land"] and lab.sequence.status=="Combo complete","Aerial preset must chain before landing, then complete its actual landing")
	check(maximum_height>1 and maximum_height<3.5 and lab.actor.is_on_floor(),"Air tricks must keep gravity and land without an artificial relaunch or hover")
	var stamina_before: float=lab.actor.stamina
	check(not lab.actor.start_air_trick("Flip") and lab.actor.stamina==stamina_before,"Direct grounded trick request must fail without spending stamina")
	var bad: Array[String]=["Twist"]
	lab.sequence.start(lab.actor,bad,0)
	check(not lab.sequence.active and lab.sequence.status.contains("requires airborne"),"Runtime must enforce conditions independently of the menu")
	lab.set_chain(["Jump","Flip","Twist","Land"])
	lab.run_setup()
	while lab.actor.mode!="air_trick":await physics_frame
	lab.toggle_pause()
	var held_height: float=lab.actor.position.y
	await frames(20)
	check(is_equal_approx(held_height,lab.actor.position.y),"Pause must hold aerial animation and physics")
	lab.reset_setup()
	check(not lab.sequence.active and not lab.armed and paused,"Reset must safely cancel airborne queued moves")
	paused=false
	lab.queue_free()
	await frames(3)
	if failures.is_empty():print("PASS: condition-aware combo menus, actual airborne Flip/Twist, landing unlocks, gravity, runtime rejection, pause and reset")
	quit(0 if failures.is_empty() else 1)
