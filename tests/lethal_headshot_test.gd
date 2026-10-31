extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("LETHAL HEADSHOT FAILED: "+message)
	quit(1)
	return false
func area_for(actor:Node,zone:String) -> Area3D:
	for pair in actor.targets:
		if str(pair[0].get_meta("zone",""))==zone:return pair[0]
	return null
func ready_victim(world:Node,victim:Node,health:float) -> void:
	victim.reset_fighter(Vector3(0,0,3))
	victim.health=health;victim.invulnerability=0;victim.guard_energy=0
	victim.practice_god_mode=false;victim.practice_immortal=false
	world.round_active=true
func hit(world:Node,actor:Node,victim:Node,zone:String,damage:float=10.0) -> void:
	var area:=area_for(victim,zone)
	world.apply_impact(actor,victim,{"id":"severance_test","effect":"orb","projectile_element":"None","damage":damage},area.global_position,Vector3.BACK,area,Vector3.BACK*80)
func run() -> void:
	var world=load("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	var floor_body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new();shape.size=Vector3(50,0.2,50)
	collision.shape=shape;floor_body.position.y=-0.1;floor_body.add_child(collision);world.add_child(floor_body)
	var actor=world.spawn_combatant(0,Vector3.ZERO)
	var female=world.spawn_combatant(1,Vector3(0,0,3))
	var male=world.spawn_combatant(2,Vector3(0,0,3),preload("res://scripts/creation_bot_outfit.gd").profile(1))
	for victim in [female,male]:
		ready_victim(world,victim,15)
		hit(world,actor,victim,"head")
		if not check(victim.health==0 and victim.head_severed and is_instance_valid(victim.ragdoll),"Lethal headshot does not detach head and ragdoll body"):return
		if not check(victim.head_severance.head_triangles>0 and not victim.head_severance.originals.is_empty(),"No actual head geometry separated"):return
		var originals:Array=victim.head_severance.originals.duplicate()
		for record in originals:
			if not check(record.node.mesh!=record.mesh and record.node.mesh.get_surface_count()==record.mesh.get_surface_count(),"Severance mutates shared skin or loses material surfaces"):return
		victim.ragdoll.step(1.0/60.0);victim.ragdoll.step(1.0/60.0)
		if not check(not victim.ragdoll.links.has("chest/head"),"Severed head still has a neck constraint"):return
		if not check(victim.ragdoll.bodies.size()==11,"Severance adds unnecessary physics bodies"):return
		var initial:Vector3=victim.ragdoll.bodies.head.global_position
		for frame in 20:
			await physics_frame
			victim.ragdoll.step(1.0/60.0)
		if not check(victim.ragdoll.bodies.head.global_position.distance_to(initial)>0.5,"Detached head does not move independently"):return
		if not check(not victim.sever_head(Vector3.BACK*80),"Duplicate death detaches head twice"):return
		ready_victim(world,victim,160)
		for record in originals:
			if not check(record.node.mesh==record.mesh,"Reset does not restore the intact appearance"):return
		if not check(not victim.head_severed and victim.head_severance.originals.is_empty(),"Reset leaves severance state"):return
		hit(world,actor,victim,"head")
		if not check(victim.health==140 and not victim.head_severed,"Nonlethal headshot severs the head"):return
		victim.health=1;victim.burn_time=1;victim.burn_clock=0.49;victim.burn_damage=3;victim.burn_source=actor
		victim.update_status(0.02)
		if not check(victim.health==0 and not victim.head_severed,"Later burn death incorrectly inherits headshot finisher"):return
		ready_victim(world,victim,5)
		hit(world,actor,victim,"chest")
		victim.ragdoll.step(1.0/60.0)
		if not check(not victim.head_severed and victim.ragdoll.links.has("chest/head"),"Body kill detaches head or loses normal neck joint"):return
		ready_victim(world,victim,160)
		victim.practice_god_mode=true
		hit(world,actor,victim,"head",1000)
		if not check(victim.health>0 and not victim.head_severed,"God Mode victim gets decapitated"):return
		ready_victim(world,victim,15)
		victim.start_ragdoll(Vector3.BACK*20,victim.bone_point("Head"))
		victim.ragdoll.step(1.0/60.0);victim.ragdoll.step(1.0/60.0)
		var existing_id:int=victim.ragdoll.bodies.head.get_instance_id()
		hit(world,actor,victim,"head")
		if not check(victim.head_severed and not victim.ragdoll.links.has("chest/head") and victim.ragdoll.bodies.head.get_instance_id()==existing_id,"Finishing an existing ragdoll does not reuse and detach its head"):return
	print("LETHAL HEADSHOT PASSED: female/male training skin, actual split geometry, independent head motion, reused ragdoll body, existing-neck release, nonlethal/body/burn/God exclusions and complete reset restoration")
	quit()
