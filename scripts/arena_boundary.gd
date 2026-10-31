extends Node3D
## Circular colosseum: architecture is baked into one colored mesh per sector.
const MapConfig=preload("res://scripts/gladiatorial_pit_config.gd")
const RADIUS := MapConfig.FLOOR_RADIUS
const HEIGHT := MapConfig.WALL_HEIGHT
const SECTORS := MapConfig.SECTORS
var sectors: Array[MeshInstance3D]=[]
var vertices:=PackedVector3Array()
var normals:=PackedVector3Array()
var colors:=PackedColorArray()
var stone:=Color("b9a080")
var trim:=Color("dfc69a")

func _ready() -> void:
	name="Colosseum"
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.roughness=0.92
	var floor_:=StaticBody3D.new()
	floor_.name="ArenaFloor"
	var shape:=BoxShape3D.new()
	shape.size=Vector3((RADIUS+23.0)*2.0,0.2,(RADIUS+23.0)*2.0)
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	collision.position.y=-0.1
	floor_.add_child(collision)
	add_child(floor_)
	build_sand()
	build_upper_ward()
	for i in SECTORS:
		vertices=PackedVector3Array()
		normals=PackedVector3Array()
		colors=PackedColorArray()
		var angle:=i*TAU/SECTORS
		var half:=PI/SECTORS
		var b:=Basis(Vector3.UP,angle)
		build_collision(b*Vector3.BACK,angle)
		for course in 6:
			for block in 2:
				var start:=angle-half+block*half+0.0015
				ring_block(10,11.1,course*0.58,course*0.58+0.56,start,start+half-0.003,stone.darkened(float((i+course+block)%4)*0.035))
		ring_block(9.88,11.24,3.48,3.72,angle-half,angle+half,trim)
		ring_block(9.9,11.15,0.03,0.27,angle-half,angle+half,stone.darkened(0.2))
		if i%(SECTORS/4)==0:
			gate(b)
		for row in 12:
			var radius:=11.3+row*0.73
			var y:=3.72+row*0.34
			var seat:=stone.lightened(0.035 if row%2==0 else 0.0)
			if i%4==0:
				var gap:=0.32/(radius+RADIUS-10.0)
				ring_block(radius,radius+0.71,0,y,angle-half,angle-gap,seat)
				ring_block(radius,radius+0.71,0,y,angle+gap,angle+half,seat)
				ring_block(radius,radius+0.71,0,y-0.12,angle-gap,angle+gap,stone.darkened(0.22))
			else:
				ring_block(radius,radius+0.71,0,y,angle-half+0.001,angle+half-0.001,seat)
		for course in 6:
			ring_block(20.65,23.0,course*1.25,course*1.25+1.23,angle-half,angle+half,stone.darkened((course%2)*0.05))
		exterior_niche(b)
		for level in 2:
			var base:=7.55+level*3.85
			for side in [-1,1]:
				box(b*Vector3(side*2.125,base+1.05,RADIUS+12.3),Vector3(0.48,2.1,1.1),b,stone)
				box(b*Vector3(side*2.125,base+2.12,RADIUS+12.3),Vector3(0.7,0.22,1.3),b,trim)
			arch(b,Vector3(0,base+2.12,RADIUS+12.3),1.88,0.34,1.05,stone)
			ring_block(21.65,23.05,base+3.52,base+3.82,angle-half,angle+half,trim)
			ring_block(21.85,22.9,base-0.22,base,angle-half,angle+half,stone.darkened(0.15))
		if i%4==2:
			var banner: Color=[Color("913a2b"),Color("315d78"),Color("aa7b25")][(i/4)%3]
			box(b*Vector3(0,9.05,RADIUS+11.63),Vector3(1.05,2.2,0.055),b,banner)
			box(b*Vector3(0,9.05,RADIUS+11.59),Vector3(0.07,2.2,0.03),b,trim)
			box(b*Vector3(0,10.2,RADIUS+11.6),Vector3(1.32,0.09,0.14),b,Color("766039"))
		var mesh_:=ArrayMesh.new()
		var arrays:=[]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_NORMAL]=normals
		arrays[Mesh.ARRAY_COLOR]=colors
		mesh_.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var node:=MeshInstance3D.new()
		node.mesh=mesh_
		node.material_override=material
		add_child(node)
		sectors.append(node)

