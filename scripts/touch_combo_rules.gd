extends RefCounted
## Shared Touch linking rules; no controller-specific speed or damage bonuses.
const LINK_PROGRESS:=0.50
const LINK_BLEND_SECONDS:=0.05
const ALTERNATING_SPEED:=1.12
const LEG_LINK_PROGRESS:=0.90
static func leg_attack(item:Dictionary)->bool:
 if str(item.get("animation_type","")) in ["Leg","Legs"]:return true
 var bones:Array=item.get("touch_contacts",[]).duplicate()
 bones.append(str(item.get("attack_bone",item.get("hand",""))))
 for value in bones:
  var bone:=str(value)
  if bone.begins_with("foot_") or bone.begins_with("ball_") or bone.begins_with("calf_") or bone.begins_with("thigh_") or bone.begins_with("leg_") or bone.begins_with("knee_"):return true
 return false
static func needs_recovery(profile:Dictionary)->bool:
 return leg_attack(profile) or not preload("res://scripts/animation_jump_motion.gd").settings(profile).is_empty()
static func link_progress(profile:Dictionary)->float:
 var source_default:=0.63 if str(profile.get("clip","")).begins_with("boxing/hook_") else LINK_PROGRESS
 var minimum:=LEG_LINK_PROGRESS if needs_recovery(profile) else LINK_PROGRESS
 return clampf(float(profile.get("combo_link_progress",maxf(source_default,minimum))),minimum,0.95)
static func link_end(profile:Dictionary)->float:return 0.985 if needs_recovery(profile) else 0.90
static func arm_attack(item:Dictionary)->bool:
 if leg_attack(item) or not item.get("jump_motion",{}).is_empty():return false
 var bone:=str(item.get("hand",item.get("attack_bone","")))
 return bone.begins_with("hand_") or bone.begins_with("lowerarm_") or bone.begins_with("upperarm_") or bone.begins_with("elbow_")
static func side(bone:String)->String:
 if bone.ends_with("_l"):return "left"
 if bone.ends_with("_r"):return "right"
 return ""
static func speed(previous:Dictionary,next:Dictionary)->float:
 if not arm_attack(previous) or not arm_attack(next):return 1.0
 var a:=side(str(previous.get("hand","")))
 var b:=side(str(next.get("hand","")))
 return ALTERNATING_SPEED if not a.is_empty() and not b.is_empty() and a!=b else 1.0

## Shared recovery gate for player and tool adapters. Never cancel a windup.
static func can_link(profile:Dictionary,progress:float,released:bool)->bool:
 return released and progress>=link_progress(profile)
