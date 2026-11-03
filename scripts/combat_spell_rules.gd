extends RefCounted
## Shared authoring and execution rules. Defaults are content, never mode logic.
const Projectile=preload("res://scripts/basic_projectile.gd")
const CastType=preload("res://scripts/animation_cast_type.gd")
const Mana=preload("res://scripts/animation_mana_scaling.gd")
const Momentum=preload("res://scripts/physical_momentum.gd")
const Allocation=preload("res://scripts/projectile_allocation.gd")
const Burn=preload("res://scripts/burn_rules.gd")
const MIN_RELEASE_FRACTION:=0.05
const MAX_RELEASE_FRACTION:=0.55
const MAX_RELEASE_BONUS:=0.25
const PROJECTILE_BASE_MANA:=10.0
const FIRE_MANA_SURCHARGE:=10.0
const BARRIER_BASE_MANA:={"Shield":20.0,"Absorb":40.0,"Reflect":60.0,"Effect":100.0}
const BARRIER_NEUTRAL_WAIT:=0.3
const TOUCH_EXTRA_CONTACT_STAMINA:=0.25
const TOUCH_CONTACT_BONES:=["hand_l","hand_r","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","thigh_l","thigh_r","calf_l","calf_r","foot_l","foot_r","Head"]
const DELIVERY_MANA_MULTIPLIERS:={"Projectile":1.0,"Beam":1.0,"Targeted":1.25,"Touch":0.5,"Barrier":0.5}
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

static func barrier_base_mana(kind:String)->float:
	return float(BARRIER_BASE_MANA.get(kind,BARRIER_BASE_MANA.Shield))

static func left_jab_strike()->Array:
	return ["left_jab","ual1/Punch_Jab","hand_l",0.12,0.48,8.0,8.0,1.0]

static func touch_base(contacts:Array)->Dictionary:
	return {"id":"physical_touch","name":"Physical Touch","effect":"touch","delivery_type":"Touch","hand":str(contacts[0]) if not contacts.is_empty() else "hand_l","mana":PROJECTILE_BASE_MANA,"damage":0.0,"projectile_element":"None","potency":0.0,"touch_contacts":contacts.duplicate()}

static func self_barrier_base(strength:float=10.0,duration:float=1.0)->Dictionary:
	return {"id":"self_block","name":"Self Block","effect":"self_barrier","delivery_type":"Barrier","hand":"hand_r","mana":barrier_base_mana("Shield"),"damage":0.0,"shield_strength":maxf(0.0,strength),"shield_duration":maxf(0.0,duration),"parry_mana_refund":5.0}

static func neutral_projectile() -> Dictionary:
	var base:=allocate(projectile_base("None"),{"size":0.5,"speed":0.5},"None",1.0)
	return author(base,1.0,(MIN_RELEASE_FRACTION+MAX_RELEASE_FRACTION)*0.5,true)

static func damage(spec:Dictionary,defaults:Dictionary=BATTLE_DEFAULTS) -> float:
	if spec.has("damage"):return float(spec.damage)
	var values:Dictionary=defaults.get("damage",BATTLE_DEFAULTS.damage)
	return float(values.get(str(spec.get("effect","orb")),values.get("default",4.5)))*(1.0+float(spec.get("charge",0.0))*float(defaults.get("charge_damage",1.2)))

static func delivery_mana_multiplier(delivery_type:String) -> float:
	return float(DELIVERY_MANA_MULTIPLIERS.get(delivery_type,1.0))

static func mana_cost(spec:Dictionary,capacity:float=100.0,defaults:Dictionary=BATTLE_DEFAULTS) -> float:
	var multiplier:=1.0 if bool(spec.get("delivery_mana_priced",false)) else delivery_mana_multiplier(str(spec.get("delivery_type","Projectile")))
	return unscaled_mana_cost(spec,capacity,defaults)*multiplier

