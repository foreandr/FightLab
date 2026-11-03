extends RefCounted
## Shared Touch linking rules; no controller-specific speed or damage bonuses.
const LINK_PROGRESS:=0.55
const ALTERNATING_SPEED:=1.12
static func link_progress(profile:Dictionary)->float:
 var source_default:=0.68 if str(profile.get("clip","")).begins_with("boxing/hook_") else LINK_PROGRESS
 return clampf(float(profile.get("combo_link_progress",source_default)),LINK_PROGRESS,0.9)
static func side(bone:String)->String:
 if bone.ends_with("_l"):return "left"
 if bone.ends_with("_r"):return "right"
 return ""
static func speed(previous:Dictionary,next:Dictionary)->float:
 var a:=side(str(previous.get("hand","")))
 var b:=side(str(next.get("hand","")))
 return ALTERNATING_SPEED if not a.is_empty() and not b.is_empty() and a!=b else 1.0
