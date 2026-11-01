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
	var contact:=visual_contact(surface,point,normal)
	point=contact.position
	normal=contact.normal
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

static func visual_contact(surface:CollisionObject3D,point:Vector3,normal:Vector3) -> Dictionary:
	# A level can associate visible geometry with its simpler collision proxy.
	var result:={"position":point,"normal":normal}
	if not surface.has_meta("impact_visual_mesh"):return result
	var reference:WeakRef=surface.get_meta("impact_visual_mesh")
	var visual:MeshInstance3D=reference.get_ref() as MeshInstance3D
	if not is_instance_valid(visual) or visual.mesh==null:return result
	var start:=point+normal.normalized()*2.0
	var origin:=visual.to_local(start)
	var direction:Vector3=(visual.global_basis.inverse()*-normal).normalized()
	var faces:=visual.mesh.get_faces()
	var best:=4.0
	for i in range(0,faces.size(),3):
		var contact:Variant=Geometry3D.ray_intersects_triangle(origin,direction,faces[i],faces[i+1],faces[i+2])
		if contact==null:continue
		var world_point:=visual.to_global(contact)
		var distance:=start.distance_to(world_point)
		if distance<best:
			best=distance
			var face_normal:Vector3=visual.global_basis.inverse().transposed()*(faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]).normalized()
			if face_normal.dot(normal)<0.0:face_normal=-face_normal
			result={"position":world_point,"normal":face_normal.normalized()}
	return result

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
