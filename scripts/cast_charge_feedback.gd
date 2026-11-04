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
var quote_label:Label3D
var state:Dictionary={}

func setup(owner_actor:CharacterBody3D)->void:
 actor=owner_actor;name="CastChargeFeedback"
 overlays=Overlay.apply(actor.skeleton)
 quote_label=Label3D.new();quote_label.name="ChargeQuote";quote_label.position=Vector3(0,3.3,0)
 quote_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;quote_label.font=preload("res://assets/fonts/Cinzel.ttf")
 quote_label.font_size=30;quote_label.pixel_size=0.004;quote_label.outline_size=7;quote_label.visible=false
 actor.add_child(quote_label)

func begin(emitter:String)->void:
 bone=emitter;tier=0;holding=true;fade=1.0;pulse=0.0
 state=preload("res://scripts/cast_charge_rules.gd").sample(0.0)
 quote_label.text="Tap"
 refresh()

func progress(value:float)->void:
 if not holding:return
 state=preload("res://scripts/cast_charge_rules.gd").sample(value)
 var reached:int=state.tier
 if reached>tier:
  for next in range(tier+1,mini(3,reached)+1):actor.arena.audio.impact("charge_"+str(next),actor.bone_point(bone),0.35+next*0.2)
  tier=reached;pulse=1.0
 refresh()

func show_quote(spec:Dictionary)->void:
 if not is_instance_valid(quote_label):return
 var text:="%s\nPhysical %.1f · Stamina %.1f"%[state.get("name","Tap"),float(spec.get("damage",0.0)),float(spec.get("stamina_cost",0.0))]
 if quote_label.text!=text:quote_label.text=text

func finish()->void:holding=false

func refresh()->void:
 # A visual contribution shares the barrier's skinned shell, not its defenses.
 # The source key keeps ending a charge from clearing an actual active shield.
 var intensity:=0.12+mini(3,tier)*0.24+pulse*0.15
 Overlay.set_strength(overlays,fade*intensity,"cast_charge")
 var color:Color=state.get("color",Color.WHITE)
 Overlay.set_charge_color(overlays,color)
 if is_instance_valid(quote_label):
  quote_label.modulate=Color(color,fade);quote_label.visible=fade>0.01

func _process(delta:float)->void:
 pulse=maxf(0.0,pulse-delta*5.0)
 if not holding:fade=maxf(0.0,fade-delta*7.0)
 if is_instance_valid(actor):refresh()
