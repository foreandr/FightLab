extends RefCounted
## Provisional balance values, shared by live combat and authoring predictions.
const RAGDOLL_DAMAGE:=40.0
static func hit_recovery_seconds(damage:float,head:bool=false,support_loss:float=0.0)->float:
	# Brief ordinary flinch; stronger non-ragdoll hits retain a little more weight.
	return clampf(0.12+0.12*clampf(damage/RAGDOLL_DAMAGE,0.0,1.0)+(0.03 if head else 0.0)+clampf(support_loss,0.0,1.0)*0.02,0.12,0.27)
static func ragdolls(physical_damage:float) -> bool:
	return physical_damage>=RAGDOLL_DAMAGE
static func prediction(damage:float) -> String:
	if ragdolls(damage):return "Ragdoll: Yes"
	if ragdolls(damage*preload("res://scripts/combat_hit_regions.gd").HEAD_PHYSICAL_MULTIPLIER):return "Ragdoll: Yes (head only)"
	return "Ragdoll: No"
