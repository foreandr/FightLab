extends RefCounted
## Provisional balance values, shared by live combat and authoring predictions.
const RAGDOLL_DAMAGE:=40.0
static func ragdolls(physical_damage:float) -> bool:
	return physical_damage>=RAGDOLL_DAMAGE
static func prediction(damage:float) -> String:
	if ragdolls(damage):return "Ragdoll: Yes"
	if ragdolls(damage*preload("res://scripts/combat_hit_regions.gd").HEAD_PHYSICAL_MULTIPLIER):return "Ragdoll: Yes (head only)"
	return "Ragdoll: No"
