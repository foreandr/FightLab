extends Node3D
## Surface-attached fire: scorch follows the surface; flames and smoke rise upward.
const Plume=preload("res://scripts/fire_plume.gd")
var flames:Array[MeshInstance3D]=[]
var embers:CPUParticles3D
var smoke:CPUParticles3D
func setup(radius:float,appearance:Dictionary={},normal:Vector3=Vector3.UP) -> void:
 var surface_basis:=Basis(Quaternion(Vector3.UP,normal.normalized()))
 var scorch:=MeshInstance3D.new()
 var quad:=QuadMesh.new()
 quad.size=Vector2.ONE*radius*2
 scorch.mesh=quad
 scorch.basis=surface_basis*Basis(Vector3.RIGHT,-PI/2)
 scorch.position=normal*0.025
 var dark:=StandardMaterial3D.new()
 dark.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 dark.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 dark.albedo_texture=load("res://assets/combat/vfx/scorch_03.png")
 dark.albedo_color=Color(0.16,0.08,0.025,0.55)
 dark.cull_mode=BaseMaterial3D.CULL_DISABLED
 scorch.material_override=dark
 scorch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(scorch)
 var count:int=clampi(int(radius*7)+5,7,16)
 for i in count:
  var height:float=minf(1.0,0.28+radius*0.45)*(0.7+float(i%4)*0.17)
  var flame:=Plume.flame(height*0.62,height,i*2.37,appearance)
  var r:float=radius*0.8*sqrt(float(i)/maxf(1,count-1))
  flame.position=surface_basis*Vector3(cos(i*2.4)*r,0,sin(i*2.4)*r)+normal*0.07+Vector3.UP*height*0.5
  add_child(flame)
  flames.append(flame)
 embers=Plume.particles(radius*0.5)
 embers.emission_shape=CPUParticles3D.EMISSION_SHAPE_POINTS
 var origins:=PackedVector3Array()
 for flame in flames:origins.append(flame.position-Vector3.UP*float(flame.mesh.size.y)*0.5)
 embers.emission_points=origins
 add_child(embers)
 smoke=Plume.particles(radius*0.4,true)
 smoke.emission_shape=CPUParticles3D.EMISSION_SHAPE_POINTS
 smoke.emission_points=origins
 smoke.position=Vector3.UP*0.2
 add_child(smoke)

func fade(remaining:float) -> void:
 var strength:=clampf(remaining/1.2,0.0,1.0)
 for flame in flames:flame.material_override.set_shader_parameter("strength",strength)
 embers.emitting=remaining>0.6
 smoke.emitting=remaining>0.3
