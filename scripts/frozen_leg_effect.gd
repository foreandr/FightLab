extends Node3D
## Opaque frost-crusted leg casings, independent of the blue torso armor.
var fighter: CharacterBody3D
var pieces: Array=[]
var frost: ShaderMaterial

func _ready() -> void:
	name="FrozenLegs"
	frost=ShaderMaterial.new()
	frost.shader=preload("res://assets/combat/vfx/frozen_legs.gdshader")
	for side in ["l","r"]:
		for pair in [["thigh_"+side,"calf_"+side,0.18],["calf_"+side,"foot_"+side,0.16],["foot_"+side,"ball_"+side,0.14]]:
			var node:=MeshInstance3D.new()
			var mesh_:=CylinderMesh.new()
			mesh_.top_radius=pair[2]*0.8
			mesh_.bottom_radius=pair[2]*1.15
			mesh_.height=1.0
			mesh_.radial_segments=5
			node.mesh=mesh_
			node.material_override=frost
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(node)
			pieces.append([node,pair[0],pair[1]])
			for i in 3:
				var shard:=MeshInstance3D.new()
				var cone:=CylinderMesh.new()
				cone.top_radius=0
				cone.bottom_radius=0.075
				cone.height=0.5
				cone.radial_segments=4
				shard.mesh=cone
				shard.material_override=frost
				shard.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				node.add_child(shard)
				shard.position=Vector3(0.13 if side=="l" else -0.13,-0.25+i*0.22,0.04)
				shard.rotation.z=-0.85 if side=="l" else 0.85
	visible=false

func step() -> void:
	visible=is_instance_valid(fighter) and fighter.health>0 and fighter.freeze_time>0
	if not visible:
		return
	for piece in pieces:
		var a: Vector3=fighter.bone_point(piece[1])
		var b: Vector3=fighter.bone_point(piece[2])
		var axis:=b-a
		piece[0].global_position=(a+b)*0.5
		piece[0].global_basis=Basis(Quaternion(Vector3.UP,axis.normalized()))
		piece[0].scale=Vector3(1,maxf(0.15,axis.length()+0.08),1)

func _process(_delta:float) -> void:
	step()
