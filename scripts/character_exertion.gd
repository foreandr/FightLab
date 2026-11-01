extends RefCounted
## Shared sprint cost for live actors and script-driven editor controllers.
const SPRINT_STAMINA_PER_SECOND:=12.0
const SPRINT_RECOVERY_DELAY:=0.4
const MIN_SPRINT_STAMINA:=40.0
const MIN_RUN_STAMINA:=10.0

static func walking_only(actor:Node) -> bool:
	return not actor.practice_god_mode and actor.stamina<MIN_RUN_STAMINA

static func can_sprint(actor:Node) -> bool:
	return actor.practice_god_mode or (actor.stamina>=MIN_SPRINT_STAMINA and not actor.sprint_exhausted)
static func sprint(actor:Node,delta:float,requested:bool,moving:bool) -> bool:
	if not requested:actor.sprint_exhausted=false
	if actor.health<=0 or not requested or not moving:return false
	if actor.practice_god_mode:
		actor.sprint_exhausted=false
		return true
	if not can_sprint(actor):
		actor.sprint_exhausted=true
		return false
	if delta<=0.0:return true
	var cost:=minf(maxf(0.0,actor.stamina-MIN_SPRINT_STAMINA),delta*SPRINT_STAMINA_PER_SECOND)
	if cost<=0.0:
		actor.sprint_exhausted=true
		return false
	actor.stamina-=cost
	actor.stamina_spent+=cost
	actor.minimum_stamina=minf(actor.minimum_stamina,actor.stamina)
	actor.stamina_delay=maxf(actor.stamina_delay,SPRINT_RECOVERY_DELAY)
	if actor.stamina<=MIN_SPRINT_STAMINA:
		actor.sprint_exhausted=true
		return false
	return true
