extends SceneTree
const Types=preload("res://scripts/animation_store_types.gd")
func _initialize():call_deferred("run")
func run():
	for sample in [
		[{"title":"Female1 D6 CartWheel","category":"Misc"},"Movement"],
		[{"title":"Left knee","category":"Kick"},"Leg"],
		[{"title":"Melee Hook","category":"Punch"},"Arm"],
		[{"title":"Headbutt","category":"Misc"},"Head"],
		[{"title":"Walk arm swing","category":"Walk"},"Movement"],
		[{"title":"Jump Slash","animation_type":"Arms"},"Arm"],
		[{"title":"Unknown source 123"},"Movement"]]:
		assert(Types.kind(sample[0])==sample[1],str(sample))
	var library=load("res://scripts/animation_store_library.gd")
	var hook:=library.enrich({"title":"Melee Hook","category":"Punch"})
	assert(library.matches(hook,"type:arm") and not library.matches(hook,"type:leg"))
	assert(Types.kind(hook)=="Arm")
	print("STORE TYPE CLASSIFICATION PASS: four types, whole-motion precedence, explicit declarations preserved")
	quit()
