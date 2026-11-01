extends SceneTree
const Level=preload("res://scripts/combat_level.gd")
const World=preload("res://scripts/combat_world.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("LEVEL INDEPENDENCE FAILED: "+message)
	quit(1)
	return false

func solid(parent:Node3D,location:Vector3,size:Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new()
	var shape:=BoxShape3D.new()
	shape.size=size
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	body.add_child(collision)
	parent.add_child(body)
	body.position=location
	return body

func run() -> void:
	var world:=World.new()
	root.add_child(world)
	world.set_physics_process(false)
	var map:=Node3D.new()
	world.add_child(map)
	map.position=Vector3(100,8,-40)
	map.rotation.y=0.5
	var definition:=Level.new()
	definition.bounds=Level.Bounds.BOX
	definition.half_extents=Vector2(12,7)
	definition.spawn_points=[Vector3(0,0.02,0),Vector3(0,0.02,4)]
	world.use_level(map,definition)
	solid(map,Vector3(0,-0.1,0),Vector3(24,0.2,14))
	var ramp:=solid(map,Vector3(0,0.8,-4),Vector3(6,0.2,2))
	ramp.rotation.z=0.2
	var wall:=solid(map,Vector3(6,1.5,0),Vector3(0.2,3,4))
	# Another floor below the same footprint must not receive upstairs effects.
	solid(world,Vector3(100,-6.1,-40),Vector3(40,0.2,40))
	await physics_frame
	await physics_frame
	var center:Vector3=map.to_global(Vector3.ZERO)
	if not check(is_equal_approx(world.ground_height(center),8.0),"Translated/elevated floor was treated as world zero"):return
	var left:float=world.ground_height(map.to_global(Vector3(-2,1.5,-4)))
	var right:float=world.ground_height(map.to_global(Vector3(2,1.5,-4)))
	if not check(absf(left-right)>0.5,"Terrain support ignored a sloped collision surface"):return
	var outside:Vector3=map.to_global(Vector3(20,3,0))
	var clamped:Vector3=world.constrain_to_level(outside)
	if not check(is_equal_approx(map.to_local(clamped).x,11.6) and is_equal_approx(clamped.y,outside.y),"Rectangular, rotated level bounds used pit/origin clamping"):return
	if not check(world.level_inward(center).is_zero_approx() and not world.level_inward(outside).is_zero_approx(),"Level steering uses distance from global origin"):return
	if not check(definition.radius==0 and definition.spawn_points[0]==Vector3(0,0.02,0),"World changed the supplied shared level resource"):return
	if not check(world.is_impact_wall(wall,map.global_basis.x) and not world.is_impact_wall(wall,Vector3.UP),"Generated walls require pit-only tags"):return
	var actor:CharacterBody3D=world.spawn_combatant(0,world.level_spawn(0))
	var target:CharacterBody3D=world.spawn_combatant(1,world.level_spawn(1))
	actor.brain_enabled=false;target.brain_enabled=false
	actor.editor_pose_locked=true;target.editor_pose_locked=true
	actor.practice_god_mode=false;target.practice_god_mode=true
	actor.invulnerability=0;target.invulnerability=0
	world.round_active=true
	actor.update_targets();target.update_targets()
	await physics_frame
	var spec:=Rules.neutral_projectile()
	var origin:Vector3=actor.bone_point("hand_r")
	spec.aim_direction=(target.bone_point("spine_03")-origin).normalized()
	var before:float=target.damage_taken
	if not check(world.combat().release(actor,spec,origin),"Shared casting failed away from the original arena"):return
	for frame in 100:
		world.step_shots(1.0/60.0)
		if world.shots.is_empty():break
	if not check(is_equal_approx(target.damage_taken-before,10.0) and is_equal_approx(actor.mana,100.0-Rules.mana_cost(spec)) and actor.stamina==90,"Same spell has different costs/damage on a generated level"):return
	var env=world.spell_environment
	var ground:Vector3=map.to_global(Vector3(-3,0,0))
	var fire:Dictionary={"spec":{"projectile_element":"Fire","potency":1.0},"radius":0.2,"caster":actor,"velocity":Vector3.BACK}
	env.projectile_step(fire,ground+Vector3.UP,ground,true)
	if not check(env.patches.size()==1 and is_equal_approx(env.patches[0].point.y,8.0) and is_equal_approx(env.patches[0].node.global_position.y,8.0),"Fire was placed at height zero"):return
	var earth=env.summon_earth_wall(map.to_global(Vector3(5,0,3)),Vector3.BACK,0.5,1.0)
	var half:float=earth.get_child(0).shape.size.y*0.5
	if not check(is_equal_approx(earth.global_position.y-half,8.0),"Earth wall grew out of the original arena floor"):return
	env.add_water(1.0,ground)
	if not check(env.water.size()==1 and env.water_height(ground)>8 and not is_finite(env.water_height(Vector3(ground.x,-6,ground.z))),"Elevated water affects the floor below"):return
	env.add_water(0.5,Vector3(ground.x,-6,ground.z))
	if not check(env.water.size()==2,"Water on separate floors merged"):return
	for pool in env.water:env.freeze_water(pool.point,2,1,pool.depth,pool.radius,pool.point)
	var elevations:Dictionary={}
	for ice in env.ice.values():elevations[roundi(ice.global_position.y-ice.get_child(0).shape.size.y*0.5)]=true
	if not check(elevations.has(8) and elevations.has(-6),"Ice height/cell identity assumes one floor at zero"):return
	world.use_level(map)
	if not check(world.constrain_to_level(outside)==outside and world.level_inward(outside).is_zero_approx(),"An unspecified/generated level inherited invisible pit bounds"):return
	env.reset_environment()
	actor.editor_pose_locked=false
	actor.reset_fighter(Vector3(100,-5.98,-40))
	actor.brain_enabled=false
	world.set_physics_process(true)
	for frame in 60:await physics_frame
	if not check(actor.global_position.y< -5.8 and actor.global_position.y> -6.1,"Ordinary locomotion teleported a below-zero level to the old flat floor"):return
	actor.mode="melee_charge";actor.mode_time=0.0
	for frame in 12:await physics_frame
	if not check(actor.global_position.y< -5.8,"Charged attack gravity assumes floor zero"):return
	actor.start_ragdoll(Vector3(25,0,0),actor.bone_point("spine_03"))
	var recovered:=false
	for frame in 720:
		await physics_frame
		if not is_instance_valid(actor.ragdoll):recovered=true;break
	if not check(recovered and actor.global_position.y< -5.7 and actor.global_position.y> -6.1,"Ragdoll recovery used the pit's floor or bounds"):return
	solid(world,Vector3(103,-4.5,-40),Vector3(0.2,3,6))
	actor.reset_fighter(Vector3(100,-5.98,-40))
	actor.practice_god_mode=true
	actor.brain_enabled=false
	await physics_frame
	await physics_frame
	actor.mode="burst_dash";actor.mode_time=0.0
	actor.combo_speed=25.0;actor.burst_left=0.48;actor.burst_direction=Vector3.RIGHT
	actor.velocity=Vector3.RIGHT*25.0;actor.drive_velocity=actor.velocity
	var crashes:int=actor.wall_crashes
	for frame in 60:
		await physics_frame
		if actor.wall_crashes>crashes:break
	if not check(actor.wall_crashes>crashes,"Actual wall impacts on generated geometry require pit metadata"):return
	print("LEVEL INDEPENDENCE PASSED: translated/rotated rectangular map, elevated/sloped terrain, local spawns/bounds, generic walls, unchanged actual 10/10/10 cast, elevated fire/earth/water/ice, separate floors, unbounded default")
	quit()
