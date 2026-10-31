extends RefCounted
## Session-only final values. No balance formula may change a neighboring value.
const Projectile=preload("res://scripts/basic_projectile.gd")
var values:Dictionary={}
func seed(spec:Dictionary,duration:float,release:float) -> void:
	values={"duration":duration,"release":release*100.0,"size":float(spec.projectile_radius)/(Projectile.MAX_RADIUS*Projectile.CAST_RADIUS_SCALE)*100.0,"speed":float(spec.projectile_velocity)/Projectile.MAX_VELOCITY*100.0,"effect":float(spec.get("potency",0.0))/4.0*100.0,"mana":float(spec.mana),"stamina":float(spec.stamina_cost),"damage":float(spec.damage)}
func set_value(key:String,value:float) -> void:
	if values.has(key) and is_finite(value):values[key]=maxf(0.0,value)
func apply(spec:Dictionary) -> Dictionary:
	var result:=spec.duplicate(true)
	result["unrestricted_preview"]=true
	result["testing_only"]=true
	result["mana"]=values.mana
	result["stamina_cost"]=values.stamina
	result["damage"]=values.damage
	result["physical_damage"]=values.damage
	result["projectile_radius"]=Projectile.MAX_RADIUS*Projectile.CAST_RADIUS_SCALE*float(values.size)/100.0
	result["projectile_velocity"]=Projectile.MAX_VELOCITY*float(values.speed)/100.0
	result["potency"]=4.0*float(values.effect)/100.0 if str(result.get("projectile_element","None"))!="None" else 0.0
	result["spell_amplifier"]=1.0
	result["release"]=float(values.release)/100.0
	result.erase("base_projectile_radius")
	result.erase("base_projectile_velocity")
	return result
