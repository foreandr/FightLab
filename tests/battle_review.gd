extends SceneTree
## Rendered feature study using real casts, shield intersections and limb contacts.
var field: Node3D
var subject: CharacterBody3D
var other: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(subject) and is_instance_valid(other):
			var center: Vector3=(subject.focus_position()+other.focus_position())*0.5+Vector3.UP
			var spread: float=subject.focus_position().distance_to(other.focus_position())
			center+=Vector3.UP*minf(1.0,absf(subject.focus_position().y-other.focus_position().y)*0.15)
			var goal: Vector3=center+Vector3(0,0.32,1).normalized()*maxf(8.2,7.0+spread*1.8)
			field.camera.position=field.camera.position.lerp(goal,0.1)
			field.camera.look_at(center)
func prepare(distance:=4.4) -> void:
	field.clear_battle_effects()
	field.round_active=true
	field.warmup=0
	field.intermission=0
	field.target_timer=999
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(-distance/2,0.02,0) if f.team==0 else (Vector3(distance/2,0.02,0) if f.team==1 else Vector3(-4,0.02,-4)))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
		f.rival=field.fighters[1 if f.team==0 else 0]
		f.rotation.y=PI/2 if f.team==0 else -PI/2
	subject=field.fighters[0]
	other=field.fighters[1]
	await frames(25)
func picture(name_: String) -> void:
	if not field.capture_dir.is_empty():field.capture.call_deferred(name_+".png")
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.camera.position=Vector3(0,3,10)
	field.camera.fov=43
	await prepare()
	var fire=field.fighters[0]
	var ice=field.fighters[1]
	var storm=field.fighters[2]
	field.status="QUICK FIREBALL"
	fire.spell_cursor=0
	fire.charge_requested=0
	fire.start_cast(false)
	await frames(85)
	await prepare()
	fire.spell_cursor=0
	fire.charge_requested=1
	fire.start_cast(false)
	await frames(55)
	picture("charged_fire_gather")
	ice.start_shield()
	await frames(70)
	picture("charged_guard_launch")
	await frames(260)
	await prepare(0.78)
	fire.start_uppercut()
	await frames(92)
	picture("uppercut_launch")
	await frames(260)
	await prepare()
	ice.spell_cursor=0
	ice.start_cast(false)
	await frames(80)
	ice.spell_cursor=1
	ice.charge_requested=0.8
	ice.start_cast(false)
	await frames(125)
	picture("ice_armor_freeze")
	await frames(100)
	await prepare()
	storm.position=Vector3(-4,0.02,0)
	fire.position=Vector3(0,0.02,0)
	ice.position=Vector3(5,0.02,-3)
	storm.rival=fire
	fire.rival=storm
	storm.rotation.y=PI/2
	fire.rotation.y=-PI/2
	subject=storm
	other=fire
	storm.spell_cursor=0
	storm.start_cast(false)
	await frames(70)
	storm.melee_sequence=0
	storm.start_burst()
	await frames(42)
	picture("storm_dash_combo")
	await frames(70)
	await prepare(0.78)
	fire.melee_sequence=3
	fire.start_punch()
	await frames(22)
	picture("augmented_knee")
	await frames(70)
	field.write_report()
	field.queue_free()
	await frames(3)
	quit()
