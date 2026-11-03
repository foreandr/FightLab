extends RefCounted
## Shared selection language: blue hover, gold selection, gold overhead diamond.
const SELECTED := Color("e9bf54")
const HOVERED := Color("80d8ff")

static func create_marker(parent:Node) -> Label3D:
	var marker:=Label3D.new()
	marker.name="FocusedTargetDiamond"
	marker.text="◆"
	marker.font_size=32
	marker.pixel_size=0.010
	marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test=true
	marker.modulate=SELECTED
	marker.outline_size=7
	marker.outline_modulate=Color("20202a")
	marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	marker.visible=false
	parent.add_child(marker)
	return marker

static func update_marker(marker:Label3D,target:Node3D) -> void:
	if not is_instance_valid(marker):return
	marker.visible=is_instance_valid(target) and target.is_visible_in_tree()
	if not marker.visible:return
	var anchor:Vector3=target.global_position+Vector3.UP*2.2
	if target.has_method("overhead_tag_position"):anchor=target.overhead_tag_position()
	marker.global_position=anchor+Vector3.UP*0.48

static func update_ring(ring:MeshInstance3D,selected:bool,hovered:bool,active:bool=true) -> void:
	ring.visible=active and (selected or hovered)
	var color:=SELECTED if selected else HOVERED
	var material:=ring.material_override as StandardMaterial3D
	material.albedo_color=color
	if material.emission_enabled:material.emission=color

static func ensure_ring(unit:CharacterBody3D) -> MeshInstance3D:
	var ring:MeshInstance3D=unit.get_node_or_null("UnitFocusRing")
	if is_instance_valid(ring):return ring
	ring=MeshInstance3D.new()
	ring.name="UnitFocusRing"
	var mesh:=TorusMesh.new()
	mesh.inner_radius=0.62 if unit.practice_wooden_dummy else 0.42
	mesh.outer_radius=0.68 if unit.practice_wooden_dummy else 0.47
	mesh.rings=24
	mesh.ring_segments=8
	ring.mesh=mesh
	ring.position.y=0.04
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override=material
	ring.visible=false
	unit.add_child(ring)
	return ring


static func pick(camera:Camera3D,units:Array,screen_position:Vector2) -> CharacterBody3D:
	var origin:=camera.project_ray_origin(screen_position)
	var ray_end:=origin+camera.project_ray_normal(screen_position)*200.0
	var closest:CharacterBody3D
	var distance:=INF
	for unit in units:
		if not is_instance_valid(unit) or not unit.is_visible_in_tree() or camera.is_position_behind(unit.global_position):continue
		var center:Vector3=unit.focus_position()
		var bottom:Vector3=center+Vector3.UP*0.3
		var top:Vector3=center+Vector3.UP*1.55
		if is_instance_valid(unit.ragdoll):
			bottom=unit.bone_point("pelvis")
			top=unit.bone_point("Head")
		var points:=Geometry3D.get_closest_points_between_segments(origin,ray_end,bottom,top)
		if points[0].distance_to(points[1])>0.4:continue
		var depth:=origin.distance_to(points[0])
		if depth<distance:closest=unit;distance=depth
	return closest
