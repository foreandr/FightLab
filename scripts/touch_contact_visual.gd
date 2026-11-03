extends Node3D
## Selected-region presentation follows the actual skin. It owns no hit/damage rules.
const Regions=preload("res://scripts/skinned_mesh_regions.gd")
const Plume=preload("res://scripts/fire_plume.gd")
var actor:CharacterBody3D
var preview_spec:Dictionary={}
var runtime_spec:Dictionary={}
var contacts:Array=[]
var element:="None"
var signature:=""
var regions:Dictionary={}
var white:ShaderMaterial
var fire:ShaderMaterial
func setup(owner_actor:CharacterBody3D)->void:
 actor=owner_actor;name="TouchContactVisual"
 var shader:=Shader.new()
 shader.code="shader_type spatial; render_mode unshaded,cull_front; uniform vec4 tint:source_color=vec4(1.0); uniform float thickness=0.004; void vertex(){VERTEX+=NORMAL*thickness;} void fragment(){ALBEDO=tint.rgb;EMISSION=tint.rgb*0.35;}"
 white=ShaderMaterial.new();white.shader=shader;white.set_shader_parameter("tint",Color.WHITE);white.set_shader_parameter("thickness",0.009)
 fire=ShaderMaterial.new();fire.shader=shader;fire.set_shader_parameter("tint",Color("ff9c32"));fire.set_shader_parameter("thickness",0.004)
func set_preview(spec:Dictionary)->void:
 preview_spec=spec.duplicate(true);sync_selection()
func set_runtime(spec:Dictionary)->void:
 runtime_spec=spec.duplicate(true);sync_selection()
func clear_runtime()->void:
 runtime_spec={};sync_selection()
func clear_all()->void:
 runtime_spec={};preview_spec={};sync_selection()
func sync_selection()->void:
 var spec:Dictionary=runtime_spec if not runtime_spec.is_empty() else preview_spec
 var wanted:Array=spec.get("touch_contacts",[])
 var effect:=str(spec.get("projectile_element","None"))
 var next_signature:=JSON.stringify([wanted,effect])
 if signature==next_signature:return
 signature=next_signature;contacts=wanted.duplicate();element=effect
 for bone in contacts:ensure_region(str(bone))
 _process(0.0)
func ensure_region(bone:String)->void:
 if regions.has(bone):return
 var records:Array=[]
 for source:MeshInstance3D in actor.skeleton.find_children("*","MeshInstance3D",true,false):
  if source.mesh==null or source.get_meta("presentation_overlay",false):continue
  var mesh:=Regions.region(source,actor.skeleton,bone)
  if mesh.get_surface_count()==0:continue
  var outline:=MeshInstance3D.new();outline.mesh=mesh;outline.skin=source.skin
  outline.set_meta("presentation_overlay",true)
  outline.name="ContactOutline"+bone;source.get_parent().add_child(outline)
  outline.skeleton=outline.get_path_to(actor.skeleton);outline.transform=source.transform
  outline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  outline.visible=false
  records.append({"source":source,"outline":outline})
 var flames:Array=[]
 var height:=0.32 if bone=="Head" else 0.23
 for index in 3:
  var flame:=Plume.flame(0.14,height,index*2.2)
  flame.name="ContactFlame"+bone+str(index);add_child(flame);flame.hide()
  flames.append(flame)
 regions[bone]={"records":records,"flames":flames,"height":height}
func _process(_delta:float)->void:
 if not is_instance_valid(actor):return
 var active:bool=actor.is_visible_in_tree() and actor.health>0.0
 for bone in regions:
  var region:Dictionary=regions[bone]
  var enabled:bool=active and contacts.has(bone)
  for record in region.records:
   if not is_instance_valid(record.source) or not is_instance_valid(record.outline):continue
   record.outline.visible=enabled and record.source.is_visible_in_tree()
   record.outline.transform=record.source.transform
   record.outline.material_override=fire if element=="Fire" else white
  var point:Vector3=actor.bone_point(bone)
  var fingertip:String="middle_01_"+str(bone).right(1) if str(bone).begins_with("hand") else ""
  if not fingertip.is_empty() and actor.skeleton.find_bone(fingertip)>=0:point=point.lerp(actor.bone_point(fingertip),0.6)
  for index in region.flames.size():
   var flame:MeshInstance3D=region.flames[index]
   flame.visible=enabled and element=="Fire"
   if flame.visible:
    var angle:float=index*TAU/3.0
    flame.global_position=point+Vector3(cos(angle)*0.035,float(region.height)*0.35,sin(angle)*0.035)
    flame.global_basis=Basis.IDENTITY
func _exit_tree()->void:
 for region in regions.values():
  for record in region.records:
   if is_instance_valid(record.outline):record.outline.queue_free()
