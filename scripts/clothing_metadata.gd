extends RefCounted
## Hints describe available evidence, independently of runtime fitting slots.
const VERSION := 1
const PARTS := ["head","arms","hands","torso","legs","boots","neck","back","waist","misc"]
const ALIASES := {"head":"head","face":"head","headwear":"head","hat":"head","helmet":"head","hood":"head","ears":"head","arm":"arms","arms":"arms","forearm":"arms","shoulder":"arms","shoulders":"arms","hand":"hands","hands":"hands","gloves":"hands","torso":"torso","chest":"torso","body":"torso","upper_body":"torso","upperbody":"torso","leg":"legs","legs":"legs","lower_body":"legs","lowerbody":"legs","pants":"legs","feet":"boots","foot":"boots","boots":"boots","footwear":"boots","shoes":"boots","neck":"neck","necklace":"neck","back":"back","waist":"waist","belt":"waist"}
const WORDS := {
	"head":["head","helmet","helm","hood","hat","cap","crown","tiara","mask","balaclava","beanie","beret","turban","sombrero","fedora","glasses","goggles","sunglasses","earring","earrings"],
	"arms":["arm","arms","sleeve","sleeves","gauntlet","gauntlets","bracer","bracers","bracelet","bracelets","pauldron","pauldrons","shoulder","shoulders","wristwatch"],
	"hands":["hand","hands","glove","gloves","mitten","mittens"],
	"torso":["torso","chest","shirt","shirts","tshirt","hoodie","blouse","tunic","jacket","coat","vest","waistcoat","sweater","sweatshirt","pullover","cardigan","breastplate","cuirass","bodice","corset","jersey"],
	"legs":["leg","legs","skirt","skirts","pants","trousers","jeans","shorts","kilt","leggings","stockings","greaves"],
	"boots":["boot","boots","shoe","shoes","sneaker","sneakers","sandal","sandals","slipper","slippers","sock","socks"],
	"neck":["neck","necklace","necklaces","pendant","pendants","choker","scarf","scarves","necktie"],
	"back":["backpack","rucksack","cape","cloak"],
	"waist":["belt","waistband"]
}
static var token_patterns: Dictionary = {}
static var camel_pattern: RegEx

static func annotate(item: Dictionary) -> void:
	if int(item.get("body_part_metadata_version",0)) == VERSION: return
	var hints: Array[String] = []
	var evidence: Array[String] = []
	var source := "title_keywords"
	var preset_values: Array = []
	for key in ["source_body_part","source_body_parts","equip_slot","equipment_slot","wear_location"]:
		if item.has(key): preset_values.append(item[key])
	if not item.has("body_part_source"):
		for key in ["body_part","body_parts"]:
			if item.has(key): preset_values.append(item[key])
	var preset: Dictionary = item.get("source_metadata",{}) if item.get("source_metadata",{}) is Dictionary else {}
	for key in ["body_part","body_parts","slot","equip_slot","wear_location"]:
		if preset.has(key): preset_values.append(preset[key])
	for value in preset_values: _preset_parts(value,hints)
	if not hints.is_empty():
		source = "source_metadata"
	else:
		_prepare_patterns()
		# Creator suffixes are not clothing titles and must not supply hints.
		var title := str(item.get("title",item.get("original_name",item.get("name","")))).split("·")[0]
		title = camel_pattern.sub(title,"$1 $2",true).replace("_"," ").to_lower()
		for part in WORDS:
			for word in WORDS[part]:
				if token_patterns[word].search(title) != null:
					if not part in hints: hints.append(part)
					evidence.append(word)
	item["body_part"] = hints[0] if hints.size()==1 else "misc"
	item["body_part_hints"] = hints
	item["body_part_keywords"] = evidence
	item["body_part_source"] = source if not hints.is_empty() else "unknown"
	item["body_part_metadata_version"] = VERSION

static func _preset_parts(value: Variant, result: Array[String]) -> void:
	if value is Array:
		for entry in value: _preset_parts(entry,result)
		return
	if not value is String: return
	var normalized := str(value).strip_edges().to_lower().replace(" ","_").replace("-","_")
	normalized = normalized.trim_prefix("wardrobe_").trim_prefix("left_").trim_prefix("right_").trim_suffix("_slot").trim_suffix("_l").trim_suffix("_r")
	var part := str(ALIASES.get(normalized,""))
	if not part.is_empty() and not part in result: result.append(part)

static func _prepare_patterns() -> void:
	if camel_pattern != null: return
	camel_pattern = RegEx.new()
	camel_pattern.compile("([a-z])([A-Z])")
	for part in WORDS:
		for word in WORDS[part]:
			var pattern := RegEx.new()
			pattern.compile("\\b"+str(word)+"\\b")
			token_patterns[word] = pattern
