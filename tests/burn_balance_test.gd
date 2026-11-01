extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:
	# Actual allocation rules, including total power, timing amp and player movement.
	for release in [0.05,0.3,0.55]:
		for power in [0.25,0.5,1.0]:
			for movement in [Vector3.ZERO,Vector3(3,0,4)]:
				var baseline_total:float=-1.0
				for speed_share in [0.0,0.2,0.4,0.6,0.8]:
					var base:=Rules.allocate(Rules.projectile_base("Fire"),{"size":0.2,"speed":speed_share,"effect":0.8-speed_share},"Fire",power)
					var stats:=Rules.authored_stats(base,1.0,release,true,movement)
					var total:float=stats.physical_damage+stats.burn_dps*stats.burn_duration
					if baseline_total<0.0:baseline_total=total
					assert(is_equal_approx(total,baseline_total),"Speed-to-burn trade changed the total damage of a 1s body hit")
	print("BURN BALANCE PASS: equal marginal physical/burn damage across 90 allocations, timing, total power and movement")
	quit()
