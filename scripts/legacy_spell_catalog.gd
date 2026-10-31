extends RefCounted
const SPELLS := [
	{"id":"palm_fireball", "name":"Palm Fireball", "description":"Draw back, turn the shoulder, extend the right palm.", "release":0.68, "hand":"hand_r", "effect":"orb"},
	{"id":"cleaving_flick", "name":"Severing Flick", "description":"A compact, finger-led slash across the body.", "release":0.64, "hand":"hand_r", "effect":"slash"},
	{"id":"overhead_cleave", "name":"Cinder Cleave", "description":"Raise both hands, then cut down like a sword stroke.", "release":0.92, "hand":"both", "effect":"cleave"},
	{"id":"self_mend", "name":"Verdant Mend", "description":"Gather in both palms and draw the light toward the chest.", "release":0.95, "hand":"both", "effect":"heal"},
	{"id":"twin_push", "name":"Twin-Palm Blast", "description":"Compress an ember between the hands and push it outward.", "release":1.00, "hand":"both", "effect":"heavy"},
	{"id":"offhand_spark", "name":"Offhand Spark", "description":"A quick left-hand cast with the opposite shoulder leading.", "release":0.68, "hand":"hand_l", "effect":"spark"},
	{"id":"sun_spear", "name":"Sun Spear", "description":"Draw above the shoulder and throw a lance of fire.", "release":0.84, "hand":"hand_r", "effect":"spear"},
	{"id":"ground_sigil", "name":"Ground Sigil", "description":"Sink through the knees and press the spell into the earth.", "release":0.85, "hand":"hand_r", "effect":"ground"},
	{"id":"solar_nova", "name":"Solar Nova", "description":"Cross the arms inward, then open them into a spreading pulse.", "release":0.96, "hand":"both", "effect":"nova"},
	{"id":"flame_channel", "name":"Flame Channel", "description":"Brace both palms forward and sustain a stream of fire.", "release":0.80, "hand":"both", "effect":"beam"},
]
