extends SceneTree
## Controlled lethal projectile contacts; the corpse is always driven by physics.
var field: Node3D
var subject: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(subject):
			var center: Vector3=subject.focus_position()+Vector3.UP*0.7
			var goal: Vector3=center+Vector3(3.2,2.3,6.0)
			field.camera.position=field.camera.position.lerp(goal,0.14)
			field.camera.look_at(center)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.camera.position=Vector3(3.2,4.5,6.0)
	field.camera.fov=43
	subject=field.fighters[1]
	for spec in [["BACKWARD",Vector3.FORWARD],["RIGHT",Vector3.RIGHT],["LEFT",Vector3.LEFT],["UPWARD",Vector3.UP],["DOWNWARD",Vector3.DOWN]]:
		field.clear_battle_effects()
		field.round_active=true
		field.warmup=0
		field.intermission=0
		field.target_timer=999
		field.eliminated.clear()
		for f in field.fighters:
			f.brain_enabled=false
			f.reset_fighter(Vector3(0,2,0) if f.team==1 else Vector3(15+f.team*3,0.02,12))
			f.mode="review"
			f.mode_length=999
			f.invulnerability=0
			f.rival=subject if f!=subject else field.fighters[0]
			subject.rotation.y=0
		await frames(12)
		subject.health=1
		var direction: Vector3=spec[1]
		var point: Vector3=subject.bone_point("spine_03")
		var attack: Dictionary=field.KITS[0][0].duplicate(true)
		attack.charge=0.5
		field.spawn_projectile(field.fighters[0],attack,point-direction*0.8)
		field.shots[-1].velocity=direction*field.shots[-1].velocity.length()
		await frames(7)
		field.status="LETHAL PROJECTILE  ·  "+spec[0]+"  ·  PHYSICS RAGDOLL"
		await frames(140)
	field.write_report()
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	quit()
