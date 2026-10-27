extends SceneTree
var field: Node3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(field):
			field.camera.position=Vector3(3.5,4.2,7.5)
			field.camera.look_at(Vector3(8.1,1.3,0))
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.camera.fov=52
	for lethal in [false,true]:
		field.clear_battle_effects()
		field.round_active=true
		field.warmup=0
		field.intermission=0
		field.target_timer=999
		field.eliminated.clear()
		for f in field.fighters:
			f.brain_enabled=false
			f.reset_fighter(Vector3(5,0.02,0) if f.team==0 else (Vector3(8.7,0.02,0) if f.team==1 else Vector3(-5,0.02,-5)))
			f.mode="review"
			f.mode_length=999
			f.invulnerability=0
			f.rotation.y=PI/2 if f.team==0 else -PI/2
		field.fighters[0].rival=field.fighters[1]
		field.fighters[1].rival=field.fighters[0]
		await frames(15)
		field.fighters[1].health=1 if lethal else 160
		field.status="LETHAL WALL SLAM" if lethal else "CHARGED FIREBALL  ·  WALL COLLISION"
		field.fighters[0].charge_requested=1
		field.fighters[0].spell_cursor=0
		field.fighters[0].start_cast(false)
		await frames(210)
	field.write_report()
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit()
