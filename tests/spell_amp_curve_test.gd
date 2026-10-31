extends SceneTree
const Scaling=preload("res://scripts/animation_mana_scaling.gd")
func _initialize() -> void:
	for point in [[0.1,1.0],[1.0,1.0],[5.5,1.5],[10.0,2.0],[19.0,5.0],[28.0,10.0],[37.0,17.0]]:
		if not is_equal_approx(Scaling.amplifier(point[0]),point[1]):
			push_error("Unexpected amp at "+str(point[0]));quit(1);return
	assert(absf(Scaling.amplifier(10.0001)-Scaling.amplifier(9.9999))<0.001)
	assert(is_equal_approx(Scaling.multiplier(0.5),sqrt(2.0)))
	assert(is_equal_approx(Scaling.multiplier(1.0),1.0))
	assert(is_zero_approx(Scaling.multiplier(10.0)))
	print("SPELL AMP CURVE PASSED: neutral baseline, linear early charge, quadratic late charge, continuous threshold, preserved mana cost")
	quit()
