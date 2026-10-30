extends RefCounted
const Source=preload("res://scripts/animation_source_pose.gd")
const Mirror=preload("res://scripts/animation_mirror.gd")

static func pose(actor:Node,profile:Dictionary,progress:float) -> void:
	actor.capture_ice_pose()
	actor.skeleton.reset_bone_poses()
	actor.model.rotation=Vector3.ZERO
	actor.twist_age=-1
	var duration:float=float(profile.get("source_duration",Source.duration(actor,profile.step,profile.clip)))
	var recipe:=Source.clip_at(actor,profile.step,profile.clip,progress,duration)
	actor.clip=recipe.name
	actor.player.speed_scale=1.0
	actor.player.play(recipe.name,0,1)
	actor.player.seek(actor.player.get_animation(recipe.name).length*float(recipe.blend),true)
	actor.player.advance(0)
	preload("res://scripts/editor_rig_pose.gd").sample(actor,recipe.name,actor.player.get_animation(recipe.name).length*float(recipe.blend))
	if profile.get("mirrored",false):Mirror.apply(actor)
	if profile.get("frames",[]).size()>=2:actor.apply_custom_jump_pose(progress,profile.frames,true)
	actor.restore_ice_pose()
	actor.skeleton.force_update_all_bone_transforms()
