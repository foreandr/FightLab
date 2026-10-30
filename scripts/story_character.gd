extends Node3D
## A lightweight, reusable story character assembled from the game's existing skinned assets.

const BASE := "res://assets/combat/"
const CHARACTER_BASE := "res://assets/characters/base/"
const EXTERNAL_WARDROBE := "res://assets/characters/wardrobe/external/"

var profile: Dictionary = {}
var model: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var spin := 0.0
var head_mesh_cache: Dictionary = {}

func play_preview_animation(animation_id: String) -> bool:
	if animator == null:return false
	var clips := {
		"punch_left":"ual1/Punch_Jab",
		"punch_right":"ual1/Punch_Cross",
		"block":"duel/shield_raise_palm",
		"front_kick":"boxing/front_kick_r",
		"dash":"duel/dash",
	}
	var clip_name := str(clips.get(animation_id, animation_id))
	var library := clip_name.get_slice("/", 0)
	var resource_paths := {
		"duel":BASE+"animations/duel.res",
		"boxing":BASE+"animations/boxing.res",
		"battle":BASE+"animations/battle.res",
		"fight":BASE+"animations/fight_anims.res",
		"spells":BASE+"animations/spells.res",
		"ual2":BASE+"animations/UAL2_Standard.glb",
	}
	if not animator.has_animation_library(library) and resource_paths.has(library):
		var animation_library := load(resource_paths[library]) as AnimationLibrary
		if animation_library != null:
			# AnimationMixer caches can become invalid when a resource-cached
			# AnimationLibrary is registered directly on a runtime preview rig.
			animator.add_animation_library(library, animation_library.duplicate(true))
	if not animator.has_animation(clip_name):
		push_warning("Loadout preview has no animation clip: %s" % clip_name)
		return false
	animator.play(clip_name, 0.12)
	return true

func preview_bone_position(bone_name: String) -> Vector3:
	if skeleton == null:return Vector3(0, 1.1, 0.35)
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index < 0:return Vector3(0, 1.1, 0.35)
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(bone_index).origin))

func set_wardrobe_size(wardrobe_key: String, amount: float, side := "") -> bool:
	"""Resize already-built wardrobe meshes without reconstructing the character."""
	if wardrobe_key.is_empty():
		return false
	amount = clampf(amount, 0.85, 1.50)
	var size_keys := {
		"wardrobe_shirt": "top_size", "wardrobe_arms": "gloves_size",
		"wardrobe_pants": "bottoms_size", "wardrobe_boots": "footwear_size",
		"wardrobe_hands": "handwear_size", "wardrobe_belt": "belt_size",
		"wardrobe_hat": "hat_size", "wardrobe_mask": "mask_size", "wardrobe_back": "back_size",
	}
	var size_key := str(size_keys.get(wardrobe_key, ""))
	if not size_key.is_empty():
		profile[size_key] = amount
	var changed := false
	for node in find_children("*", "Node3D", true, false):
		if str(node.get_meta("wardrobe_loadout_key", "")) != wardrobe_key:
			continue
		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			var mesh_side := str(mesh_instance.get_meta("wardrobe_side", ""))
			if not side.is_empty() and not mesh_side.is_empty() and side != mesh_side:
				continue
			var base_mesh := mesh_instance.get_meta("wardrobe_base_mesh") as Mesh
			if base_mesh != null:
				var resized_mesh := _scale_wardrobe_cloth(base_mesh, 1.015 * amount)
				if not mesh_side.is_empty():
					resized_mesh = _wardrobe_side_mesh(resized_mesh, mesh_side)
				for hidden_side in mesh_instance.get_meta("wardrobe_hidden_arm_sides", []):
					resized_mesh = _wardrobe_hide_arm_side(resized_mesh, str(hidden_side))
				mesh_instance.mesh = resized_mesh
				changed = true
		elif node is Node3D and node.has_meta("wardrobe_base_scale"):
			var accessory := node as Node3D
			accessory.scale = node.get_meta("wardrobe_base_scale") * amount
			changed = true
	return changed

func set_profile(next_profile: Dictionary) -> void:
	profile = next_profile.duplicate(true)
	spin = float(profile.get("rotation", 0.0))
	rotation.y = spin
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var body_type := str(profile.get("body", "Masculine"))
	var gender := "Male" if body_type == "Masculine" else "Female"
	var packed := load(CHARACTER_BASE + "Superhero_%s_FullBody.gltf" % gender) as PackedScene
	if packed == null:
		push_error("Story character body asset could not be loaded: " + gender)
		return
	model = packed.instantiate()
	# Imported rigs can contain surfaces with no material resource. Fill those
	# while the model is still outside the rendered tree so GLES never sees a
	# transient null material during outfit/preview construction.
	_ensure_preview_surface_materials()
	add_child(model)
	scale = Vector3.ONE * float(profile.get("height", 1.0))
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		push_error("Story character model has no Skeleton3D")
		return
	_apply_body(gender)
	_apply_handwear(gender)
	_apply_beltwear(gender)
	_apply_proportions()
	_apply_hair(gender)
	_apply_headwear(gender)
	_apply_backwear()
	_ensure_preview_surface_materials()
	animator = AnimationPlayer.new()
	model.add_child(animator)
	var library := load(BASE + "animations/UAL1_Standard.glb") as AnimationLibrary
	if library != null:
		animator.add_animation_library("ual1", library.duplicate(true))
		# Let Godot advance preview animations through its normal scene update.
		# Manually calling AnimationPlayer.advance() from _process can crash when
		# switching dynamically loaded character animation libraries at runtime.
		animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
		if library.has_animation("Idle"):
			animator.play(preload("res://scripts/default_idle.gd").resolve(self,animator,profile.get("idle_animation")))
	if is_inside_tree(): _finish_pavlov_wardrobe()
	else: ready.connect(_finish_pavlov_wardrobe,CONNECT_ONE_SHOT)

