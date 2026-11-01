extends Node3D
## Combat-state presentation belongs to the actor, never the containing mode.
var actor:CharacterBody3D
var frozen:Node3D
var pulse_clock:=0.0

func setup(owner_actor:CharacterBody3D) -> void:
	actor=owner_actor
	name="CharacterStatusVisual"

func ensure_frozen() -> Node3D:
	if not is_instance_valid(frozen):
		frozen=preload("res://scripts/frozen_leg_effect.gd").new()
		frozen.fighter=actor
		add_child(frozen)
	return frozen

func _process(delta:float) -> void:
	if not is_instance_valid(actor):return
	if actor.burn_time>0.0 and actor.health>0.0 and not is_instance_valid(actor.burn_visual):
		actor.burn_visual=preload("res://scripts/character_burn_visual.gd").new()
		actor.add_child(actor.burn_visual)
		actor.burn_visual.setup(actor)
	if actor.freeze_time>0.0:ensure_frozen()
	pulse_clock-=delta
	if pulse_clock>0.0:return
	pulse_clock=0.14
	if not actor.is_visible_in_tree() or actor.health<=0:return
	var vfx:Node3D=actor.arena.vfx
	if not is_instance_valid(vfx):return
	if actor.stun_time>0:
		vfx.puff(actor.bone_point("spine_03"),"spark_05",2,Vector2.ONE*0.5,Vector3.UP*0.2,0.2,Color("fff253"),0.25)
	if actor.chill_time>0:
		vfx.puff(actor.bone_point("calf_l").lerp(actor.bone_point("calf_r"),0.5),"smoke_04",1,Vector2.ONE*0.65,Vector3.UP*0.3,0.4,Color(0.6,0.9,1,0.4),0.3)
	if actor.haste_time>0:
		vfx.puff(actor.bone_point("calf_r"),"trace_02",2,Vector2(0.2,0.8),Vector3.UP,0.16,Color("fff1a3"),0.3)

func reset() -> void:
	pulse_clock=0.0
	if is_instance_valid(frozen):frozen.step()
