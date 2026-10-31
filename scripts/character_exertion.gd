extends RefCounted
## Shared sprint cost for live actors and script-driven editor controllers.
const SPRINT_STAMINA_PER_SECOND:=12.0
const SPRINT_RECOVERY_DELAY:=0.4
static func sprint(actor:Node,delta:float,requested:bool,moving:bool) -> bool:
	if not requested:actor.sprint_exhausted=false
	if actor.health<=0 or not requested or not moving:return false
	if actor.practice_god_mode:
		actor.sprint_exhausted=false
		return true
	if actor.sprint_exhausted or actor.stamina<=0:
		actor.sprint_exhausted=true
		return false
	var cost:=minf(actor.stamina,maxf(0,delta)*SPRINT_STAMINA_PER_SECOND)
	actor.stamina-=cost
	actor.stamina_spent+=cost
	actor.minimum_stamina=minf(actor.minimum_stamina,actor.stamina)
	actor.stamina_delay=maxf(actor.stamina_delay,SPRINT_RECOVERY_DELAY)
	if actor.stamina<=0:
		actor.sprint_exhausted=true
		return false
	return true
