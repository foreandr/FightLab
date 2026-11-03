extends Node3D
## Short-lived visual fragments only: no collision bodies or combat state.
var shards:Array[Dictionary]=[]
var age:=0.0
const LIFE:=0.72
static func show_for(actor:Node3D)->Node3D:
 var effect=load("res://scripts/block_shatter_effect.gd").new()
 actor.get_parent().add_child(effect)
 effect.global_position=actor.global_position+Vector3.UP*1.0
 effect.build()
 return effect
func build()->void:
 var rng:=RandomNumberGenerator.new();rng.randomize()
 var mesh:=ArrayMesh.new();var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-0.5,-0.35,0),Vector3(0.5,-0.2,0),Vector3(0.1,0.65,0)])
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 for i in 32:
  var shard:=MeshInstance3D.new();shard.mesh=mesh
  var material:=StandardMaterial3D.new()
  material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  material.cull_mode=BaseMaterial3D.CULL_DISABLED
  material.albedo_color=Color("ffe7a1") if i%3==0 else Color("e5f6ff")
  shard.material_override=material;add_child(shard)
  var outward:=Vector3(cos(i*TAU/16.0),rng.randf_range(-0.7,1.0),sin(i*TAU/16.0)).normalized()
  shard.position=outward*0.48;shard.rotation=Vector3(rng.randf()*TAU,rng.randf()*TAU,rng.randf()*TAU)
  shard.scale=Vector3.ONE*rng.randf_range(0.12,0.3)
  shards.append({"node":shard,"velocity":outward*rng.randf_range(2.0,4.0)+Vector3.UP,"spin":Vector3(rng.randf_range(-9,9),rng.randf_range(-9,9),rng.randf_range(-9,9))})
func _process(delta:float)->void:
 age+=delta
 if age>=LIFE:queue_free();return
 for shard in shards:
  shard.velocity+=Vector3.DOWN*delta*5.0
  shard.node.position+=shard.velocity*delta
  shard.node.rotation+=shard.spin*delta
  shard.node.material_override.albedo_color.a=clampf((LIFE-age)/0.3,0.0,1.0)
