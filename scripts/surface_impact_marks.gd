extends Node3D
## Bounded visual dents/cracks. Never changes a surface's mesh or collision.
const MAX_MARKS:=32
const Rules=preload("res://scripts/combat_defense_rules.gd")
var marks:Array[Dictionary]=[]
var serial:=0

static func radius_for(damage:float) -> float:
	return clampf(0.28*sqrt(maxf(0.0,damage)/Rules.RAGDOLL_DAMAGE),0.28,1.75)

func add_impact(surface:CollisionObject3D,point:Vector3,normal:Vector3,damage:float) -> MeshInstance3D:
	if not Rules.ragdolls(damage) or surface.get_meta("combat_no_surface_marks",false):return null
	prune()
	var radius:=radius_for(damage)
	for mark in marks:
		if mark.surface.get_ref()==surface and mark.node.global_position.distance_to(point)<minf(radius,mark.radius)*0.3:
			if damage>mark.damage:
				mark.damage=damage;mark.radius=radius
				configure(mark.node,point,normal,damage)
			return mark.node
	while marks.size()>=MAX_MARKS:marks.pop_front().node.queue_free()
	var node:=MeshInstance3D.new()
	node.name="PhysicalImpactMark"
	var quad:=QuadMesh.new()
	quad.size=Vector2.ONE*2.0
	node.mesh=quad
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/combat/vfx/surface_impact.gdshader")
	mat.set_shader_parameter("seed",float(serial))
	node.material_override=mat
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.add_child(node)
	configure(node,point,normal,damage)
	marks.append({"surface":weakref(surface),"node":node,"radius":radius,"damage":damage})
	serial+=1
	return node

func configure(node:MeshInstance3D,point:Vector3,normal:Vector3,damage:float) -> void:
	var radius:=radius_for(damage)
	node.global_transform=Transform3D(Basis(Quaternion(Vector3.BACK,normal.normalized())).scaled(Vector3.ONE*radius),point+normal.normalized()*0.008)
	node.material_override.set_shader_parameter("severity",clampf(sqrt(damage/Rules.RAGDOLL_DAMAGE),1.0,8.0))
	node.set_meta("physical_damage",damage)
	node.set_meta("dent_radius",radius)

func prune() -> void:
	for i in range(marks.size()-1,-1,-1):
		if not is_instance_valid(marks[i].node):marks.remove_at(i)

func _process(_delta:float) -> void:prune()

func clear() -> void:
	for mark in marks:
		if is_instance_valid(mark.node):mark.node.queue_free()
	marks.clear()
