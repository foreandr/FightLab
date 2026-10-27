extends RefCounted
## Completion-driven choreography. New primitives can be added without spell presets.
const OPTIONS := ["End","Dash","Punch","Knee","Jump","Flip","Twist","Land","Run","Sprint","Crouch","Block","Brace Block","Dodge Back","Dodge Left","Dodge Right","Roll Back","Kick","Round Kick","Cross","Hook","Uppercut","Spell Throw","Slash Throw"]
var steps: Array[String]=[]
var index := -1
var active := false
var status := "Ready"
var step_time := 0.0
var direction := 0
var history: Array[String]=[]
const ATTACKS := ["Punch","Knee","Kick","Round Kick","Cross","Hook","Uppercut","Spell Throw","Slash Throw"]

static func allowed_for_state(step: String,grounded: bool) -> bool:
	if step=="End":return true
	if step in ATTACKS:return true
	return not grounded if step in ["Flip","Twist","Land"] else grounded

static func state_after(step: String,grounded: bool) -> bool:
	if step=="Jump":return false
	if step=="Land":return true
	return grounded

static func needs_mana(chosen: Array) -> bool:
	return chosen.any(func(step):return step in ["Block","Brace Block","Spell Throw","Slash Throw"])

func reset() -> void:
	steps.clear()
	history.clear()
	index=-1
	active=false
	status="Ready"
	step_time=0

func start(fighter: CharacterBody3D,chosen: Array[String],dash_direction: int) -> void:
	reset()
	steps=chosen.duplicate()
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
	status="Step %d / %d: %s"%[index+1,steps.size(),step]
	var accepted:=true
	# A long airborne attack can naturally land before its queued Land marker.
	if not allowed_for_state(step,fighter.is_on_floor()) and step!="Land":
		active=false
		status="Stopped: %s requires %s"%[step,"airborne" if step in ["Flip","Twist","Land"] else "grounded"]
		return
	match step:
		"Dash": accepted=fighter.start_motion_dash(direction)
		"Punch","Knee","Kick","Round Kick","Cross","Hook":
			var move_index: int={"Punch":0,"Cross":1,"Kick":2,"Knee":3,"Hook":4,"Round Kick":5}[step]
			accepted=fighter.stamina>=[8,11,15,13,12,17][move_index]
			if accepted:
				fighter.melee_sequence=move_index
				fighter.start_punch()
		"Jump": accepted=fighter.start_motion_jump()
		"Flip","Twist": accepted=fighter.start_air_trick(step)
		"Land": pass # Gravity and the existing landing animation finish this step.
		"Run","Sprint","Crouch","Block","Brace Block","Dodge Back","Dodge Left","Dodge Right","Roll Back": accepted=fighter.start_editor_motion(step)
		"Uppercut":
			accepted=fighter.stamina>=28
			if accepted:fighter.start_uppercut()
		"Spell Throw","Slash Throw":
			var spell_index:=0 if step=="Spell Throw" else 1
			var spec: Dictionary=fighter.arena.profile_spells(fighter.team)[spell_index]
			accepted=fighter.mana>=fighter.arena.mana_cost(spec)
			if accepted:
				fighter.spell_cursor=spell_index
				fighter.charge_requested=0
				fighter.start_cast(false)
				accepted=fighter.mode=="cast"
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
	if step_time>4:
		active=false
		status="Stopped: step timed out"
		return
	var step: String=steps[index]
	var complete: bool=false
	match step:
		"Dash": complete=fighter.mode!="motion_dash"
		"Punch","Knee","Kick","Round Kick","Cross","Hook": complete=fighter.mode!="punch"
		"Run","Sprint": complete=fighter.mode!="motion_dash"
		"Crouch": complete=fighter.mode!="motion_pose"
		"Block","Brace Block": complete=fighter.mode!="shield"
		"Dodge Back","Dodge Left","Dodge Right": complete=fighter.mode!="dodge_back"
		"Roll Back": complete=fighter.mode!="roll_back"
		"Uppercut": complete=fighter.mode not in ["melee_charge","punch"]
		"Spell Throw","Slash Throw": complete=fighter.mode!="cast"
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
