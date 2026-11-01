extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=preload("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.round_active=true
	var source=world.spawn_combatant(0,Vector3(-3,0,0))
	var victim=world.spawn_combatant(1,Vector3(0,0,3))
	for actor in [source,victim]:
		actor.brain_enabled=false;actor.editor_pose_locked=true
		actor.guard_energy=0;actor.invulnerability=0
		actor.update_targets()
	victim.practice_god_mode=true
	await physics_frame;await physics_frame
	var spec:Dictionary={"id":"burn_behavior","effect":"orb","projectile_element":"Fire","potency":1.0,"damage":1.0,"projectile_radius":0.1,"projectile_velocity":8.0,"aim_direction":Vector3.BACK}
	world.spawn_projectile(source,spec,victim.bone_point("spine_03")-Vector3.BACK*1.5)
	for i in 100:
		world.step_shots(1.0/60.0)
		if world.shots.is_empty():break
	assert(world.shots.is_empty() and victim.burn_time==Burn.DURATION and is_equal_approx(victim.burn_damage,Burn.TICK_DAMAGE))
	assert(world.spell_environment.patches.is_empty(),"Character impact created ground fire")
	var before:float=victim.damage_taken
	world.events.clear()
	# Oversized and uneven updates must still produce exactly ten ticks.
	for delta in [0.21,0.29,1.25,1.25,4.0]:victim.update_status(delta)
	assert(is_equal_approx(victim.damage_taken-before,10.0*Burn.TICK_DAMAGE) and victim.burn_time==0.0)
	assert(world.events.filter(func(event):return event.event=="burn_tick").size()==10)
	victim.update_status(2.0)
	assert(is_equal_approx(victim.damage_taken-before,10.0*Burn.TICK_DAMAGE))
	victim.reset_fighter(Vector3(2,0,3));victim.practice_god_mode=true
	var env=world.spell_environment
	var point:=Vector3(0,0,3)
	env.projectile_step({"spec":spec,"caster":source,"radius":0.1,"impact_position":point,"velocity":Vector3.DOWN},point+Vector3.UP,point,true)
	assert(env.patches.size()==1 and env.patches[0].life==5.0)
	world.set_physics_process(true)
	env._physics_process(0.1)
	assert(victim.burn_time==0.0)
	victim.position=point
	before=victim.damage_taken
	var applications:int=victim.burns_applied
	env._physics_process(0.1)
	assert(victim.burn_time==5.0 and is_equal_approx(victim.burn_damage,Burn.TICK_DAMAGE))
	for i in 25:
		victim.update_status(0.1)
		env._physics_process(0.1)
	assert(victim.burns_applied==applications+1,"Standing in fire refreshed burn")
	victim.position=point+Vector3.RIGHT*2.0
	for i in 35:
		victim.update_status(0.1)
		env._physics_process(0.1)
	assert(is_equal_approx(victim.damage_taken-before,10.0*Burn.TICK_DAMAGE) and victim.burn_time==0.0)
	assert(env.patches.is_empty(),"Default floor fire outlasted five seconds")
	Burn.apply(victim,source,2.0)
	before=victim.damage_taken
	victim.update_status(5.1)
	assert(is_equal_approx(victim.damage_taken-before,20.0*Burn.TICK_DAMAGE),"Amplification did not scale burn")
	Burn.apply(victim,source)
	before=victim.damage_taken
	victim.update_status(2.3)
	assert(is_equal_approx(victim.damage_taken-before,4.0*Burn.TICK_DAMAGE))
	assert(victim.cleanse_burn())
	assert(victim.burn_time==0.0 and victim.burn_clock==0.0 and victim.burn_source==null)
	victim.update_status(10.0)
	assert(is_equal_approx(victim.damage_taken-before,4.0*Burn.TICK_DAMAGE),"Cleansed burn dealt future damage")
	assert(not victim.cleanse_burn())
	Burn.apply(victim,source)
	victim.update_status(0.2)
	assert(is_equal_approx(victim.damage_taken-before,4.0*Burn.TICK_DAMAGE),"New burn inherited old partial tick")
	victim.update_status(0.3)
	assert(is_equal_approx(victim.damage_taken-before,5.0*Burn.TICK_DAMAGE))
	env.add_water(0.4,victim.global_position)
	env._physics_process(0.1)
	assert(victim.burn_time==0.0 and victim.burn_clock==0.0 and victim.burn_source==null,"Water bypassed the shared cleanse")
	before=victim.damage_taken
	victim.update_status(1.0)
	assert(victim.damage_taken==before)
	print("BURN BEHAVIOR PASSED: body/floor separation, 5s/10 ticks, variable steps, ground ignition, no refresh spam, amp, mid-burn cleanse, clean reapplication and water cleanse")
	quit()
