extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=load("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.setup_combat_services()
	world.round_active=true
	world.set_combat_numbers(true)
	var attacker=world.spawn_combatant(0,Vector3.ZERO)
	var victim=world.spawn_combatant(1,Vector3(0,0,3))
	victim.receive_status(attacker,{"projectile_element":"Fire","potency":2.0})
	var before:float=victim.health
	victim.update_status(0.25)
	assert(not is_instance_valid(world.combat_numbers))
	victim.update_status(0.25)
	var numbers=world.combat_numbers
	assert(numbers.entries.size()==1)
	var tick:Dictionary=numbers.entries.back()
	assert(tick.kind=="burn" and is_equal_approx(tick.amount,2.0*Burn.TICK_DAMAGE) and tick.actor.get_ref()==victim)
	assert(tick.label.text=="%.1f burn"%(2.0*Burn.TICK_DAMAGE) and tick.color==numbers.COLORS.burn and not tick.headshot)
	assert(is_equal_approx(before-victim.health,tick.amount) and is_equal_approx(attacker.damage_dealt,2.0*Burn.TICK_DAMAGE))
	victim.practice_god_mode=true
	before=victim.health
	victim.update_status(0.5)
	assert(victim.health==before and numbers.entries.size()==2 and is_equal_approx(victim.damage_taken,4.0*Burn.TICK_DAMAGE))
	world.set_combat_numbers(false)
	victim.update_status(0.5)
	assert(numbers.entries.is_empty() and is_equal_approx(victim.damage_taken,6.0*Burn.TICK_DAMAGE))
	world.set_combat_numbers(true)
	victim.practice_god_mode=false
	victim.health=Burn.TICK_DAMAGE
	victim.update_status(0.5)
	assert(victim.health==0 and numbers.entries.size()==1 and is_equal_approx(numbers.entries.back().amount,Burn.TICK_DAMAGE))
	print("BURN NUMBERS PASSED: real half-second ticks, red typed labels, actual damage, source credit, God dummy, disabled silence and lethal cap")
	quit()
