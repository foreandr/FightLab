extends RefCounted
## Provisional balance values, shared by live combat and authoring predictions.
const RAGDOLL_DAMAGE:=30.0
const RAGDOLL_IMPULSE_GAIN:=2.5
const RAGDOLL_MAX_SPEED:=26.0
static func ragdoll_launch_impulse(impulse:Vector3)->Vector3:
	var flat:=Vector3(impulse.x,0,impulse.z)
	if flat.is_zero_approx() or impulse.y<0.0:return impulse
	var angle:=deg_to_rad(30.0)
	if atan2(impulse.y,flat.length())>=angle:return impulse
	# Tilt the same impulse upward, rather than adding free impact energy.
	return (flat.normalized()*cos(angle)+Vector3.UP*sin(angle))*impulse.length()
## The whole ragdoll receives a coherent launch, not just a torque/spin.
static func ragdoll_launch_velocity(velocity:Vector3,impulse:Vector3,mass:float,terminal:bool=false)->Vector3:
	if impulse.is_zero_approx():return velocity
	var launch:=ragdoll_launch_impulse(impulse)*RAGDOLL_IMPULSE_GAIN/maxf(1.0,mass)
	var flat:=Vector3(launch.x,0.0,launch.z)
	var minimum:=7.5 if terminal else 6.0
	var maximum:=18.0 if terminal else 14.0
	if not flat.is_zero_approx():flat=flat.normalized()*clampf(flat.length(),minimum,maximum)
	# Downward slams keep their direction; ordinary hits have a clear upward arc.
	var vertical:=clampf(launch.y,-maximum,maximum) if impulse.y<0.0 else clampf(launch.y,minimum,maximum)
	return (velocity*0.35+flat+Vector3.UP*vertical).limit_length(RAGDOLL_MAX_SPEED)
static func contact_body_impulse(spec:Dictionary,damage:float,impulse:Vector3) -> Vector3:
	# Keep the full limb impact for the pose, but don't shove ordinary combos apart.
	var contact:=str(spec.get("delivery_type",""))=="Touch" or str(spec.get("effect","")) in ["touch","melee"]
	if not contact or ragdolls(damage) or bool(spec.get("launch",false)) or float(spec.get("charge",0.0))>0.6 or str(spec.get("element",""))=="Wind":return impulse
	return (impulse*0.2).limit_length(33.75)
static func hit_recovery_seconds(damage:float,head:bool=false,support_loss:float=0.0)->float:
	# Brief ordinary flinch; stronger non-ragdoll hits retain a little more weight.
	return clampf(0.12+0.12*clampf(damage/RAGDOLL_DAMAGE,0.0,1.0)+(0.03 if head else 0.0)+clampf(support_loss,0.0,1.0)*0.02,0.12,0.27)
static func ragdolls(physical_damage:float) -> bool:
	return physical_damage>=RAGDOLL_DAMAGE
static func prediction(damage:float) -> String:
	if ragdolls(damage):return "Ragdoll: Yes"
	if ragdolls(damage*preload("res://scripts/combat_hit_regions.gd").HEAD_PHYSICAL_MULTIPLIER):return "Ragdoll: Yes (head only)"
	return "Ragdoll: No"
