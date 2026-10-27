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
func prepare(team: int) -> void:
	field.clear_battle_effects()
	field.round_active=true
	field.warmup=0
	field.intermission=0
	field.target_timer=999
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(0,1,0) if f.team==team else Vector3(-5+f.team*3,0.02,-5))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
	await frames(3)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	for team in 3:
		await prepare(team)
		var f=field.fighters[team]
		f.velocity=Vector3(2,4,0)
		f.start_ragdoll(Vector3(300,200,0),f.bone_point("Head"))
		await frames(6)
		# Root relocation and heading changes must preserve every bone at handoff.
		var points:=[]
		for i in f.skeleton.get_bone_count():
			points.append(f.skeleton.global_transform*f.skeleton.get_bone_global_pose(i))
		f.finish_ragdoll()
		var maximum:=0.0
		for i in f.skeleton.get_bone_count():
			var after: Transform3D=f.skeleton.global_transform*f.skeleton.get_bone_global_pose(i)
			maximum=maxf(maximum,after.origin.distance_to(points[i].origin))
			check(after.basis.get_rotation_quaternion().angle_to(points[i].basis.get_rotation_quaternion())<0.002,"Recovery handoff must preserve bone orientation")
		check(maximum<0.002,"Recovery handoff must not teleport any bone; drift="+str(maximum))
		check(f.mode_length>1.35,"The get-up must use a deliberate gather and slower animation")
		await frames(12)
		check(f.mode=="getup" and f.player.current_animation_position<0.01,"The first quarter second must gather from the landing pose before rising")
		await frames(150)
		check(f.mode!="getup" and f.collision_layer==(128<<team),"Recovery must complete and restore the upright collider")
		await prepare(team)
		f.velocity=Vector3(3,4,0)
		f.start_ragdoll(Vector3(300,200,0),f.bone_point("Head"))
		await frames(6)
		f.finish_ragdoll()
		await frames(8)
		f.reset_fighter(Vector3(0,0.02,0))
		for bone in f.skeleton.get_bone_count():
			if f.skeleton.get_bone_name(bone)!="pelvis":
				check(f.skeleton.get_bone_pose_position(bone).distance_to(f.skeleton.get_bone_rest(bone).origin)<0.002,"Resetting mid-recovery must clear unanimated bone/root offsets")
		# Actual simulation must require continuous stable contact before getting up.
		await prepare(team)
		f.velocity=Vector3(-2,5,1)
		f.start_ragdoll(Vector3(-350,200,100),f.bone_point("spine_03"))
		var recovered:=false
		var settled:=0.0
		var minimum_age:=0.0
		for i in 600:
			if is_instance_valid(f.ragdoll):
				settled=f.ragdoll.settled_time
				minimum_age=f.ragdoll.age
			await physics_frame
			if f.mode=="getup":
				recovered=true
				break
		check(recovered and settled>=0.32 and minimum_age>=1.38,"Actual knockdown must settle on the floor before recovery on every rig")
		print("RECOVERY team=",team," handoff_drift=",maximum," settled=",settled," age=",minimum_age)
	if failures.is_empty():
		print("PASS: world-pose continuity, deliberate gather, slower rise, collider restoration and stable ground dwell on all three rigs")
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
