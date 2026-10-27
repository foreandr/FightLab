extends Node3D
## Persistent, bounded golden mantle and camera-facing lightning around Storm.
var fighter: CharacterBody3D
var clock := 0.0
var active_age := 0.0
var spark_clock := 0.0
var mantle: ShaderMaterial
var lightning: ImmediateMesh
var lightning_material: StandardMaterial3D
var light: OmniLight3D

func _ready() -> void:
	name="OverdriveAura"
	mantle=ShaderMaterial.new()
	mantle.shader=preload("res://assets/combat/vfx/overdrive.gdshader")
	var shell:=MeshInstance3D.new()
	var mesh_:=SphereMesh.new()
	mesh_.radius=0.72
	mesh_.height=2.6
	mesh_.radial_segments=20
	mesh_.rings=12
	shell.mesh=mesh_
	shell.material_override=mantle
	shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shell)
	lightning_material=StandardMaterial3D.new()
	lightning_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	lightning_material.albedo_color=Color("fff0a3")
	lightning_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	lightning=ImmediateMesh.new()
	var arcs:=MeshInstance3D.new()
	arcs.mesh=lightning
	arcs.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arcs)
	light=OmniLight3D.new()
	light.light_color=Color("ffd151")
	light.light_energy=0.65
	light.omni_range=3.2
	light.shadow_enabled=false
	add_child(light)
	visible=false

func step(delta: float) -> void:
	var active: bool=is_instance_valid(fighter) and fighter.health>0 and (fighter.haste_time>0 or fighter.flash_aura_time>0)
	visible=active
	if not active:
		active_age=0
		spark_clock=0
		return
	clock+=delta
	active_age+=delta
	spark_clock+=delta
	global_position=fighter.bone_point("pelvis")+Vector3.UP*0.12
	var strength:=minf(1,active_age/0.18)*minf(1,maxf(fighter.haste_time,fighter.flash_aura_time)/0.45)
	mantle.set_shader_parameter("clock",clock)
	mantle.set_shader_parameter("strength",strength)
	scale=Vector3.ONE*(1.0+sin(clock*8)*0.035)
	light.light_energy=(0.65+sin(clock*11)*0.12)*strength
	lightning.clear_surfaces()
	lightning.surface_begin(Mesh.PRIMITIVE_TRIANGLES,lightning_material)
	var view: Vector3=(fighter.arena.camera.global_position-global_position).normalized()
	for arc in 5:
		var angle:=arc*TAU/5+floorf(clock*12)*0.73
		var previous:=Vector3(cos(angle)*0.6,-0.85,sin(angle)*0.6)
		for segment in range(1,6):
			var t:=segment/5.0
			var radius:=0.57+sin(clock*29+arc*3+segment*5)*0.13
			var zigzag:=angle+t*0.7+sin(arc*12+segment*8+floorf(clock*12))*0.28
			var point:=Vector3(cos(zigzag)*radius,-0.85+t*2.05,sin(zigzag)*radius)
			var side: Vector3=(point-previous).cross(view).normalized()*0.012*strength
			for vertex in [previous-side,previous+side,point+side,previous-side,point+side,point-side]:
				lightning.surface_add_vertex(vertex)
			previous=point
	lightning.surface_end()
	if spark_clock>=0.12:
		spark_clock=0
		for i in 2:
			var angle:=clock*9+i*PI
			var point: Vector3=global_position+Vector3(cos(angle)*0.48,-0.65,sin(angle)*0.48)
			fighter.arena.vfx.puff(point,"spark_05",2,Vector2(0.16,0.7),Vector3.UP*2.2,0.45,Color(1,0.8,0.2,0.85),0.2)
			fighter.arena.vfx.puff(global_position+Vector3(cos(angle)*0.5,0.15+i*0.35,sin(angle)*0.5),"flame_04",2,Vector2(0.45,0.95),Vector3.UP*1.8,0.45,Color(1,0.82,0.16,0.4),0.15)
