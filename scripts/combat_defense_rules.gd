extends RefCounted
## Provisional balance values, shared by live combat and authoring predictions.
const RAGDOLL_DAMAGE:=40.0
static func ragdolls(physical_damage:float) -> bool:
	return physical_damage>=RAGDOLL_DAMAGE
static func prediction(damage:float) -> String:
	return "Ragdoll: %s · Headshot: %s\nThreshold: %.0f physical · unblocked"%["YES" if ragdolls(damage) else "No","YES" if ragdolls(damage*preload("res://scripts/combat_hit_regions.gd").HEAD_PHYSICAL_MULTIPLIER) else "No",RAGDOLL_DAMAGE]
