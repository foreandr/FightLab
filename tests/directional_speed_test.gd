extends SceneTree
const Movement=preload("res://scripts/character_movement.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("DIRECTIONAL SPEED FAILED: "+message)
	quit(1)
	return false
func key(code:int,pressed:bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func run() -> void:
	var directions:=[Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
	# Shared API uses positive Y forward.
	var walk:=[0.6,0.7,0.8,0.9,1.0,0.9,0.8,0.7]
	var sprint:=[0.5,0.6,0.75,0.9,1.0,0.9,0.75,0.6]
	for index in directions.size():
		if not check(is_equal_approx(Movement.directional_speed(directions[index]),walk[index]),"Walk factor %s"%index):return
		if not check(is_equal_approx(Movement.directional_speed(directions[index],true),sprint[index]),"Sprint factor %s"%index):return
		if not check(is_equal_approx(Movement.directional_speed(directions[index]*0.25),walk[index]),"Analog strength changes angle factor"):return
	if not check(is_equal_approx(Movement.directional_speed(Vector2(sin(PI/8),cos(PI/8))),0.95),"Intermediate angle does not interpolate"):return
	change_scene_to_file("res://scenes/fight.tscn")
	await process_frame
	await process_frame
	var field=current_scene
	field.set_physics_process(false)
	field.round_active=true;field.warmup=0.0
	var actor=field.fighters[0]
	for other in field.fighters:
		if other!=actor:other.global_position=Vector3(20,0.02,20)
	actor.player_controlled=true
	for sprinting in [false,true]:
		for sample in [[KEY_W,1.0,1.0],[KEY_D,0.8,0.75],[KEY_S,0.6,0.5]]:
			root.grab_focus()
			for frame in 30:
				await process_frame
				if root.has_focus():break
			actor.reset_fighter(Vector3(0,0.02,0))
			actor.player_controlled=true
			actor.mode="run"
			var spent_before:float=actor.stamina_spent
			key(sample[0],true)
			if sprinting:key(KEY_SHIFT,true)
			for frame in 40:
				await physics_frame
				actor.tick(1.0/60.0)
			var expected:float=(8.2 if sprinting else 4.8)*sample[2 if sprinting else 1]*actor.movement_multiplier()
			if not check(absf(Vector2(actor.velocity.x,actor.velocity.z).length()-expected)<0.05,"Actual Story speed: key=%s sprint=%s expected=%s actual=%s"%[sample[0],sprinting,expected,actor.velocity]):return
			if not check(is_equal_approx(actor.stamina_spent-spent_before,8.0 if sprinting else 0.0),"Story sprint cost is missing or charged twice"):return
			key(sample[0],false)
			key(KEY_SHIFT,false)
	print("DIRECTIONAL SPEED PASSED: eight walk/sprint rates, analog interpolation and actual Story forward/strafe/backpedal speeds")
	quit()
