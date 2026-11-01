extends RefCounted
## One burn definition for characters, ground ignition, authoring and previews.
const DURATION:=5.0
const TICK_INTERVAL:=0.5
const TICK_DAMAGE:=1.0
static func dps(potency:float=1.0) -> float:return TICK_DAMAGE/TICK_INTERVAL*maxf(0.0,potency)
static func cleanse(actor:CharacterBody3D) -> bool:
	var active:bool=actor.burn_time>0.0
	actor.burn_time=0.0
	actor.burn_clock=0.0
	actor.burn_damage=TICK_DAMAGE
	actor.burn_source=null
	return active
static func apply(actor:CharacterBody3D,source:CharacterBody3D,potency:float=1.0,duration:float=DURATION) -> void:
	if potency<=0.0 or duration<=0.0:return
	if actor.burn_time<=0.0:actor.burn_clock=0.0
	actor.burn_damage=TICK_DAMAGE*potency
	actor.burn_time=maxf(actor.burn_time,duration)
	actor.burn_source=source
	actor.burns_applied+=1
