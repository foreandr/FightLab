extends RefCounted
## Animation metadata plus Touch-specific pose ownership and physical tradeoff.
const HEAD:="Head"
const ARMS:="Arm"
const LEGS:="Leg"
const WHOLE_BODY:="Movement"
const TYPES:=[HEAD,ARMS,LEGS,WHOLE_BODY]
const LEGACY_TYPES:={"Arms":"Arm","Legs":"Leg","Whole body":"Movement"}
const LEG_PHYSICAL_BONUS:=0.20
const LEG_DRAG:=4.5
const BODY_DRAG:=2.25
const LEG_RECOVERY_START:=0.0
const RECOVERY_FRACTION:=0.25
const MAX_RECOVERY_SECONDS:=0.35
static func normalize(value:String) -> String:return str(LEGACY_TYPES.get(value,value))
static func declared(profile:Dictionary) -> bool:
 return normalize(str(profile.get("animation_type",""))) in TYPES
static func legacy_type(profile:Dictionary) -> String:
 if declared(profile):return normalize(str(profile.animation_type))
 var components:Variant=profile.get("animation_components",[])
 if components is Array and not components.is_empty():return composite_type(components)
 if profile.has("composed_timeline"):return composite_type(profile.composed_timeline.get("clips",[]))
 var track:=str(profile.get("track",""))
 if track=="HEAD":return HEAD
 if track in ["TORSO","LEFT ARM","RIGHT ARM"]:return ARMS
 if track in ["LEFT LEG","RIGHT LEG"]:return LEGS
 var bone:=str(profile.get("attack_bone",""))
 if bone in ["Head","head","mouth","neck_01"]:return HEAD
 if bone.begins_with("calf_") or bone.begins_with("foot_") or bone.begins_with("ball_") or bone.begins_with("thigh_"):return LEGS
 if str(profile.get("category","")) in ["Kick","Knee","Sweep"]:return LEGS
 if str(profile.get("category","")) in ["Punch","Elbow","Block","Uppercut","Slash"]:return ARMS
 return WHOLE_BODY
static func kind(profile:Dictionary) -> String:
 return normalize(str(profile.animation_type)) if declared(profile) else legacy_type(profile)
## Standalone animation editing retains regional ownership. For spells, only
## Touch interprets the type; other delivery methods share unrestricted movement.
static func applies(profile:Dictionary) -> bool:
 if profile.has("delivery_type"):return str(profile.delivery_type)=="Touch"
 return not profile.has("projectile_element")
static func owns_legs(profile:Dictionary) -> bool:return applies(profile) and kind(profile) in [LEGS,WHOLE_BODY]
static func physical_multiplier(profile:Dictionary) -> float:
 return 1.0+LEG_PHYSICAL_BONUS if str(profile.get("delivery_type",""))=="Touch" and kind(profile)==LEGS else 1.0
static func begin(actor:Node3D,profile:Dictionary,movement:Vector3=Vector3.INF) -> void:
 var velocity:Vector3=movement if movement.is_finite() else actor.velocity
 velocity.y=0.0
 actor.set_meta("animation_cast_momentum",velocity if applies(profile) else Vector3.ZERO)
static func drift(actor:Node3D,profile:Dictionary,delta:float) -> Vector3:
 if not applies(profile):return Vector3.ZERO
 var velocity:Vector3=actor.get_meta("animation_cast_momentum",Vector3.ZERO)
 velocity*=exp(-(LEG_DRAG if kind(profile)==LEGS else BODY_DRAG)*maxf(0.0,delta))
 if velocity.length()<0.05:velocity=Vector3.ZERO
 actor.set_meta("animation_cast_momentum",velocity)
 return velocity
static func description(type_:String) -> String:
 match normalize(type_):
  HEAD:return "Head only · movement stays available."
  ARMS:return "Running legs + upper-body cast."
  LEGS:return "Leg region · Touch: momentum slows · +20% physical damage."
  WHOLE_BODY:return "Entire body · momentum carries forward and slows."
 return "Choose an animation type before saving."

