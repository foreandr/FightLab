extends RefCounted
## Shared authoring and execution rules. Defaults are content, never mode logic.
const Projectile=preload("res://scripts/basic_projectile.gd")
const Mana=preload("res://scripts/animation_mana_scaling.gd")
const Momentum=preload("res://scripts/physical_momentum.gd")
const Allocation=preload("res://scripts/projectile_allocation.gd")
const MIN_RELEASE_FRACTION:=0.05
const MAX_RELEASE_FRACTION:=0.55
const MAX_RELEASE_BONUS:=0.25
const PROJECTILE_BASE_MANA:=10.0
const FIRE_MANA_SURCHARGE:=10.0
const NEUTRAL_DAMAGE_BASE_VELOCITY:=(Projectile.MIN_VELOCITY+Projectile.MAX_VELOCITY)*0.5
const NEUTRAL_DAMAGE_AMP:=1.0+MAX_RELEASE_BONUS*0.5
const NEUTRAL_DAMAGE_VELOCITY:=NEUTRAL_DAMAGE_BASE_VELOCITY*NEUTRAL_DAMAGE_AMP
const BATTLE_DEFAULTS={"damage":{"orb":18.0,"slash":16.0,"default":4.5},"mana":{"orb":14.0,"slash":12.0,"armor":20.0,"ice_beam":22.0,"haste":18.0,"burst":9.0,"default":12.0},"charge_damage":1.2,"charge_mana":0.8}
const LEGACY_DEFAULTS={"damage":{"orb":16.0,"spark":12.0,"slash":18.0,"cleave":22.0,"heavy":24.0,"spear":22.0,"ground":18.0,"nova":20.0,"beam":24.0,"default":16.0},"mana":{"orb":14.0,"spark":10.0,"slash":16.0,"cleave":18.0,"heavy":22.0,"spear":20.0,"ground":18.0,"nova":28.0,"beam":26.0,"heal":24.0,"default":14.0},"charge_damage":0.0,"charge_mana":0.0,"motion":{"spear":{"speed":15.0,"radius":0.12},"heavy":{"speed":10.5,"radius":0.18},"default":{"speed":12.5,"radius":0.12}}}

static func projectile_base(element:String,radius:float=0.16,potency:float=1.0,testing:bool=false,velocity:float=Projectile.DEFAULT_VELOCITY) -> Dictionary:
	var spec:=Projectile.spec(element,radius,potency,testing,velocity)
	if element=="None":
		spec["name"]="Elementless projectile"
		spec["mana"]=PROJECTILE_BASE_MANA
		spec["mana_percent"]=PROJECTILE_BASE_MANA
	elif element=="Fire":
		spec["name"]="Fireball"
		spec["mana"]=PROJECTILE_BASE_MANA+FIRE_MANA_SURCHARGE
		spec["mana_percent"]=spec.mana
	return spec

static func earth_spell(radius:float,potency:float) -> Dictionary:
	return {"id":"earth_wall","name":"Earth Wall","effect":"summon_earth","animation":"palm_fireball","hand":"hand_r","release":0.25,"summon_radius":radius,"potency":potency,"mana_percent":Projectile.mana_percent(radius,potency),"mana":Projectile.mana_cost(radius,potency),"damage":0.0}

static func neutral_projectile() -> Dictionary:
	var base:=allocate(projectile_base("None"),{"size":0.5,"speed":0.5},"None",1.0)
	return author(base,1.0,(MIN_RELEASE_FRACTION+MAX_RELEASE_FRACTION)*0.5,true)

static func damage(spec:Dictionary,defaults:Dictionary=BATTLE_DEFAULTS) -> float:
	if spec.has("damage"):return float(spec.damage)
	var values:Dictionary=defaults.get("damage",BATTLE_DEFAULTS.damage)
	return float(values.get(str(spec.get("effect","orb")),values.get("default",4.5)))*(1.0+float(spec.get("charge",0.0))*float(defaults.get("charge_damage",1.2)))

static func mana_cost(spec:Dictionary,capacity:float=100.0,defaults:Dictionary=BATTLE_DEFAULTS) -> float:
	if spec.has("mana_percent"):return maxf(0.0,float(spec.mana_percent)*capacity*0.01)
	if spec.has("mana"):return maxf(0.0,float(spec.mana))
	var values:Dictionary=defaults.get("mana",BATTLE_DEFAULTS.mana)
	return float(values.get(str(spec.get("effect","orb")),values.get("default",12.0)))*(1.0+float(spec.get("charge",0.0))*float(defaults.get("charge_mana",0.8)))

