extends Node3D
## Name and three live resource bars that follow each arena fighter.
var fighter: CharacterBody3D
var display_name := ""
var name_label: Label3D
var status_label: Label3D
var resource_fills: Dictionary = {}
var chat_bubble: Node3D
var chat_panel: MeshInstance3D
var chat_outline: MeshInstance3D
var chat_tail: MeshInstance3D
var chat_tail_fill: MeshInstance3D
var chat_label: Label3D
var chat_time_left := 0.0
const BAR_WIDTH := 1.28
const BAR_HEIGHT := 0.065

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
	name_label=make_label(23,0.0085)
	name_label.name="FighterName"
	name_label.position.y=0.34
	name_label.text=display_name
	name_label.modulate=Color("fff4d8")
	name_label.outline_modulate=outline_color
	add_child(name_label)
	_add_resource_bar("HEALTH", 0.11, Color("ed414b"))
	_add_resource_bar("STAMINA", 0.03, Color("70d5a8"))
	_add_resource_bar("MAGICA", -0.05, Color("8fc8ff"))
	_add_resource_bar("BLOCK", -0.13, Color("efbd58"))
	status_label=make_label(18,0.009)
	status_label.name="Status"
	status_label.position.y=-0.31
	status_label.outline_modulate=outline_color
	add_child(status_label)
	_build_chat_bubble()
	update_tag()

func _add_resource_bar(caption: String, y: float, color: Color) -> void:
	var fill_box:=BoxMesh.new()
	fill_box.size=Vector3(BAR_WIDTH,BAR_HEIGHT,0.05)
	var fill:=MeshInstance3D.new()
	fill.name=caption+"Fill"
	fill.mesh=fill_box
	fill.material_override=make_material(color)
	fill.position=Vector3(0,y,0.045)
	add_child(fill)
	resource_fills[caption.to_lower()]={"node":fill,"mesh":fill_box}

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
	box.size=Vector3(BAR_WIDTH,BAR_HEIGHT,0.05)
	mesh.mesh=box
	mesh.material_override=make_material(color)
	return mesh

func _build_chat_bubble() -> void:
	chat_bubble=Node3D.new()
	chat_bubble.name="ChatBubble"
	# Keep the bubble close enough to the nameplate to stay inside the camera
	# frame during the tutorial's close third-person view.
	chat_bubble.position.y=0.62
	chat_bubble.visible=false
	add_child(chat_bubble)
	chat_outline=MeshInstance3D.new()
	chat_outline.name="BubbleBorder"
	chat_outline.mesh=_rounded_rect_mesh(0.96,0.38,0.075)
	chat_outline.material_override=_bubble_material(Color("d8e5ed"))
	chat_outline.position.z=0.02
	chat_bubble.add_child(chat_outline)
	chat_tail=MeshInstance3D.new()
	chat_tail.name="BubbleTailBorder"
	chat_tail.mesh=_triangle_mesh(Vector2(-0.38,-0.135),Vector2(-0.16,-0.135),Vector2(-0.61,-0.285))
	chat_tail.material_override=_bubble_material(Color("d8e5ed"))
	chat_tail.position.z=0.018
	chat_bubble.add_child(chat_tail)
	chat_panel=MeshInstance3D.new()
	chat_panel.name="BubblePanel"
	chat_panel.mesh=_rounded_rect_mesh(0.91,0.33,0.06)
	chat_panel.material_override=_bubble_material(Color("172331"))
	chat_panel.position.z=0.05
	chat_bubble.add_child(chat_panel)
	chat_tail_fill=MeshInstance3D.new()
	chat_tail_fill.name="BubbleTailFill"
	chat_tail_fill.mesh=_triangle_mesh(Vector2(-0.35,-0.125),Vector2(-0.19,-0.125),Vector2(-0.57,-0.238))
	chat_tail_fill.material_override=_bubble_material(Color("172331"))
	chat_tail_fill.position.z=0.048
	chat_bubble.add_child(chat_tail_fill)
	chat_label=make_label(19,0.008)
	chat_label.name="ChatText"
	chat_label.position=Vector3(0,0,0.08)
	chat_label.modulate=Color("f5f7fa")
	chat_label.outline_size=3
	chat_bubble.add_child(chat_label)
	_resize_chat_bubble(0.96)

func _rounded_rect_mesh(width:float,height:float,radius:float)->ArrayMesh:
	var half_width:=width*0.5
	var half_height:=height*0.5
	var corner_radius:=minf(radius,minf(half_width,half_height))
	var points:=PackedVector2Array()
	var corner_centers:=[
		Vector2(half_width-corner_radius,half_height-corner_radius),
		Vector2(-half_width+corner_radius,half_height-corner_radius),
		Vector2(-half_width+corner_radius,-half_height+corner_radius),
		Vector2(half_width-corner_radius,-half_height+corner_radius)
	]
	for corner_index in 4:
		var start_angle:=deg_to_rad(float(corner_index)*90.0)
		for step in 5:
			var angle:=start_angle+deg_to_rad(float(step)*22.5)
			points.append(corner_centers[corner_index]+Vector2(cos(angle),sin(angle))*corner_radius)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point_index in points.size():
		var next_index:=(point_index+1)%points.size()
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(points[point_index].x,points[point_index].y,0))
		surface.add_vertex(Vector3(points[next_index].x,points[next_index].y,0))
	surface.generate_normals()
	return surface.commit()

