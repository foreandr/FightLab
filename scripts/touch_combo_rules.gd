extends RefCounted
## Shared Touch linking rules; no controller-specific speed or damage bonuses.
const LINK_PROGRESS:=0.55
const ALTERNATING_SPEED:=1.12
static func side(bone:String)->String:
 if bone.ends_with("_l"):return "left"
 if bone.ends_with("_r"):return "right"
 return ""
static func speed(previous:Dictionary,next:Dictionary)->float:
 var a:=side(str(previous.get("hand","")))
 var b:=side(str(next.get("hand","")))
 return ALTERNATING_SPEED if not a.is_empty() and not b.is_empty() and a!=b else 1.0
