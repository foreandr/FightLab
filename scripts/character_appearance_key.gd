extends RefCounted
## Names, progress, camera rotation and ability bindings do not change the mesh.
static func make(profile: Dictionary) -> String:
	var appearance: Dictionary={}
	var keys=profile.keys();keys.sort()
	for key in keys:
		var s:=str(key)
		if s in ["body","skin","hair","height","build","idle_animation","story_unequipped_parts"] or s.begins_with("wardrobe_") or s.ends_with("_color") or s.ends_with("_size") or "_offset_" in s: appearance[s]=profile[key]
	return var_to_str(appearance).sha256_text()
