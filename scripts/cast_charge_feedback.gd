extends Node
## Actor-owned presentation only. Shared cast rules still determine all power.
const Regions=preload("res://scripts/skinned_mesh_regions.gd")
var actor:CharacterBody3D
var bone:="hand_r"
var tier:=0
var holding:=false
var pulse:=0.0
var fade:=0.0
var material:ShaderMaterial
var regions:Dictionary={}

func setup(owner_actor:CharacterBody3D)->void:
 actor=owner_actor;name="CastChargeFeedback"
 var shader:=Shader.new()
 shader.code="shader_type spatial; render_mode unshaded,cull_front,blend_add,depth_draw_never; uniform vec4 tint:source_color=vec4(1.0,0.8,0.3,1.0); uniform float strength=0.0; uniform float thickness=0.01; void vertex(){VERTEX+=NORMAL*thickness;} void fragment(){ALBEDO=tint.rgb;EMISSION=tint.rgb*1.5;ALPHA=strength;}"
 material=ShaderMaterial.new();material.shader=shader

func begin(emitter:String)->void:
 bone=emitter;tier=0;holding=true;fade=1.0;pulse=0.0
 if not regions.has(bone):
  var meshes:Array=[]
  for source:MeshInstance3D in actor.skeleton.find_children("*","MeshInstance3D",true,false):
   if source.mesh==null or source.get_meta("presentation_overlay",false):continue
   var mesh:=Regions.region(source,actor.skeleton,bone)
   if mesh.get_surface_count()==0:continue
   var outline:=MeshInstance3D.new();outline.mesh=mesh;outline.skin=source.skin
   outline.name="ChargeOutline"+bone;outline.set_meta("presentation_overlay",true)
   source.get_parent().add_child(outline);outline.transform=source.transform
   outline.skeleton=outline.get_path_to(actor.skeleton);outline.material_override=material
   outline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   meshes.append(outline)
  regions[bone]=meshes
 refresh()

func progress(value:float)->void:
 if not holding:return
 var reached:=clampi(floori(clampf(value,0.0,1.0)*3.0+0.0001),0,3)
 if reached>tier:
  for next in range(tier+1,reached+1):actor.arena.audio.impact("charge_"+str(next),actor.bone_point(bone),0.35+next*0.2)
  tier=reached;pulse=1.0
 refresh()

func finish()->void:holding=false

func refresh()->void:
 for region in regions:
  for mesh in regions[region]:mesh.visible=region==bone and fade>0.001
 var colors:=[Color("e4d7ab"),Color("ffda79"),Color("ffbc35"),Color("fff0a0")]
 material.set_shader_parameter("tint",colors[tier])
 material.set_shader_parameter("strength",fade*(0.18+tier*0.2+pulse*0.4))
 material.set_shader_parameter("thickness",0.008+tier*0.006+pulse*0.008)

func _process(delta:float)->void:
 pulse=maxf(0.0,pulse-delta*5.0)
 if not holding:fade=maxf(0.0,fade-delta*7.0)
 if is_instance_valid(actor):refresh()
