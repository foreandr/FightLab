extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:
	var base:=Rules.allocate(Rules.projectile_base("Fire"),{"size":0.344,"speed":0.371,"effect":0.285},"Fire",1.0)
	var example:=Rules.authored_stats(base,4.0,0.3,true)
	assert(is_equal_approx(example.mana,27.3352876875))
	assert(is_equal_approx(example.mana_wait,1.2))
	assert(is_equal_approx(example.amplifier,1.5) and is_equal_approx(Rules.physical(4.0,true).stamina,40.0))
	for element in ["None","Fire"]:
		var original:=Rules.projectile_base(element)
		for duration in [0.1,1.0,4.0,10.0,20.0,60.0]:
			var previous:=INF
			for release in [0.05,0.3,0.55]:
				var stats:=Rules.authored_stats(original,duration,release,true)
				var spec:=Rules.author(original,duration,release,true)
				assert(is_equal_approx(Rules.mana_cost(spec),stats.mana))
				assert(is_equal_approx(spec.release,release))
				assert(stats.mana<=previous)
				assert(stats.mana>0.0 or duration*release>=10.0)
				previous=stats.mana
	# Same time before release, different follow-through: identical mana cost.
	assert(is_equal_approx(Rules.authored_stats(base,3.0,0.4,true).mana_multiplier,example.mana_multiplier))
	assert(is_equal_approx(Rules.authored_stats(base,4.0,0.25,true).mana,31.4))
	assert(Rules.authored_stats(base,20.0,0.5,true).mana==0.0)
	print("RELEASE MANA PASS: 4s/30% costs 27.335 mana after effect-cost transfer; actual wait, matching author/preview costs, later-release savings, unchanged physical/amp and no follow-through discount")
	quit()
