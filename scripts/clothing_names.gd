extends RefCounted
## Names are labels; asset IDs and source files remain independent.
static func make_unique(items: Array, reserved_names: Array = []) -> int:
	var reserved := {}
	var used := {}
	for label in reserved_names:
		reserved[str(label).strip_edges().to_lower()] = true
		used[str(label).strip_edges().to_lower()] = true
	for item in items:
		reserved[str(item.get("name","")).strip_edges().to_lower()] = true
	var suffix := RegEx.new()
	suffix.compile("^(.*?)[ ]*\\(([0-9]+)\\)$")
	var next_numbers := {}
	var renamed := 0
	for item in items:
		var name_value := str(item.get("name","")).strip_edges()
		if not item.has("original_name"): item["original_name"] = str(item.get("name",""))
		if name_value.is_empty(): name_value = "Clothing"
		var key := name_value.to_lower()
		if not used.has(key):
			item["name"] = name_value
			used[key] = true
			continue
		var stem := name_value
		var number := 1
		var match_value := suffix.search(name_value)
		if match_value != null:
			stem = match_value.get_string(1).strip_edges()
			number = int(match_value.get_string(2))+1
		var stem_key := stem.to_lower()
		number = maxi(number,int(next_numbers.get(stem_key,1)))
		var candidate := "%s (%d)" % [stem,number]
		while used.has(candidate.to_lower()) or reserved.has(candidate.to_lower()):
			number += 1
			candidate = "%s (%d)" % [stem,number]
		next_numbers[stem_key] = number+1
		item["name"] = candidate
		used[candidate.to_lower()] = true
		renamed += 1
	return renamed
