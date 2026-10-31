extends Node3D
## A wooden, padded striking dummy. The actor still owns damage and status logic.
var fighter:CharacterBody3D
var body:Node3D
var hurtboxes:Array[Area3D]=[]
var enabled:=false
var previous_damage:=0.0
var wobble:=0.0
var age:=0.0
var markers:Dictionary={}

func _ready() -> void:
	var wood:=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
varying vec3 grain_position;
void vertex(){ grain_position=VERTEX; }
void fragment(){
 float grain=sin(grain_position.y*95.0+sin(grain_position.x*18.0+grain_position.z*13.0)*2.0);
 ALBEDO=mix(vec3(0.30,0.14,0.055),vec3(0.65,0.38,0.14),grain*0.17+0.65);
 ROUGHNESS=0.88;
}
"""
	wood.shader=shader
	var canvas:=material(Color("baa477"))
	var leather:=material(Color("4b2c1d"))
	var iron:=material(Color("464643"))
	var red:=material(Color("b63524"))
	var chalk:=material(Color("e2d2ac"))
	box(self,"CrossFootA",Vector3(0,0.065,0),Vector3(1.0,0.13,0.2),wood)
	var foot:=box(self,"CrossFootB",Vector3(0,0.075,0),Vector3(1.0,0.13,0.2),wood)
	foot.rotation.y=PI/2
	cylinder(self,"FootCollar",Vector3(0,0.19,0),0.13,0.09,iron)
	body=Node3D.new()
	body.name="WoodenBody"
	body.position.y=0.2
	add_child(body)
	cylinder(body,"WoodenPost",Vector3(0,0.46,0),0.075,0.75,wood)
	cylinder(body,"PaddedTorso",Vector3(0,1.18,0),0.29,0.68,canvas)
	cylinder(body,"LowerBelt",Vector3(0,0.9,0),0.295,0.05,leather)
	cylinder(body,"UpperBelt",Vector3(0,1.46,0),0.295,0.045,leather)
	cylinder(body,"Neck",Vector3(0,1.59,0),0.085,0.17,wood)
	var head_mesh:=SphereMesh.new()
	head_mesh.radius=0.175
	head_mesh.height=0.35
	head_mesh.radial_segments=16
	head_mesh.rings=8
	mesh(body,"BlankWoodenHead",head_mesh,Vector3(0,1.83,0),wood)
	for side in [-1.0,1.0]:
		var arm:=cylinder(body,"WoodenArm",Vector3(side*0.5,1.39,0),0.075,0.58,wood)
		arm.rotation.z=side*deg_to_rad(80)
		var wrap:=cylinder(body,"ArmBinding",Vector3(side*0.67,1.36,0),0.084,0.15,leather)
		wrap.rotation.z=side*deg_to_rad(80)
	for ring in [[0.19,chalk],[0.145,red],[0.095,chalk],[0.045,red]]:
		var disc:=cylinder(body,"PaintedBullseye",Vector3(0,1.22,0.29+(0.2-float(ring[0]))*0.06),float(ring[0]),0.008,ring[1])
		disc.rotation.x=PI/2
	marker("Head",Vector3(0,1.83,0))
	marker("spine_03",Vector3(0,1.22,0))
	marker("pelvis",Vector3(0,0.87,0))
	marker("hand_l",Vector3(-0.76,1.35,0))
	marker("hand_r",Vector3(0.76,1.35,0))
	hurtbox("DummyTorso",Vector3(0,1.19,0),0.29,0.69,"chest","spine_03")
	hurtbox("DummyHead",Vector3(0,1.83,0),0.175,0.35,"head","Head")
	hurtbox("DummyPost",Vector3(0,0.55,0),0.085,0.75,"pelvis","pelvis")
	for side in [-1.0,1.0]:
		var arm:=hurtbox("DummyArm",Vector3(side*0.5,1.39,0),0.08,0.6,"arm_l" if side<0 else "arm_r","hand_l" if side<0 else "hand_r")
		arm.rotation.z=side*deg_to_rad(80)
	visible=false

func material(color:Color) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=color
	result.roughness=0.93
	return result

func mesh(parent:Node3D,title:String,shape:Mesh,point:Vector3,look:Material) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.name=title
	node.mesh=shape
	node.material_override=look
	node.position=point-(body.position if parent==body else Vector3.ZERO)
	parent.add_child(node)
	return node

func box(parent:Node3D,title:String,point:Vector3,size_:Vector3,look:Material) -> MeshInstance3D:
	var shape:=BoxMesh.new()
	shape.size=size_
	return mesh(parent,title,shape,point,look)

func cylinder(parent:Node3D,title:String,point:Vector3,radius:float,height:float,look:Material) -> MeshInstance3D:
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=16
	return mesh(parent,title,shape,point,look)

func marker(key:String,point:Vector3) -> void:
	var node:=Node3D.new()
	node.position=point-body.position
	body.add_child(node)
	markers[key]=node

func hurtbox(title:String,point:Vector3,radius:float,height:float,zone:String,bone:String) -> Area3D:
	var area:=Area3D.new()
	area.name=title
	area.position=point-body.position
	area.collision_layer=0
	area.collision_mask=0
	area.monitoring=false
	area.set_meta("fighter",fighter)
	area.set_meta("zone",zone)
	area.set_meta("bone",bone)
	var shape:=CapsuleShape3D.new()
	shape.radius=radius
	shape.height=height
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	area.add_child(collision)
	body.add_child(area)
	hurtboxes.append(area)
	return area

func aim_point(bone:String) -> Vector3:
	var marker_node:Node3D=markers.get(bone,markers.get("spine_03"))
	return marker_node.global_position if is_instance_valid(marker_node) else global_position+Vector3.UP*1.2

func set_enabled(value:bool) -> void:
	enabled=value
	visible=value
	fighter.practice_wooden_dummy=value
	fighter.model.visible=not value
	for area in hurtboxes:area.collision_layer=(8<<fighter.team) if value else 0
	if value:
		for item in fighter.targets:item[0].collision_layer=0
		for item in fighter.limb_targets:item[0].collision_layer=0
		reset_pose()

func reset_pose() -> void:
	body.rotation=Vector3.ZERO
	wobble=0.0
	previous_damage=fighter.damage_taken

func _process(delta:float) -> void:
	if not enabled:return
	# Keep the native human hidden even when an actor animation changes state.
	fighter.model.hide()
	age+=delta
	if fighter.damage_taken>previous_damage:
		wobble=minf(0.2,wobble+0.08)
		previous_damage=fighter.damage_taken
	wobble=move_toward(wobble,0.0,delta*0.16)
	var fallen:bool=fighter.health<=0.0
	var lean:Vector3=Vector3(0,0,-1.25) if fallen else Vector3(sin(age*20)*wobble,0,cos(age*17)*wobble*0.6)
	body.rotation=body.rotation.lerp(lean,minf(1.0,delta*9.0))
