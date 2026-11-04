extends RefCounted
## Preview-only presentation. Source materials and combat actors are never changed.
const SHADER = preload("res://assets/ui/shaders/gear_digitize.gdshader")
var actor: Node3D
var tween: Tween
var surfaces: Array[Dictionary] = []
var pending: Dictionary
var slots: Array[String] = []
var generation := 0
var active := false
func swap(host: Node3D, next: Dictionary, changed: Array[String]) -> void:
	actor=host; pending=next.duplicate(true); slots=changed; generation+=1
	if tween != null and tween.is_valid(): tween.kill()
	restore()
	active=true
	apply(0.0)
	tween=actor.create_tween()
	tween.tween_method(set_amount,0.0,1.0,0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(rebuild.bind(generation))
func matches(mesh: MeshInstance3D) -> bool:
	var node: Node=mesh
	while node!=null and node!=actor:
		if str(node.get_meta("wardrobe_loadout_key","")) in slots: return true
		if "hair" in slots and "hair" in str(node.name).to_lower(): return true
		node=node.get_parent()
	return false
func apply(amount: float) -> void:
	for mesh: MeshInstance3D in actor.model.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null or not matches(mesh): continue
		for i in mesh.mesh.get_surface_count():
			var original=mesh.get_surface_override_material(i)
			var source=mesh.get_active_material(i)
			var material:=ShaderMaterial.new(); material.shader=SHADER
			if source is StandardMaterial3D:
				material.set_shader_parameter("tint",source.albedo_color)
				material.set_shader_parameter("albedo_tex",source.albedo_texture)
				material.set_shader_parameter("vertex_tint",source.vertex_color_use_as_albedo)
				material.set_shader_parameter("surface_roughness",source.roughness)
			material.set_shader_parameter("amount",amount)
			mesh.set_surface_override_material(i,material)
			surfaces.append({"mesh":weakref(mesh),"surface":i,"original":original,"material":material})
func set_amount(value: float) -> void:
	for entry in surfaces: entry.material.set_shader_parameter("amount",value)
func rebuild(expected: int) -> void:
	if expected!=generation or not is_instance_valid(actor): return
	restore()
	pending["rotation"]=actor.rotation.y
	actor.set_profile(pending)
	apply(1.0)
	tween=actor.create_tween()
	tween.tween_method(set_amount,1.0,0.0,0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(finish)
func restore() -> void:
	for entry in surfaces:
		var mesh=entry.mesh.get_ref()
		if is_instance_valid(mesh): mesh.set_surface_override_material(entry.surface,entry.original)
	surfaces.clear()
func finish() -> void:
	restore(); active=false
func cancel() -> void:
	generation+=1
	if tween!=null and tween.is_valid(): tween.kill()
	finish()
