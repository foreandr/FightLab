extends RefCounted
## Shared full-body get-up; independent of the spell/animation currently equipped.
const CLIP:="recovery/arms_lariat"
const ANIMATION=preload("res://assets/animations/recovery/arms_lariat.res")
const Timing=preload("res://scripts/ragdoll_recovery_timing.gd")
const NORMAL_SECONDS:=Timing.NORMAL_GETUP_SECONDS
static func ensure(actor:Node)->String:
 if not actor.player.has_animation_library("recovery"):actor.player.add_animation_library("recovery",AnimationLibrary.new())
 if not actor.player.has_animation(CLIP):actor.player.get_animation_library("recovery").add_animation("arms_lariat",ANIMATION)
 return CLIP
static func profile()->Dictionary:
 return {"title":"Arms Lariat Recovery","group":"Motion","category":"Recovery","step":"Imported Motion","clip":CLIP,"animation_resource":"res://assets/animations/recovery/arms_lariat.res","store_raw":true,"animation_type":"Movement","recovery_animation":true,"duration":ANIMATION.length/Timing.GETUP_SPEED,"source_duration":ANIMATION.length/Timing.GETUP_SPEED,"min_duration":Timing.RECOVERY_GETUP_SECONDS,"max_duration":NORMAL_SECONDS,"tags":["recovery","getup","full body"],"store_creator":"foreandr","provenance":ANIMATION.get_meta("provenance",{}).duplicate(true)}
