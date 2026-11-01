extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:
	var neutral:=Rules.projectile_base("None")
	var fire:=Rules.projectile_base("Fire")
	assert(is_equal_approx(neutral.mana,10.0))
	assert(is_equal_approx(fire.mana,20.0))
	var allocated:=Rules.allocate(fire,{"size":0.3,"speed":0.3,"effect":0.4},"Fire",1.0)
	for duration in [0.5,1.0,2.0,10.0]:
		var spec:=Rules.author(allocated,duration,0.3,true)
		var stats:=Rules.authored_stats(allocated,duration,0.3,true)
		assert(is_equal_approx(Rules.mana_cost(spec),stats.mana))
		assert(is_equal_approx(stats.mana,20.0*preload("res://scripts/animation_mana_scaling.gd").stats(duration).multiplier))
		assert(is_equal_approx(stats.burn_dps,3.0*spec.potency))
	var early:=Rules.authored_stats(allocated,1.0,Rules.MIN_RELEASE_FRACTION,true)
	var late:=Rules.authored_stats(allocated,1.0,Rules.MAX_RELEASE_FRACTION,true)
	assert(is_equal_approx(late.burn_dps/early.burn_dps,1.25))
	print("FIRE MANA RULES PASSED: 10 neutral + 10 Fire, shared duration pricing and amplified burn")
	quit()
