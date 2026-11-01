extends RefCounted
## Plain-language arithmetic using the same live values as the shared combat rules.
const Rules=preload("res://scripts/combat_spell_rules.gd")
const Projectile=Rules.Projectile
const Mana=Rules.Mana
const Burn=Rules.Burn

static func number(value:float) -> String:
	return ("%.2f"%value).trim_suffix("0").trim_suffix("0").trim_suffix(".")

static func factor(value:float) -> String:
	return ("%.4f"%value).trim_suffix("0").trim_suffix("0").trim_suffix("0").trim_suffix("0").trim_suffix(".")

static func breakdown(base:Dictionary,seconds:float,fraction:float,offensive:bool,stats:Dictionary) -> Dictionary:
	var timing:=Rules.release_timing(seconds,fraction)
	var physical:=Rules.physical(seconds,offensive)
	var shares:Dictionary=base.get("power_allocation",{})
	var power:float=base.get("total_power",1.0)
	var duration_amp:=Mana.amplifier(seconds)
	var movement_bonus:=float(stats.velocity)-float(stats.stationary_velocity)
	var speed_bonus:=float(stats.velocity)/Rules.NEUTRAL_DAMAGE_VELOCITY
	var n_time:=number(seconds)
	var n_amp:=number(float(stats.amplifier))
	var n_damage:=number(float(stats.physical_damage))
	var damage:="Player speed = %s m/s\nMovement bonus = %s × %s = %s m/s\nSpell speed (with amp) = %s m/s\nImpact speed = %s + %s = %s m/s\nNormal impact speed = %s m/s\nSpeed multiplier = %s ÷ %s = %s×\nBase damage = 10 × %s seconds = %s\n\nPhysical damage = %s × %s = %s"%[
		number(float(stats.movement_speed)),number(float(stats.movement_speed)),number(Rules.Momentum.PROJECTILE_TRANSFER),number(movement_bonus),number(float(stats.stationary_velocity)),number(float(stats.stationary_velocity)),number(movement_bonus),number(float(stats.velocity)),number(Rules.NEUTRAL_DAMAGE_VELOCITY),number(float(stats.velocity)),number(Rules.NEUTRAL_DAMAGE_VELOCITY),factor(speed_bonus),n_time,number(float(physical.damage)),number(float(physical.damage)),factor(speed_bonus),n_damage]
	if not offensive:damage="Attack animation = No\n\nPhysical damage = 0"
	var surcharge:=float(stats.base_mana)-Rules.PROJECTILE_BASE_MANA
	var mana:="Projectile cost = %s mana\nEffect cost = %s mana\nAnimation time = %s seconds\nMana cost multiplier = %s×\n\nMana cost = (%s + %s) × %s = %s"%[number(Rules.PROJECTILE_BASE_MANA),number(surcharge),n_time,number(Mana.multiplier(seconds)),number(Rules.PROJECTILE_BASE_MANA),number(surcharge),number(Mana.multiplier(seconds)),number(float(stats.mana))]
	var stamina:="Animation time = %s seconds\nNormal stamina cost = 10\n\nStamina depletion = 10 %s %s = %s"%[n_time,"×" if seconds>=1.0 else "÷",n_time,number(float(physical.stamina))]
	if not offensive:stamina="Attack animation = No\n\nStamina depletion = 0"
	var amp:="Duration multiplier = %s×\nTiming multiplier = %s×\n\nSpell multiplier = %s × %s = %s×\nSpell amp = +%s%%"%[number(duration_amp),number(float(timing.multiplier)),number(duration_amp),number(float(timing.multiplier)),n_amp,number((float(stats.amplifier)-1.0)*100.0)]
	var size:="Size power = %s%%\nBase diameter = %s m\nSpell multiplier = %s×\n\nDiameter = %s × %s = %s m"%[number(float(shares.get("size",0.0))*100.0),number(float(stats.base_radius)*2.0),n_amp,number(float(stats.base_radius)*2.0),n_amp,number(float(stats.radius)*2.0)]
	var speed:="Speed power = %s%%\nBase spell speed = %s m/s\nSpell multiplier = %s×\nMovement bonus = %s m/s\n\nSpell speed = (%s × %s) + %s = %s m/s"%[number(float(shares.get("speed",0.0))*100.0),number(float(stats.base_velocity)),n_amp,number(movement_bonus),number(float(stats.base_velocity)),n_amp,number(movement_bonus),number(float(stats.velocity))]
	var potency:float=base.get("potency",0.0)
	var burn:="Burn strength = %s\nSpell multiplier = %s×\n\nBurn per second = %s × %s × %s = %s\nBurn duration = %s seconds\nEach tick = %s damage every %s seconds\nTotal burn = %s × %s = %s"%[number(potency),n_amp,number(Burn.dps()),number(potency),n_amp,number(float(stats.burn_dps)),number(float(stats.burn_duration)),number(float(stats.burn_dps)*Burn.TICK_INTERVAL),number(Burn.TICK_INTERVAL),number(float(stats.burn_dps)),number(float(stats.burn_duration)),number(float(stats.burn_dps)*float(stats.burn_duration))]
	var allocation:="Total power = %s%%"%number(power*100.0)
	for key in shares:allocation+="\n%s power = %s%%"%["Burn" if key=="effect" else str(key).capitalize(),number(float(shares[key])*100.0)]
	return {"mana":mana,"stamina":stamina,"damage":damage,"amp":amp,"size":size,"speed":speed,"burn":burn,"allocation":allocation,"duration":"Animation time = %s seconds"%n_time,"release":"Animation time = %s seconds\nRelease point = %s%%\n\nSpell launches at = %s × %s = %s seconds"%[n_time,number(fraction*100.0),n_time,number(fraction),number(seconds*fraction)],"ragdoll":"Physical damage = %s\nHeadshot damage = %s × 2 = %s\nRagdoll needs = %s physical damage\n\n%s"%[n_damage,n_damage,number(float(stats.physical_damage)*2.0),number(preload("res://scripts/combat_defense_rules.gd").RAGDOLL_DAMAGE),preload("res://scripts/combat_defense_rules.gd").prediction(float(stats.physical_damage))]}