static func unscaled_mana_cost(spec:Dictionary,capacity:float=100.0,defaults:Dictionary=BATTLE_DEFAULTS) -> float:
	if spec.has("mana_percent"):return maxf(0.0,float(spec.mana_percent)*capacity*0.01)
	if spec.has("mana"):return maxf(0.0,float(spec.mana))
	var values:Dictionary=defaults.get("mana",BATTLE_DEFAULTS.mana)
	return float(values.get(str(spec.get("effect","orb")),values.get("default",12.0)))*(1.0+float(spec.get("charge",0.0))*float(defaults.get("charge_mana",0.8)))

static func motion(spec:Dictionary,defaults:Dictionary=BATTLE_DEFAULTS) -> Dictionary:
	var resolved:=preload("res://scripts/combat_spec.gd").copy(spec)
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

static func cast_timing_stats(duration:float,fraction:float) -> Dictionary:
	var timing:=Mana.stats(duration)
	var wait:=maxf(0.0,duration)*clampf(fraction,0.0,1.0)
	var cost:=Mana.multiplier(wait)
	timing["release_seconds"]=wait
	timing["multiplier"]=cost
	timing["cost_percent"]=cost*100.0
	timing["saved_percent"]=(1.0-cost)*100.0
	return timing

static func allocate(spec:Dictionary,mix:Dictionary,effect:String,total_power:float) -> Dictionary:
	var result:=preload("res://scripts/combat_spec.gd").copy(spec)
	var shares:=Allocation.spend(mix,effect!="None",total_power)
	result["projectile_radius"]=Projectile.MIN_RADIUS*pow(Projectile.MAX_RADIUS/Projectile.MIN_RADIUS,float(shares.size))
	result["projectile_velocity"]=lerpf(Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY,float(shares.speed))
	result["potency"]=4.0*float(shares.get("effect",0.0))
	result["power_allocation"]=shares.duplicate()
	result["total_power"]=total_power
	return result

static func touch_contact_count(spec:Dictionary) -> int:
	if str(spec.get("delivery_type",""))!="Touch":return 1
	var contacts:Variant=spec.get("touch_contacts",[])
	if not contacts is Array:return 1
	var unique:Dictionary={}
	for value in contacts:
		if not value is String:continue
		var bone:String={"head":"Head","mouth":"Head","ball_l":"foot_l","ball_r":"foot_r"}.get(value,value)
		if bone in TOUCH_CONTACT_BONES:unique[bone]=true
	return maxi(1,unique.size())

static func resource_split(base:Dictionary,duration:float,offensive:bool) -> Dictionary:
	var original:float=physical(duration,offensive).stamina
	var effect_share:=clampf(float(base.get("power_allocation",{}).get("effect",0.0)),0.0,1.0) if str(base.get("projectile_element","None"))!="None" else 0.0
	var transfer:=original*effect_share
	var contact_count:=touch_contact_count(base)
	var contact_surcharge:=original*TOUCH_EXTRA_CONTACT_STAMINA*(contact_count-1)
	var reference:=Mana.multiplier(BARRIER_NEUTRAL_WAIT) if str(base.get("effect",""))=="self_barrier" else 1.0
	return {"original_stamina":original,"effect_share":effect_share,"transfer":transfer,"stamina":original-transfer+contact_surcharge,"touch_contact_count":contact_count,"touch_contact_stamina":contact_surcharge,"delivery_mana_multiplier":delivery_mana_multiplier(str(base.get("delivery_type","Projectile"))),"base_mana":(float(base.get("mana",unscaled_mana_cost(base)))+transfer)*delivery_mana_multiplier(str(base.get("delivery_type","Projectile")))/reference}

