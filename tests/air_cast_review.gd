extends SceneTree
var field: Node3D
var subject: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(subject):
			var center: Vector3=subject.global_position+Vector3.UP
			field.camera.position=field.camera.position.lerp(center+Vector3(4,2.1,5),0.12)
			field.camera.look_at(center)
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.camera.fov=43
	for example in [[0,0],[0,1],[1,1],[1,0],[2,0],[2,1]]:
		field.clear_battle_effects()
		field.round_active=true
		field.warmup=0
		field.intermission=0
		field.target_timer=999
		field.eliminated.clear()
		subject=field.fighters[example[0]]
		var target=field.fighters[(subject.team+1)%3]
		for f in field.fighters:
			f.brain_enabled=false
			f.reset_fighter(Vector3(-2,0.02,0) if f==subject else (Vector3(3,0.02,0) if f==target else Vector3(-6,0.02,-6)))
			f.mode="review"
			f.mode_length=999
			f.invulnerability=0
			f.rival=target if f==subject else subject
		subject.rotation.y=PI/2
		await frames(15)
		subject.spell_cursor=example[1]
		subject.start_jump("jump_cast")
		field.status="AIR CAST  ·  "+field.KITS[example[0]][example[1]].name
		await frames(180)
	field.write_report()
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit()
