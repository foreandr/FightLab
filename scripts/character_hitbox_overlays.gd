extends Node
## Display actual receiving collision shapes without changing collision settings.
var field:Node
var enabled:=false
var outlines:Dictionary={}
var material:=StandardMaterial3D.new()

func _ready() -> void:
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color("ff69c7")
	material.no_depth_test=true
	set_process(enabled)

func set_enabled(value:bool) -> void:
	enabled=value
	set_process(enabled)
	for record in outlines.values():
		if is_instance_valid(record.node):record.node.visible=enabled
	if enabled:refresh()

func _process(_delta:float) -> void:refresh()

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
					outlines[id]={"node":outline,"shape":child.shape,"dirty":true}
					child.shape.changed.connect(mark_dirty.bind(id))
				var record:Dictionary=outlines[id]
				if record.shape!=child.shape:
					record.shape=child.shape
					record.dirty=true
					child.shape.changed.connect(mark_dirty.bind(id))
				if record.dirty:
					record.node.mesh=wire_mesh(child.shape)
					record.dirty=false
				record.node.visible=enabled
	for id in outlines:
		if not active.has(id):outlines[id].node.hide()

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
