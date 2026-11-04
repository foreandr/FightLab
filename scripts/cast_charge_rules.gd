extends RefCounted
## Shared charge policy. Input adapters supply time; combat still owns payment/hits.
const PERFECT_START:=1.0
const PERFECT_END:=1.25
const TIRED_AT:=2.25
const COLORS:=[Color("f3f5ff"),Color("67eb9a"),Color("67bfff"),Color("ffd35b"),Color("ff4a43")]
const NAMES:=["Tap","Good","Better","Perfect","Overheld"]
static func sample(seconds:float)->Dictionary:
 var time:=maxf(0.0,seconds) if is_finite(seconds) else 0.0
 var tier:=4 if time>=PERFECT_END else (3 if time>=PERFECT_START else (2 if time>=2.0/3.0 else (1 if time>=1.0/3.0 else 0)))
 var multiplier:=lerpf(1.0,2.0,smoothstep(0.0,PERFECT_START,time))
 if time>=PERFECT_END:multiplier=lerpf(2.0,0.15,smoothstep(PERFECT_END,TIRED_AT,time))
 var stamina_multiplier:=1.0+0.15*smoothstep(0.0,PERFECT_START,time)
 if time>=PERFECT_START:stamina_multiplier=1.0
 if time>=PERFECT_END:stamina_multiplier=lerpf(1.0,0.75,smoothstep(PERFECT_END,TIRED_AT,time))
 return {"stamina_multiplier":stamina_multiplier,"seconds":time,"tier":tier,"name":NAMES[tier],"color":COLORS[tier],"multiplier":multiplier}
static func apply(spec:Dictionary,seconds:float,reference_exertion:float=-1.0)->Dictionary:
 var state:=sample(seconds)
 var multiplier:float=state.multiplier
 var stamina_multiplier:float=state.stamina_multiplier
 for key in ["damage","physical_damage","motion_damage"]:
  if spec.has(key):spec[key]=maxf(0.0,float(spec[key]))*multiplier
 # Authored jumps still pay their minimum physical takeoff requirement.
 var jump:=maxf(0.0,float(spec.get("jump_stamina_cost",0.0)))
 var exertion:=reference_exertion if reference_exertion>=0.0 else maxf(0.0,float(spec.get("stamina_cost",0.0))-jump)
 spec["stamina_cost"]=exertion*stamina_multiplier+jump
 if spec.has("touch_contact_stamina"):spec.touch_contact_stamina=float(spec.touch_contact_stamina)*stamina_multiplier
 spec["cast_charge_stamina_multiplier"]=stamina_multiplier
 spec["cast_charge_seconds"]=state.seconds;spec["cast_charge_tier"]=state.tier;spec["cast_charge_multiplier"]=multiplier
 return spec
