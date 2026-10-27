extends "res://scripts/sparring_fighter.gd"
## Reuses the licensed skinned character assembly. No sparring AI runs in this mode.
var is_target := false
var spell_hits := 0
var flinch := 0.0

func _ready() -> void:
	super._ready()
	player.add_animation_library("spells", load(BASE + "animations/spells.res"))
	collision_layer = 8 if is_target else 2
	collision_mask = 1
	paused_ai = true
	play("ual1/Idle" if is_target else "spells/idle")
	player.advance(0)

func advance_pose(delta: float) -> void:
	if flinch > 0:
		flinch -= delta
		if flinch <= 0:
			play("ual1/Idle")
	player.advance(delta)
	var lowest := INF
	for bone in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		var i: int = bones[bone]
		lowest = minf(lowest, skeleton.get_bone_global_pose(i).origin.y - skeleton.get_bone_global_rest(i).origin.y - 0.01)
	model.position.y = maxf(0, -lowest)

func spell_hit() -> void:
	spell_hits += 1
	flinch = 0.43
	clip = ""
	play("ual1/Hit_Chest")
