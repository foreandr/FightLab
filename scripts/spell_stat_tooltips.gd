extends RefCounted
## Explain the shared rules using their live inputs and outputs; never reprice a cast.
const Rules=preload("res://scripts/combat_spell_rules.gd")
const Projectile=Rules.Projectile
const Mana=Rules.Mana
const Burn=Rules.Burn

static func breakdown(base:Dictionary,seconds:float,fraction:float,offensive:bool,stats:Dictionary) -> Dictionary:
	var timing:=Rules.release_timing(seconds,fraction)
	var duration_amp:=Mana.amplifier(seconds)
	var physical:=Rules.physical(seconds,offensive)
	var shares:Dictionary=base.get("power_allocation",{})
	var power:float=base.get("total_power",1.0)
	var allocation:="Used share = chosen mix × total power (%.1f%%)."%(power*100.0)
	for key in shares:
		allocation+="\n%s: %.3f × %.3f = %.3f"%[str(key).capitalize(),float(shares[key])/power,power,float(shares[key])] if power>0.0 else "\n%s: any mix × 0 total power = 0"%str(key).capitalize()
	var speed_math:="Speed = minimum + (maximum − minimum) × used speed share\n%.3f + (%.3f − %.3f) × %.4f = %.4f m/s"%[Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY,Projectile.MIN_VELOCITY,float(shares.get("speed",0.0)),float(stats.base_velocity)]
	var movement:="Movement contribution = horizontal movement × %.2f\n%.4f m/s × %.2f = %.4f m/s"%[Rules.Momentum.PROJECTILE_TRANSFER,float(stats.movement_speed),Rules.Momentum.PROJECTILE_TRANSFER,float(stats.velocity)-float(stats.stationary_velocity)]
	var amp_math:="Duration: 1 + %s = %.4f×\nRelease: (%.4f − %.2f) ÷ (%.2f − %.2f) = %.4f\nTiming: 1 + %.4f × %.2f = %.4f×\nCombined: %.4f × %.4f = %.4f×\nSpell amp: (%.4f − 1) × 100 = +%.1f%%"%[
		"[(max(0, %.3f − 1) ÷ 9)²]"%seconds if seconds>10.0 else "[max(0, %.3f − 1) ÷ 9]"%seconds,duration_amp,
		fraction,Rules.MIN_RELEASE_FRACTION,Rules.MAX_RELEASE_FRACTION,Rules.MIN_RELEASE_FRACTION,float(timing.bonus_percent)/(Rules.MAX_RELEASE_BONUS*100.0),
		float(timing.bonus_percent)/(Rules.MAX_RELEASE_BONUS*100.0),Rules.MAX_RELEASE_BONUS,float(timing.multiplier),duration_amp,float(timing.multiplier),float(stats.amplifier),float(stats.amplifier),(float(stats.amplifier)-1.0)*100.0]
	var mana_math:="Base: %.1f projectile + %.1f effect = %.1f mana"%[Rules.PROJECTILE_BASE_MANA,float(stats.base_mana)-Rules.PROJECTILE_BASE_MANA,float(stats.base_mana)]
	mana_math+="\nDuration ≥ 10 s: cost multiplier = 0" if seconds>=10.0 else "\nDuration multiplier: 2^(1 − %.3f) = %.6f"%[maxf(0.05,seconds),Mana.multiplier(seconds)]
	mana_math+="\n%.1f × %.6f = %.1f mana\nShown for 100 maximum mana; percentage-priced costs\nscale with the caster's maximum mana.\nGod mode prevents payment; it does not change the price."%[float(stats.base_mana),Mana.multiplier(seconds),float(stats.mana)]
	var stamina_math:="Base: 10 stamina at 1 second\n10 × max(%.3f, 1 ÷ %.3f) = %.1f stamina\nFaster and slower both cost more stamina.\nInterrupted cost = full cost × elapsed ÷ time to release.\nGod mode prevents payment; the quoted cost stays the same."%[seconds,seconds,float(physical.stamina)] if offensive else "This demo is non-attacking: stamina cost = 0.\nDuration does not add a physical attack cost."
	var benchmark:="Default benchmark = 50/50 speed × centered timing\n((%.3f + %.3f) ÷ 2) × %.4f = %.5f m/s"%[Projectile.MIN_VELOCITY,Projectile.MAX_VELOCITY,Rules.NEUTRAL_DAMAGE_AMP,Rules.NEUTRAL_DAMAGE_VELOCITY]
	var damage_math:="Base physical = 10 damage/second × %.3f s = %.4f\n%s\n%s\nLaunch speed ÷ benchmark = %.4f ÷ %.5f\nDamage: %.4f × (%.4f ÷ %.5f) = %.1f\nBody hit: %.1f · Headshot: %.4f × 2 = %.1f\nBefore target blocking; burn is separate.\nMovement is sampled again when the projectile launches."%[
		seconds,float(physical.damage),benchmark,movement,float(stats.velocity),Rules.NEUTRAL_DAMAGE_VELOCITY,float(physical.damage),float(stats.velocity),Rules.NEUTRAL_DAMAGE_VELOCITY,float(stats.physical_damage),float(stats.physical_damage),float(stats.physical_damage),float(stats.physical_damage)*2.0]
	if not offensive:damage_math="Non-attacking demo: base physical damage = 0.\n0 × speed × spell amp × movement = 0. Burn is separate."
	else:damage_math=allocation+"\n"+speed_math+"\n"+amp_math+"\nLaunch: %.4f speed × %.4f amp + %.4f movement = %.4f m/s\n"%[float(stats.base_velocity),float(stats.amplifier),float(stats.velocity)-float(stats.stationary_velocity),float(stats.velocity)]+damage_math
	var diameter_math:="Used size share: %.4f\nRadius = %.3f × (%.3f ÷ %.3f)^%.4f × %.6f\nBase diameter = 2 × radius = %.4f m\nFinal diameter: %.4f × %.4f spell amp = %.2f m\nMinimum/maximum radii come from the projectile rules.\nThe %.6f scale is the global projectile size calibration."%[float(shares.get("size",0.0)),Projectile.MIN_RADIUS,Projectile.MAX_RADIUS,Projectile.MIN_RADIUS,float(shares.get("size",0.0)),Projectile.CAST_RADIUS_SCALE,float(stats.base_radius)*2.0,float(stats.base_radius)*2.0,float(stats.amplifier),float(stats.radius)*2.0,Projectile.CAST_RADIUS_SCALE]
	var speed_tooltip:="%s\nAfter spell amp: %.4f × %.4f = %.4f m/s\n%s\nFinal: %.4f + %.4f = %.1f m/s"%[speed_math,float(stats.base_velocity),float(stats.amplifier),float(stats.stationary_velocity),movement,float(stats.stationary_velocity),float(stats.velocity)-float(stats.stationary_velocity),float(stats.velocity)]
	var potency:float=base.get("potency",0.0)
	var burn_math:="Potency = 4 × used burn share %.4f = %.4f\nTick damage = %.1f base × %.4f potency × %.4f amp = %.4f\nTick interval: %.1f s (%.0f ticks/second)\nPer second: %.4f ÷ %.1f = %.1f damage/s\nFull burn: %.1f/s × %.1f s = %.1f damage\nEach tick is paid separately; cleansing stops future ticks.\nHeadshots and movement do not multiply burn."%[float(shares.get("effect",0.0)),potency,Burn.TICK_DAMAGE,potency,float(stats.amplifier),Burn.TICK_DAMAGE*potency*float(stats.amplifier),Burn.TICK_INTERVAL,1.0/Burn.TICK_INTERVAL,Burn.TICK_DAMAGE*potency*float(stats.amplifier),Burn.TICK_INTERVAL,float(stats.burn_dps),float(stats.burn_dps),float(stats.burn_duration),float(stats.burn_dps)*float(stats.burn_duration)]
	diameter_math=allocation+"\n"+diameter_math+"\n"+amp_math
	speed_tooltip=allocation+"\n"+speed_tooltip+"\n"+amp_math
	burn_math=allocation+"\n"+burn_math+"\n"+amp_math
	return {"mana":mana_math,"stamina":stamina_math,"damage":damage_math,"amp":amp_math,"size":diameter_math,"speed":speed_tooltip,"burn":burn_math,"allocation":allocation,"duration":"Chosen animation duration: %.3f seconds.\nThis value feeds stamina, base physical damage, mana and spell amp."%seconds,"release":"Release: %.3f s × %.4f = %.3f s into the animation.\nAllowed range: %.0f%%–%.0f%% of the animation.\n%s"%[seconds,fraction,seconds*fraction,Rules.MIN_RELEASE_FRACTION*100.0,Rules.MAX_RELEASE_FRACTION*100.0,amp_math],"ragdoll":"Unblocked physical threshold: %.1f damage.\nBody: %.1f · Head: %.1f × 2 = %.1f\n%s\nLethal hits also ragdoll. Burn does not count toward this threshold."%[preload("res://scripts/combat_defense_rules.gd").RAGDOLL_DAMAGE,float(stats.physical_damage),float(stats.physical_damage),float(stats.physical_damage)*2.0,preload("res://scripts/combat_defense_rules.gd").prediction(float(stats.physical_damage))]}

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