func _finish_pavlov_wardrobe() -> void:
	# Downloaded draped garments bind against the standing preview pose.
	# Author-created T-pose shirts retain their original rest-pose binding.
	var draped := false
	for key in profile:
		if not str(key).begins_with("wardrobe_"): continue
		var value := str(profile[key])
		if not value.begins_with("Pavlov:"): continue
		if str(preload("res://scripts/clothing_pool.gd").item_for_value(value).get("format","")) == "pvm":
			draped = true
			break
	if draped and animator != null and animator.is_playing(): animator.advance(0.0)
	_apply_pavlov_wardrobe()
	_ensure_preview_surface_materials()

func _ensure_preview_surface_materials() -> void:
	# Some imported body and wardrobe surfaces intentionally omit a material.
	# GLES logs a null-material error when those meshes are rebuilt/replaced, so
	# give only the unassigned surfaces a quiet neutral fallback.
	if model == null:return
	for mesh_instance:MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null or mesh_instance.material_override != null:continue
		for surface in mesh_instance.mesh.get_surface_count():
			if mesh_instance.get_surface_override_material(surface) != null:continue
			if mesh_instance.mesh.surface_get_material(surface) != null:continue
			mesh_instance.set_surface_override_material(surface,_fallback_surface_material())

func _fallback_surface_material() -> StandardMaterial3D:
	var fallback:=StandardMaterial3D.new()
	fallback.albedo_color=Color("b8b2a6")
	fallback.vertex_color_use_as_albedo=true
	fallback.roughness=0.9
	return fallback

func _apply_body(gender: String) -> void:
	var skin_key := str(profile.get("skin", "Light"))
	var skin_tint: Color = profile.get("skin_color", Color.WHITE)
	var skin_texture := CHARACTER_BASE + ("T_Superhero_Male_%s.png" % skin_key if gender == "Male" else "T_Superhero_Female_%s_BaseColor.png" % skin_key)
	var body_mesh: MeshInstance3D
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		# The imported rig already has a separate eyebrow mesh. Keep it visible
		# and override its pale imported hair texture so brows match the selected
		# hairstyle on every character.
		if mesh.name.to_lower().contains("eyebrow"):
			var brow_material := StandardMaterial3D.new()
			var brow_color: Color = profile.get("hair_color", Color("3c2b25"))
			# The source brow atlas has white/grey fibres baked into it. Use a
			# clean, opaque hair-tone material so every skin preset gets readable
			# eyebrows instead of the pale speckled look from the imported atlas.
			brow_material.albedo_color = brow_color.darkened(0.22)
			brow_material.albedo_texture = null
			brow_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			brow_material.vertex_color_use_as_albedo = false
			brow_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			brow_material.roughness = 1.0
			mesh.visible = true
			mesh.material_override = brow_material
		var body_surface := false
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface)
			if original == null:
				continue
			var material := original.duplicate() as StandardMaterial3D
			if material.resource_name.begins_with("MI_Superhero"):
				material.albedo_texture = load(skin_texture) as Texture2D
				material.albedo_color = skin_tint
				material.roughness = 0.82
				mesh.set_surface_override_material(surface, material)
				body_surface = true
		if body_surface and body_mesh == null:
			body_mesh = mesh
	if body_mesh == null:
		push_error("Could not find the character's base body mesh")
		return
	if str(profile.get("wardrobe_shirt","")) == "Training tank top":
		preload("res://scripts/creation_bot_outfit.gd").add_tank(body_mesh,skeleton,profile.get("shirt_color",Color.WHITE))
	body_mesh.mesh = _body_mesh_for_wardrobe(body_mesh.mesh, gender)
	_apply_modular_wardrobe(gender)

