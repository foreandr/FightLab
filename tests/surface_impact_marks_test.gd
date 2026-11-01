extends SceneTree
var impact_events:Array=[]
func _initialize() -> void:call_deferred("run")
func box(parent:Node,position_:Vector3,size_:Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=size_
	collision.shape=shape
	body.add_child(collision)
	parent.add_child(body)
	body.position=position_
	return body
func shoot(world:Node,actor:CharacterBody3D,point:Vector3,normal:Vector3,damage:float) -> void:
	world.spawn_projectile(actor,{"id":"surface_test","effect":"orb","projectile_element":"None","damage":damage,"projectile_radius":0.1,"projectile_velocity":12.0,"aim_direction":-normal},point+normal*1.5)
	for i in 40:
		world.step_shots(1.0/60.0)
		if world.shots.is_empty():break
	assert(world.shots.is_empty())
func run() -> void:
	var world=preload("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.round_active=true
	world.surface_impacted.connect(func(surface,point,normal,damage,impulse):impact_events.append({"surface":surface,"point":point,"normal":normal,"damage":damage,"impulse":impulse}))
	var floor_=box(world,Vector3(0,2.9,0),Vector3(12,0.2,12))
	var wall=box(world,Vector3(0,5,-3),Vector3(8,4,0.2))
	wall.rotation.y=0.4
	var actor=world.spawn_combatant(0,Vector3(-4,3,2))
	actor.brain_enabled=false
	await physics_frame;await physics_frame
	shoot(world,actor,Vector3(0,3,0),Vector3.UP,39.9)
	assert(not is_instance_valid(world.surface_marks) and impact_events.size()==1)
	shoot(world,actor,Vector3(0,3,0),Vector3.UP,40.0)
	assert(world.surface_marks.marks.size()==1)
	var mark=world.surface_marks.marks[0].node
	assert(mark.get_parent()==floor_ and mark.global_basis.z.normalized().is_equal_approx(Vector3.UP))
	var small:float=mark.get_meta("dent_radius")
	shoot(world,actor,Vector3(0,3,0),Vector3.UP,160.0)
	assert(world.surface_marks.marks.size()==1 and is_equal_approx(mark.get_meta("dent_radius"),small*2.0))
	var normal:Vector3=wall.global_basis.z
	var point:Vector3=wall.global_position+normal*0.1
	shoot(world,actor,point,normal,80.0)
	assert(world.surface_marks.marks.size()==2)
	var wall_mark=world.surface_marks.marks.back().node
	assert(wall_mark.get_parent()==wall and wall_mark.global_basis.z.normalized().dot(normal)>0.999)
	var relative:Transform3D=wall_mark.transform
	wall.position+=Vector3.RIGHT
	wall.rotation.y+=0.3
	assert(wall_mark.transform.is_equal_approx(relative))
	assert(world.surface_impact(actor,actor.position,Vector3.UP,100.0)==null)
	assert(world.surface_marks.marks.size()==2)
	var strike:Dictionary={"id":"wall_punch","clock":0.2,"damage":80.0,"dynamic_damage":false,"radius":0.1}
	var previous:=Vector3(2,3.3,1)
	var limb:=Vector3(2,2.9,1)
	preload("res://scripts/melee_contact.gd").surface_contact(actor,strike,previous,limb,0.1)
	var after_punch:int=impact_events.size()
	preload("res://scripts/melee_contact.gd").surface_contact(actor,strike,previous,limb,0.1)
	assert(impact_events.size()==after_punch and world.surface_marks.marks.size()==3)
	actor.last_physical_impact_damage=80.0
	normal=wall.global_basis.z
	point=wall.global_position+normal*0.1+wall.global_basis.x*1.5
	actor.wall_crash(point,normal,8.0,-normal*8.0,wall)
	assert(world.surface_marks.marks.size()==4,"Ragdoll wall crash bypassed shared surface marks")
	for i in 40:world.surface_impact(floor_,Vector3(i*2,3,3),Vector3.UP,40.0)
	assert(world.surface_marks.marks.size()==world.surface_marks.MAX_MARKS)
	assert(floor_.get_child(0).shape.size==Vector3(12,0.2,12) and wall.get_child(0).shape.size==Vector3(8,4,0.2))
	world.spell_environment.reset_environment()
	assert(world.surface_marks.marks.is_empty())
	print("SURFACE IMPACTS PASSED: actual floor/rotated-wall projectiles, threshold, larger dents, merge, surface following, no actor marks, one melee event, bounded marks, reset and untouched collision")
	quit()
