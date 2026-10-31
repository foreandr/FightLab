extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("IMPACT PREDICTION FAILED: "+message)
	quit(1)
	return false
func spec(radius:float) -> Dictionary:
	return {"id":"prediction_test","name":"Prediction test","effect":"orb","hand":"hand_r","projectile_element":"None","base_projectile_radius":radius,"base_projectile_velocity":14.0,"projectile_radius_scale":1.0/3.0,"spell_amplifier":1.0,"aim_direction":Vector3.BACK,"damage":10.0}
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace()
	await process_frame
	await process_frame
	b.set_process(false);b.set_physics_process(false)
	b.playing=false;b.preview_repeating=false
	var field=editor.field
	field.set_physics_process(false)
	var actor=editor.actor
	for fighter in field.fighters:
		fighter.position=Vector3(15+fighter.team*3,0.02,15)
		fighter.mode="review"
	var obstacle:=Area3D.new()
	obstacle.name="GrazingTarget"
	obstacle.collision_layer=8<<editor.target.team
	obstacle.collision_mask=0
	obstacle.set_meta("fighter",editor.target)
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.1;capsule.height=0.2
	var shape:=CollisionShape3D.new();shape.shape=capsule
	obstacle.add_child(shape)
	field.add_child(obstacle)
	obstacle.position=Vector3(0.25,2,4)
	var wall:=StaticBody3D.new()
	var box:=BoxShape3D.new();box.size=Vector3(4,4,0.2)
	shape=CollisionShape3D.new();shape.shape=box
	wall.add_child(shape);field.add_child(wall)
	wall.position=Vector3(0,2,7)
	await physics_frame
	await physics_frame
	var origin:=Vector3(0,2,0)
	var small:Dictionary=field.predict_projectile_impact(actor,spec(0.04),origin)
	var large:Dictionary=field.predict_projectile_impact(actor,spec(0.2),origin)
	if not check(small.hit and small.collider==wall,"Small spell should miss nearby body and hit wall"):return
	if not check(large.hit and large.collider==obstacle and float(large.distance)<4.0,"Projectile size does not detect closer grazing target"):return
	var mana:float=actor.mana
	var stamina:float=actor.stamina
	for camera_position in [Vector3(2,3,-5),Vector3(-12,10,-30),Vector3(18,14,8)]:
		field.camera.global_position=camera_position
		field.camera.look_at(Vector3(0,2,7))
		var before:Transform3D=field.camera.global_transform
		var prediction:Dictionary=field.predict_projectile_impact(actor,spec(0.2),origin)
		if not check(prediction.collider==obstacle and prediction.position.distance_to(large.position)<0.001 and field.camera.global_transform.is_equal_approx(before),"Prediction depends on or moves arbitrary camera"):return
	if not check(is_equal_approx(float(actor.mana),mana) and is_equal_approx(float(actor.stamina),stamina),"Prediction spends resources"):return
	var inside:Dictionary=field.predict_projectile_impact(actor,spec(0.2),obstacle.position)
	if not check(inside.hit and inside.collider==obstacle and is_zero_approx(float(inside.distance)),"Initial overlap is ignored"):return
	obstacle.queue_free();wall.queue_free()
	b.reset_practice_scene()
	await physics_frame
	await physics_frame
	b.preview_effect="None"
	b.demo_duration=1.0
	b.manual_aim=true;b.manual_aim_valid=true
	b.manual_aim_point=editor.target.bone_point("spine_03")
	var launch:Dictionary=b.projectile_preview_launch()
	var prediction:Dictionary=field.predict_projectile_impact(actor,launch.spec,launch.origin)
	if not check(prediction.hit and prediction.collider.get_meta("fighter",null)==editor.target,"Real cast prediction misses actual dummy hitboxes"):return
	field.camera.global_position=actor.global_position+Vector3(3,3,-7)
	field.camera.look_at(prediction.position)
	var before_damage:float=editor.target.damage_taken
	editor.target.invulnerability=0.0
	field.spawn_projectile(actor,launch.spec,launch.origin)
	var shot:Dictionary=field.shots.back()
	var resolved:Dictionary=preload("res://scripts/basic_projectile.gd").resolved_motion(launch.spec)
	if not check(is_equal_approx(float(shot.radius),float(resolved.radius)) and is_equal_approx(float(shot.velocity.length()),float(resolved.speed)),"Prediction and flight use different geometry/speed"):return
	for step in 90:
		field.step_shots(1.0/60.0)
		if field.shots.is_empty():break
	if not check(editor.target.damage_taken>before_damage,"Real projectile did not hit predicted dummy"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/projectile_impact_prediction.png")
	print("IMPACT PREDICTION PASSED: near/far first hit, actual sphere radius, initial overlaps, arbitrary camera/no camera mutation, no resource mutation, real cast matches predicted dummy")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
