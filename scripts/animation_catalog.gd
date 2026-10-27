extends RefCounted
const GROUPS := {
	"Motion":["Run","Sprint","Jump","Dash","Crouch","Block","Dodges","Acrobatics"],
	"Attack":["Punch","Kick","Knee","Uppercut"],
	"Spells":["Casting","Projectiles","Buffs","Debuffs","Effects","Heals"]
}
const SPELL_PROFILES := [
	{"id":"fireball","team":0,"slot":0,"name":"Fireball","category":"Projectiles","effect":"orb","delivery":"Homing projectile","mana":14,"damage":18,"animation":"palm_fireball","detail":"Fast fire projectile. A hit applies a lingering burn; holding the cast increases its damage and size."},
	{"id":"cinder_slash","team":0,"slot":1,"name":"Cinder Slash","category":"Projectiles","effect":"slash","delivery":"Crescent projectile","mana":12,"damage":16,"animation":"cleaving_flick","detail":"A fast slashing wave from an arm sweep. Hits can ignite the target."},
	{"id":"glacial_armor","team":1,"slot":0,"name":"Glacial Armor","category":"Buffs","effect":"armor","delivery":"Self buff","mana":20,"damage":0,"animation":"twin_push","detail":"Adds 50 points of ice armor for 6.5 seconds."},
	{"id":"overdrive","team":2,"slot":0,"name":"Overdrive","category":"Buffs","effect":"haste","delivery":"Self buff","mana":18,"damage":0,"animation":"self_mend","detail":"Boosts Storm movement and close-combat attacks for 14 seconds."},
	{"id":"freezing_ray","team":1,"slot":1,"name":"Freezing Ray","category":"Debuffs","effect":"ice_beam","delivery":"Sustained beam","mana":22,"damage":4.5,"animation":"flame_channel","detail":"Continuous ice beam that damages, chills, slows, and freezes on repeated hits."},
	{"id":"flash_step","team":2,"slot":1,"name":"Flash Step","category":"Effects","effect":"burst","delivery":"Charged dash + knee","mana":9,"damage":13,"animation":"palm_fireball","detail":"Brief charge, lightning-fast forward dash, then an impact knee."}
]
static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary]=[
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
		item("Spells","Casting","Palm thrust","Spell Throw","spells/palm_fireball"),
		item("Spells","Casting","Arm slash","Slash Throw","spells/cleaving_flick")
	]
	for spell in SPELL_PROFILES:
		var entry:=item("Spells",spell.category,spell.name,"spell_"+spell.id,"spells/"+spell.animation,"spell_profile")
		entry.merge(spell,true)
		result.append(entry)
	return result
static func item(group: String,category: String,title: String,step: String,clip: String,kind: String="ground") -> Dictionary:
	return {"group":group,"category":category,"title":title,"step":step,"clip":clip,"kind":kind}
