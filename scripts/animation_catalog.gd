extends RefCounted
const GROUPS := {
	"Motion":["Run","Sprint","Jump","Dash","Crouch","Block","Dodges","Acrobatics"],
	"Attack":["Punch","Kick","Knee","Uppercut","Spell Throwing"]
}
static func entries() -> Array[Dictionary]:
	return [
		item("Motion","Run","Run","Run","ual1/Jog_Fwd"),
		item("Motion","Sprint","Sprint","Sprint","duel/run"),
		item("Motion","Jump","Jump","Jump","duel/air","jump"),
		item("Motion","Jump","Land","Land","duel/land"),
		item("Motion","Dash","Dash","Dash","duel/dash"),
		item("Motion","Crouch","Crouch","Crouch","ual1/Crouch_Idle"),
		item("Motion","Block","Palm block","Block","duel/shield_hold_palm","block"),
		item("Motion","Block","Braced block","Brace Block","duel/shield_hold_brace","block"),
		item("Motion","Dodges","Dodge backward","Dodge Back","duel/dodge_back"),
		item("Motion","Dodges","Dodge left","Dodge Left","duel/strafe_left"),
		item("Motion","Dodges","Dodge right","Dodge Right","duel/strafe_right"),
		item("Motion","Dodges","Roll backward","Roll Back","duel/roll_back"),
		item("Motion","Acrobatics","Backflip · airborne","Flip","duel/backflip","air"),
		item("Motion","Acrobatics","Twist · airborne","Twist","duel/air","twist"),
		item("Attack","Punch","Left jab","Punch","ual1/Punch_Jab"),
		item("Attack","Punch","Right cross","Cross","ual1/Punch_Cross"),
		item("Attack","Punch","Left hook","Hook","boxing/hook_l"),
		item("Attack","Kick","Front kick","Kick","boxing/front_kick_r"),
		item("Attack","Kick","Roundhouse kick","Round Kick","boxing/high_kick_l"),
		item("Attack","Knee","Knee","Knee","battle/knee"),
		item("Attack","Uppercut","Charged uppercut","Uppercut","battle/uppercut"),
		item("Attack","Spell Throwing","Palm throw · Fireball","Spell Throw","spells/palm_fireball"),
		item("Attack","Spell Throwing","Arm slash · Cinder Slash","Slash Throw","spells/cleaving_flick")
	]
static func item(group: String,category: String,title: String,step: String,clip: String,kind: String="ground") -> Dictionary:
	return {"group":group,"category":category,"title":title,"step":step,"clip":clip,"kind":kind}
