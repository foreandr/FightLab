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
		f.reset_fighter(Vector3(-3+f.team*3,0.02,0))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
		f.rival=field.fighters[(f.team+1)%3]
	await frames(6)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	for team in [0,1]:
		await prepare()
		var f=field.fighters[team]
		for name_ in ["palm_fireball","cleaving_flick","flame_channel","twin_push","self_mend"]:
			f.player.play("battle/air_"+name_,0)
			f.player.advance(0)
			var previous:=Vector3.ZERO
			var path:=0.0
			for i in 50:
				f.player.seek(f.player.current_animation_length*i/49.0,true)
				var point: Vector3=f.bone_point("hand_r")-f.bone_point("spine_03")
				if i>0:
					path+=point.distance_to(previous)
				previous=point
			check(path>0.85,"Air spell needs a large visible arm arc on each rig: "+name_+" path="+str(path))
			print("AIR ARM team=",team," spell=",name_," hand_arc=",path)
	# Charge and dash must integrate vertical velocity rather than suspend it.
	for action in ["charge","burst","freeze"]:
		await prepare()
		var f=field.fighters[2]
		f.position=Vector3(0,3,0)
		f.rival=field.fighters[0]
		f.rival.position=Vector3(7,0.02,0)
		await frames(1)
		f.velocity=Vector3(0,-2,0)
		if action=="charge":
			f.start_uppercut()
		elif action=="burst":
			f.start_burst()
		else:
			f.freeze_time=1.25
		await frames(8)
		check(f.velocity.y<-4 and f.position.y<2.6,"Gravity must keep advancing during airborne "+action)
		await frames(180)
		print("AIR FALL ",action," root=",f.position," velocity=",f.velocity," mode=",f.mode," floor=",f.is_on_floor())
		check(f.position.y<0.05,"An airborne "+action+" must return to the floor")
	for team in 3:
		for cursor in [0,1]:
			await prepare()
			var f=field.fighters[team]
			f.spell_cursor=cursor
			f.start_jump("jump_cast")
			var peak:=0.0
			for i in 150:
				await physics_frame
				peak=maxf(peak,f.position.y)
			check(peak>1 and f.position.y<0.05,"Every airborne kit action must jump and land without hovering")
			check(f.air_casts>0,"Jump must actually enter an airborne spell")
	# Exercise the actual action playback, not just direct animation sampling.
	await prepare()
	var caster=field.fighters[0]
	caster.spell_cursor=0
	caster.start_jump("jump_cast")
	var visible_windup:=false
	for i in 55:
		await physics_frame
		if caster.mode=="cast" and caster.cast_time>0.3 and caster.cast_time<0.52:
			visible_windup=visible_windup or caster.bone_point("hand_r").y>caster.bone_point("Head").y+0.12
	check(visible_windup,"Actual airborne cast playback must show the raised casting arm rather than staying blended to takeoff")
	await prepare()
	var f=field.fighters[0]
	f.position.y=3
	f.velocity.y=-3
	await frames(1)
	var falling: float=f.velocity.y
	f.start_jump("jump_cast")
	check(f.velocity.y==falling and f.mode=="air","Repeated jump requests must not relaunch an airborne fighter")
	if failures.is_empty():
		print("PASS: exaggerated skeletal air casts on both rigs; charge/dash/freeze gravity, all six jumping kit actions land and no repeated midair relaunch")
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
