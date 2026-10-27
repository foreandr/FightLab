extends Control
## Isolated rig preview: no combat actions, resource changes or chain edits.
var viewport: SubViewport
class PreviewRig extends Node3D:
	var model: Node3D
	var skeleton: Skeleton3D
	var player: AnimationPlayer
	var bones := {}

var fighter: PreviewRig
var camera: Camera3D
var entry: Dictionary={}
var clock := 0.0
var loops := 0
var arena_geometry: Node3D
var arena_mesh_count := 0

func setup(arena: Node3D) -> void:
	var headless: bool=DisplayServer.get_name()=="headless"
	var parent: Node=self
	if not headless:
		var render:=SubViewportContainer.new()
		render.stretch=true
		render.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(render)
		viewport=SubViewport.new()
		viewport.size=Vector2i(640,400)
		viewport.own_world_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
		render.add_child(viewport)
		parent=viewport
	var stage:=Node3D.new()
	parent.add_child(stage)
	if not headless:
		for node in arena.get_children():
			if node is WorldEnvironment or node is DirectionalLight3D:
				var copy=node.duplicate()
				if copy is DirectionalLight3D:copy.shadow_enabled=false
				stage.add_child(copy)
	# Reuse the actual arena meshes/materials, including its sand, gates, stands
	# and upper walls. The preview stays independent of combat state and physics.
	arena_geometry=Node3D.new()
	arena_geometry.name="ColosseumPreview"
	stage.add_child(arena_geometry)
	for source in arena.get_node("Colosseum").find_children("*","MeshInstance3D",true,false):
		var copy:=MeshInstance3D.new()
		copy.mesh=source.mesh
		copy.material_override=source.material_override
		copy.transform=arena.global_transform.affine_inverse()*source.global_transform
		arena_geometry.add_child(copy)
		arena_mesh_count+=1
	fighter=PreviewRig.new()
	stage.add_child(fighter)
	fighter.model=arena.fighters[0].model.duplicate()
	fighter.add_child(fighter.model)
	fighter.skeleton=fighter.model.find_child("Skeleton3D",true,false)
	fighter.player=fighter.model.find_children("*","AnimationPlayer",true,false)[0]
	fighter.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for i in fighter.skeleton.get_bone_count():
		fighter.bones[fighter.skeleton.get_bone_name(i)]=i
	camera=Camera3D.new()
	camera.fov=38
	stage.add_child(camera)
	camera.current=not headless

func show_animation(selected: Dictionary) -> void:
	entry=selected.duplicate()
	clock=0
	loops=0
	fighter.skeleton.reset_bone_poses()
	tick(0)

func tick(delta: float) -> void:
	if entry.is_empty() or not is_instance_valid(fighter):return
	clock+=delta
	var duration:=1.6
	if clock>=duration:
		loops+=int(clock/duration)
		clock=fmod(clock,duration)
	var phase:=clock/duration
	var clip: String=entry.clip
	var kind: String=entry.kind
	var rate:=1.75 if entry.step=="Sprint" else 1.0
	var height:=0.0
	var t:=clampf((phase-0.12)/0.74,0,1)
	if kind=="jump":
		if phase<0.18:
			clip="duel/takeoff"
			t=phase/0.18
		elif phase<0.78:
			clip="duel/air"
			t=(phase-0.18)/0.6
			height=sin(t*PI)*1.6
		else:
			clip="duel/land"
			t=(phase-0.78)/0.22
	elif kind in ["air","twist"]:height=1.1
	elif kind=="block":
		var style: String="brace" if entry.step=="Brace Block" else "palm"
		if phase<0.2:
			clip="duel/shield_raise_"+style
			t=phase/0.2
		elif phase<0.75:
			clip="duel/shield_hold_"+style
			t=(phase-0.2)/0.55
		else:
			clip="duel/shield_lower_"+style
			t=(phase-0.75)/0.25
	fighter.skeleton.reset_bone_poses()
	fighter.player.play(clip,0)
	var animation: Animation=fighter.player.get_animation(clip)
	var sample_time:=t*animation.length
	if entry.step in ["Run","Sprint","Crouch"]:sample_time=fmod(clock*rate,animation.length)
	fighter.player.seek(sample_time,true)
	var pelvis: int=fighter.bones["pelvis"]
	var origin: Vector3=fighter.skeleton.get_bone_pose_position(pelvis)
	var rest: Vector3=fighter.skeleton.get_bone_rest(pelvis).origin
	origin.x=rest.x
	origin.z=rest.z
	fighter.skeleton.set_bone_pose_position(pelvis,origin)
	if kind=="twist":
		var pose: Quaternion=fighter.skeleton.get_bone_pose_rotation(pelvis)
		fighter.skeleton.set_bone_pose_rotation(pelvis,Quaternion(Vector3.UP,TAU*t)*pose)
	fighter.position=Vector3(0,height,0)
	fighter.model.position=Vector3.ZERO
	if kind not in ["air","twist","jump"]:
		var lowest:=INF
		for bone in ["foot_l","foot_r","ball_l","ball_r"]:
			lowest=minf(lowest,fighter.skeleton.get_bone_global_pose(fighter.bones[bone]).origin.y)
		fighter.model.position.y=-lowest+0.015
	var airborne: bool=kind in ["air","twist","jump"]
	camera.position=Vector3(2.7,2.3,4.7) if airborne else Vector3(1.8,1.45,3.0)
	camera.look_at(Vector3(0,1.55 if airborne else 0.95,0))
