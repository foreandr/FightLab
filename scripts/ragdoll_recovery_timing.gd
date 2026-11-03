extends RefCounted
## One shared, simulation-clock recovery attempt per knockdown.
const WINDOW:=1.10
const YELLOW_START:=0.65
const PERFECT_START:=0.86
const YELLOW_STAMINA:=10.0
var age:=0.0
var result:=""
var running:=false
func begin()->void:
 age=0.0;result="";running=true
func clear()->void:
 age=0.0;result="";running=false
func waiting()->bool:return running and result.is_empty()
func progress()->float:return clampf(age/WINDOW,0.0,1.0)
func step(delta:float)->void:
 if not waiting():return
 age+=maxf(0.0,delta)
 if age>WINDOW:result="Miss"
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