func _body_mesh_for_wardrobe(source: Mesh, gender: String) -> Mesh:
	var unequipped_parts: Dictionary = profile.get("story_unequipped_parts", {})
	var covered := {
		"torso": _is_clothing(str(profile.get("wardrobe_shirt", "Peasant"))),
		"arms": _is_clothing(str(profile.get("wardrobe_arms", "Peasant"))),
		"legs": _is_clothing(str(profile.get("wardrobe_pants", "Peasant"))),
		# Keep the lower calf visible with bare feet so cropped trouser meshes do
		# not leave a gap between the hem and the body's feet.
		"calves": _is_clothing(str(profile.get("wardrobe_pants", "Peasant"))) and (_is_clothing(str(profile.get("wardrobe_boots", "Peasant"))) or bool(profile.get("creation_training_outfit",false))),
		"feet": _is_clothing(str(profile.get("wardrobe_boots", "Peasant"))),
	}
	var cache_key := gender + ":" + str(covered) + ":" + str(unequipped_parts)
	if head_mesh_cache.has(cache_key):
		return head_mesh_cache[cache_key]
	var visible_body := ArrayMesh.new()
	for surface in source.get_surface_count():
		var source_material := source.surface_get_material(surface)
		# The source Superhero mesh includes a baked scalp cap as a separate
		# material surface. We use independent, rigged hairstyle meshes here, so
		# retaining that cap causes the black band to poke through at the nape.
		if source_material != null and source_material.resource_name.begins_with("MI_Hair_"):
			continue
		var arrays: Array = source.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var visible_indices := PackedInt32Array()
		for triangle in range(0, indices.size(), 3):
			var region_weights := {"head": 0.0, "torso": 0.0, "arms": 0.0, "legs": 0.0, "calves": 0.0, "feet": 0.0}
			var side_weights := {"left": 0.0, "right": 0.0}
			for corner in 3:
				var vertex_index := indices[triangle + corner]
				for influence in 4:
					var slot := vertex_index * 4 + influence
					if slot >= bones.size() or slot >= weights.size():
						continue
					var bone_name := skeleton.get_bone_name(bones[slot])
					var region := _body_region_for_bone(bone_name)
					if not region.is_empty():
						region_weights[region] += weights[slot]
					if bone_name.ends_with("_l"):
						side_weights.left += weights[slot]
					elif bone_name.ends_with("_r"):
						side_weights.right += weights[slot]
			var dominant_region := "head"
			for region in region_weights:
				if region_weights[region] > region_weights[dominant_region]:
					dominant_region = region
			var triangle_covered := bool(covered.get(dominant_region, false))
			if dominant_region in ["arms", "legs", "calves", "feet"]:
				var side := "left" if side_weights.left > side_weights.right else "right"
				var side_part: String = {
					"arms": side + "_arm",
					"legs": side + "_leg",
					"calves": side + "_leg",
					"feet": side + "_boot",
				}.get(dominant_region, "")
				if bool(unequipped_parts.get(side_part, false)):
					triangle_covered = false
			var keep_triangle := dominant_region == "head" or not triangle_covered
			if keep_triangle:
				for corner in 3:
					visible_indices.append(indices[triangle + corner])
		if visible_indices.is_empty():
			continue
		arrays[Mesh.ARRAY_INDEX] = visible_indices
		# The female GLTF body contains custom vertex channels encoded in a
		# format ArrayMesh cannot rebuild from surface_get_arrays(). They are
		# not used by the character shader, so drop them from this trimmed mesh.
		for custom_slot in range(Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM3 + 1):
			arrays[custom_slot] = null
		visible_body.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		# A few imported body surfaces intentionally have no material. Keep a
		# concrete fallback on the rebuilt mesh so GLES never receives a null
		# material while the preview is replaced during gear changes.
		var surface_material:Material = source_material
		if surface_material == null:
			var fallback := StandardMaterial3D.new()
			fallback.albedo_color = Color("d7b18e")
			fallback.roughness = 0.88
			surface_material = fallback
		visible_body.surface_set_material(visible_body.get_surface_count() - 1, surface_material)
	if visible_body.get_surface_count() == 0:
		push_error("Could not isolate uncovered body regions for modular clothing")
		visible_body = source.duplicate() as ArrayMesh
	head_mesh_cache[cache_key] = visible_body
	return visible_body

func _is_clothing(choice: String) -> bool:
	return choice.get_slice(":",0) in ["Peasant", "Traveler", "Guard castoff"]

func _body_region_for_bone(bone_name: String) -> String:
	if bone_name == "Head" or bone_name == "neck_01":
		return "head"
	if bone_name.begins_with("spine_"):
		return "torso"
	if bone_name.begins_with("clavicle_") or bone_name.begins_with("upperarm_") or bone_name.begins_with("lowerarm_") or bone_name.begins_with("hand_") or bone_name.begins_with("index_") or bone_name.begins_with("middle_") or bone_name.begins_with("pinky_") or bone_name.begins_with("ring_") or bone_name.begins_with("thumb_"):
		return "arms"
	if bone_name.begins_with("thigh_"):
		return "legs"
	if bone_name.begins_with("calf_"):
		return "calves"
	if bone_name.begins_with("foot_") or bone_name.begins_with("ball_"):
		return "feet"
	if bone_name == "pelvis":
		return "legs"
	return ""

