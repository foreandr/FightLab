extends RefCounted
const GROUPS := {
	"Motion":["Idle","Run","Sprint","Jump","Land","Dash","Crouch","Acrobatics"],
	"Attack":["Punch","Kick","Block","Dodges"]
}
static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary]=[
		item("Motion","Idle","Idle","Idle","spells/idle"),
		item("Motion","Run","Run","Run","ual1/Jog_Fwd"),
		item("Motion","Sprint","Sprint","Sprint","duel/run"),
		item("Motion","Jump","Jump","Jump","duel/air","jump"),
		item("Motion","Land","Land","Land","duel/land"),
		item("Motion","Dash","Dash","Dash","duel/dash"),
		item("Motion","Crouch","Crouch","Crouch","ual1/Crouch_Idle"),
		item("Attack","Block","Palm block","Block","duel/shield_hold_palm","block"),
		item("Attack","Block","Braced block","Brace Block","duel/shield_hold_brace","block"),
		item("Attack","Dodges","Dodge backward","Dodge Back","duel/dodge_back"),
		item("Attack","Dodges","Dodge left","Dodge Left","duel/strafe_left"),
		item("Attack","Dodges","Dodge right","Dodge Right","duel/strafe_right"),
		item("Attack","Dodges","Roll backward","Roll Back","duel/roll_back"),
		item("Motion","Acrobatics","Backflip · airborne","Flip","duel/backflip","air"),
		item("Motion","Acrobatics","Twist · airborne","Twist","duel/air","twist"),
		attack("Punch","Left jab","Punch","ual1/Punch_Jab","hand_l"),
		attack("Punch","Right jab","Punch","ual1/Punch_Jab","hand_r",true),
		attack("Punch","Right cross","Cross","ual1/Punch_Cross","hand_r"),
		attack("Punch","Left cross","Cross","ual1/Punch_Cross","hand_l",true),
		attack("Punch","Left hook","Hook","boxing/hook_l","hand_l"),
		attack("Punch","Right hook","Hook","boxing/hook_r","hand_r"),
		attack("Kick","Right front kick","Kick","boxing/front_kick_r","ball_r"),
		attack("Kick","Left front kick","Kick","boxing/front_kick_l","ball_l"),
		attack("Kick","Left roundhouse","Round Kick","boxing/high_kick_l","ball_l"),
		attack("Kick","Right roundhouse","Round Kick","boxing/high_kick_r","ball_r"),
		attack("Knee","Right knee","Knee","battle/knee","calf_r"),
		attack("Knee","Left knee","Knee","battle/knee","calf_l",true),
		attack("Elbow","Right elbow","Elbow","editor_attacks/elbow","lowerarm_r"),
		attack("Elbow","Left elbow","Elbow","editor_attacks/elbow","lowerarm_l",true),
		attack("Uppercut","Right uppercut","Uppercut","battle/uppercut","hand_r"),
		attack("Uppercut","Left uppercut","Uppercut","battle/uppercut","hand_l",true),
		attack("Sweep","Right sweep","Sweep","fight/sweep","ball_r"),
		attack("Sweep","Left sweep","Sweep","fight/sweep","ball_l",true),
		attack("Punch","Right sky palm","Sky Palm","editor_attacks/sky_palm","hand_r"),
		attack("Punch","Left sky palm","Sky Palm","editor_attacks/sky_palm","hand_l",true),
		attack("Punch","Right ground punch","Ground Punch","editor_attacks/ground_punch","hand_r"),
		attack("Punch","Left ground punch","Ground Punch","editor_attacks/ground_punch","hand_l",true),
		attack("Kick","Right ground stomp","Stomp","editor_attacks/stomp","ball_r"),
		attack("Kick","Left ground stomp","Stomp","editor_attacks/stomp","ball_l",true),
		attack("Slash","Right body slash","Body Slash","editor_attacks/body_slash","hand_r"),
		attack("Slash","Left body slash","Body Slash","editor_attacks/body_slash","hand_l",true),
		attack("Punch","Default Spell Cast","Palm Cast","editor_attacks/default_spell_cast","hand_r")
	]
	return result
static func item(group: String,category: String,title: String,step: String,clip: String,kind: String="ground") -> Dictionary:
	if group=="Attack":category=category_for(category)
	return {"group":group,"category":category,"title":title,"step":step,"clip":clip,"kind":kind}

static func category_for(category:String) -> String:
	if category in ["Uppercut","Elbow","Slash"]:return "Punch"
	if category in ["Sweep","Knee"]:return "Kick"
	return category

static func attack(category:String,title:String,step:String,clip:String,bone:String,mirrored:=false) -> Dictionary:
	var entry:=item("Attack",category,title,step,clip)
	entry["attack_bone"]=bone
	entry["mirrored"]=mirrored
	return entry