static func authored_stats(base:Dictionary,duration:float,fraction:float,offensive:bool,movement:=Vector3.ZERO,aim:=Vector3.BACK) -> Dictionary:
	var timing:=cast_timing_stats(duration,fraction)
	var resources:=resource_split(base,duration,offensive)
	var amp:float=float(timing.amplifier)*float(release_timing(duration,fraction).multiplier)
	var radius:float=float(base.get("projectile_radius",Projectile.MIN_RADIUS))*Projectile.CAST_RADIUS_SCALE
	var speed:float=float(base.get("projectile_velocity",Projectile.DEFAULT_VELOCITY))
	var factor:=speed*amp/NEUTRAL_DAMAGE_VELOCITY
	var type_multiplier:=CastType.physical_multiplier(base)
	var impact:float=float(physical(duration,offensive).damage)*factor*type_multiplier
	var launch:=Momentum.projectile(base,movement,aim,speed*amp,impact)
	var effect:=str(base.get("projectile_element","None"))
	return {"animation_type":CastType.kind(base),"animation_type_multiplier":type_multiplier,"base_mana":resources.base_mana,"original_base_mana":float(base.mana),"delivery_type":str(base.get("delivery_type","Projectile")),"delivery_mana_multiplier":resources.delivery_mana_multiplier,"stamina":resources.stamina,"stamina_to_mana":resources.transfer,"touch_contact_count":resources.touch_contact_count,"touch_contact_stamina":resources.touch_contact_stamina,"effect_share":resources.effect_share,"mana":float(resources.base_mana)*float(timing.multiplier),"mana_multiplier":timing.multiplier,"mana_wait":timing.release_seconds,"cost_percent":float(timing.cost_percent),"amplifier":amp,"base_radius":radius,"base_velocity":speed,"radius":radius*amp,"velocity":launch.speed,"stationary_velocity":speed*amp,"speed_damage_multiplier":factor,"physical_damage":launch.spec.damage,"stationary_damage":impact,"movement_multiplier":launch.multiplier,"movement_speed":launch.spec.movement_speed,"burn_dps":Burn.dps(float(base.get("potency",0.0))*amp) if effect=="Fire" else 0.0,"burn_duration":float(base.get("burn_duration",Burn.DURATION)),"effect":effect}

static func author(base:Dictionary,duration:float,fraction:float,offensive:bool) -> Dictionary:
	var spec:=preload("res://scripts/combat_spec.gd").copy(base)
	spec["release"]=clampf(fraction,0.0,1.0)
	spec["animation_duration"]=maxf(0.0,duration) if is_finite(duration) else 1.0
	var physical_stats:=physical(duration,offensive)
	physical_stats.damage*=CastType.physical_multiplier(base)
	var resources:=resource_split(base,duration,offensive)
	var timing:=cast_timing_stats(duration,fraction)
	var amp:float=float(timing.amplifier)*float(release_timing(duration,fraction).multiplier)
	spec["animation_type"]=CastType.kind(base)
	spec["animation_type_multiplier"]=CastType.physical_multiplier(base)
	spec["stamina_cost"]=resources.stamina
	if str(base.get("delivery_type",""))=="Touch":
		spec["touch_contact_stamina"]=resources.touch_contact_stamina
	spec["mana"]=float(resources.base_mana)*float(timing.multiplier)
	spec["delivery_mana_priced"]=true
	spec["delivery_mana_multiplier"]=resources.delivery_mana_multiplier
	if base.has("mana_percent"):spec["mana_percent"]=(float(base.mana_percent)+float(resources.transfer))*float(resources.delivery_mana_multiplier)*float(timing.multiplier)
	spec["damage"]=float(physical_stats.damage)*amp
	spec["physical_damage"]=physical_stats.damage
	spec["potency"]=float(base.get("potency",1.0))*amp
	if str(base.get("effect",""))=="touch":
		spec["damage"]=float(physical_stats.damage)*amp/NEUTRAL_DAMAGE_AMP
		spec["physical_damage"]=spec.damage
	if str(base.get("effect",""))=="self_barrier":
		spec["shield_strength_multiplier"]=amp/NEUTRAL_DAMAGE_AMP
		spec["shield_strength"]=float(base.get("shield_strength",10.0))*float(spec.shield_strength_multiplier)
		spec["spell_amplifier"]=amp
		spec["damage"]=0.0;spec["physical_damage"]=0.0
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