func _apply_modular_wardrobe(gender: String) -> void:
	var prefix := "Male_" if gender == "Male" else "Female_"
	var wardrobe_path := "res://assets/characters/wardrobe/quaternius_fantasy/"
	var selected_parts := {
		"wardrobe_shirt": "Body",
		"wardrobe_arms": "Arms",
		"wardrobe_pants": "Legs",
		"wardrobe_boots": "Feet",
	}
	var color_keys := {
		"wardrobe_shirt": "shirt_color",
		"wardrobe_arms": "gloves_color",
		"wardrobe_pants": "bottoms_color",
		"wardrobe_boots": "footwear_color",
	}
	var size_keys := {
		"wardrobe_shirt": "top_size",
		"wardrobe_arms": "gloves_size",
		"wardrobe_pants": "bottoms_size",
		"wardrobe_boots": "footwear_size",
	}
	var side_parts := {
		"wardrobe_arms": ["left_arm", "right_arm"],
		"wardrobe_pants": ["left_leg", "right_leg"],
		"wardrobe_boots": ["left_boot", "right_boot"],
	}
	var unequipped_parts: Dictionary = profile.get("story_unequipped_parts", {})
	for key in selected_parts:
		var variant := str(profile.get(key, "Peasant"))
		if not _is_clothing(variant):
			continue
		var part := str(selected_parts[key])
		var set_name := _wardrobe_mesh_set(variant, part)
		var garment_part := part
		if set_name == "Ranger" and part == "Feet" and gender == "Male":
			garment_part = "Feet_Boots"
		var filename: String = prefix + set_name + "_" + garment_part + ".gltf"
		var tint: Color = profile.get(color_keys[key], profile.get("outfit_color", Color.WHITE))
		var garment_size := float(profile.get(size_keys[key], 1.0))
		var body_parts: Array = side_parts.get(key, [])
		if body_parts.is_empty():
			var hidden_arm_sides: Array[String] = []
			if key == "wardrobe_shirt":
				for body_part in ["left_arm", "right_arm"]:
					if bool(unequipped_parts.get(body_part, false)):
						hidden_arm_sides.append("left" if str(body_part).begins_with("left_") else "right")
			_attach_wardrobe_piece(wardrobe_path + filename, gender, tint, garment_size, "", hidden_arm_sides, key)
		else:
			for body_part in body_parts:
				if bool(unequipped_parts.get(body_part, false)):
					continue
				var side := "left" if str(body_part).begins_with("left_") else "right"
				_attach_wardrobe_piece(wardrobe_path + filename, gender, tint, garment_size, side, [], key)

func _apply_handwear(gender: String) -> void:
	if str(profile.get("wardrobe_hands", "None")) != "Fingerless gloves":
		return
	var prefix := "Male_" if gender == "Male" else "Female_"
	var source_path := "res://assets/characters/wardrobe/quaternius_fantasy/" + prefix + "Peasant_Arms.gltf"
	var packed := load(source_path) as PackedScene
	if packed == null:
		push_warning("The fingerless glove source asset could not be loaded.")
		return
	var source_scene := packed.instantiate()
	var source_instance: MeshInstance3D
	for candidate: MeshInstance3D in source_scene.find_children("*", "MeshInstance3D", true, false):
		if candidate.mesh != null:
			source_instance = candidate
			break
	if source_instance == null or not source_instance.mesh is ArrayMesh:
		source_scene.free()
		push_warning("The fingerless glove source asset has no compatible mesh.")
		return
	var glove_mesh := _handwear_mesh(source_instance.mesh as ArrayMesh)
	source_scene.free()
	if glove_mesh.get_surface_count() == 0:
		push_warning("No fingerless glove geometry was found in the sourced arm mesh.")
		return
	var size := float(profile.get("handwear_size", 1.0))
	var handwear := MeshInstance3D.new()
	handwear.name = "StoryFingerlessGloves"
	handwear.set_meta("wardrobe_loadout_key", "wardrobe_hands")
	handwear.set_meta("wardrobe_base_mesh", glove_mesh)
	handwear.mesh = _scale_wardrobe_cloth(glove_mesh, 1.015 * size)
	skeleton.add_child(handwear)
	handwear.transform = Transform3D.IDENTITY
	handwear.skeleton = handwear.get_path_to(skeleton)
	handwear.set_meta("wardrobe_piece", true)
	var tint: Color = profile.get("handwear_color", Color("29313b"))
	for surface in handwear.mesh.get_surface_count():
		var source := handwear.mesh.surface_get_material(surface)
		var material := source.duplicate() as StandardMaterial3D if source is StandardMaterial3D else StandardMaterial3D.new()
		material.albedo_color = tint
		handwear.set_surface_override_material(surface, material)

