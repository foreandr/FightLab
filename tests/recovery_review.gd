extends SceneTree
var field: Node3D
var subject: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(subject):
			var center: Vector3=subject.focus_position()+Vector3.UP*0.5
			field.camera.position=field.camera.position.lerp(center+Vector3(3,2.6,5.5),0.08)
			field.camera.look_at(center)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.camera.fov=48
	for team in [1,0,2]:
		field.clear_battle_effects()
		field.round_active=true
		field.warmup=0
		field.intermission=0
		field.target_timer=999
		for f in field.fighters:
			f.brain_enabled=false
			f.reset_fighter(Vector3(0,1,0) if f.team==team else Vector3(-5+f.team*3,0.02,-6))
			f.mode="review"
			f.mode_length=999
			f.invulnerability=0
		subject=field.fighters[team]
		await frames(15)
		subject.velocity=Vector3(-2 if team==0 else 2,5,1)
		subject.start_ragdoll(Vector3(-350 if team==0 else 350,200,100),subject.bone_point("Head" if team==1 else "spine_03"))
		field.status="KNOCKDOWN  ·  SETTLE  ·  BLEND  ·  GET UP"
		await frames(510)
	field.write_report()
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit()