func _process(_delta: float) -> void:
	var camera:=get_viewport().get_camera_3d()
	if camera==null:
		return
	var direction:=Vector3(camera.global_basis.z.x,0,camera.global_basis.z.z).normalized()
	var inside_bowl:=Vector2(camera.global_position.x,camera.global_position.z).length()<RADIUS+6.5
	for i in sectors.size():
		var outward:=Vector3(sin(i*TAU/SECTORS),0,cos(i*TAU/SECTORS))
		sectors[i].visible=inside_bowl or camera.global_position.y>17 or outward.dot(direction)<0.45

func build_collision(outward: Vector3,angle: float) -> void:
	var wall:=StaticBody3D.new()
	wall.name="ColosseumWall"
	wall.collision_layer=1
	wall.collision_mask=0
	wall.set_meta("arena_wall",true)
	wall.set_meta("inward_normal",-outward)
	var physics:=PhysicsMaterial.new()
	physics.friction=0.65
	physics.bounce=0.16
	wall.physics_material_override=physics
	var shape:=BoxShape3D.new()
	shape.size=Vector3(2*(RADIUS+0.55)*tan(PI/SECTORS)+0.08,HEIGHT,1.1)
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	wall.add_child(collision)
	add_child(wall)
	wall.position=outward*(RADIUS+0.55)+Vector3.UP*(HEIGHT/2)
	wall.rotation.y=angle

func build_upper_ward() -> void:
	# The bowl's upper containment is visible, rather than an unexplained air wall.
	var node:=MeshInstance3D.new()
	var mesh_:=CylinderMesh.new()
	mesh_.top_radius=RADIUS+0.01
	mesh_.bottom_radius=RADIUS+0.01
	mesh_.height=14.28
	mesh_.radial_segments=64
	mesh_.cap_top=false
	mesh_.cap_bottom=false
	node.mesh=mesh_
	node.position.y=10.86
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded,cull_disabled,depth_draw_never; void fragment(){float ribs=pow(max(0.,cos(UV.x*201.0619)),60.); float edge=pow(abs(UV.y*2.-1.),40.); ALBEDO=vec3(.9,.68,.32); ALPHA=.008+ribs*.035+edge*.035;}"
	var material:=ShaderMaterial.new()
	material.shader=shader
	node.material_override=material
	add_child(node)

func build_sand() -> void:
	var node:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(240,240)
	node.mesh=plane
	node.position.y=-0.015
	var shader:=Shader.new()
	shader.code="shader_type spatial; uniform float arena_radius=15.; varying vec3 p; void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;} void fragment(){float grain=fract(sin(dot(floor(p.xz*120.),vec2(12.9898,78.233)))*43758.5453); float wear=sin(p.x*.8+sin(p.z*.6))*sin(p.z*1.3)*.5+.5; float r=length(p.xz); float ring=1.-smoothstep(.018,.045,abs(r-(arena_radius-.75))); float circle=1.-smoothstep(.025,.05,abs(r-arena_radius*.32)); ALBEDO=mix(vec3(.45,.32,.17),vec3(.69,.55,.35),wear*.38+grain*.2+.32); ALBEDO=mix(ALBEDO,vec3(.36,.25,.13),max(ring,circle)*.42); ROUGHNESS=1.;}"
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("arena_radius",RADIUS)
	node.material_override=material
	add_child(node)

