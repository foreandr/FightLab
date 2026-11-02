extends Node3D
## Bone-following burn presentation reused by every BattleActor and game mode.
const Plume=preload("res://scripts/fire_plume.gd")
var actor:CharacterBody3D
var anchors:Array[Dictionary]=[]
var strength:=0.0
var embers:CPUParticles3D
var burn_audio:AudioStreamPlayer3D
func setup(owner_actor:CharacterBody3D) -> void:
	actor=owner_actor
	name="CharacterBurnVisual"
	burn_audio=preload("res://scripts/burning_audio.gd").new()
	add_child(burn_audio)
	burn_audio.setup(actor.arena.audio)
	for item in [["spine_03",Vector3(0,0,0.14),0.48],["pelvis",Vector3(0.1,0,-0.12),0.38],["lowerarm_l",Vector3(-0.04,0,0.03),0.32],["lowerarm_r",Vector3(0.04,0,0.03),0.35],["thigh_l",Vector3(-0.07,0,0.07),0.37],["calf_r",Vector3(0.05,0,0.06),0.33]]:
		if actor.practice_wooden_dummy:
			item[0]={"lowerarm_l":"hand_l","lowerarm_r":"hand_r","thigh_l":"pelvis","calf_r":"Head"}.get(item[0],item[0])
		var flame:=Plume.flame(float(item[2])*0.65,item[2],anchors.size()*2.37)
		add_child(flame)
		anchors.append({"node":flame,"bone":item[0],"offset":item[1],"height":item[2]})
	embers=Plume.particles(0.18)
	embers.amount=6
	add_child(embers)
	_process(0.0)

func _process(delta:float) -> void:
	if not is_instance_valid(actor):queue_free();return
	var burning:bool=actor.burn_time>0.0 and actor.health>0.0
	strength=move_toward(strength,1.0 if burning else 0.0,delta*5.0)
	global_basis=Basis.IDENTITY
	for anchor in anchors:
		anchor.node.global_position=actor.bone_point(anchor.bone)+actor.global_basis*anchor.offset+Vector3.UP*float(anchor.height)*0.5
		anchor.node.material_override.set_shader_parameter("strength",strength)
	burn_audio.global_position=actor.bone_point("spine_03")
	burn_audio.set_burning(burning and actor.is_visible_in_tree())
	embers.global_position=actor.bone_point("spine_03")
	embers.emitting=burning and actor.is_visible_in_tree()
	if not burning and strength<=0.0:queue_free()
