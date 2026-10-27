extends SceneTree
var field: Node3D
var storm: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(storm):
			var center: Vector3=storm.focus_position()+Vector3.UP
			field.camera.position=field.camera.position.lerp(center+Vector3(3.4,2.1,5),0.1)
			field.camera.look_at(center)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.warmup=0
	field.round_active=true
	field.target_timer=999
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(-4,0.02,0) if f.team==2 else (Vector3(1,0.02,0) if f.team==1 else Vector3(-5,0.02,-5)))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
	storm=field.fighters[2]
	storm.rival=field.fighters[1]
	storm.rotation.y=PI/2
	field.camera.position=Vector3(0,3,6)
	field.camera.fov=43
	await frames(15)
	storm.spell_cursor=0
	storm.start_cast(false)
	await frames(100)
	storm.melee_sequence=0
	storm.start_burst()
	await frames(90)
	storm.start_punch()
	await frames(60)
	storm.start_punch()
	await frames(70)
	field.status="OVERDRIVE  ·  GOLDEN MANTLE  ·  KNEE COMBOS"
	await frames(150)
	field.write_report()
	field.finish_run()
