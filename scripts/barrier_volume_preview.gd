extends Node3D
## Reusable barrier geometry preview; no protection, resource or damage rules.
var surface:MeshInstance3D
var mode:="Self"
var radius:=1.5
var placed_ground:=Vector3.ZERO
func _ready()->void:
 surface=MeshInstance3D.new();add_child(surface)
 var mesh:=SphereMesh.new();mesh.radius=1.0;mesh.height=2.0;mesh.radial_segments=32;mesh.rings=16
 surface.mesh=mesh
 var material:=StandardMaterial3D.new()
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.cull_mode=BaseMaterial3D.CULL_DISABLED
 material.albedo_color=Color(0.3,0.75,1.0,0.14)
 material.rim_enabled=true;material.rim=1.0;material.rim_tint=0.5
 surface.material_override=material
 surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func update_volume(actor:Node3D,kind:String,size:float,ground:Vector3)->void:
 mode=kind;radius=size;placed_ground=ground
 if kind=="Place":
  global_position=ground+Vector3.UP*radius
  global_basis=Basis.IDENTITY
 else:
  global_position=actor.global_position+Vector3.UP*1.05
  global_basis=actor.global_basis
  if kind=="Self":global_position+=actor.global_basis.z*0.6
 scale=Vector3(radius,radius,radius*0.18 if kind=="Self" else radius)
