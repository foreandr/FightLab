extends RefCounted
## Direct sampling gives every untracked joint a posed baseline, never T-rest.
static func layer(actor:Node,clip:String,time:float) -> void:
	if not actor.player.has_animation(clip):return
	var animation:Animation=actor.player.get_animation(clip)
	for track in animation.get_track_count():
		var path:=animation.track_get_path(track)
		if path.get_subname_count()==0:continue
		var bone:=String(path.get_subname(0))
		if not actor.bones.has(bone):continue
		var index:int=actor.bones[bone]
		match animation.track_get_type(track):
			Animation.TYPE_ROTATION_3D:actor.skeleton.set_bone_pose_rotation(index,animation.rotation_track_interpolate(track,time).normalized())
			Animation.TYPE_POSITION_3D:actor.skeleton.set_bone_pose_position(index,animation.position_track_interpolate(track,time))

static func sample(actor:Node,clip:String,time:float) -> void:
	actor.skeleton.reset_bone_poses()
	layer(actor,"fight/guard",0)
	layer(actor,clip,time)
	actor.skeleton.force_update_all_bone_transforms()

static func idle(actor:Node,time:=0.0) -> void:
	actor.model.rotation=Vector3.ZERO
	actor.twist_age=-1
	var idle_clip:=preload("res://scripts/default_idle.gd").resolve(actor,actor.player)
	actor.clip=idle_clip
	var length:float=actor.player.get_animation(idle_clip).length
	sample(actor,idle_clip,fposmod(time,maxf(0.001,length)))
