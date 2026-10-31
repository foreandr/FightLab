extends SceneTree
const Aim=preload("res://scripts/combat_aim.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("CURSOR CONVERGENCE FAILED: "+message)
	quit(1)
	return false
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
	b.set_process(false);b.set_physics_process(false)
	var field=editor.field
	field.set_physics_process(false)
	for fighter in field.fighters:
		fighter.set_physics_process(false)
		fighter.global_position=Vector3(20,0,20)
	var target=editor.target
	var area:=Area3D.new()
	area.collision_layer=8<<target.team
	area.set_meta("fighter",target)
	var shape:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.4;capsule.height=2.0
	shape.shape=capsule;area.add_child(shape);field.add_child(area)
	area.position=Vector3(0,1.1,4)
	# Use a controlled hurt volume while retaining a real actor/contact implementation.
	target.targets=[[area,"spine_03",Vector3.ZERO]]
	target.limb_targets=[]
	var camera:Camera3D=field.camera
	await physics_frame
	await physics_frame
	var old_false_hits:=0
	for location in [Vector3(2,2.5,-5),Vector3(-3,3,-8),Vector3(1,4,-14)]:
		camera.position=location
		camera.look_at(Vector3(0,1.1,4))
		var before:=camera.global_transform
		var pointer:=camera.unproject_position(Vector3(0,2.25,4))
		var far_point:Vector3=Aim.ray_point(camera,editor.actor,pointer)
		var near_point:Vector3=Aim.ray_point(camera,editor.actor,pointer,[target],0.03)
		var hand:=Vector3(-0.5,1.1,0)
		var spec:Dictionary={"effect":"orb","projectile_element":"None","base_projectile_radius":0.03,"projectile_radius_scale":1.0,"base_projectile_velocity":14.0,"damage":10.0}
		spec.aim_direction=(far_point-hand).normalized()
		var old:Dictionary=field.predict_projectile_impact(editor.actor,spec,hand)
		if old.hit and old.collider==area:old_false_hits+=1
		spec.aim_direction=(near_point-hand).normalized()
		var corrected:Dictionary=field.predict_projectile_impact(editor.actor,spec,hand)
		if not check(not corrected.hit or corrected.collider!=area,"Above-head aim still hits body from camera %s"%location):return
		if not check(camera.unproject_position(near_point).distance_to(pointer)<0.1,"Depth correction moved aim off cursor"):return
		if not check(before.is_equal_approx(camera.global_transform),"Correction moved camera"):return
		pointer=camera.unproject_position(area.global_position)
		near_point=Aim.ray_point(camera,editor.actor,pointer,[target],0.03)
		spec.aim_direction=(near_point-hand).normalized()
		corrected=field.predict_projectile_impact(editor.actor,spec,hand)
		if not check(corrected.hit and corrected.collider==area,"Chest aim misses from camera %s"%location):return
	if not check(old_false_hits>0,"Test did not reproduce old far-convergence false hit"):return
	print("CURSOR CONVERGENCE PASSED: reproduced old false hits; above-head misses and chest hits across camera angles/distances; cursor/camera unchanged")
	quit()
