extends RefCounted
## One shared, simulation-clock recovery attempt per knockdown.
const WINDOW:=1.10
const OPPORTUNITY_DELAY:=0.35
const YELLOW_START:=0.65
const PERFECT_START:=0.86
const YELLOW_STAMINA:=10.0
const GETUP_SPEED:=1.20
const PERFECT_GETUP_SECONDS:=0.65/GETUP_SPEED
const GOOD_GETUP_SECONDS:=1.10/GETUP_SPEED
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
 if age>OPPORTUNITY_DELAY+WINDOW:result="Miss"
 elif offered() and is_instance_valid(actor):cpu_policy.step(actor,self)
func attempt(actor:Node)->String:
 if not waiting() or not offered() or actor.health<=0 or not is_instance_valid(actor.ragdoll):return result
 if progress()>=PERFECT_START and progress()<=1.0:result="Perfect"
 elif progress()>=YELLOW_START and actor.spend_stamina(YELLOW_STAMINA):result="Good"
 else:result="Miss"
 if result in ["Perfect","Good"]:actor.arena.show_recovery_feedback(actor,result)
 actor.arena.events.append({"event":"recovery_timing","time":actor.arena.elapsed,"team":actor.team,"result":result,"progress":progress(),"stamina":YELLOW_STAMINA if result=="Good" else 0.0})
 return result
func early_ready(actor:Node)->bool:
 if result not in ["Perfect","Good"] or not is_instance_valid(actor.ragdoll):return false
 var rag=actor.ragdoll
 if rag.age<0.35 or rag.floor_contacts<=0:return false
 var pelvis:RigidBody3D=rag.bodies.pelvis;var chest:RigidBody3D=rag.bodies.chest
 var support:float=actor.arena.spell_environment.support_height(rag.location())
 return minf(pelvis.global_position.y,chest.global_position.y)<support+0.8 and maxf(pelvis.linear_velocity.length(),chest.linear_velocity.length())<6.0
func getup_seconds()->float:
 return PERFECT_GETUP_SECONDS if result=="Perfect" else (GOOD_GETUP_SECONDS if result=="Good" else 0.0)
