extends Node3D
## A compact name, HP readout, and bar that follows each arena fighter.
var fighter: CharacterBody3D
var display_name := ""
var name_label: Label3D
var value_label: Label3D
var fill: MeshInstance3D
var fill_box: BoxMesh
const BAR_WIDTH := 1.28

static func attach(fighter_: CharacterBody3D, name_: String) -> Node3D:
	var tag=load("res://scripts/fighter_overhead_tag.gd").new()
	tag.name="OverheadHealthTag"
	tag.fighter=fighter_
	tag.display_name=name_
	fighter_.add_child(tag)
	return tag

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var outline_color:=Color("121922")
	name_label=make_label(27,0.01)
	name_label.name="FighterName"
	name_label.position.y=0.16
	name_label.text=display_name
	name_label.modulate=Color("fff4d8")
	name_label.outline_modulate=outline_color
	add_child(name_label)
	value_label=make_label(22,0.01)
	value_label.name="CurrentHealth"
	value_label.position.y=-0.10
	value_label.outline_modulate=outline_color
	add_child(value_label)
	var backing:=make_bar(Color("15202b"))
	backing.position.y=-0.27
	backing.position.z=0.015
	add_child(backing)
	fill_box=BoxMesh.new()
	fill_box.size=Vector3(BAR_WIDTH,0.072,0.05)
	fill=MeshInstance3D.new()
	fill.name="HealthFill"
	fill.mesh=fill_box
	fill.material_override=make_material(Color("66dc85"))
	fill.position.y=-0.27
	fill.position.z=0.045
	add_child(fill)
	update_tag()

func make_label(size: int, pixel_size_: float) -> Label3D:
	var label:=Label3D.new()
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true
	label.font_size=size
	label.pixel_size=pixel_size_
	label.outline_size=7
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return label

func make_material(color: Color) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test=true
	return material

func make_bar(color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var box:=BoxMesh.new()
	box.size=Vector3(BAR_WIDTH,0.072,0.05)
	mesh.mesh=box
	mesh.material_override=make_material(color)
	return mesh

func update_tag() -> void:
	if not is_instance_valid(fighter):
		queue_free()
		return
	visible=fighter.visible
	if not visible or not is_instance_valid(fill):return
	var anchor: Vector3=fighter.global_position+Vector3.UP*2.20
	if fighter.has_method("overhead_tag_position"):
		anchor=fighter.overhead_tag_position()
	global_position=anchor
	var camera:=get_viewport().get_camera_3d()
	if camera!=null:global_basis=camera.global_basis.orthonormalized()
	var maximum: float=fighter.max_health_value()
	var fraction:=clampf(fighter.health/maximum,0,1)
	value_label.text="%d / %d HP"%[ceili(fighter.health),ceili(maximum)]
	fill_box.size.x=BAR_WIDTH*fraction
	fill.position.x=-(BAR_WIDTH-fill_box.size.x)*0.5
	var ratio_color:=Color("e45149").lerp(Color("71df88"),fraction)
	fill.material_override.albedo_color=ratio_color

func _process(_delta: float) -> void:
	update_tag()
