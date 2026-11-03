extends RefCounted
## Actor-owned timed barrier. Status ticking and impact dispatch are shared by modes.
const PARRY_WINDOW:=0.12
const Overlay=preload("res://scripts/body_barrier_overlay.gd")
var owner_ref:WeakRef
var overlays:Array=[]
var remaining:=0.0
var time_left:=0.0
var age:=INF
func active()->bool:return remaining>0.0 and time_left>0.0
func can_parry()->bool:return active() and age<=PARRY_WINDOW
func activate(actor:Node3D,strength:float,duration:float)->void:
 clear()
 owner_ref=weakref(actor);overlays=Overlay.apply(actor.skeleton)
 remaining=maxf(0.0,strength);time_left=maxf(0.0,duration);age=0.0
 sync_visual()
func step(delta:float)->void:
 if not active():return
 var actor=owner_ref.get_ref() if owner_ref!=null else null
 if not is_instance_valid(actor) or actor.health<=0.0:
  clear();return
 age+=maxf(0.0,delta)
 time_left=maxf(0.0,time_left-delta)
 if time_left<=0.0:clear()
func absorb(damage:float)->float:
 if not active():return 0.0
 var absorbed:=minf(remaining,maxf(0.0,damage))
 remaining-=absorbed
 if remaining<=0.0:clear()
 return absorbed
func clear()->void:
 remaining=0.0;time_left=0.0;age=INF
 sync_visual()
func sync_visual()->void:
 Overlay.set_strength(overlays,1.0 if active() else 0.0,"self_barrier")
