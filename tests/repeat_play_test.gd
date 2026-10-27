extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:await physics_frame
func run() -> void:
	var lab=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(lab)
	lab.camera_input_enabled=false
	check(lab.play_button.text=="Play [R]" and lab.repeat_play_button.text=="Repeat Play","Play and Repeat Play must be separate controls")
	check(lab.play_button.disabled and lab.repeat_play_button.disabled,"Empty chains must not play or repeat")
	lab.distance_input.value=5.0
	lab.set_chain(["Jump","Flip","Land"])
	var view: Transform3D=lab.field.camera.global_transform
	lab.repeat_play_button.pressed.emit()
	var flip_time:=0.0
	var saw_inversion:=false
	for i in 600:
		await physics_frame
		if lab.repeat_cycles==1 and lab.actor.mode=="air_trick" and lab.actor.air_trick=="Flip":
			flip_time+=1.0/60
			saw_inversion=saw_inversion or lab.actor.bone_point("Head").y<lab.actor.bone_point("pelvis").y
	check(lab.repeat_playing and lab.repeat_cycles>=3 and lab.repeat_play_button.text=="Stop Repeat","Repeat must autonomously replay completed chains")
	check(flip_time>0.60 and flip_time<0.74 and saw_inversion,"Backflip must rotate over roughly 0.68 seconds with a visible inversion")
	check(lab.field.camera.global_transform.is_equal_approx(view) and lab.distance_input.value==5.0,"Repeats must preserve camera placement and chosen distance")
	lab.repeat_play_button.pressed.emit()
	var cycles: int=lab.repeat_cycles
	await frames(180)
	check(not lab.repeat_playing and not lab.armed and lab.repeat_cycles==cycles,"Stop Repeat must stop and reset without restarting")
	var jumps: int=lab.actor.actions.get("motion_jump",0)
	lab.play_button.pressed.emit()
	await frames(400)
	check(not lab.repeat_playing and lab.sequence.status=="Combo complete" and lab.actor.actions.get("motion_jump",0)==jumps+1,"Play must perform exactly one pass")
	lab.repeat_play_button.pressed.emit()
	await frames(70)
	lab.distance_input.value=6.0
	check(not lab.repeat_playing and not lab.armed,"Changing settings must stop repeat safely")
	lab.repeat_play_button.pressed.emit()
	await frames(50)
	lab.browse_animations()
	check(not lab.repeat_playing and lab.browser.visible,"Browse must stop chain repeat and restore preview")
	lab.set_chain(["Spell Throw"])
	lab.repeat_play_button.pressed.emit()
	var pending_projectile:=false
	for i in 500:
		await physics_frame
		if not lab.field.shots.is_empty():
			pending_projectile=true
			check(is_zero_approx(lab.repeat_wait),"Repeats must wait for projectiles to finish")
	check(pending_projectile and lab.repeat_cycles>=2,"Spell chains must also repeat after their projectiles finish")
	lab.reset_setup()
	check(not lab.repeat_playing,"Reset must disable repeat")
	paused=false
	lab.queue_free()
	await frames(3)
	var spells=load("res://scenes/spell_editor.tscn").instantiate()
	root.add_child(spells)
	spells.camera_input_enabled=false
	spells.repeat_play_button.pressed.emit()
	await frames(1250)
	check(spells.repeat_playing and spells.repeat_cycles>=2,"Spell workspace must expose working Repeat Play too")
	spells.play_button.pressed.emit()
	check(not spells.repeat_playing,"Play must cancel repeat in the spell workspace")
	paused=false
	spells.queue_free()
	await frames(3)
	if failures.is_empty():print("PASS: Play once, autonomous Repeat/Stop, slower skeletal backflip, preserved camera/distance, edits/reset/browse cancellation, projectile completion and spell workspace repeat")
	quit(0 if failures.is_empty() else 1)
