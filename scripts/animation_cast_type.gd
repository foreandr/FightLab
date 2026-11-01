extends RefCounted
## One declaration controls pose ownership, cast travel and the physical tradeoff.
const ARMS:="Arms"
const LEGS:="Legs"
const WHOLE_BODY:="Whole body"
const TYPES:=[ARMS,LEGS,WHOLE_BODY]
const LEG_PHYSICAL_BONUS:=0.20
const LEG_DRAG:=6.0
const BODY_DRAG:=3.0
static func declared(profile:Dictionary) -> bool:
 return str(profile.get("animation_type","")) in TYPES
static func legacy_type(profile:Dictionary) -> String:
 if declared(profile):return str(profile.animation_type)
 var bone:=str(profile.get("attack_bone",""))
 if bone.begins_with("calf_") or bone.begins_with("foot_") or bone.begins_with("ball_") or bone.begins_with("thigh_"):return LEGS
 if str(profile.get("category","")) in ["Kick","Knee","Sweep"]:return LEGS
 if str(profile.get("category","")) in ["Punch","Elbow","Block","Uppercut","Slash"]:return ARMS
 return WHOLE_BODY
static func kind(profile:Dictionary) -> String:
 return str(profile.animation_type) if declared(profile) else legacy_type(profile)
static func owns_legs(profile:Dictionary) -> bool:return kind(profile)!=ARMS
static func physical_multiplier(profile:Dictionary) -> float:
 return 1.0+LEG_PHYSICAL_BONUS if kind(profile)==LEGS else 1.0
static func begin(actor:Node3D,profile:Dictionary) -> void:
 var velocity:Vector3=actor.velocity
 velocity.y=0.0
 actor.set_meta("animation_cast_momentum",velocity if owns_legs(profile) else Vector3.ZERO)
static func drift(actor:Node3D,profile:Dictionary,delta:float) -> Vector3:
 var velocity:Vector3=actor.get_meta("animation_cast_momentum",Vector3.ZERO)
 velocity*=exp(-(LEG_DRAG if kind(profile)==LEGS else BODY_DRAG)*maxf(0.0,delta))
 if velocity.length()<0.05:velocity=Vector3.ZERO
 actor.set_meta("animation_cast_momentum",velocity)
 return velocity
static func description(type_:String) -> String:
 match type_:
  ARMS:return "Running legs + upper-body cast."
  LEGS:return "Full leg animation · momentum slows · +20% physical damage."
  WHOLE_BODY:return "Full animation · momentum carries forward and slows."
 return "Choose an animation type before saving."
