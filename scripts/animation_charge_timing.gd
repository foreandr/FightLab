extends RefCounted
## Shared animation timing policy, independent of input/UI and combat mode.
static func duration_range(profile:Dictionary)->Vector2:
 var native:=clampf(float(profile.get("source_duration",profile.get("duration",profile.get("source_length",1.0)))),0.1,60.0)
 var minimum:=clampf(maxf(preload("res://scripts/animation_jump_motion.gd").minimum(profile),float(profile.get("min_duration",native*0.7))),0.1,60.0)
 return Vector2(minimum,clampf(float(profile.get("max_duration",native*1.6)),minimum,60.0))

static func charge_window(profile:Dictionary)->float:
 var range_:=duration_range(profile)
 return maxf(0.1,(range_.x+range_.y)*0.5)
static func normalized_hold(profile:Dictionary,held_seconds:float)->float:
 return maxf(0.0,held_seconds)/charge_window(profile)
