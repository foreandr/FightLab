extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var showcase=load("res://scenes/combat_showcase.tscn").instantiate()
	showcase.case_ids.assign(["fireball_ground","fireball_jump","cinder_slash_ground","cinder_slash_jump","fireball_palm_block","freezing_ray_ground","armor_fireball","flash_ground","melee_2","uppercut"])
	showcase.exit_when_done=true
	root.add_child(showcase)
	# Movie recording must not be steered by keyboard input in the desktop session.
	showcase.set_process_unhandled_key_input(false)
