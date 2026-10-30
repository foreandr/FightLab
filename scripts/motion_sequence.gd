extends RefCounted
## Completion-driven choreography. New primitives can be added without spell presets.
const OPTIONS := ["End","Idle","Dash","Punch","Knee","Jump","Flip","Twist","Land","Run","Sprint","Crouch","Block","Brace Block","Dodge Back","Dodge Left","Dodge Right","Roll Back","Kick","Round Kick","Cross","Hook","Elbow","Sweep","Uppercut","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast"]
var steps: Array[String]=[]
var profiles:Array[Dictionary]=[]
var index := -1
var active := false
var status := "Ready"
var step_time := 0.0
var direction := 0
var history: Array[String]=[]
const ATTACKS := ["Punch","Knee","Kick","Round Kick","Cross","Hook","Elbow","Sweep","Uppercut","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast"]

static func allowed_for_state(step: String,grounded: bool) -> bool:
	if step=="End":return true
	if step in ATTACKS:return true
	return not grounded if step in ["Flip","Twist","Land"] else grounded

static func state_after(step: String,grounded: bool) -> bool:
	if step=="Jump":return false
	if step=="Land":return true
	return grounded

static func needs_mana(chosen: Array) -> bool:
	return chosen.any(func(step):return step in ["Block","Brace Block"])

func reset() -> void:
	steps.clear()
	profiles.clear()
	history.clear()
	index=-1
	active=false
	status="Ready"
	step_time=0

func start(fighter: CharacterBody3D,chosen: Array[String],dash_direction: int,chosen_profiles:Array=[]) -> void:
	reset()
	steps=chosen.duplicate()
	for i in steps.size():profiles.append(chosen_profiles[i].duplicate(true) if i<chosen_profiles.size() and chosen_profiles[i] is Dictionary else {})
	if fighter.has_method("set_editor_animation_profile"):fighter.set_editor_animation_profile({},"")
	direction=dash_direction
	active=true
	next_step(fighter)

func next_step(fighter: CharacterBody3D) -> void:
	index+=1
	step_time=0
	if index>=steps.size():
		active=false
		status="Combo complete"
		return
	var step: String=steps[index]
	var animation_name:String=str(profiles[index].get("title",step))
	status="Step %d / %d: %s"%[index+1,steps.size(),animation_name]
	var accepted:=true
	# A long airborne attack can naturally land before its queued Land marker.
	if not allowed_for_state(step,fighter.is_on_floor()) and step!="Land":
		active=false
		status="Stopped: %s requires %s"%[step,"airborne" if step in ["Flip","Twist","Land"] else "grounded"]
		return
	if fighter.has_method("set_editor_animation_profile"):fighter.set_editor_animation_profile(profiles[index],step)
	match step:
		"Dash": accepted=fighter.start_motion_dash(direction)
		"Punch","Knee","Kick","Round Kick","Cross","Hook":
			var move_index: int={"Punch":0,"Cross":1,"Kick":2,"Knee":3,"Hook":4,"Round Kick":5}[step]
			accepted=fighter.stamina>=[8,11,15,13,12,17][move_index]
			if accepted:
				fighter.melee_sequence=move_index
				fighter.start_punch()
		"Elbow","Sweep":
			accepted=fighter.stamina>=12 if step=="Elbow" else fighter.stamina>=17
			if accepted:
				fighter.begin_strike(["elbow","editor_attacks/elbow","lowerarm_r",0.18,0.36,12.0,12.0,1.0] if step=="Elbow" else ["sweep","fight/sweep","ball_r",0.25,0.70,17.0,17.0,1.3])
		"Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast":
			var specs:Dictionary={
				"Palm Cast":["palm_cast","editor_attacks/default_spell_cast","hand_r",0.12,0.34,8.0,8.0,1.0],
				"Sky Palm":["sky_palm","editor_attacks/sky_palm","hand_r",0.25,0.52,12.0,12.0,1.0],
				"Ground Punch":["ground_punch","editor_attacks/ground_punch","hand_r",0.29,0.58,17.0,17.0,1.0],
				"Stomp":["stomp","editor_attacks/stomp","ball_r",0.30,0.49,16.0,16.0,1.0],
				"Body Slash":["body_slash","editor_attacks/body_slash","hand_r",0.25,0.52,12.0,12.0,1.0]
			}
			accepted=fighter.stamina>=float(specs[step][6])
			if accepted:fighter.begin_strike(specs[step])
		"Jump": accepted=fighter.start_motion_jump()
		"Flip","Twist": accepted=fighter.start_air_trick(step)
		"Land": pass # Gravity and the existing landing animation finish this step.
		"Idle","Run","Sprint","Crouch","Block","Brace Block","Dodge Back","Dodge Left","Dodge Right","Roll Back": accepted=fighter.start_editor_motion(step)
		"Uppercut":
			accepted=fighter.stamina>=18
			if accepted:fighter.start_uppercut()
		_: accepted=false
	if not accepted:
		active=false
		status="Stopped: %s could not start (check stamina / grounding)"%step
	else:
		history.append(step)

func tick(fighter: CharacterBody3D,delta: float) -> void:
	if not active:
		return
	step_time+=delta
	if fighter.health<=0 or fighter.mode in ["hit","ragdoll","frozen","getup","ko"]:
		active=false
		status="Combo interrupted"
		return
	if step_time>maxf(4.0,float(profiles[index].get("duration",0.0))+1.0):
		active=false
		status="Stopped: step timed out"
		return
	var step: String=steps[index]
	var complete: bool=false
	match step:
		"Dash": complete=fighter.mode!="motion_dash"
		"Punch","Knee","Kick","Round Kick","Cross","Hook","Elbow","Sweep","Sky Palm","Ground Punch","Stomp","Body Slash","Palm Cast": complete=fighter.mode!="punch"
		"Run","Sprint": complete=fighter.mode!="motion_dash"
		"Idle","Crouch": complete=fighter.mode!="motion_pose"
		"Block","Brace Block": complete=fighter.mode!="shield"
		"Dodge Back","Dodge Left","Dodge Right": complete=fighter.mode!="dodge_back"
		"Roll Back": complete=fighter.mode!="roll_back"
		"Uppercut": complete=fighter.mode not in ["melee_charge","punch"]
		"Jump":
			var aerial_next: bool=index+1<steps.size() and (steps[index+1] in ["Flip","Twist","Land"] or steps[index+1] in ATTACKS)
			complete=not fighter.is_on_floor() and fighter.mode!="takeoff" if aerial_next else step_time>0.2 and fighter.is_on_floor() and fighter.mode not in ["takeoff","land"]
		"Flip": complete=fighter.mode!="air_trick"
		"Twist":
			# An attack in the following slot starts during the turn, not after it.
			var attack_next: bool=index+1<steps.size() and steps[index+1] in ATTACKS
			complete=fighter.mode!="air_trick" or (attack_next and fighter.twist_age>=fighter.TWIST_DELAY)
		"Land": complete=fighter.is_on_floor() and fighter.mode not in ["takeoff","land"]
	if complete:
		next_step(fighter)
