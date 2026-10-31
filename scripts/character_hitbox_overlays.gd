extends Node
const Regions=preload("res://scripts/combat_hit_regions.gd")
## Display actual receiving collision shapes without changing collision settings.
var field:Node
var enabled:=false
var outlines:Dictionary={}
var material:=StandardMaterial3D.new()
var head_material:StandardMaterial3D
var flash_material:StandardMaterial3D
var fill_material:StandardMaterial3D
var flashes:Dictionary={}

func _ready() -> void:
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Regions.BODY_COLOR
	material.no_depth_test=true
	head_material=material.duplicate()
	head_material.albedo_color=Regions.HEAD_COLOR
	flash_material=material.duplicate()
	flash_material.albedo_color=Color("fff2a0")
	fill_material=flash_material.duplicate()
	fill_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_material.albedo_color=Color(1.0,0.8,0.15,0.38)
	set_process(enabled)

func set_enabled(value:bool) -> void:
	enabled=value
	if not enabled:clear_hits()
	set_process(enabled)
	for record in outlines.values():
		if is_instance_valid(record.node):record.node.visible=enabled
		if is_instance_valid(record.fill):record.fill.hide()
		if is_instance_valid(record.label):record.label.visible=enabled
	if enabled:refresh()

func flash_hit(area:Area3D) -> void:
	if not enabled or not is_instance_valid(area):return
	flashes[area.get_instance_id()]=Regions.FLASH_SECONDS
	refresh()

func clear_hits() -> void:
	flashes.clear()
	for record in outlines.values():
		if is_instance_valid(record.fill):record.fill.hide()
		if is_instance_valid(record.node):record.node.material_override=head_material if Regions.is_head(record.zone) else material

func _process(delta:float) -> void:
	for id in flashes.keys():
		flashes[id]-=delta
		if flashes[id]<=0:flashes.erase(id)
	refresh()

func refresh() -> void:
	for id in outlines.keys():
		if not is_instance_valid(outlines[id].node):outlines.erase(id)
	var active:Dictionary={}
	for fighter in field.fighters:
		var areas:Dictionary={}
		for pair in fighter.targets+fighter.limb_targets:areas[pair[0].get_instance_id()]=pair[0]
		if is_instance_valid(fighter.practice_dummy_visual):
			for area in fighter.practice_dummy_visual.hurtboxes:areas[area.get_instance_id()]=area
		for area in areas.values():
			if area.collision_layer==0 or not fighter.is_visible_in_tree() or not area.is_visible_in_tree():continue
			for child in area.get_children():
				if not child is CollisionShape3D or child.disabled or child.shape==null:continue
				var id:int=child.get_instance_id()
				active[id]=true
				if not outlines.has(id):
					var outline:=MeshInstance3D.new()
					outline.name="ReceiveHitbox"
					outline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					outline.material_override=material
					child.add_child(outline)
					var fill:=MeshInstance3D.new()
					fill.name="HitRegionFlash"
					fill.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					fill.material_override=fill_material
					child.add_child(fill)
					var zone:String=area.get_meta("zone","chest")
					var label:Label3D
					if not Regions.label(zone).is_empty():
						label=Label3D.new()
						label.text=Regions.label(zone)
						label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
						label.no_depth_test=true
						label.font_size=18
						label.pixel_size=0.008
						label.outline_size=4
						label.outline_modulate=Color("151b22")
						label.modulate=Regions.color(zone)
						child.add_child(label)
					outlines[id]={"node":outline,"fill":fill,"label":label,"zone":zone,"area_id":area.get_instance_id(),"shape":child.shape,"dirty":true}
					child.shape.changed.connect(mark_dirty.bind(id))
				var record:Dictionary=outlines[id]
				if record.shape!=child.shape:
					record.shape=child.shape
					record.dirty=true
					child.shape.changed.connect(mark_dirty.bind(id))
				if record.dirty:
					record.node.mesh=wire_mesh(child.shape)
					record.fill.mesh=solid_mesh(child.shape)
					if is_instance_valid(record.label):record.label.position=Vector3.UP*(child.shape.get_debug_mesh().get_aabb().size.y*0.5+0.08)
					record.dirty=false
				record.node.visible=enabled
				var flashing:bool=enabled and flashes.has(record.area_id)
				record.node.material_override=flash_material if flashing else (head_material if Regions.is_head(record.zone) else material)
				record.fill.visible=flashing
				if is_instance_valid(record.label):record.label.visible=enabled
	for id in outlines:
		if not active.has(id):
			outlines[id].node.hide()
			outlines[id].fill.hide()
			if is_instance_valid(outlines[id].label):outlines[id].label.hide()

func solid_mesh(shape:Shape3D) -> Mesh:
	if shape is CapsuleShape3D:
		var mesh:=CapsuleMesh.new()
		mesh.radius=shape.radius;mesh.height=shape.height
		mesh.radial_segments=12;mesh.rings=4
		return mesh
	if shape is SphereShape3D:
		var mesh:=SphereMesh.new()
		mesh.radius=shape.radius;mesh.height=shape.radius*2
		return mesh
	if shape is BoxShape3D:
		var mesh:=BoxMesh.new()
		mesh.size=shape.size
		return mesh
	return shape.get_debug_mesh()

func mark_dirty(id:int) -> void:
	if outlines.has(id):outlines[id].dirty=true

func wire_mesh(shape:Shape3D) -> Mesh:
	if not shape is CapsuleShape3D:return shape.get_debug_mesh()
	var radius:float=shape.radius
	var half:=maxf(0.0,float(shape.height)*0.5-radius)
	var mesh:=ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for end in [-1.0,1.0]:
		for step in 24:
			for angle in [TAU*step/24.0,TAU*(step+1)/24.0]:
				mesh.surface_add_vertex(Vector3(cos(angle)*radius,end*half,sin(angle)*radius))
	for plane in 4:
		var radial:=Vector3(cos(PI*plane/4.0),0,sin(PI*plane/4.0))
		for side in [-1.0,1.0]:
			mesh.surface_add_vertex(radial*radius*side+Vector3.UP*half)
			mesh.surface_add_vertex(radial*radius*side-Vector3.UP*half)
		for end in [-1.0,1.0]:
			for step in 16:
				for angle in [PI*step/16.0,PI*(step+1)/16.0]:
					mesh.surface_add_vertex(radial*cos(angle)*radius+Vector3.UP*end*(half+sin(angle)*radius))
	mesh.surface_end()
	return mesh
