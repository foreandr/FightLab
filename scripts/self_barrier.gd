extends RefCounted
## Actor-owned timed barrier. Status ticking and impact dispatch are shared by modes.
const PARRY_WINDOW:=0.12
const BLOCK_FLASH_SECONDS:=0.22
const DIRECTION_HALF_ANGLE:=deg_to_rad(30.0)
const TIER_COLORS:=[Color("60e88a"),Color("69d8ff"),Color("ffd36a")]
const Overlay=preload("res://scripts/body_barrier_overlay.gd")
var owner_ref:WeakRef
var overlays:Array=[]
var remaining:=0.0
var time_left:=0.0
var age:=INF
var flash_left:=0.0
var flash_color:=TIER_COLORS[0]
var parry_refunded:=false
var refunded_mana:=0.0
var parry_mana_refund:=5.0
func active()->bool:return remaining>0.0 and time_left>0.0
func can_parry()->bool:return active() and age<=PARRY_WINDOW
func activate(actor:Node3D,strength:float,duration:float,refund:float=5.0)->void:
 clear()
 owner_ref=weakref(actor);overlays=Overlay.apply(actor.skeleton)
 remaining=maxf(0.0,strength);time_left=maxf(0.0,duration);age=0.0
 parry_refunded=false;refunded_mana=0.0;parry_mana_refund=maxf(0.0,refund)
 sync_visual()
func step(delta:float)->void:
 if flash_left>0.0:
  flash_left=maxf(0.0,flash_left-delta);sync_visual()
 if not active():return
 var actor=owner_ref.get_ref() if owner_ref!=null else null
 if not is_instance_valid(actor) or actor.health<=0.0:
  clear();return
 age+=maxf(0.0,delta)
 time_left=maxf(0.0,time_left-delta)
 if time_left<=0.0:clear()
func resolve_hit(damage:float,incoming_direction:=Vector3.ZERO)->Dictionary:
 var result:Dictionary={"absorbed":0.0,"parry":false,"broken":false,"stamina_spent":0.0,"mana_refund":0.0,"tier":0,"tier_name":"None"}
 if not active():return result
 var actor=owner_ref.get_ref() if owner_ref!=null else null
 if not is_instance_valid(actor):clear();return result
 var incoming:=maxf(0.0,damage)
 var parry_ready:=can_parry() and incoming<=remaining+0.0001
 var before:float=actor.stamina
 var exhausted:bool=not parry_ready and not actor.practice_god_mode and incoming>before+0.0001
 if not parry_ready:actor.spend_stamina(minf(before,incoming))
 result.stamina_spent=maxf(0.0,before-actor.stamina)
 if exhausted:
  result.broken=true;clear();return result
 result.absorbed=absorb(incoming)
 if incoming>0.0 and float(result.absorbed)+0.0001>=incoming:
  result.parry=parry_ready
  var directional:bool=parry_ready and not incoming_direction.is_zero_approx() and actor.global_basis.z.normalized().dot(-incoming_direction.normalized())>=cos(DIRECTION_HALF_ANGLE)-0.000001
  result.tier=3 if directional else (2 if parry_ready else 1)
  result.tier_name=["None","Block","Perfect timing","Directional perfect"][int(result.tier)]
  if parry_ready:actor.parry_cast_haste.grant(2 if directional else 1)
  if parry_ready:
   var refund_target:=parry_mana_refund*(2.0 if directional else 1.0)
   var refund:=maxf(0.0,refund_target-refunded_mana)
   var mana_before:float=actor.mana
   actor.mana=minf(actor.MAX_MANA,actor.mana+refund)
   result.mana_refund=actor.mana-mana_before
   refunded_mana=maxf(refunded_mana,refund_target)
   parry_refunded=true
  flash_color=TIER_COLORS[int(result.tier)-1]
  flash_left=BLOCK_FLASH_SECONDS;sync_visual()
 return result
func absorb(damage:float)->float:
 if not active():return 0.0
 var absorbed:=minf(remaining,maxf(0.0,damage))
 remaining-=absorbed
 if remaining<=0.0:clear()
 return absorbed
func clear()->void:
 remaining=0.0;time_left=0.0;age=INF;flash_left=0.0
 sync_visual()
func sync_visual()->void:
 Overlay.set_strength(overlays,1.0 if active() else 0.0,"self_barrier")
 Overlay.set_block_flash(overlays,flash_left/BLOCK_FLASH_SECONDS,flash_color)
