extends Node
## Actor-owned presentation only. Shared cast rules still determine all power.
const Overlay=preload("res://scripts/body_barrier_overlay.gd")
var actor:CharacterBody3D
var bone:="hand_r"
var tier:=0
var holding:=false
var pulse:=0.0
var fade:=0.0
var overlays:Array=[]

func setup(owner_actor:CharacterBody3D)->void:
 actor=owner_actor;name="CastChargeFeedback"
 overlays=Overlay.apply(actor.skeleton)

func begin(emitter:String)->void:
 bone=emitter;tier=0;holding=true;fade=1.0;pulse=0.0
 refresh()

func progress(value:float)->void:
 if not holding:return
 var reached:=clampi(floori(clampf(value,0.0,1.0)*3.0+0.0001),0,3)
 if reached>tier:
  for next in range(tier+1,reached+1):actor.arena.audio.impact("charge_"+str(next),actor.bone_point(bone),0.35+next*0.2)
  tier=reached;pulse=1.0
 refresh()

func finish()->void:holding=false

func refresh()->void:
 # A visual contribution shares the barrier's skinned shell, not its defenses.
 # The source key keeps ending a charge from clearing an actual active shield.
 Overlay.set_strength(overlays,fade*(0.12+tier*0.24+pulse*0.15),"cast_charge")

func _process(delta:float)->void:
 pulse=maxf(0.0,pulse-delta*5.0)
 if not holding:fade=maxf(0.0,fade-delta*7.0)
 if is_instance_valid(actor):refresh()
