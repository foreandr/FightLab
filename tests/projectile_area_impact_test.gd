extends SceneTree
var areas:Array[Area3D]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PROJECTILE AOE FAILED: "+message)
	quit(1)
	return false
func fixture(field:Node,fighter:Node,point:Vector3) -> void:
	for pair in fighter.targets:pair[0].collision_layer=0
	for pair in fighter.limb_targets:pair[0].collision_layer=0
	fighter.targets=[];fighter.limb_targets=[]
	# Several overlapping hurtboxes must still cause only one damage application.
	for index in 3:
		var area:=Area3D.new()
		area.collision_layer=8<<fighter.team
		area.set_meta("fighter",fighter)
		area.set_meta("zone","chest");area.set_meta("bone","spine_03")
		var shape:=CollisionShape3D.new()
		var capsule:=CapsuleShape3D.new()
		capsule.radius=0.2;capsule.height=0.6
		shape.shape=capsule;area.add_child(shape);field.add_child(area)
		area.global_position=point+Vector3.UP*index*0.01
		fighter.targets.append([area,"spine_03",Vector3.ZERO])
		areas.append(area)
func reset_hits(fighters:Array) -> void:
	for fighter in fighters:
		fighter.health=fighter.MAX_HEALTH
		fighter.damage_taken=0.0;fighter.invulnerability=0.0
		fighter.guard_energy=0.0;fighter.freeze_time=0.0;fighter.frost=0.0
		fighter.practice_immortal=true;fighter.practice_god_mode=true
		fighter.mode="review"
func cast(field:Node,caster:Node,radius:float,element:String="None") -> void:
	field.spawn_projectile(caster,{"id":"aoe_test","effect":"orb","hand":"hand_r","projectile_element":element,"unrestricted_preview":true,"testing_only":true,"projectile_radius":radius,"projectile_velocity":14.0,"aim_direction":Vector3.BACK,"damage":10.0,"potency":1.0 if element=="Fire" else 0.0},Vector3(0,2,0))
	for frame in 100:
		field.step_shots(1.0/60.0)
		if field.shots.is_empty():break
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace();b.set_process(false);b.set_physics_process(false);b.clear_shots()
	var field=editor.field
	field.set_physics_process(false)
	var caster=editor.actor
	var first=editor.target
	var second=b.practice_human
	for fighter in field.fighters:
		fighter.set_physics_process(false)
		fighter.position=Vector3(20+fighter.team*2,0,20)
	fixture(field,first,Vector3(0,2,4))
	fixture(field,second,Vector3(1,2,4))
	fixture(field,caster,Vector3(0.5,2,4))
	await physics_frame
	await physics_frame
	reset_hits(field.fighters)
	cast(field,caster,0.05)
	if not check(is_equal_approx(float(first.damage_taken),10.0) and second.damage_taken==0.0,"Small shot hits wrong number of characters"):return
	reset_hits(field.fighters)
	cast(field,caster,1.3)
	if not check(is_equal_approx(float(first.damage_taken),10.0) and is_equal_approx(float(second.damage_taken),10.0),"Large projectile fails to hit both targets exactly once"):return
	if not check(caster.damage_taken==0.0,"AOE hits its own caster"):return
	reset_hits(field.fighters)
	var first_burns:int=first.burns_applied
	var second_burns:int=second.burns_applied
	cast(field,caster,1.3,"Fire")
	if not check(first.burns_applied==first_burns+1 and second.burns_applied==second_burns+1 and first.burn_time>0.0 and second.burn_time>0.0,"Fire effect not applied once to both targets"):return
	reset_hits(field.fighters)
	for index in 3:areas[3+index].position.x=3.0
	await physics_frame
	cast(field,caster,1.3)
	if not check(first.damage_taken==10.0 and second.damage_taken==0.0,"AOE damages out-of-radius target"):return
	for index in 3:areas[3+index].position.x=1.0
	var wall:=StaticBody3D.new()
	var box:=BoxShape3D.new();box.size=Vector3(0.1,3,3)
	var shape:=CollisionShape3D.new();shape.shape=box;wall.add_child(shape);field.add_child(wall)
	wall.position=Vector3(0.5,2,4)
	await physics_frame
	reset_hits(field.fighters)
	cast(field,caster,1.3)
	if not check(first.damage_taken==10.0 and second.damage_taken==0.0,"AOE travels through solid cover"):return
	wall.queue_free()
	await physics_frame
	reset_hits(field.fighters)
	# The same area resolver applies ground/wall impacts without a primary fighter.
	var spec:Dictionary={"id":"ground_aoe","effect":"orb","damage":10.0,"potency":0.0}
	field.projectile_area_impact.apply(field,{"id":999,"caster":caster,"radius":1.3,"velocity":Vector3.BACK*14,"mass":1.0,"spec":spec},Vector3(0.4,2,3.8))
	if not check(first.damage_taken==10.0 and second.damage_taken==10.0,"World impact area fails to hit both targets"):return
	print("PROJECTILE AOE PASSED: small single-target, large multi-target, one hit per actor despite overlapping limbs, caster exclusion, radius boundary, cover occlusion and world-impact splash")
	quit()
