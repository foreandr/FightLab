extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=preload("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.round_active=true
	var pit=preload("res://scenes/maps/gladiatorial_pit.tscn").instantiate()
	world.add_child(pit)
	var actor=world.spawn_combatant(0,Vector3.ZERO)
	var victim=world.spawn_combatant(1,Vector3(0,0,3))
	for fighter in [actor,victim]:fighter.brain_enabled=false;fighter.practice_god_mode=true
	await physics_frame;await physics_frame
	var angle:=TAU/float(pit.SECTORS)+0.025
	var outward:=Vector3(sin(angle),0,cos(angle))
	var start:Vector3=outward*(pit.RADIUS-2.0)+Vector3.UP*1.4
	world.spawn_projectile(actor,{"id":"wall_fire","effect":"orb","projectile_element":"Fire","potency":1.0,"damage":80.0,"projectile_radius":0.2,"projectile_velocity":10.0,"aim_direction":outward},start)
	for i in 60:
		world.step_shots(1.0/60.0)
		if world.shots.is_empty():break
	var env=world.spell_environment
	assert(env.patches.size()==1 and world.surface_marks.marks.size()==1)
	var patch:Dictionary=env.patches[0]
	var mark=world.surface_marks.marks[0].node
	assert(absf(patch.point.y-1.4)<0.001 and absf(patch.normal.y)<0.01,"Wall fire fell onto the floor")
	assert(patch.node.get_parent()==mark.get_parent(),"Fire must attach to the struck wall")
	assert(mark.global_position.distance_to(patch.point+patch.normal*0.008)<0.001,"Fire and dent must share the visible impact face")
	var scorch:MeshInstance3D=patch.node.get_child(0)
	assert(scorch.global_basis.z.normalized().dot(patch.normal)>0.999)
	# Walking into the burning wall ignites; standing beneath a high patch does not.
	victim.position=patch.point+patch.normal*0.25-Vector3.UP*1.4
	victim.update_targets()
	assert(env.touches_patch(victim,patch))
	world.set_physics_process(true)
	env._physics_process(0.1)
	assert(victim.burn_time==Burn.DURATION)
	victim.cleanse_burn()
	var high:=patch.duplicate()
	high.point+=Vector3.UP*5.0
	assert(not env.touches_patch(victim,high))
	# The attachment and its contact follow a moving/rotating surface.
	var wall:Node3D=patch.node.get_parent()
	var local:Transform3D=patch.node.transform
	wall.position+=Vector3.UP*0.5
	wall.rotation.y+=0.1
	env._physics_process(0.1)
	assert(patch.node.transform.is_equal_approx(local) and patch.point.is_equal_approx(patch.node.global_position))
	env._physics_process(5.0)
	assert(env.patches.is_empty())
	# Removing the burning surface must not leave an invalid effect during reset.
	var orphan=env.surface_fire(patch.point,patch.normal,0.7,{},wall)
	env.patches.append({"node":orphan})
	wall.free()
	env.reset_environment()
	assert(env.patches.is_empty())
	print("WALL FIRE PASS: actual pit hit, wall-height fire/scorch/dent, no ground duplicate, contact burn, high-wall separation, moving surface and 5s expiry")
	quit()
