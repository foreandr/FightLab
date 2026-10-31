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
