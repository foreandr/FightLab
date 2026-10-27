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
	check(lab.browser.visible and lab.field.visible and not paused,"Animations must open directly on the live arena")
	for node in lab.find_children("*","Button",true,false):
		check(node.text not in ["Pause [Space]","Run [Space]","Resume [Space]","Reframe [F]","Fight [B]","Battle [B]"],"Removed Create bottom controls must not remain")
	check(lab.group_buttons.has_all(["Motion","Attack"]),"Top-level Motion and Attack controls are required")
	lab.group_buttons.Attack.pressed.emit()
	lab.category_buttons.Knee.pressed.emit()
	check(lab.selected_group=="Attack" and lab.selected_category=="Knee","Actual tab and category buttons must navigate to the selected animations")
	for group in lab.Library.GROUPS:
		lab.select_group(group)
		for category in lab.Library.GROUPS[group]:
			check(lab.category_buttons.has(category),"Missing category: "+category)
			lab.select_category(category)
			check(not lab.library_buttons.is_empty(),"Category must contain usable animations: "+category)
	# Hover drives the actual arena actor, never an isolated preview clone.
	lab.set_chain(["Dash","Knee"])
	var original: Array[String]=lab.chosen_steps()
	lab.select_group("Motion")
	lab.select_group("Attack")
	check(lab.chosen_steps()==original,"Motion and Attack must continue sharing one chain")
	lab.distance_input.value=0.8
	lab.select_category("Kick")
	lab.library_buttons.Kick.mouse_entered.emit()
	await frames(90)
	check(lab.live_preview_sequence.history==["Kick"],"Hover must execute the selected action on the real fighter")
	check(lab.actor==lab.field.fighters[0] and lab.actor.melee_attempts>0,"Preview must use the actual arena fighter")
	check(lab.target.damage_taken>lab.marks.damage,"Hovering a kick at contact distance must cause an actual arena hit")
	check(lab.chosen_steps()==original and not lab.armed,"Live preview must not edit or execute the composed chain")
	await frames(160)
	check(lab.live_preview_loops>0,"Live actions must automatically repeat in the arena")
	lab.set_chain([])
	lab.library_buttons.Kick.pressed.emit()
	check(lab.chosen_steps()==["Kick"],"Click must append the chosen animation")
	lab.select_group("Motion")
	lab.select_category("Acrobatics")
	lab.library_buttons.Flip.mouse_entered.emit()
	lab.library_buttons.Flip.pressed.emit()
	check(lab.chosen_steps()==["Kick"] and lab.selection_status.text.contains("Jump"),"Air-only moves must preview but refuse an invalid grounded chain")
	lab.set_chain(["Jump"])
	lab.library_buttons.Flip.pressed.emit()
	check(lab.chosen_steps()==["Jump","Flip"],"A preceding jump must enable adding a flip")
	var distances: Array[float]=[]
	for step in ["Run","Sprint"]:
		lab.distance_input.value=12
		lab.set_chain([step])
		lab.run_setup()
		var origin: Vector3=lab.actor.position
		await frames(120)
		distances.append(lab.actor.position.distance_to(origin))
		lab.browse_animations()
	check(distances[0]>2 and distances[1]>distances[0]*1.5,"Run and Sprint must move the real fighter at different speeds")
	# Every catalog clip must sample and every step must start/finish in real playback.
	for entry in lab.Library.entries():
		check(lab.actor.player.has_animation(entry.clip),"Missing preview clip: "+str(entry.clip))
		lab.preview_animation(entry)
		await frames(50)
		check(lab.live_preview_sequence.history.has(entry.step),"Every hover choice must start its actual arena action: "+str(entry.step))
		var chosen: Array=[entry.step]
		if entry.step in ["Flip","Twist","Land"]:chosen=["Jump",entry.step]
		lab.distance_input.value=4.4 if entry.step in ["Spell Throw","Slash Throw"] else 0.8
		lab.set_chain(chosen)
		lab.run_setup()
		check(not lab.browser.visible and lab.field.visible,"Run must switch to the actual test arena")
		await frames(240)
		check(lab.sequence.history.has(entry.step) and lab.sequence.status=="Combo complete","Catalog action must complete in real playback: "+str(entry.step)+" / "+lab.sequence.status)
		if entry.step in ["Block","Brace Block"]:check(lab.seen.shield,"Block actions must raise a real active shield")
		if entry.step=="Crouch":
			lab.browse_animations()
			lab.set_chain(["Crouch"])
			lab.run_setup()
			await frames(55)
			check(lab.actor.mode=="motion_pose","Crouch must enter its grounded pose mode")
			check(lab.actor.bone_point("Head").y<1.5,"Crouch must lower the actual skeletal head")
		lab.browse_animations()
		check(lab.browser.visible and not paused and not lab.armed,"Browse must resume live arena preview without running the chain")
	if failures.is_empty():print("PASS: Motion/Attack categories, automatic live arena previews and repeat, click-to-add, air gating and all 23 real animation actions")
	paused=false
	lab.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
