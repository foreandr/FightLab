extends Node3D
## Collision walls enclose the meadow; transparent upper panels keep launches visible.
const HALF_SIZE := 10.0
const HEIGHT := 18.0

func _ready() -> void:
	var stone:=StandardMaterial3D.new()
	stone.albedo_color=Color("526063")
	stone.roughness=0.95
	var barrier:=StandardMaterial3D.new()
	barrier.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	barrier.albedo_color=Color(0.22,0.7,0.8,0.065)
	barrier.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	barrier.cull_mode=BaseMaterial3D.CULL_DISABLED
	var trim:=StandardMaterial3D.new()
	trim.albedo_color=Color("82c1ca")
	trim.emission_enabled=true
	trim.emission=Color("3d8a99")
	trim.emission_energy_multiplier=0.6
	for normal in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
		var along_x: bool=absf(normal.x)>0.5
		var center: Vector3=-normal*(HALF_SIZE+0.4)
		var wall:=StaticBody3D.new()
		wall.name="BoundaryWall"
		wall.collision_layer=1
		wall.collision_mask=0
		wall.set_meta("arena_wall",true)
		wall.set_meta("inward_normal",normal)
		var material:=PhysicsMaterial.new()
		material.friction=0.65
		material.bounce=0.16
		wall.physics_material_override=material
		var size:=Vector3(0.8,HEIGHT,21.6) if along_x else Vector3(21.6,HEIGHT,0.8)
		var collision:=CollisionShape3D.new()
		var shape:=BoxShape3D.new()
		shape.size=size
		collision.shape=shape
		wall.add_child(collision)
		add_child(wall)
		wall.position=center+Vector3.UP*(HEIGHT/2)
		box(center+Vector3.UP*0.5,Vector3(size.x,1,size.z),stone)
		box(center+Vector3.UP*9.5,Vector3(size.x,17,size.z),barrier)
		box(center+Vector3.UP*1.03,Vector3(size.x+0.03,0.065,size.z+0.03),trim)
		for offset in [-10.0,-5.0,0.0,5.0,10.0]:
			var p: Vector3=center+(Vector3.BACK if along_x else Vector3.RIGHT)*offset
			box(p+Vector3.UP*1.5,Vector3(0.9,3,0.9),stone)
			box(p+Vector3.UP*3.03,Vector3(0.95,0.09,0.95),trim)

func box(at: Vector3,size: Vector3,material: Material) -> void:
	var node:=MeshInstance3D.new()
	var mesh_:=BoxMesh.new()
	mesh_.size=size
	node.mesh=mesh_
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position=at
