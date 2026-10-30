extends "res://scripts/examples/corkscrew_hook_slash_demo.gd"
const HOOK_DELAY:=0.14
const HOOK_LENGTH:=0.46666667

func demo_name() -> String:
	return "Corkscrew Delayed Melee Hook"

func swing_credits() -> Array:
	return [Credits.source(hook_source)]

func sample_swing(time:float) -> Dictionary:
	# Both the backflip counterbalance and the separate torso/arm layers use
	# only the exact Melee Hook. No slash samples enter this version.
	return sample_source(hook_source,clampf((time-HOOK_DELAY)/HOOK_LENGTH,0,1))

func derived_entry(source:Dictionary,title:String,resource:Dictionary,group:String,category:String,step:String,parents:Array,operation:String) -> Dictionary:
	if step=="Flip":
		operation="delayed inverted backflip with Melee Hook hip and counterbalance motion"
	else:
		source=hook_source
		parents=swing_credits()
		title="Melee Hook · torso" if group=="Motion" else "Melee Hook · right arm"
		operation="exact Melee Hook only; delayed 0.14 seconds; no slash"
		if group=="Attack":step="Hook"
	return super.derived_entry(source,title,resource,group,category,step,parents,operation)

func make_clip(editor:Node,entry:Dictionary,id:int,track:String,start:float,duration:float,priority:int,stamina:float) -> Dictionary:
	var clip:=super.make_clip(editor,entry,id,track,start,duration,priority,stamina)
	if id in [3,4]:
		clip.start=ATTACK_START+HOOK_DELAY
		clip.duration=HOOK_LENGTH
		clip.source_in=HOOK_DELAY
		clip.speed=1.0
	return clip