func _apply_beltwear(gender: String) -> void:
	if str(profile.get("wardrobe_belt", "None")) != "Leather belt":
		return
	var prefix := "Male_" if gender == "Male" else "Female_"
	var path := "res://assets/characters/wardrobe/quaternius_fantasy/" + prefix + "Ranger_Body.gltf"
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("The sourced belt assets could not be loaded.")
		return
	var source_scene := packed.instantiate()
	var belt_pieces: Array[MeshInstance3D] = []
	for candidate: MeshInstance3D in source_scene.find_children("*", "MeshInstance3D", true, false):
		if candidate.mesh != null and candidate.name.contains("_Belt_"):
			belt_pieces.append(candidate)
	if belt_pieces.is_empty():
		source_scene.free()
		push_warning("The sourced modular outfit contains no standalone belt meshes.")
		return
	var tint: Color = profile.get("belt_color", Color("8a6135"))
	var amount := 1.015 * float(profile.get("belt_size", 1.0))
	for piece in belt_pieces:
		piece.owner = null
		piece.get_parent().remove_child(piece)
		skeleton.add_child(piece)
		piece.transform = Transform3D.IDENTITY
		piece.set_meta("wardrobe_loadout_key", "wardrobe_belt")
		piece.set_meta("wardrobe_base_mesh", piece.mesh)
		piece.mesh = _scale_wardrobe_cloth(piece.mesh, amount)
		piece.skeleton = piece.get_path_to(skeleton)
		piece.set_meta("wardrobe_piece", true)
		for surface in piece.mesh.get_surface_count():
			var source := piece.mesh.surface_get_material(surface)
			var material := source.duplicate() as StandardMaterial3D if source is StandardMaterial3D else StandardMaterial3D.new()
			material.albedo_color *= tint
			piece.set_surface_override_material(surface, material)
	source_scene.free()

func _handwear_mesh(source: ArrayMesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in source.get_surface_count():
		var material := source.surface_get_material(surface)
		if material != null and material.resource_name.begins_with("MI_Regular_"):
			continue
		var arrays: Array = source.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var glove_indices := PackedInt32Array()
		for triangle in range(0, indices.size(), 3):
			var hand_weight := 0.0
			for corner in 3:
				var vertex := indices[triangle + corner]
				for influence in 4:
					var slot := vertex * 4 + influence
					var bone_name := str(skeleton.get_bone_name(bones[slot]))
					if bone_name.begins_with("hand_") or bone_name.begins_with("index_") or bone_name.begins_with("middle_") or bone_name.begins_with("pinky_") or bone_name.begins_with("ring_") or bone_name.begins_with("thumb_"):
						hand_weight += weights[slot]
			if hand_weight / 3.0 >= 0.40:
				for corner in 3:
					glove_indices.append(indices[triangle + corner])
		if glove_indices.is_empty():
			continue
		arrays[Mesh.ARRAY_INDEX] = glove_indices
		for custom_slot in range(Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM3 + 1):
			arrays[custom_slot] = null
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		result.surface_set_material(result.get_surface_count() - 1, material if material != null else _fallback_surface_material())
	return result

func _apply_headwear(gender: String) -> void:
	var wardrobe_path := "res://assets/characters/wardrobe/quaternius_fantasy/"
	if str(profile.get("wardrobe_hat", "None")) == "Hood":
		var prefix := "Male_" if gender == "Male" else "Female_"
		var hat_color: Color = profile.get("hat_color", Color("3b3028"))
		_attach_wardrobe_piece(wardrobe_path + prefix + "Ranger_Head_Hood.gltf", gender, hat_color, float(profile.get("hat_size", 1.0)), "", [], "wardrobe_hat")
	if str(profile.get("wardrobe_mask", "None")) in ["Rogue mask", "Cloth mask"]:
		var attachment := BoneAttachment3D.new()
		attachment.name = "StoryRogueMaskAttachment"
		attachment.bone_name = "Head"
		skeleton.add_child(attachment)
		var mask_scene := load(EXTERNAL_WARDROBE + "rogue_mask_scott_marshall.glb") as PackedScene
		if mask_scene == null:
			push_warning("The sourced rogue mask asset could not be loaded.")
			return
		var mask := mask_scene.instantiate() as Node3D
		mask.name = "StoryRogueMask"
		mask.position = Vector3(
			float(profile.get("mask_offset_x", 0.0)),
			0.06 + float(profile.get("mask_offset_y", 0.0)),
			0.12 + float(profile.get("mask_offset_z", 0.0))
		)
		mask.scale = Vector3.ONE * float(profile.get("mask_size", 1.0)) * 0.42
		mask.set_meta("wardrobe_loadout_key", "wardrobe_mask")
		mask.set_meta("wardrobe_base_scale", Vector3.ONE * 0.42)
		attachment.add_child(mask)
		var mask_tint: Color = profile.get("mask_color", Color("29313b"))
		_tint_accessory(mask, mask_tint, false)

func _apply_backwear() -> void:
	var selected := str(profile.get("wardrobe_back", "None"))
	if selected not in ["Cape", "Backpack"]:
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "StoryBackAttachment"
	attachment.bone_name = "spine_03"
	skeleton.add_child(attachment)
	var filename := "completionist_cape_julien_savoie.glb" if selected == "Cape" else "backpack_quaternius.glb"
	var accessory_scene := load(EXTERNAL_WARDROBE + filename) as PackedScene
	if accessory_scene == null:
		push_warning("The selected back accessory could not be loaded: " + filename)
		return
	var accessory := accessory_scene.instantiate() as Node3D
	accessory.name = "Story" + selected.replace(" ", "")
	var size := float(profile.get("back_size", 1.0))
	var offset := Vector3(
		float(profile.get("back_offset_x", 0.0)),
		float(profile.get("back_offset_y", 0.0)),
		float(profile.get("back_offset_z", 0.0))
	)
	if selected == "Cape":
		# The mesh is authored upright from the ground origin; keep its neckline
		# at the shoulders and pull the cloth close enough to follow the back.
		accessory.position = Vector3(0.0, -0.78, -0.11) + offset
		accessory.rotation.y = PI
		accessory.scale = Vector3.ONE * size * 0.09
		accessory.set_meta("wardrobe_base_scale", Vector3.ONE * 0.09)
	else:
		# Raise the pack onto the shoulder blades instead of the waist.
		accessory.position = Vector3(0.0, 0.12, -0.15) + offset
		accessory.rotation.y = PI
		accessory.scale = Vector3(0.35, 0.44, 0.26) * size
		accessory.set_meta("wardrobe_base_scale", Vector3(0.35, 0.44, 0.26))
	accessory.set_meta("wardrobe_loadout_key", "wardrobe_back")
	attachment.add_child(accessory)
	_tint_accessory(accessory, profile.get("back_color", Color.WHITE), selected != "Cape", selected == "Cape")

func _tint_accessory(accessory: Node3D, tint: Color, multiply_existing: bool, flatten_texture := false) -> void:
	for mesh: MeshInstance3D in accessory.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface)
			var material := source.duplicate() as StandardMaterial3D if source is StandardMaterial3D else StandardMaterial3D.new()
			if multiply_existing:
				material.albedo_color *= tint
			else:
				material.albedo_color = tint
			if flatten_texture:
				material.albedo_texture = null
			material.roughness = 0.92
			mesh.set_surface_override_material(surface, material)

