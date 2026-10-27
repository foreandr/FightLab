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
		f.reset_fighter(Vector3(-3+f.team*3,0.02,-5))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
	await frames(4)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	for dead in [false,true]:
		for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
			await prepare()
			var f=field.fighters[1]
			f.position=direction*8.4+Vector3.UP*1.5
			await frames(2)
			f.health=0 if dead else f.MAX_HEALTH
			f.velocity=direction*10+Vector3.UP*2
			f.start_ragdoll(direction*750,f.bone_point("spine_03"))
			var before: int=f.wall_crashes
			for i in 120:
				await physics_frame
				if is_instance_valid(f.ragdoll):
					for body in f.ragdoll.bodies.values():
						check(absf(body.position.x)<10.65 and absf(body.position.z)<10.65,"Ragdoll must remain inside the physical walls")
			print("WALL dead=",dead," direction=",direction," crashes=",f.wall_crashes-before," health=",f.health)
			check(f.wall_crashes>before,"Thrown bodies must generate a real wall crash on every boundary: "+str(direction))
			if dead:
				check(f.health==0 and is_instance_valid(f.ragdoll),"A wall collision must leave a dead body physical")
			else:
				check(f.health<f.MAX_HEALTH and f.health>0,"A hard wall crash must apply bounded damage to a living fighter")
				var recoveries: int=f.recoveries_count
				await frames(360)
				check(f.recoveries_count>recoveries or not is_instance_valid(f.ragdoll),"A surviving wall slam must settle and allow recovery")
	# A wall can finish a vulnerable fighter without replacing its existing body.
	await prepare()
	var fragile=field.fighters[1]
	fragile.position=Vector3(8.4,1.5,0)
	await frames(2)
	fragile.health=1
	fragile.velocity=Vector3(10,2,0)
	fragile.start_ragdoll(Vector3.RIGHT*750,fragile.bone_point("spine_03"))
	var identity: int=fragile.ragdoll.get_instance_id()
	await frames(120)
	check(fragile.health==0 and is_instance_valid(fragile.ragdoll) and fragile.ragdoll.get_instance_id()==identity,"Lethal wall damage must keep the same ragdoll and prevent recovery")
	# A forced upright knockback must hit the wall and become a physical tumble.
	await prepare()
	var f=field.fighters[0]
	f.position=Vector3(9.2,1.2,0)
	f.knockback=Vector3.RIGHT*12
	f.velocity=Vector3.RIGHT*12
	var before: int=f.wall_crashes
	await frames(24)
	check(f.wall_crashes>before and is_instance_valid(f.ragdoll),"A fast upright wall impact must trigger a ragdoll")
	# Ordinary movement is stopped by a real collider, with no crash spam/damage.
	await prepare()
	f=field.fighters[0]
	f.position=Vector3(9.3,0.02,0)
	for i in 60:
		f.velocity=Vector3.RIGHT*3
		f.move_and_slide()
		await physics_frame
	check(f.position.x<9.9 and f.health==f.MAX_HEALTH,"Walking into a wall must stop without crash damage")
	# A projectile cannot travel through the boundary to a target outside it.
	await prepare()
	f=field.fighters[0]
	var target=field.fighters[1]
	f.position=Vector3(8,0.02,0)
	target.position=Vector3(12,0.02,0)
	f.rival=target
	await frames(3)
	var spell: Dictionary=field.KITS[0][0].duplicate(true)
	spell.charge=0.0
	field.spawn_projectile(f,spell,Vector3(9,1.1,0))
	await frames(30)
	check(field.shots.is_empty() and target.health==target.MAX_HEALTH,"Wall collision must stop a projectile before it hits a target beyond the arena")
	await prepare()
	f=field.fighters[1]
	target=field.fighters[0]
	f.position=Vector3(8,0.02,0)
	target.position=Vector3(12,0.02,0)
	f.rival=target
	await frames(3)
	f.mode="cast"
	field.cast_magic(f,field.KITS[1][1].duplicate(true),false)
	field.step_channels(0.18)
	f.mode="review"
	check(target.health==target.MAX_HEALTH and target.frost==0,"The ice beam must stop at the wall before damaging or freezing an outside target")
	if failures.is_empty():
		print("PASS: all four physical walls contain living/dead ragdolls, momentum crashes damage, upright knockback tumbles and ordinary movement stops safely")
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
