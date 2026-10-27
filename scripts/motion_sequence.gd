extends RefCounted
## Completion-driven choreography. New primitives can be added without spell presets.
const OPTIONS := ["End","Dash","Punch","Knee","Jump"]
var steps: Array[String]=[]
var index := -1
var active := false
var status := "Ready"
var step_time := 0.0
var direction := 0
var quick := false
var history: Array[String]=[]

func reset() -> void:
	steps.clear()
	history.clear()
	index=-1
	active=false
	status="Ready"
	step_time=0

func start(fighter: CharacterBody3D,chosen: Array[String],dash_direction: int,quick_dash: bool) -> void:
	reset()
	steps=chosen.duplicate()
	direction=dash_direction
	quick=quick_dash
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
	match step:
		"Dash": accepted=fighter.start_motion_dash(direction,quick)
		"Punch","Knee":
			accepted=fighter.stamina>= (13 if step=="Knee" else 8)
			if accepted:
				fighter.melee_sequence=3 if step=="Knee" else 0
				fighter.start_punch()
		"Jump": accepted=fighter.start_motion_jump()
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
		"Punch","Knee": complete=fighter.mode!="punch"
		"Jump": complete=step_time>0.2 and fighter.is_on_floor() and fighter.mode not in ["takeoff","land"]
	if complete:
		next_step(fighter)
