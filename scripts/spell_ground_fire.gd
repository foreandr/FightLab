extends Node3D
## Grounded animated tongues, sparse embers/smoke, and a soft scorch base.
const Plume=preload("res://scripts/fire_plume.gd")
var flames:Array[MeshInstance3D]=[]
var embers:CPUParticles3D
var smoke:CPUParticles3D
func setup(radius:float,appearance:Dictionary={}) -> void:
 var scorch:=MeshInstance3D.new()
 var quad:=QuadMesh.new()
 quad.size=Vector2.ONE*radius*2
 scorch.mesh=quad
 scorch.rotation.x=-PI/2
 scorch.position.y=0.025
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
  flame.position=Vector3(cos(i*2.4)*r,height*0.5+0.02,sin(i*2.4)*r)
  add_child(flame)
  flames.append(flame)
 embers=Plume.particles(radius*0.5)
 add_child(embers)
 smoke=Plume.particles(radius*0.4,true)
 smoke.position.y=0.2
 add_child(smoke)

func fade(remaining:float) -> void:
 var strength:=clampf(remaining/1.2,0.0,1.0)
 for flame in flames:flame.material_override.set_shader_parameter("strength",strength)
 embers.emitting=remaining>0.6
 smoke.emitting=remaining>0.3
