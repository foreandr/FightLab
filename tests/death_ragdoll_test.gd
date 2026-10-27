extends SceneTree
var field: Node3D
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func prepare(team: int) -> void:
	field.clear_battle_effects()
	field.round_active=true
	field.warmup=0
	field.intermission=0
	field.target_timer=999
	field.eliminated.clear()
	for f in field.fighters:
		f.brain_enabled=false
		f.reset_fighter(Vector3(0,2,0) if f.team==team else Vector3(5+f.team*3,0.02,5))
		f.mode="review"
		f.mode_length=999
		f.invulnerability=0
		f.rival=field.fighters[(f.team+1)%3]
	await frames(3)
func average_velocity(rag: Node3D) -> Vector3:
	var result:=Vector3.ZERO
	for body in rag.bodies.values():
		result+=body.linear_velocity*body.mass/rag.total_mass
	return result
func kill_with_projectile(victim: CharacterBody3D,direction: Vector3,mass:=13.0) -> void:
	var attacker=field.fighters[(victim.team+1)%3]
	var target: Vector3=victim.bone_point("spine_03")
	var spec: Dictionary=field.KITS[0][0].duplicate(true)
	spec.charge=0.0
	field.spawn_projectile(attacker,spec,target-direction*0.65)
	field.shots[-1].velocity=direction*20
	field.shots[-1].mass=mass
	victim.health=1
	for i in 20:
		await physics_frame
		if victim.health<=0:
			break
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	for team in 3:
		for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK,Vector3.UP,Vector3.DOWN]:
			await prepare(team)
			var victim=field.fighters[team]
			await kill_with_projectile(victim,direction)
			check(victim.health==0 and is_instance_valid(victim.ragdoll),"Any lethal projectile must enter ragdoll, including weak impacts")
			if not is_instance_valid(victim.ragdoll):
				continue
			check(victim.mode=="ragdoll" and victim.clip!="ual1/Death01","A killing hit must not select a canned death animation")
			check(victim.death_impulse.normalized().dot(direction)>0.99,"Death must retain the actual killing projectile direction")
			await frames(3)
			var velocity:=average_velocity(victim.ragdoll)
			check(velocity.dot(direction)>0.6,"Rigid-body momentum must follow the killing hit: "+str(direction))
			check(victim.ragdoll.bodies.size()==11 and victim.collision_layer==0,"Corpse must use physical bodies instead of an upright character collider")
			var recoveries: int=victim.recoveries_count
			await frames(100)
			check(is_instance_valid(victim.ragdoll) and victim.recoveries_count==recoveries,"A dead ragdoll must remain physical and never get up")
	for direction in [Vector3.RIGHT,Vector3.DOWN]:
		await prepare(1)
		var body=field.fighters[1]
		await kill_with_projectile(body,direction,40.0)
		await frames(3)
		check(average_velocity(body.ragdoll).dot(direction)>7.0,"A strong lethal impulse must retain more momentum than a living stagger")
	# Real animated fists use the same lethal-impact path as projectiles.
	for team in 3:
		for move in [0,1,4,6]:
			var attacker=field.fighters[team]
			var target=field.fighters[(team+1)%3]
			for distance in [0.60 if move in [1,4] else 0.78]:
				await prepare((team+1)%3)
				attacker.position=Vector3(-distance/2,0.02,0)
				target.position=Vector3(distance/2,0.02,0)
				attacker.rival=target
				target.rival=attacker
				attacker.rotation.y=PI/2
				target.rotation.y=-PI/2
				await frames(6)
				target.health=1
				if move==6:
					attacker.start_uppercut()
				else:
					attacker.melee_sequence=move
					attacker.start_punch()
				for i in 110:
					await physics_frame
					if target.health<=0:
						break
				if attacker.melee_connected:
					print("LETHAL FIST team=%d move=%d distance=%.2f"%[team,move,distance])
					break
			check(attacker.melee_connected and target.health==0 and is_instance_valid(target.ragdoll),"An animated killing punch must physically contact and ragdoll: team %d move %d"%[team,move])
			if not is_instance_valid(target.ragdoll):
				continue
			check(target.clip!="ual1/Death01" and not target.death_impulse.is_zero_approx(),"Killing fists must preserve the contact impulse without a canned death clip")
			await frames(3)
			if move==6:
				check(average_velocity(target.ragdoll).y>4,"A lethal charged uppercut must launch the physical corpse upward")
			var recoveries: int=target.recoveries_count
			await frames(100)
			check(is_instance_valid(target.ragdoll) and target.recoveries_count==recoveries,"A fighter killed by a punch must stay down")
	# Finishing an already airborne ragdoll must preserve it and transmit the hit.
	await prepare(1)
	var victim=field.fighters[1]
	victim.velocity=Vector3.UP*2
	victim.start_ragdoll(Vector3.UP*150,victim.bone_point("spine_03"))
	await frames(6)
	var identity: int=victim.ragdoll.get_instance_id()
	await kill_with_projectile(victim,Vector3.RIGHT)
	await frames(2)
	check(victim.health==0 and victim.ragdoll.get_instance_id()==identity,"An airborne finisher must not reset/recreate the existing ragdoll")
	check(average_velocity(victim.ragdoll).x>2.0,"An airborne killing blow must transfer full-body impulse rather than a tiny pelvis nudge")
	# Damage over time collapses under existing momentum/gravity, without an invented launch.
	await prepare(1)
	victim=field.fighters[1]
	victim.health=1
	victim.burn_time=1
	victim.burn_clock=0.49
	victim.burn_source=field.fighters[0]
	await frames(4)
	check(victim.health==0 and is_instance_valid(victim.ragdoll) and victim.death_impulse==Vector3.ZERO,"Burn death must ragdoll without an artificial upward killing impulse")
	await frames(3)
	check(average_velocity(victim.ragdoll).y<=0,"A burn collapse must fall under gravity")
	if failures.is_empty():
		print("PASS: lethal projectiles in six directions and animated jabs/crosses/hooks/charged uppercuts on all fighters, no death clip/get-up, airborne finishers and burn collapse")
	field.audio.stop_all()
	field.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
