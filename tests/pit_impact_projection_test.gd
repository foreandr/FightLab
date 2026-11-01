extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=preload("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.round_active=true
	var pit=preload("res://scenes/maps/gladiatorial_pit.tscn").instantiate()
	world.add_child(pit)
	var actor=world.spawn_combatant(0,Vector3.ZERO)
	actor.brain_enabled=false
	await physics_frame;await physics_frame
	var angle:=TAU/float(pit.SECTORS)+0.025
	var outward:=Vector3(sin(angle),0,cos(angle))
	var start:Vector3=outward*(pit.RADIUS-2.0)+Vector3.UP*1.4
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start+outward*4.0,1))
	assert(not hit.is_empty() and hit.collider.has_meta("impact_visual_mesh"))
	var projected:=preload("res://scripts/surface_impact_marks.gd").visual_contact(hit.collider,hit.position,hit.normal)
	assert((projected.position-hit.position).dot(hit.normal)>0.008,"Visible brick face should be in front of the collision proxy")
	world.spawn_projectile(actor,{"id":"pit_wall_test","effect":"orb","projectile_element":"None","damage":80.0,"projectile_radius":0.1,"projectile_velocity":10.0,"aim_direction":outward},start)
	for i in 60:
		world.step_shots(1.0/60.0)
		if world.shots.is_empty():break
	assert(world.shots.is_empty() and world.surface_marks.marks.size()==1)
	var mark=world.surface_marks.marks[0].node
	assert(mark.global_position.distance_to(projected.position+projected.normal*0.008)<0.001)
	assert(mark.global_basis.z.normalized().dot(projected.normal)>0.999)
	print("PIT WALL MARK PASS: real projectile, real pit collision proxy, visible stone-face projection and matching mark normal")
	quit()
