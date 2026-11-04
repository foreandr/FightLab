extends RefCounted
## Stable names and provenance shared by creator, saved characters and previews.
const PATH := "res://assets/characters/hair/community/catalog.json"
static var entries: Array = []
static func catalog() -> Array:
	if entries.is_empty() and FileAccess.file_exists(PATH):
		entries = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return entries
static func names() -> Array[String]:
	var result: Array[String] = ["Short", "Buns", "Long", "Side part", "None"]
	for item in catalog(): result.append(str(item.name))
	return result
static func find_style(value: String) -> Dictionary:
	for item in catalog():
		if str(item.name) == value: return item
	return {}
static func attach(skeleton: Skeleton3D, style: Dictionary, color: Color) -> void:
	var head := skeleton.find_bone("Head")
	if head < 0: return
	var mesh := load(str(style.mesh)) as Mesh
	if mesh == null: return
	var socket := BoneAttachment3D.new()
	socket.name = "CommunityHair"
	socket.bone_name = "Head"
	skeleton.add_child(socket)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	# Downloaded meshes are fitted in the same standing space as the base body.
	visual.transform = skeleton.get_bone_global_rest(head).affine_inverse()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.88
	if not str(style.texture).is_empty():
		mat.albedo_texture = load(str(style.texture))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.35
	visual.material_override = mat
	socket.add_child(visual)
