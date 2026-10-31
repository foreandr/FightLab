extends RefCounted
## Presentation only: resource accounting stays immediate and authoritative.
static func approach(current:float,target:float,delta:float) -> float:
	if absf(current-target)<0.0005:return target
	return lerpf(current,target,1.0-exp(-14.0*maxf(0.0,delta)))
