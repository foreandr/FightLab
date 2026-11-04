extends RefCounted
## One shared, simulation-clock recovery attempt per knockdown.
const WINDOW:=1.10
const YELLOW_START:=0.65
const PERFECT_START:=0.86
const YELLOW_STAMINA:=10.0
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
func progress()->float:return clampf(age/WINDOW,0.0,1.0)
func step(delta:float,actor:Node=null)->void:
 if not waiting():return
 age+=maxf(0.0,delta)
 if age>WINDOW:result="Miss"
 elif is_instance_valid(actor):cpu_policy.step(actor,self)
func attempt(actor:Node)->String:
 if not waiting() or actor.health<=0 or not is_instance_valid(actor.ragdoll):return result
 if progress()>=PERFECT_START and progress()<=1.0:result="Perfect"
 elif progress()>=YELLOW_START and actor.spend_stamina(YELLOW_STAMINA):result="Good"
 else:result="Miss"
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
 return 0.65 if result=="Perfect" else (1.10 if result=="Good" else 0.0)