func _wardrobe_mesh_set(variant: String, part: String) -> String:
	variant = variant.get_slice(":",0)
	match variant:
		"Traveler":
			return "Ranger"
		"Guard castoff":
			return "Ranger" if part in ["Body", "Arms", "Feet"] else "Peasant"
		_:
			return "Peasant"

func _apply_proportions() -> void:
	if skeleton == null:
		return
	var bulk := float(profile.get("build", 1.0))
	var arm := float(profile.get("arms_size", 1.0))
	var leg := float(profile.get("legs_size", 1.0))
	var hands := float(profile.get("hands_size", 1.0))
	var feet := float(profile.get("feet_size", 1.0))
	var head := float(profile.get("head_size", 1.0))
	for bone in skeleton.get_bone_count():
		var bone_name := str(skeleton.get_bone_name(bone))
		var factor := Vector3.ONE
		if bone_name in ["pelvis", "spine_01", "spine_02", "spine_03"]:
			factor.x = bulk
			factor.z = bulk
		if bone_name.begins_with("upperarm_"):
			factor.x = arm
			factor.z = arm
		if bone_name.begins_with("thigh_") or bone_name.begins_with("calf_"):
			factor.x = leg
			factor.z = leg
		if bone_name.begins_with("hand_") or bone_name.begins_with("index_") or bone_name.begins_with("middle_") or bone_name.begins_with("pinky_") or bone_name.begins_with("ring_") or bone_name.begins_with("thumb_"):
			factor *= hands
		if bone_name.begins_with("foot_") or bone_name.begins_with("ball_"):
			factor *= feet
		if bone_name == "Head":
			factor *= head
		skeleton.set_bone_pose_scale(bone, factor)

func _attach_wardrobe_piece(path: String, gender: String, tint: Color, garment_size: float = 1.0, side: String = "", hidden_arm_sides: Array[String] = [], loadout_key := "") -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load wardrobe piece: " + path)
		return
	var piece := packed.instantiate()
	var mesh_instance: MeshInstance3D
	for candidate: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
		if candidate.mesh != null:
			mesh_instance = candidate
			break
	if mesh_instance == null:
		piece.free()
		push_error("Wardrobe asset has no mesh: " + path)
		return
	mesh_instance.owner = null
	mesh_instance.get_parent().remove_child(mesh_instance)
	mesh_instance.transform = Transform3D.IDENTITY
	# Resize only cloth material surfaces: modular outfit files also contain
	# exposed skin surfaces, which must stay aligned with the underlying body.
	var base_mesh := mesh_instance.mesh
	mesh_instance.set_meta("wardrobe_loadout_key", loadout_key)
	mesh_instance.set_meta("wardrobe_side", side)
	mesh_instance.set_meta("wardrobe_base_mesh", base_mesh)
	mesh_instance.set_meta("wardrobe_hidden_arm_sides", hidden_arm_sides.duplicate())
	var rendered_mesh := _scale_wardrobe_cloth(base_mesh, 1.015 * garment_size)
	if not side.is_empty():
		rendered_mesh = _wardrobe_side_mesh(rendered_mesh, side)
	for hidden_side in hidden_arm_sides:
		rendered_mesh = _wardrobe_hide_arm_side(rendered_mesh, hidden_side)
	if bool(profile.get("creation_training_outfit",false)) and loadout_key=="wardrobe_pants":
		rendered_mesh = preload("res://scripts/creation_bot_outfit.gd").full_length_pants(rendered_mesh,side)
	mesh_instance.mesh = rendered_mesh
	mesh_instance.name = path.get_file().get_basename()
	mesh_instance.set_meta("wardrobe_piece", true)
	for surface in mesh_instance.mesh.get_surface_count():
		var original := mesh_instance.mesh.surface_get_material(surface)
		var material := original.duplicate() as StandardMaterial3D if original is StandardMaterial3D else _fallback_surface_material()
		if bool(profile.get("creation_training_outfit",false)) and loadout_key=="wardrobe_pants":
			material.albedo_texture=null
			material.albedo_color=tint
		elif original != null and material.resource_name.begins_with("MI_Regular_"):
			# Keep the wardrobe pack's exposed-skin texture and multiply it by the
			# custom tint, just like the body uses its own skin atlas.
			material.albedo_color = profile.get("skin_color", Color.WHITE)
		elif original != null:
			material.albedo_color = tint
			if bool(profile.get("creation_training_outfit",false)) and loadout_key=="wardrobe_pants": material.albedo_texture=null
			var selected := str(profile.get(loadout_key,""))
			if selected.ends_with(":Field"):
				var texture_file := "T_Peasant_2_BaseColor.png" if selected.begins_with("Peasant") else "T_Ranger_3_BaseColor.png"
				material.albedo_texture = load("res://assets/characters/wardrobe/pavlov_imports/" + texture_file)
		mesh_instance.set_surface_override_material(surface, material)
	skeleton.add_child(mesh_instance)
	mesh_instance.transform = Transform3D.IDENTITY
	mesh_instance.skeleton = mesh_instance.get_path_to(skeleton)
	piece.free()

