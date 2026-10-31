extends RefCounted
## One second is neutral. Amp grows linearly to +100% at ten seconds,
## then quadratically. Mana savings retain their separate ten-second cap.
static func multiplier(duration:float) -> float:
	if duration>=10.0:return 0.0
	return pow(2.0,1.0-maxf(0.05,duration))

static func amplifier(duration:float) -> float:
	var charge:=maxf(0.0,duration-1.0)/9.0
	return 1.0+(charge if duration<=10.0 else charge*charge)

static func stats(duration:float) -> Dictionary:
	var cost:=multiplier(duration)
	var strength:=amplifier(duration)
	return {"duration":duration,"multiplier":cost,"cost_percent":cost*100.0,"saved_percent":(1.0-cost)*100.0,"amplifier":strength,"amplifier_percent":(strength-1.0)*100.0}
