extends SceneTree
var field: Node3D
var subject: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if field.review_camera and is_instance_valid(subject):
			var center: Vector3=subject.focus_position()+Vector3.UP*0.8
			field.camera.position=field.camera.position.lerp(center+Vector3(3.2,1.8,4.8),0.15)
			field.camera.look_at(center)
func prepare(team: int) -> void:
	field.clear_battle_effects()
	field.round_active=true
	field.warmup=0
	field.intermission=0
	field.target_timer=999
	field.eliminated.clear()
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(-5,0.02,0) if f.team==2 else (Vector3(0,0.02,0) if f.team==1 else Vector3(0,0.02,-6)))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
	subject=field.fighters[team]
	field.review_camera=true
	await frames(10)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.camera.fov=43
	await prepare(2)
	subject.rival=field.fighters[1]
	subject.rotation.y=PI/2
	field.status="FLASH STEP  ·  CHARGE  ·  34 m/s  ·  AUTOMATIC KNEE"
	subject.start_burst()
	await frames(210)
	await prepare(0)
	var ice=field.fighters[1]
	subject.position=Vector3(1,0.02,0)
	ice.position=Vector3(-3,0.02,0)
	ice.rotation.y=PI/2
	ice.rival=subject
	ice.spell_cursor=1
	ice.start_cast(false)
	field.status="FREEZING RAY  ·  PALE JAGGED ICE ON THE LEGS"
	await frames(180)
	await prepare(1)
	subject.spell_cursor=0
	subject.start_cast(false)
	field.status="GLACIAL ARMOR  ·  SEPARATE BLUE TORSO PLATES"
	await frames(150)
	await prepare(2)
	subject.position=Vector3(-10,0.02,0)
	subject.rival=field.fighters[1]
	subject.rival.position=Vector3(10,0.02,0)
	field.cast_magic(subject,field.KITS[2][0].duplicate(true),false)
	subject.mode="chase"
	subject.mode_time=0
	subject.mode_length=999
	field.status="OVERDRIVE  ·  25.5 m/s MOVEMENT"
	await frames(180)
	field.review_camera=false
	for f in field.fighters:
		f.brain_enabled=true
	field.begin_round()
	await frames(720)
	field.write_report()
	field.finish_run()
