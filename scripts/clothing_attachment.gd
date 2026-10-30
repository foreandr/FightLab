extends RefCounted
## Normalize downloaded props in their own coordinates and fit to rig bones.
const Pool = preload("res://scripts/clothing_pool.gd")
static var scene_cache: Dictionary = {}
static var cache_order: Array[String] = []

static func scene_for(item: Dictionary) -> PackedScene:
	var path := str(item.get("path", Pool.IMPORT_BASE + str(item.file)))
	if not bool(item.get("runtime",false)): return load(path) as PackedScene
	if scene_cache.has(path): return scene_cache[path]
	if str(item.get("format","")) == "pvm":
		var mesh := preload("res://scripts/clothing_mesh_source.gd").load_mesh(path)
		if mesh == null: return null
		var root := Node3D.new()
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		root.add_child(instance)
		instance.owner = root
		var mesh_scene := PackedScene.new()
		mesh_scene.pack(root)
		root.free()
		if cache_order.size()>=8: scene_cache.erase(cache_order.pop_front())
		scene_cache[path] = mesh_scene
		cache_order.append(path)
		return mesh_scene
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path,state) != OK: return null
	var generated := document.generate_scene(state)
	if generated == null: return null
	var packed := PackedScene.new()
	var error := packed.pack(generated)
	generated.free()
	if error != OK: return null
	if cache_order.size() >= 8: scene_cache.erase(cache_order.pop_front())
	scene_cache[path] = packed
	cache_order.append(path)
	return packed

static func bounds(node: Node, parent_transform := Transform3D.IDENTITY) -> Array[AABB]:
	var result: Array[AABB] = []
	var local_transform: Transform3D = parent_transform * node.transform if node is Node3D else parent_transform
	if node is MeshInstance3D and node.mesh != null:
		result.append(local_transform * node.get_aabb())
	for child in node.get_children(): result.append_array(bounds(child, local_transform))
	return result

static func attach(skeleton: Skeleton3D, item: Dictionary, slot: String, size := 1.0) -> void:
	var packed := scene_for(item)
	if packed == null: return
	var bones: Array = ["Head"]
	if item.kind in ["backpack","shirt","outfit","pants","necklace","cape"]: bones = ["spine_03"]
	if item.kind == "boots": bones = ["foot_l", "foot_r"]
	if item.kind in ["gloves","gauntlets"]: bones = ["hand_l","hand_r"]
	if item.kind == "bracelet": bones = ["lowerarm_l","lowerarm_r"]
	if item.kind == "shoulders": bones = ["clavicle_l","clavicle_r"]
	if item.kind == "belt": bones = ["pelvis"]
	for bone in bones:
		if skeleton.find_bone(bone) < 0: continue
		var accessory := packed.instantiate() as Node3D
		if bool(item.get("paired",false)):
			var wanted := "Left" if str(bone).ends_with("_l") else "Right"
			for child in accessory.get_children():
				if child.name != wanted: child.free()
		var boxes := bounds(accessory)
		if boxes.is_empty():
			accessory.free()
			continue
		var box: AABB = boxes[0]
		for other in boxes: box = box.merge(other)
		# Some prop exports face along X rather than Z.
		if item.kind == "mask" and box.size.x < box.size.z * 0.55:
			accessory.rotate_y(PI/2.0)
			boxes = bounds(accessory)
			box = boxes[0]
			for other in boxes: box = box.merge(other)
		if box.size.x < 0.00001 or box.size.y < 0.00001 or box.size.z < 0.00001:
			accessory.free()
			continue
		if item.kind in ["shirt","outfit","pants"]:
			_attach_shirt(skeleton,accessory,box,item,size)
			accessory.free()
			continue
		var attachment := BoneAttachment3D.new()
		attachment.name = "Pavlov_" + str(item.id)
		attachment.bone_name = bone
		skeleton.add_child(attachment)
		var fit := Node3D.new()
		fit.set_meta("wardrobe_loadout_key",slot)
		attachment.add_child(fit)
		fit.add_child(accessory)
		# Imported scenes have inconsistent units and origins; preserve their
		# proportions while fitting a known size for the selected body slot.
		var factor := 0.43 / box.size.x
		var center := box.get_center()
		var target := Vector3(0,0.16,0)
		if item.kind in ["hat","helmet","hood"]:
			center.y = box.position.y
			if item.kind == "hood":
				factor = minf(0.31 / box.size.x,0.40 / box.size.y)
				target.y = -0.09
			elif str(item.name).to_lower().contains("helmet"): target.y = 0.0
		elif item.kind == "glasses":
			factor = 0.20 / box.size.x
			target = Vector3(0,0.095,0.07)
		elif item.kind == "mask":
			factor = minf(0.22 / box.size.x,0.27 / box.size.y)
			target = Vector3(0,0.09,0.10)
		elif item.kind == "backpack":
			factor = minf(0.44 / box.size.x,0.57 / box.size.y)
			target = Vector3(0,-0.02,-0.23)
			fit.rotation.y = PI
		elif item.kind == "necklace":
			factor = minf(0.29 / box.size.x,0.31 / box.size.y)
			target = Vector3(0,0.12,0.10)
		elif item.kind == "cape":
			factor = minf(0.65 / box.size.x,1.05 / box.size.y)
			target = Vector3(0,-0.40,-0.18)
		elif item.kind in ["gloves","gauntlets","bracelet"]:
			factor = minf(0.16 / box.size.x,0.24 / box.size.y)
			fit.basis = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).basis.inverse()
			target = Vector3.ZERO
		elif item.kind == "belt":
			factor = 0.44 / box.size.x
			target = Vector3(0,0.02,0)
		elif item.kind == "shoulders":
			factor = minf(0.25 / box.size.x,0.25 / box.size.y)
			target = Vector3(0,0.02,0)
		elif item.kind == "earrings":
			factor = minf(0.20 / box.size.x,0.10 / box.size.y)
			target = Vector3(0,0.08,0)
		elif item.kind == "shirt":
			factor = minf(0.78 / box.size.x,0.67 / box.size.y)
			target = Vector3(0,-0.1,0)
		elif item.kind == "boots":
			# Foot bones point forward; use their rest-space frame to keep
			# the upright boot aligned with the lower leg.
			factor = minf(0.24 / box.size.x,0.28 / box.size.y)
			fit.basis = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).basis.inverse()
			target = fit.basis * Vector3(0,0.05,0.06)
		fit.position = target
		fit.scale = Vector3.ONE * factor * size
		fit.set_meta("wardrobe_base_scale", Vector3.ONE * factor)
		accessory.position -= center
		for animator in accessory.find_children("*", "AnimationPlayer", true, false): animator.stop()

