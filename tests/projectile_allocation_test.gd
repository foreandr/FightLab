extends SceneTree
const Allocation=preload("res://scripts/projectile_allocation.gd")
func _initialize() -> void:
	for has_effect in [false,true]:
		var shares:=Allocation.normalize({},has_effect)
		for count in 300:
			var keys:Array=shares.keys()
			var key:String=keys[count%keys.size()]
			shares=Allocation.change(shares,key,float((count*17)%101)/100.0,has_effect)
			var total:=0.0
			for value in shares.values():
				assert(float(value)>=0.0 and float(value)<=1.00001)
				total+=float(value)
			assert(is_equal_approx(total,1.0))
		shares=Allocation.change(shares,"size",1.0,has_effect)
		assert(is_equal_approx(float(shares["size"]),1.0))
		assert(is_zero_approx(float(shares.speed)))
		shares=Allocation.change(shares,"size",0.0,has_effect)
		assert(is_equal_approx(float(shares.speed),0.5 if has_effect else 1.0))
	print("PROJECTILE ALLOCATION PASSED: fixed budget, nonnegative shares, two/three channels, extremes and redistribution from zero")
	quit()
