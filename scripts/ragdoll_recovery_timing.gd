extends RefCounted
## One shared, simulation-clock recovery attempt per knockdown.
const WINDOW:=1.10
const OPPORTUNITY_DELAY:=0.0
const MAX_STAMINA_COST:=30.0
const GETUP_SPEED:=1.32
const RECOVERY_GETUP_SECONDS:=0.65/GETUP_SPEED
const NORMAL_GETUP_SECONDS:=1.71/GETUP_SPEED
var age:=0.0
var result:=""
var running:=false
var cpu_policy=preload("res://scripts/ai/ragdoll_recovery.gd").new()
## Returns true for the recovery key so it cannot also charge a jump.
static func handle_input(actor:Node,event:InputEvent)->bool:
 if not event is InputEventKey or event.echo or not is_instance_valid(actor):return false
 var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 if key!=KEY_SPACE or not actor.player_controlled or actor.health<=0.0 or not is_instance_valid(actor.ragdoll):return false
 if event.pressed:actor.try_quick_recovery()
 return true
func begin()->void:
 age=0.0;result="";running=true;cpu_policy.clear()
func clear()->void:
 age=0.0;result="";running=false;cpu_policy.clear()
func waiting()->bool:return running and result.is_empty()
func offered()->bool:return running and age>=OPPORTUNITY_DELAY
func progress()->float:return clampf((age-OPPORTUNITY_DELAY)/WINDOW,0.0,1.0)
func step(delta:float,actor:Node=null)->void:
 if not waiting():return
 age+=maxf(0.0,delta)
 if offered() and is_instance_valid(actor):cpu_policy.step(actor,self)
func stamina_cost()->float:return MAX_STAMINA_COST*(1.0-progress())
func attempt(actor:Node)->String:
 if not waiting() or not offered() or actor.health<=0 or not is_instance_valid(actor.ragdoll):return result
 var cost:=stamina_cost()
 if cost>0.0 and not actor.spend_stamina(cost):return ""
 result="Recovered"
 actor.arena.show_combat_number(actor,"stamina",cost)
 actor.arena.show_recovery_feedback(actor,result)
 actor.arena.events.append({"event":"recovery_timing","time":actor.arena.elapsed,"team":actor.team,"result":result,"progress":progress(),"stamina":cost})
 return result
func early_ready(actor:Node)->bool:
 return result=="Recovered" and is_instance_valid(actor.ragdoll)
func getup_seconds()->float:
 return RECOVERY_GETUP_SECONDS if result=="Recovered" else 0.0
