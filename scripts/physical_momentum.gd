extends RefCounted
## Shared body-motion contribution. Animation speed and spell effects stay separate.
const MELEE_BONUS_PER_MPS:=0.03
const PROJECTILE_TRANSFER:=0.35

static func forward_speed(movement:Vector3,direction:Vector3) -> float:
	movement.y=0.0
	return maxf(0.0,movement.dot(direction.normalized()))

static func melee_multiplier(movement:Vector3,direction:Vector3,spec:Dictionary) -> float:
	if str(spec.get("effect",""))!="melee" or spec.get("unrestricted_preview",false):return 1.0
	return 1.0+forward_speed(movement,direction)*MELEE_BONUS_PER_MPS

static func projectile(spec:Dictionary,movement:Vector3,direction:Vector3,speed:float,damage:float) -> Dictionary:
	var result:=spec.duplicate(true)
	if spec.get("movement_applied",false):
		return {"spec":result,"velocity":direction.normalized()*float(spec.projectile_launch_speed),"speed":float(spec.projectile_launch_speed),"multiplier":float(spec.movement_damage_multiplier)}
	var contribution:=0.0 if spec.get("unrestricted_preview",false) else forward_speed(movement,direction)*PROJECTILE_TRANSFER
	var launch_speed:=speed+contribution
	var multiplier:=launch_speed/speed if speed>0.0001 else 1.0
	result["damage"]=damage*multiplier
	result["physical_damage"]=result.damage
	result["movement_damage_multiplier"]=multiplier
	result["movement_speed"]=contribution/PROJECTILE_TRANSFER
	result["movement_applied"]=true
	result["projectile_launch_speed"]=launch_speed
	if result.has("speed_damage_multiplier"):result.speed_damage_multiplier*=multiplier
	return {"spec":result,"velocity":direction.normalized()*launch_speed,"speed":launch_speed,"multiplier":multiplier}
