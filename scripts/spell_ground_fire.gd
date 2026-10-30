extends Node3D
## Layered flame masks and a soft scorch decal, bounded to twelve flame quads.
func setup(radius:float,appearance:Dictionary={}) -> void:
 var texture_name:String=str(appearance.get("texture","flame_04"))
 if texture_name=="Element style":texture_name="flame_04"
 var texture:Texture2D=preload("res://scripts/spell_textures.gd").texture(texture_name)
 if texture==null:texture=load("res://assets/combat/vfx/flame_04.png")
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
 dark.albedo_color=Color(0.18,0.09,0.03,0.5)
 dark.cull_mode=BaseMaterial3D.CULL_DISABLED
 scorch.material_override=dark
 scorch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(scorch)
 var count:int=clampi(int(radius*5)+4,5,12)
 for i in count:
  var flame:=MeshInstance3D.new()
  var mesh:=QuadMesh.new()
  var height:float=minf(1.5,0.45+radius*0.5)*(0.8+float(i%3)*0.15)
  mesh.size=Vector2(height*0.9,height)
  flame.mesh=mesh
  var r:float=radius*0.75*sqrt(float(i)/maxf(1,count-1))
  flame.position=Vector3(cos(i*2.4)*r,height*0.45,sin(i*2.4)*r)
  var mat:=ShaderMaterial.new()
  mat.shader=preload("res://assets/combat/vfx/flame_sprite.gdshader")
  mat.set_shader_parameter("mask_texture",texture)
  mat.set_shader_parameter("phase",float(i)*1.7)
  mat.set_shader_parameter("primary",appearance.get("color",Color("ff631b")))
  mat.set_shader_parameter("accent",appearance.get("accent",Color("fff3a0")))
  mat.set_shader_parameter("opacity",0.85)
  flame.material_override=mat
  flame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(flame)
