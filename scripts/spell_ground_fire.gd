extends Node3D
## Surface-attached fire: scorch follows the surface; flames and smoke rise upward.
const Plume=preload("res://scripts/fire_plume.gd")
var flames:Array[MeshInstance3D]=[]
var embers:CPUParticles3D
var smoke:CPUParticles3D
func setup(radius:float,appearance:Dictionary={},normal:Vector3=Vector3.UP) -> void:
 radius=maxf(0.0,radius)
 normal=normal.normalized() if not normal.is_zero_approx() else Vector3.UP
 var surface_basis:=Basis(Quaternion(Vector3.UP,normal))
 var lift:float=minf(0.025,radius*0.04)
 var tangent_up:Vector3=Vector3.UP-normal*normal.dot(Vector3.UP)
 var scorch:=MeshInstance3D.new()
 var quad:=QuadMesh.new()
 quad.size=Vector2.ONE*radius*2
 scorch.mesh=quad
 scorch.basis=surface_basis*Basis(Vector3.RIGHT,-PI/2)
 scorch.position=normal*lift
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
  var height:float=radius*0.9*(0.7+float(i%4)*0.17)
  var flame:=Plume.flame(height*0.62,height,i*2.37,appearance)
  # Keep the projected flame card inside the hitbox footprint on any surface.
  var half_extent:float=height*0.62*0.5+height*0.5*tangent_up.length()
  var r:float=maxf(0.0,radius-half_extent)*sqrt(float(i)/maxf(1,count-1))
  flame.position=surface_basis*Vector3(cos(i*2.4)*r,0,sin(i*2.4)*r)+normal*(lift+normal.dot(Vector3.UP)*height*0.5)
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
 smoke.position=Vector3.UP*radius*0.25
 # Embers and smoke retain the same proportions at tiny and large hitbox sizes.
 for particles in [embers,smoke]:
  var factor:float=radius/0.8
  var velocity_range:=Vector2(particles.initial_velocity_min,particles.initial_velocity_max)*factor
  var size_range:=Vector2(particles.scale_amount_min,particles.scale_amount_max)*factor
  particles.initial_velocity_min=velocity_range.x
  particles.initial_velocity_max=velocity_range.y
  particles.gravity*=factor
  particles.scale_amount_min=size_range.x
  particles.scale_amount_max=size_range.y
 add_child(smoke)

func fade(remaining:float) -> void:
 var strength:=clampf(remaining/1.2,0.0,1.0)
 for flame in flames:flame.material_override.set_shader_parameter("strength",strength)
 embers.emitting=remaining>0.6
 smoke.emitting=remaining>0.3