func _wardrobe_side_mesh(source: Mesh, side: String) -> Mesh:
	if not source is ArrayMesh:
		return source
	var source_array := source as ArrayMesh
	var filtered := ArrayMesh.new()
	var wanted_suffix := "_l" if side == "left" else "_r"
	var opposite_suffix := "_r" if side == "left" else "_l"
	for surface in source_array.get_surface_count():
		var arrays: Array = source_array.surface_get_arrays(surface)
		var material := source_array.surface_get_material(surface)
		if material != null and material.resource_name.begins_with("MI_Regular_"):
			filtered.add_surface_from_arrays(source_array.surface_get_primitive_type(surface), arrays)
			filtered.surface_set_material(filtered.get_surface_count() - 1, material)
			continue
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if indices.is_empty() or bones.is_empty() or weights.is_empty():
			filtered.add_surface_from_arrays(source_array.surface_get_primitive_type(surface), arrays)
			filtered.surface_set_material(filtered.get_surface_count() - 1, material if material != null else _fallback_surface_material())
			continue
		var kept_indices := PackedInt32Array()
		for triangle in range(0, indices.size(), 3):
			var wanted_weight := 0.0
			var opposite_weight := 0.0
			for corner in 3:
				var vertex_index := indices[triangle + corner]
				for influence in 4:
					var influence_index := vertex_index * 4 + influence
					if influence_index >= bones.size() or influence_index >= weights.size():
						continue
					var bone_index := bones[influence_index]
					if bone_index < 0 or bone_index >= skeleton.get_bone_count():
						continue
					var bone_name := str(skeleton.get_bone_name(bone_index))
					if bone_name.ends_with(wanted_suffix):
						wanted_weight += weights[influence_index]
					elif bone_name.ends_with(opposite_suffix):
						opposite_weight += weights[influence_index]
			if wanted_weight > opposite_weight and wanted_weight > 0.01:
				for corner in 3:
					kept_indices.append(indices[triangle + corner])
		if not kept_indices.is_empty():
			arrays[Mesh.ARRAY_INDEX] = kept_indices
			filtered.add_surface_from_arrays(source_array.surface_get_primitive_type(surface), arrays)
			filtered.surface_set_material(filtered.get_surface_count() - 1, material if material != null else _fallback_surface_material())
	return filtered if filtered.get_surface_count() > 0 else source