static func refresh(b:Node) -> void:
	var controls:Dictionary={"mana":b.demo_mana_cost_label,"stamina":b.demo_stamina_label,"damage":b.demo_damage_label,"amp":b.demo_amplifier_label,"size":b.demo_size_bonus_label,"speed":b.demo_speed_bonus_label,"burn":b.demo_burn_label,"ragdoll":b.demo_ragdoll_label,"duration":b.demo_duration_label,"release":b.release_slider,"allocation":b.total_power_label}
	var texts:Dictionary={}
	if b.limiter_enabled:
		var effect:String=b.preview_effect if b.creation_step=="projectile" else b.element
		texts=breakdown(b.projectile_effect_spec(effect),b.demo_duration,b.release_fraction,b.demo_offensive(),b.demo_projectile_stats())
	else:
		for key in controls:texts[key]="Limiter off: independent testing value.\nNo duration, allocation, movement or spell-amp scaling is applied."
		var spec:Dictionary=b.test_overrides.apply(b.projectile_effect_spec(b.preview_effect))
		texts.size="Limiter off: %.4f maximum radius × %.6f calibration\n× %.3f%% ÷ 100 × 2 = %.2f m diameter"%[Projectile.MAX_RADIUS,Projectile.CAST_RADIUS_SCALE,float(b.test_overrides.values.size),float(spec.projectile_radius)*2.0]
		texts.speed="Limiter off: %.3f maximum speed × %.3f%% ÷ 100 = %.1f m/s"%[Projectile.MAX_VELOCITY,float(b.test_overrides.values.speed),float(spec.projectile_velocity)]
		texts.burn="Limiter off: %.1f tick damage ÷ %.1f s\n× (4 × %.3f%% ÷ 100) = %.1f burn damage/s"%[Burn.TICK_DAMAGE,Burn.TICK_INTERVAL,float(b.test_overrides.values.effect),Burn.dps(float(spec.potency))]
	for key in controls:
		controls[key].mouse_filter=Control.MOUSE_FILTER_IGNORE if controls[key].has_meta("stat_hover_box") else Control.MOUSE_FILTER_PASS
		controls[key].tooltip_text=texts[key]
	for key in b.allocation_labels:
		b.allocation_labels[key].mouse_filter=Control.MOUSE_FILTER_PASS
		b.allocation_labels[key].tooltip_text=texts.allocation
		b.allocation_sliders[key].tooltip_text=texts.allocation
	if b.has_meta("cast_length_input"):b.get_meta("cast_length_input").get_line_edit().tooltip_text=texts.duration
