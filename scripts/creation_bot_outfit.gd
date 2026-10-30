extends RefCounted
## Plain training clothes use the base body's exact skin weights.
static func profile(index: int) -> Dictionary:
	return {"creation_training_outfit":true,"name":"Training bot","body":"Masculine","skin":"Light","skin_color":[Color("d4a582"),Color("aa7957"),Color("e2bfa1")][index%3],"hair":"Short","hair_color":Color("32261f"),"build":0.98,"wardrobe_shirt":"Training tank top","shirt_color":[Color("deddd7"),Color("929ba5"),Color("b2b8b6")][index%3],"wardrobe_pants":"Peasant","bottoms_color":Color("303b4c"),"wardrobe_arms":"None","wardrobe_boots":"None","wardrobe_hands":"None","wardrobe_belt":"None","wardrobe_hat":"None","wardrobe_mask":"None","wardrobe_back":"None","wardrobe_necklace":"None","wardrobe_earrings":"None","wardrobe_shoulders":"None","wardrobe_bracelet":"None"}

static func add_tank(body: MeshInstance3D, skeleton: Skeleton3D, color: Color) -> void:
	var source := body.mesh
	var result := ArrayMesh.new()
	var pelvis_y := skeleton.get_bone_global_rest(skeleton.find_bone("pelvis")).origin.y
	var chest_y := skeleton.get_bone_global_rest(skeleton.find_bone("spine_03")).origin.y
	var neck_y := skeleton.get_bone_global_rest(skeleton.find_bone("neck_01")).origin.y
	for surface in source.get_surface_count():
		var original := source.surface_get_material(surface)
		if original != null and not original.resource_name.begins_with("MI_Superhero"): continue
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var kept := PackedInt32Array()
		for triangle in range(0,indices.size(),3):
			var center := (vertices[indices[triangle]]+vertices[indices[triangle+1]]+vertices[indices[triangle+2]])/3.0
			if center.y < pelvis_y-0.06 or center.y > neck_y+0.01: continue
			var torso_weight := 0.0
			for corner in 3:
				var vertex := indices[triangle+corner]
				for influence in 4:
					var offset := vertex*4+influence
					if offset>=bones.size():continue
					var name_value := skeleton.get_bone_name(bones[offset])
					if name_value.begins_with("spine_") or name_value=="pelvis" or name_value.begins_with("clavicle_"):
						torso_weight += weights[offset]
			if torso_weight < 1.65: continue
			# Leave the neck and armholes open, with two shoulder straps.
			var neckline := chest_y+0.055 if center.z>0.0 else chest_y+0.16
			if center.y>neckline and absf(center.x)<0.095: continue
			if center.y>chest_y-0.025 and absf(center.x)>0.205: continue
			kept.append_array(PackedInt32Array([indices[triangle],indices[triangle+1],indices[triangle+2]]))
		if kept.is_empty(): continue
		for index in vertices.size():
			if vertices[index].y<pelvis_y-0.04:
				for influence in 4:
					bones[index*4+influence]=skeleton.find_bone("pelvis") if influence==0 else 0
					weights[index*4+influence]=1.0 if influence==0 else 0.0
			vertices[index].x *= 1.035
			vertices[index].z *= 1.045
			vertices[index].y = maxf(vertices[index].y,pelvis_y-0.04)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		arrays[Mesh.ARRAY_INDEX] = kept
		for custom in range(Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM3+1):arrays[custom]=null
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.95
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		result.surface_set_material(result.get_surface_count()-1,material)
	if result.get_surface_count()==0:return
	var tank := MeshInstance3D.new()
	tank.name = "TrainingTankTop"
	tank.mesh = result
	tank.skin = body.skin
	skeleton.add_child(tank)
	tank.skeleton = tank.get_path_to(skeleton)
	tank.set_meta("wardrobe_loadout_key","wardrobe_shirt")

static func full_length_pants(source: Mesh, side := "") -> Mesh:
	var hem := 10.0
	var knee := 0.62
	for surface in source.get_surface_count():
		var arrays: Array = source.surface_get_arrays(surface)
		for vertex in arrays[Mesh.ARRAY_VERTEX]: hem = minf(hem,vertex.y)
	if hem>=knee:return source
	var result := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		if not side.is_empty():
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var kept := PackedInt32Array()
			for triangle in range(0,indices.size(),3):
				var x := (vertices[indices[triangle]].x+vertices[indices[triangle+1]].x+vertices[indices[triangle+2]].x)/3.0
				if (x>0.0)==(side=="left"): kept.append_array(PackedInt32Array([indices[triangle],indices[triangle+1],indices[triangle+2]]))
			if kept.is_empty():continue
			arrays[Mesh.ARRAY_INDEX]=kept
		for index in vertices.size():
			if vertices[index].y>=knee:continue
			vertices[index].y = remap(vertices[index].y,hem,knee,0.13,knee)
			if index<normals.size():
				normals[index].y *= (knee-hem)/(knee-0.13)
				normals[index] = normals[index].normalized()
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material := source.surface_get_material(surface)
		result.surface_set_material(result.get_surface_count()-1,material if material!=null else StandardMaterial3D.new())
	return result
