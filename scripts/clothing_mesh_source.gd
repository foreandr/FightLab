extends RefCounted
## Prepared representation of a downloaded mesh; original PLY stays beside it.
static func load_mesh(path: String) -> ArrayMesh:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size()<12 or bytes.slice(0,4).get_string_from_ascii() != "PVM1": return null
	var count := bytes.decode_u32(4)
	var index_count := bytes.decode_u32(8)
	if count>300000 or index_count>1500000 or bytes.size()!=12+count*32+index_count*4: return null
	var positions := bytes.slice(12,12+count*12).to_float32_array()
	var normal_values := bytes.slice(12+count*12,12+count*24).to_float32_array()
	var uv_values := bytes.slice(12+count*24,12+count*32).to_float32_array()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	vertices.resize(count)
	normals.resize(count)
	uv.resize(count)
	for index in count:
		vertices[index] = Vector3(positions[index*3],positions[index*3+1],positions[index*3+2])
		normals[index] = Vector3(normal_values[index*3],normal_values[index*3+1],normal_values[index*3+2])
		uv[index] = Vector2(uv_values[index*2],uv_values[index*2+1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = bytes.slice(12+count*32).to_int32_array()
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c1baa6")
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,material)
	return mesh