## Regions describe contributions, independent of the destination timeline track.
static func controls_bone(rig:Skeleton3D,index:int,type_:String) -> bool:
 type_=normalize(type_)
 if type_==WHOLE_BODY:return true
 var bone:=rig.get_bone_name(index)
 if type_==LEGS and bone in ["root","pelvis"]:return true
 if type_==ARMS and bone.begins_with("spine_"):return true
 while index>=0:
  bone=rig.get_bone_name(index)
  if type_==HEAD and bone in ["Head","neck_01"]:return true
  if type_==ARMS and (bone.begins_with("clavicle_") or bone.begins_with("upperarm_")):return true
  if type_==LEGS and bone.begins_with("thigh_"):return true
  index=rig.get_bone_parent(index)
 return false

static func affects_channel(profile:Dictionary,channel:String) -> bool:
 if not applies(profile):return true
 match kind(profile):
  HEAD:return channel=="face"
  ARMS:return channel in ["torso","arm_l","arm_r"]
  LEGS:return channel in ["root","leg_l","leg_r"]
 return true

static func restore_outside(actor:Node,baseline:Array[Transform3D],profile:Dictionary) -> void:
 var type_:=kind(profile) if applies(profile) else WHOLE_BODY
 for index in mini(baseline.size(),actor.skeleton.get_bone_count()):
  if not controls_bone(actor.skeleton,index,type_):actor.skeleton.set_bone_pose(index,baseline[index])
 actor.skeleton.force_update_all_bone_transforms()

static func composite_type(components:Array) -> String:
 var types:Array=[]
 for component in components:
  if component is Dictionary:types.append(contribution_type(component))
 for type_ in [WHOLE_BODY,LEGS,ARMS,HEAD]:
  if type_ in types:return type_
 return WHOLE_BODY

static func component_types(profile:Dictionary) -> Array[String]:
 var result:Array[String]=[]
 var components:Array=profile.get("animation_components",profile.get("composed_timeline",{}).get("clips",[]))
 for component in components:
  if not component is Dictionary:continue
  var type_:=kind(component)
  if type_ not in result:result.append(type_)
 return result

static func emitter(profile:Dictionary,fallback:String="hand_r") -> String:
 var bone:=str(profile.get("attack_bone",fallback))
 if bone.is_empty():bone=fallback
 if not applies(profile):return "Head" if bone in ["head","mouth"] else bone
 match kind(profile):
  HEAD:return "Head"
  ARMS:
   if bone in ["Head","head","mouth"] or bone.begins_with("thigh_") or bone.begins_with("calf_") or bone.begins_with("foot_") or bone.begins_with("ball_"):return "hand_r"
  LEGS:
   if not (bone.begins_with("thigh_") or bone.begins_with("calf_") or bone.begins_with("foot_") or bone.begins_with("ball_")):return "calf_r"
 return "Head" if bone in ["head","mouth"] else bone

static func components(clips:Array) -> Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for clip in clips:
  if not clip is Dictionary:continue
  var component:Dictionary={"animation_type":contribution_type(clip),"source_animation_type":kind(clip)}
  for key in ["title","clip","track","start","duration","priority","animation_resource","store_asset_id"]:
   if clip.has(key):component[key]=clip[key]
  if clip.has("animation_components"):component["animation_components"]=clip.animation_components.duplicate(true)
  result.append(component)
 return result

static func contribution_type(profile:Dictionary) -> String:
 match str(profile.get("track","BODY")):
  "HEAD":return HEAD
  "TORSO","LEFT ARM","RIGHT ARM":return ARMS
  "LEFT LEG","RIGHT LEG":return LEGS
 return kind(profile)

## Restore movement during the recovery tail, without cancelling the cast.
static func recovery_weight(profile:Dictionary,elapsed:float,duration:float,release_fraction:float=0.0) -> float:
 if not owns_legs(profile) or duration<=0.0:return 0.0
 var window:=duration*(1.0-LEG_RECOVERY_START) if kind(profile)==LEGS else minf(MAX_RECOVERY_SECONDS,duration*RECOVERY_FRACTION)
 var start:=maxf(duration-window,duration*clampf(release_fraction,0.0,1.0))
 if duration-start<=0.00001:return 0.0
 return smoothstep(start,duration,elapsed)
