extends Node3D
## Reusable barrier geometry preview; no protection, resource or damage rules.
const BodyOverlay=preload("res://scripts/body_barrier_overlay.gd")
var body_actor:Node3D
var body_overlays:Array=[]
var surface:MeshInstance3D
var mode:="Self"
var radius:=1.5
var placed_ground:=Vector3.ZERO
func _ready()->void:
 visibility_changed.connect(sync_body_overlay)
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
 if actor!=body_actor:
  BodyOverlay.set_strength(body_overlays,0.0,"authoring")
  body_actor=actor;body_overlays=BodyOverlay.apply(actor.skeleton)
 mode=kind;radius=size;placed_ground=ground
 surface.visible=kind!="Self"
 sync_body_overlay()
 if kind=="Place":
  global_position=ground+Vector3.UP*radius
  global_basis=Basis.IDENTITY
 else:
  global_position=actor.global_position+Vector3.UP*1.05
  global_basis=actor.global_basis
 scale=Vector3.ONE if kind=="Self" else Vector3.ONE*radius
func sync_body_overlay()->void:
 BodyOverlay.set_strength(body_overlays,1.0 if is_visible_in_tree() and mode=="Self" and is_instance_valid(body_actor) and body_actor.health>0.0 else 0.0,"authoring")
func _exit_tree()->void:
 BodyOverlay.set_strength(body_overlays,0.0,"authoring")