static func motion(spec:Dictionary,defaults:Dictionary=BATTLE_DEFAULTS) -> Dictionary:
	var resolved:=spec.duplicate(true)
	var presets:Dictionary=defaults.get("motion",{})
	if not presets.is_empty():
		var preset:Dictionary=presets.get(str(spec.get("effect","orb")),presets.default)
		if not resolved.has("projectile_velocity"):resolved["projectile_velocity"]=preset.speed
		if not resolved.has("projectile_radius"):resolved["projectile_radius"]=preset.radius
	return Projectile.resolved_motion(resolved)

static func physical(duration:float,offensive:bool) -> Dictionary:
	var seconds:=maxf(0.1,duration)
	var stamina:=10.0*maxf(seconds,1.0/seconds) if offensive else 0.0
	return {"duration":seconds,"stamina":stamina,"damage":10.0*seconds if offensive else 0.0,"effort":stamina}

static func release_timing(duration:float,fraction:float) -> Dictionary:
	var bonus:=clampf((fraction-MIN_RELEASE_FRACTION)/(MAX_RELEASE_FRACTION-MIN_RELEASE_FRACTION),0.0,1.0)
	return {"fraction":fraction,"seconds":duration*fraction,"bonus_percent":bonus*MAX_RELEASE_BONUS*100.0,"multiplier":1.0+bonus*MAX_RELEASE_BONUS}

static func allocate(spec:Dictionary,mix:Dictionary,effect:String,total_power:float) -> Dictionary:
	var result:=spec.duplicate(true)
	var shares:=Allocation.spend(mix,effect!="None",total_power)
	result["projectile_radius"]=Projectile.MIN_RADIUS*pow(Projectile.MAX_RADIUS/Projectile.MIN_RADIUS,float(shares.size))
	result["projectile_velocity"]=lerpf(Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY,float(shares.speed))
	result["potency"]=4.0*float(shares.get("effect",0.0))
	result["power_allocation"]=shares.duplicate()
	result["total_power"]=total_power
	return result

static func authored_stats(base:Dictionary,duration:float,fraction:float,offensive:bool,movement:=Vector3.ZERO,aim:=Vector3.BACK) -> Dictionary:
	var timing:=Mana.stats(duration)
	var amp:float=float(timing.amplifier)*float(release_timing(duration,fraction).multiplier)
	var radius:float=float(base.get("projectile_radius",Projectile.MIN_RADIUS))*Projectile.CAST_RADIUS_SCALE
	var speed:float=float(base.get("projectile_velocity",Projectile.DEFAULT_VELOCITY))
	var factor:=speed*amp/NEUTRAL_DAMAGE_VELOCITY
	var impact:float=float(physical(duration,offensive).damage)*factor
	var launch:=Momentum.projectile(base,movement,aim,speed*amp,impact)
	var effect:=str(base.get("projectile_element","None"))
	return {"base_mana":float(base.mana),"mana":float(base.mana)*float(timing.multiplier),"cost_percent":float(timing.cost_percent),"amplifier":amp,"base_radius":radius,"base_velocity":speed,"radius":radius*amp,"velocity":launch.speed,"stationary_velocity":speed*amp,"speed_damage_multiplier":factor,"physical_damage":launch.spec.damage,"stationary_damage":impact,"movement_multiplier":launch.multiplier,"movement_speed":launch.spec.movement_speed,"burn_dps":3.0*float(base.get("potency",0.0))*amp if effect=="Fire" else 0.0,"effect":effect}

static func author(base:Dictionary,duration:float,fraction:float,offensive:bool) -> Dictionary:
	var spec:=base.duplicate(true)
	var physical_stats:=physical(duration,offensive)
	var timing:=Mana.stats(duration)
	var amp:float=float(timing.amplifier)*float(release_timing(duration,fraction).multiplier)
	spec["stamina_cost"]=physical_stats.stamina
	spec["mana"]=float(base.get("mana",mana_cost(base)))*float(timing.multiplier)
	if base.has("mana_percent"):spec["mana_percent"]=float(base.mana_percent)*float(timing.multiplier)
	spec["damage"]=float(physical_stats.damage)*amp
	spec["physical_damage"]=physical_stats.damage
	spec["potency"]=float(base.get("potency",1.0))*amp
	if spec.has("projectile_radius"):
		var stats:=authored_stats(base,duration,fraction,offensive)
		spec["base_projectile_radius"]=stats.base_radius
		spec["projectile_radius_scale"]=Projectile.CAST_RADIUS_SCALE
		spec["base_projectile_velocity"]=stats.base_velocity
		spec["spell_amplifier"]=stats.amplifier
		spec["projectile_radius"]=stats.radius
		spec["projectile_velocity"]=stats.stationary_velocity
		spec["motion_damage"]=physical_stats.damage
		spec["speed_damage_multiplier"]=stats.speed_damage_multiplier
		spec["physical_damage"]=stats.stationary_damage
		spec["damage"]=stats.stationary_damage
	return spec
