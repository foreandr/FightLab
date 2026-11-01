extends SceneTree
const Exertion=preload("res://scripts/character_exertion.gd")
const Movement=preload("res://scripts/character_movement.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=preload("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	var actor=world.spawn_combatant(0,Vector3.ZERO)
	actor.practice_god_mode=false
	actor.mode="run"
	for stamina in [0.0,9.99,10.0,39.99,40.0,100.0]:
		actor.stamina=stamina;actor.sprint_exhausted=false
		assert(Exertion.can_sprint(actor)==(stamina>=40.0))
		assert(Movement.walking_only(actor)==(stamina<10.0))
		assert(is_equal_approx(Movement.gait_speed(actor,true,4.0,7.0),2.0 if stamina<10.0 else (4.0 if stamina<40.0 else 7.0)))
		assert(is_equal_approx(Movement.gait_speed(actor,true,4.8,8.2),2.4 if stamina<10.0 else (4.8 if stamina<40.0 else 8.2)))
	actor.stamina=39.0
	assert(not actor.use_sprint(0.1,true,true) and actor.stamina==39.0)
	actor.stamina=40.5;actor.sprint_exhausted=false
	assert(not actor.use_sprint(0.1,true,true) and is_equal_approx(actor.stamina,40.0))
	actor.stamina=9.0
	assert(is_equal_approx(Movement.walking_velocity(actor,Vector3.BACK*8.2,4.8).length(),2.4))
	assert(Locomotion.clips(Vector2(0,1),false,true)==["duel/walk_forward"])
	assert(actor.player.has_animation("duel/walk_forward"))
	# Flying/diving/knockback movement is not rewritten into a ground walk.
	actor.mode="air"
	assert(Movement.walking_velocity(actor,Vector3.BACK*12.0,4.8).length()==12.0)
	actor.practice_god_mode=true
	assert(not Movement.walking_only(actor) and actor.use_sprint(1.0,true,true))
	print("STAMINA GAIT PASS: exact 40/10 boundaries, shared Create/Story speeds, no refused-sprint cost, threshold crossing, walk pose, air motion preserved and God bypass")
	quit()
