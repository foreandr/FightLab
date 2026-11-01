extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=preload("res://scripts/combat_world.gd").new()
	root.add_child(world)
	world.set_physics_process(false)
	world.round_active=true
	var actor=world.spawn_combatant(0,Vector3.ZERO)
	actor.practice_god_mode=false
	for power in [0.5,1.0]:
		var previous_mana:=-1.0
		var previous_stamina:=INF
		for effect in [0.0,0.25,0.5,1.0]:
			var base:=Rules.allocate(Rules.projectile_base("Fire"),{"size":0.0,"speed":1.0-effect,"effect":effect},"Fire",power)
			var stats:=Rules.authored_stats(base,4.0,0.3,true)
			var authored:=Rules.author(base,4.0,0.3,true)
			assert(stats.mana>previous_mana and stats.stamina<previous_stamina)
			assert(is_equal_approx(stats.stamina+stats.stamina_to_mana,40.0))
			assert(is_equal_approx(stats.stamina_to_mana,40.0*effect*power))
			assert(is_equal_approx(authored.stamina_cost,stats.stamina) and is_equal_approx(Rules.mana_cost(authored),stats.mana))
			actor.mana=100.0;actor.stamina=100.0
			assert(world.combat().authorize_cast(actor,authored))
			assert(is_equal_approx(actor.stamina,100.0-stats.stamina) and is_equal_approx(actor.mana,100.0-stats.mana))
			previous_mana=stats.mana;previous_stamina=stats.stamina
	var neutral:=Rules.author(Rules.allocate(Rules.projectile_base("None"),{"size":0.5,"speed":0.5},"None",1.0),1.0,0.3,true)
	assert(is_equal_approx(neutral.stamina_cost,10.0))
	print("EFFECT RESOURCE SPLIT PASS: effect share transfers stamina into pre-discount mana, total power, zero/full effect, neutral unchanged, real atomic payment")
	quit()