func _triangle_mesh(first:Vector2,second:Vector2,tip:Vector2)->ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [first,second,tip]:
		surface.add_vertex(Vector3(point.x,point.y,0))
	surface.generate_normals()
	return surface.commit()

func _resize_chat_bubble(width:float)->void:
	if not is_instance_valid(chat_outline) or not is_instance_valid(chat_panel):return
	chat_outline.mesh=_rounded_rect_mesh(width,0.38,0.075)
	chat_panel.mesh=_rounded_rect_mesh(width-0.05,0.33,0.06)
	var half_width:=width*0.5
	chat_tail.mesh=_triangle_mesh(Vector2(-half_width+0.10,-0.135),Vector2(-half_width+0.32,-0.135),Vector2(-half_width-0.13,-0.285))
	chat_tail_fill.mesh=_triangle_mesh(Vector2(-half_width+0.13,-0.125),Vector2(-half_width+0.29,-0.125),Vector2(-half_width-0.08,-0.238))
	chat_label.position.x=0
	# Offset the bubble beside the overlapping nameplates and point its tail back
	# toward the trainer.
	chat_tail.position.x=0
	chat_tail_fill.position.x=0

func _bubble_material(color: Color) -> StandardMaterial3D:
	var material:=make_material(color)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	# The bubble is a thin, camera-facing mesh. Keep it visible regardless of
	# triangle winding so the rounded panel and its pointer render together.
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	return material

func show_chat_bubble(message: String, duration: float=4.0) -> void:
	if not is_instance_valid(chat_bubble):return
	chat_label.text=message
	var width:=clampf(float(message.length())*0.052+0.42,0.90,1.90)
	_resize_chat_bubble(width)
	chat_bubble.visible=true
	chat_time_left=duration

func update_tag() -> void:
	if not is_instance_valid(fighter):
		queue_free()
		return
	if fighter.get_meta("hide_overhead_tag", false):
		visible = false
		return
	visible=fighter.visible
	if not visible or resource_fills.is_empty():return
	var anchor: Vector3=fighter.global_position+Vector3.UP*2.20
	if fighter.has_method("overhead_tag_position"):
		anchor=fighter.overhead_tag_position()
	global_position=anchor
	var camera:=get_viewport().get_camera_3d()
	if camera!=null:global_basis=camera.global_basis.orthonormalized()
	var team_index:=int(fighter.get("team"))
	var name_offset:float=-0.34 if team_index==0 else (0.34 if team_index==1 else 0.0)
	name_label.position.x=name_offset
	chat_bubble.position.x=name_offset+1.15
	var maximum: float=fighter.max_health_value()
	_set_resource_fraction("health",fighter.health/maximum)
	_set_resource_fraction("stamina",_fighter_number("stamina")/100.0)
	_set_resource_fraction("magica",_fighter_number("mana")/100.0)
	_set_resource_fraction("block",_fighter_number("guard_energy")/44.0)
	status_label.text=""
	if fighter.get("drowned")==true:
		status_label.text="DROWNED"
	elif fighter.get("ice_trapped")==true:
		status_label.text="TRAPPED IN ICE"
	elif _fighter_number("freeze_time")>0:
		status_label.text="FROZEN · %.1fs"%_fighter_number("freeze_time")
	elif _fighter_number("stun_time")>0:
		status_label.text="STUNNED"
	elif fighter.get("practice_return_enabled")==true:
		status_label.text=str(fighter.get("return_state"))
	if _fighter_number("water_depth")>1.65 and fighter.health>0:
		status_label.text="AIR · %.1fs"%_fighter_number("air_remaining")

func _set_resource_fraction(key: String, raw_fraction: float) -> void:
	var fraction:=clampf(raw_fraction,0.0,1.0)
	var entry: Dictionary=resource_fills[key]
	var box: BoxMesh=entry.mesh
	var fill: MeshInstance3D=entry.node
	box.size.x=BAR_WIDTH*fraction
	fill.position.x=-(BAR_WIDTH-box.size.x)*0.5

func _fighter_number(property_name: String) -> float:
	var value: Variant = fighter.get(property_name)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return 0.0

func _process(_delta: float) -> void:
	update_tag()
	if chat_time_left>0:
		chat_time_left=maxf(0.0,chat_time_left-_delta)
		if chat_time_left<=0 and is_instance_valid(chat_bubble):chat_bubble.visible=false
