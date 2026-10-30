extends RefCounted
## Source animation recipes match the normal editor actions. Editable pose
## offsets layer over the original tracks, so zero edits preserve every key.

static func duration(actor:Node,step:String,clip:String) -> float:
	match step:
		"Punch","Cross","Hook","Kick","Round Kick","Knee","Elbow","Sweep","Uppercut","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast":return actor.player.get_animation(clip).length/1.25+0.08
		"Idle":return 3.0
		"Run","Sprint":return 0.8
		"Dash":return 0.30
		"Crouch":return 0.9
		"Block","Brace Block":return 1.0
		"Dodge Back","Dodge Left","Dodge Right":return 0.4
		"Roll Back":return 0.72
		"Land":return 0.24
		"Flip":return actor.BACKFLIP_DURATION
		"Twist":return actor.TWIST_DELAY+actor.TWIST_DURATION
		"Jump":return 0.14+2.0*10.8/actor.GRAVITY
	return maxf(0.2,actor.player.get_animation(clip).length)

static func clip_at(actor:Node,step:String,clip:String,progress:float,source_duration:float) -> Dictionary:
	var time:=clampf(progress,0.0,1.0)*source_duration
	if step in ["Punch","Cross","Hook","Kick","Round Kick","Knee","Elbow","Sweep","Uppercut","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast"]:return _at_time(actor,clip,time*1.25)
	if step=="Jump":
		return _at_time(actor,"duel/takeoff",time*1.35) if time<0.14 else _at_time(actor,"duel/air",time-0.14)
	if step in ["Block","Brace Block"]:
		var style:="palm" if step=="Block" else "brace"
		if time<0.22:return _at_time(actor,"duel/shield_raise_"+style,time)
		if time<0.76:return _at_time(actor,"duel/shield_hold_"+style,time-0.22)
		return _at_time(actor,"duel/shield_lower_"+style,time-0.76)
	if step in ["Flip","Twist"]:return {"name":clip,"blend":clampf(progress,0.0,1.0)}
	var speed:float={"Sprint":1.75,"Dash":1.35,"Dodge Left":3.0,"Dodge Right":3.0}.get(step,1.0)
	return _at_time(actor,clip,time*speed)

static func _at_time(actor:Node,clip:String,time:float) -> Dictionary:
	var animation:Animation=actor.player.get_animation(clip)
	if animation.loop_mode!=Animation.LOOP_NONE:time=fposmod(time,animation.length)
	return {"name":clip,"blend":clampf(time/maxf(0.001,animation.length),0,1)}
