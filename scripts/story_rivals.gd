extends RefCounted
## Stable names shared by the fight, overhead tags, and story history.
const NAMES := [
	"Tavin Greve",
	"Rolen Ashford",
	"Marek Voss",
	"Calder Wynn",
	"Joren Blackwell"
]

static func name_for_stage(stage: int) -> String:
	return NAMES[clampi(stage - 1, 0, NAMES.size() - 1)]

static func profile_for_stage(stage: int) -> Dictionary:
	var profiles: Array[Dictionary] = [
		{"skin":"Light", "skin_color":Color("f0d5bd"), "hair":"Side part", "hair_color":Color("6b3e28"), "wardrobe_shirt":"Traveler", "shirt_color":Color("8c4935"), "bottoms_color":Color("493c35")},
		{"skin":"Dark", "skin_color":Color("b98664"), "hair":"Long", "hair_color":Color("2a1c18"), "wardrobe_shirt":"Guard castoff", "shirt_color":Color("6d7957"), "bottoms_color":Color("393d36")},
		{"skin":"Light", "skin_color":Color("e0b993"), "hair":"Short", "hair_color":Color("4a3328"), "wardrobe_shirt":"Peasant", "shirt_color":Color("875f8c"), "bottoms_color":Color("393443")},
		{"skin":"Dark", "skin_color":Color("d0a276"), "hair":"Buns", "hair_color":Color("42302a"), "wardrobe_shirt":"Traveler", "shirt_color":Color("a28b4f"), "bottoms_color":Color("41413a")},
		{"skin":"Light", "skin_color":Color("d5a88c"), "hair":"Side part", "hair_color":Color("252326"), "wardrobe_shirt":"Guard castoff", "shirt_color":Color("6b4545"), "bottoms_color":Color("31343c")}
	]
	var look := profiles[clampi(stage - 1, 0, profiles.size() - 1)].duplicate(true)
	look["name"] = name_for_stage(stage)
	look["body"] = "Masculine"
	look["wardrobe_style"] = "Mix & match"
	look["wardrobe_pants"] = "Peasant"
	look["wardrobe_arms"] = "Peasant"
	look["wardrobe_boots"] = "Peasant"
	look["wardrobe_hands"] = "None"
	look["wardrobe_belt"] = "Leather belt"
	look["wardrobe_hat"] = "None"
	look["wardrobe_mask"] = "None"
	look["wardrobe_back"] = "None"
	look["gloves_color"] = Color("29313b")
	look["footwear_color"] = Color("354438")
	look["belt_color"] = Color("8a6135")
	look["story_stage"] = stage
	return preload("res://scripts/clothing_pool.gd").apply_to_cpu(look, stage * 7919)