func gate(b: Basis) -> void:
	var dark:=Color("24221e")
	box(b*Vector3(0,1.05,RADIUS-0.04),Vector3(1.7,2.1,0.05),b,dark)
	for j in 10:
		var a:=j*PI/10
		var c: Vector3=b*Vector3(0,2.05,RADIUS-0.08)
		triangle(c,c+b*Vector3(cos(a)*0.86,sin(a)*0.86,0),c+b*Vector3(cos(a+PI/10)*0.86,sin(a+PI/10)*0.86,0),b*Vector3.FORWARD,dark)
	arch(b,Vector3(0,2.05,RADIUS-0.11),1.02,0.28,0.22,trim)
	for side in [-1,1]:
		box(b*Vector3(side*1.02,1.0,RADIUS-0.11),Vector3(0.28,2.05,0.22),b,trim)
	for x in [-0.65,-0.33,0.0,0.33,0.65]:
		box(b*Vector3(x,1.32,RADIUS-0.16),Vector3(0.055,2.6,0.06),b,Color("565048"))
	box(b*Vector3(0,1.12,RADIUS-0.2),Vector3(1.68,0.07,0.07),b,Color("74603b"))

func exterior_niche(b: Basis) -> void:
	var dark:=Color("302b25")
	box(b*Vector3(0,1.7,RADIUS+13.04),Vector3(2.5,3.4,0.05),b,dark)
	for j in 12:
		var a:=j*PI/12
		var center: Vector3=b*Vector3(0,3.4,RADIUS+13.08)
		triangle(center,center+b*Vector3(cos(a+PI/12)*1.25,sin(a+PI/12)*1.25,0),center+b*Vector3(cos(a)*1.25,sin(a)*1.25,0),b*Vector3.BACK,dark)
	arch(b,Vector3(0,3.4,RADIUS+13.1),1.43,0.34,0.24,trim)
	for side in [-1,1]:
		box(b*Vector3(side*1.43,1.7,RADIUS+13.1),Vector3(0.34,3.4,0.24),b,trim)

func arch(b: Basis,center: Vector3,radius: float,thickness: float,depth: float,color: Color) -> void:
	for j in 11:
		var angle: float=(j+0.5)*PI/11
		var at: Vector3=center+Vector3(cos(angle)*radius,sin(angle)*radius,0)
		box(b*at,Vector3(radius*PI/11+0.025,thickness,depth),b*Basis(Vector3.BACK,angle+PI/2),color.darkened((j%3)*0.025))

func ring_block(inner: float,outer: float,bottom: float,top: float,start: float,end: float,color: Color) -> void:
	inner+=RADIUS-10.0
	outer+=RADIUS-10.0
	var a:=Vector3(sin(start),0,cos(start))
	var b:=Vector3(sin(end),0,cos(end))
	var p: Array[Vector3]=[a*inner+Vector3.UP*bottom,b*inner+Vector3.UP*bottom,b*outer+Vector3.UP*bottom,a*outer+Vector3.UP*bottom,a*inner+Vector3.UP*top,b*inner+Vector3.UP*top,b*outer+Vector3.UP*top,a*outer+Vector3.UP*top]
	hexahedron(p,color)

func box(center: Vector3,size: Vector3,b: Basis,color: Color) -> void:
	var p: Array[Vector3]=[]
	for v in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,-1,1),Vector3(-1,-1,1),Vector3(-1,1,-1),Vector3(1,1,-1),Vector3(1,1,1),Vector3(-1,1,1)]:
		p.append(center+b*(v*size*0.5))
	hexahedron(p,color)

func hexahedron(p: Array[Vector3],color: Color) -> void:
	for face in [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]:
		var normal: Vector3=(p[face[2]]-p[face[0]]).cross(p[face[1]]-p[face[0]]).normalized()
		triangle(p[face[0]],p[face[1]],p[face[2]],normal,color)
		triangle(p[face[0]],p[face[2]],p[face[3]],normal,color)

func triangle(a: Vector3,b: Vector3,c: Vector3,normal: Vector3,color: Color) -> void:
	vertices.append_array(PackedVector3Array([a,b,c]))
	normals.append_array(PackedVector3Array([normal,normal,normal]))
	colors.append_array(PackedColorArray([color,color,color]))