static func _attach_shirt(skeleton: Skeleton3D, source: Node3D, box: AABB, item: Dictionary, size: float) -> void:
	# Transfer the rigid source shirt to the character's rest pose and give
	# every vertex weights on the nearest matching torso/arm bones.
	var width := 1.58 if str(item.file).begins_with("oZO") else 0.90
	var dimensions := Vector3(width,0.60,0.38) * size
	if item.kind == "pants": dimensions = Vector3(0.45,0.91,0.34) * size
	if item.kind == "outfit": dimensions = Vector3(0.90,1.48,0.44) * size
	var factor := dimensions / box.size
	var target := Vector3(0,1.23,0)
	if item.kind == "pants": target = Vector3(0,0.64,0)
	if item.kind == "outfit": target = Vector3(0,0.91,0)
	var fitting := Transform3D(Basis.from_scale(factor),target - box.get_center() * factor)
	var candidates: Array[int] = []
	var bone_names := ["spine_01","spine_02","spine_03","clavicle_l","clavicle_r","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r"]
	if item.kind == "pants": bone_names = ["pelvis","thigh_l","thigh_r","calf_l","calf_r","foot_l","foot_r"]
	if item.kind == "outfit": bone_names.append_array(["pelvis","thigh_l","thigh_r","calf_l","calf_r","foot_l","foot_r"])
	for bone_name in bone_names:
		var index := skeleton.find_bone(bone_name)
		if index >= 0: candidates.append(index)
	var rest_positions: Array[Vector3] = []
	var draped := str(item.get("format","")) == "pvm"
	for candidate in candidates:
		rest_positions.append(skeleton.get_bone_global_pose(candidate).origin if draped else skeleton.get_bone_global_rest(candidate).origin)
	var meshes: Array[MeshInstance3D] = []
	for mesh in source.find_children("*","MeshInstance3D",true,false): meshes.append(mesh)
	if source is MeshInstance3D: meshes.append(source)
	var result := ArrayMesh.new()
	for mesh in meshes:
		if mesh.mesh == null: continue
		var model_transform := mesh.transform
		var parent := mesh.get_parent()
		while parent != null and parent != source.get_parent():
			if parent is Node3D: model_transform = parent.transform * model_transform
			parent = parent.get_parent()
		var transform := fitting * model_transform
		var normal_basis := transform.basis.inverse().transposed()
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var bone_indices := PackedInt32Array()
			var weights := PackedFloat32Array()
			for index in vertices.size():
				vertices[index] = transform * vertices[index]
				if index < normals.size(): normals[index] = (normal_basis * normals[index]).normalized()
				var nearest := candidates[0]
				var second := nearest
				var first_distance := INF
				var second_distance := INF
				for candidate_index in candidates.size():
					var candidate := candidates[candidate_index]
					var distance := vertices[index].distance_squared_to(rest_positions[candidate_index])
					if distance < first_distance:
						second = nearest
						second_distance = first_distance
						nearest = candidate
						first_distance = distance
					elif distance < second_distance:
						second = candidate
						second_distance = distance
				var blend := second_distance / maxf(first_distance + second_distance,0.00001)
				# Skirts remain attached at the waist rather than being pulled
				# apart by the two independent leg chains.
				if draped and "skirt" in str(item.name).to_lower() and vertices[index].y < 0.98:
					nearest = skeleton.find_bone("pelvis")
					second = nearest
					blend = 1.0
				bone_indices.append_array(PackedInt32Array([nearest,second,0,0]))
				weights.append_array(PackedFloat32Array([blend,1.0-blend,0,0]))
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_BONES] = bone_indices
			arrays[Mesh.ARRAY_WEIGHTS] = weights
			# Recompute tangents from the transformed normals/UVs if needed.
			arrays[Mesh.ARRAY_TANGENT] = null
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var material := mesh.get_active_material(surface)
			if material == null: material = StandardMaterial3D.new()
			result.surface_set_material(result.get_surface_count()-1,material)
	var fitted := MeshInstance3D.new()
	fitted.name = "PavlovShirt_"+str(item.id)
	fitted.mesh = result
	fitted.skin = skeleton.create_skin_from_rest_transforms()
	if draped:
		var binding := Skin.new()
		for bone in skeleton.get_bone_count(): binding.add_bind(bone,skeleton.get_bone_global_pose(bone).affine_inverse())
		fitted.skin = binding
	fitted.set_meta("wardrobe_loadout_key","wardrobe_pants" if item.kind == "pants" else "wardrobe_shirt")
	skeleton.add_child(fitted)
	fitted.skeleton = fitted.get_path_to(skeleton)
