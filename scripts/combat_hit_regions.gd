extends RefCounted
## Direct physical-hit rules. Status potency and damage-over-time stay separate.
const HEAD_PHYSICAL_MULTIPLIER:=2.0
const FLASH_SECONDS:=0.45
const HEAD_COLOR:=Color("ffbb55")
const BODY_COLOR:=Color("ff69c7")
static func is_head(zone:String) -> bool:return zone.to_lower()=="head"
static func physical_multiplier(zone:String) -> float:return HEAD_PHYSICAL_MULTIPLIER if is_head(zone) else 1.0
static func reaction(zone:String) -> String:return "ual1/Hit_Head" if is_head(zone) else "ual1/Hit_Chest"
static func color(zone:String) -> Color:return HEAD_COLOR if is_head(zone) else BODY_COLOR
static func label(_zone:String) -> String:
	return ""