func _wardrobe_hide_arm_side(source: Mesh, side: String) -> Mesh:
	if not source is ArrayMesh:
		return source
	var source_array := source as ArrayMesh
	var filtered := ArrayMesh.new()
	var wanted_suffix := "_l" if side == "left" else "_r"
	for surface in source_array.get_surface_count():
		var arrays: Array = source_array.surface_get_arrays(surface)
		var material := source_array.surface_get_material(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if indices.is_empty() or bones.is_empty() or weights.is_empty():
			filtered.add_surface_from_arrays(source_array.surface_get_primitive_type(surface), arrays)
			filtered.surface_set_material(filtered.get_surface_count() - 1, material if material != null else _fallback_surface_material())
			continue
		var kept_indices := PackedInt32Array()
		for triangle in range(0, indices.size(), 3):
			var target_arm_weight := 0.0
			var non_arm_weight := 0.0
			for corner in 3:
				var vertex_index := indices[triangle + corner]
				for influence in 4:
					var influence_index := vertex_index * 4 + influence
					if influence_index >= bones.size() or influence_index >= weights.size():
						continue
					var bone_index := bones[influence_index]
					if bone_index < 0 or bone_index >= skeleton.get_bone_count():
						continue
					var bone_name := str(skeleton.get_bone_name(bone_index))
					var is_arm_bone := bone_name.begins_with("clavicle_") or bone_name.begins_with("upperarm_") or bone_name.begins_with("lowerarm_") or bone_name.begins_with("hand_") or bone_name.begins_with("index_") or bone_name.begins_with("middle_") or bone_name.begins_with("pinky_") or bone_name.begins_with("ring_") or bone_name.begins_with("thumb_")
					if is_arm_bone and bone_name.ends_with(wanted_suffix):
						target_arm_weight += weights[influence_index]
					else:
						non_arm_weight += weights[influence_index]
			if target_arm_weight <= non_arm_weight:
				for corner in 3:
					kept_indices.append(indices[triangle + corner])
		if not kept_indices.is_empty():
			arrays[Mesh.ARRAY_INDEX] = kept_indices
			filtered.add_surface_from_arrays(source_array.surface_get_primitive_type(surface), arrays)
			filtered.surface_set_material(filtered.get_surface_count() - 1, material if material != null else _fallback_surface_material())
	return filtered if filtered.get_surface_count() > 0 else source

func _scale_wardrobe_cloth(source: Mesh, amount: float) -> Mesh:
	if not source is ArrayMesh:
		return source
	var source_array := source as ArrayMesh
	var cloth_min := Vector3(INF, INF, INF)
	var cloth_max := Vector3(-INF, -INF, -INF)
	for surface in source_array.get_surface_count():
		var material := source_array.surface_get_material(surface)
		if material != null and material.resource_name.begins_with("MI_Regular_"):
			continue
		var arrays: Array = source_array.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			cloth_min = cloth_min.min(vertex)
			cloth_max = cloth_max.max(vertex)
	if cloth_min.x == INF:
		return source
	var cloth_center := (cloth_min + cloth_max) * 0.5
	var resized := ArrayMesh.new()
	for surface in source_array.get_surface_count():
		var material := source_array.surface_get_material(surface)
		var arrays: Array = source_array.surface_get_arrays(surface)
		if material == null or not material.resource_name.begins_with("MI_Regular_"):
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for index in vertices.size():
				var vertex := vertices[index]
				vertex = cloth_center + (vertex - cloth_center) * amount
				vertices[index] = vertex
			arrays[Mesh.ARRAY_VERTEX] = vertices
		resized.add_surface_from_arrays(source_array.surface_get_primitive_type(surface), arrays)
		resized.surface_set_material(surface, material if material != null else _fallback_surface_material())
	return resized

func _apply_hair(gender: String) -> void:
	var hairstyle := str(profile.get("hair", "Short"))
	if str(profile.get("wardrobe_hat", "None")) == "Hood" or str(profile.get("wardrobe_hat", "None")).begins_with("Pavlov:"):
		hairstyle = "None"
	if hairstyle != "None":
		var piece_name := "Hair_BuzzedFemale" if gender == "Female" else "Hair_Buzzed"
		match hairstyle:
			"Buns":
				piece_name = "Hair_Buns"
			"Long":
				piece_name = "Hair_Long"
			"Side part":
				piece_name = "Hair_SimpleParted"
		var packed := load(BASE + "hair/%s.gltf" % piece_name) as PackedScene
		if packed != null:
			var piece := packed.instantiate()
			for mesh: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
				mesh.owner = null
				mesh.get_parent().remove_child(mesh)
				skeleton.add_child(mesh)
				# These meshes are already positioned against the matching rigged
				# head. Keep their imported transform; moving the whole skinned mesh
				# down shifts the hair onto the face and resembles a beard or mask.
				mesh.skeleton = mesh.get_path_to(skeleton)
				for surface in mesh.mesh.get_surface_count():
					var original := mesh.mesh.surface_get_material(surface)
					if original == null:
						continue
					var material := original.duplicate() as StandardMaterial3D
					material.albedo_color = profile.get("hair_color", Color("3c2b25"))
					material.roughness = 0.88
					mesh.set_surface_override_material(surface, material)
			piece.free()


func _apply_pavlov_wardrobe() -> void:
	var pool = preload("res://scripts/clothing_pool.gd")
	var attachment = preload("res://scripts/clothing_attachment.gd")
	var sizes := {"wardrobe_hat":"hat_size","wardrobe_mask":"mask_size","wardrobe_back":"back_size","wardrobe_shirt":"top_size","wardrobe_boots":"footwear_size","wardrobe_pants":"bottoms_size","wardrobe_hands":"handwear_size","wardrobe_arms":"gloves_size","wardrobe_belt":"belt_size","wardrobe_necklace":"necklace_size","wardrobe_earrings":"earrings_size","wardrobe_shoulders":"shoulders_size","wardrobe_bracelet":"bracelet_size"}
	var failures: Array[String] = []
	for slot in sizes:
		var value := str(profile.get(slot,""))
		if not value.begins_with("Pavlov:"): continue
		var item: Dictionary = pool.item_for_value(value)
		if not item.is_empty():
			var before := skeleton.get_child_count()
			attachment.attach(skeleton,item,slot,float(profile.get(sizes[slot],1.0)))
			if skeleton.get_child_count() == before: failures.append(str(item.id))
	set_meta("wardrobe_fit_failures",failures)
