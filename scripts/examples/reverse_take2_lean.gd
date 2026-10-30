extends "res://scripts/examples/open_saved_aerial_combo.gd"

func build_demo() -> void:
	await super.build_demo()
	var fixed:=0
	for clip in workspace.timeline_clips:
		if str(clip.get("step",""))=="Flip":
			fixed+=fix_resource(str(clip.animation_resource),false)
	for entry in workspace.store_library.taken.values():
		if str(entry.get("title","")).begins_with("Corkscrew Open Hand Melee Hook Take 2"):
			fixed+=fix_resource(str(entry.animation_resource),true)
	workspace._on_timeline_scrubbed(0.0)
	print("LEAN REVERSED: ",fixed," resources; -35 to +35 degrees; timeline 0.00 s")

func fix_resource(path:String,full_combo:bool) -> int:
	var animation:Animation=load(path)
	assert(animation!=null,"Missing animation")
	if animation.has_meta("forward_lean_fixed"):return 0
	var backup:=path+".before_lean_fix"
	assert(DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(backup))==OK)
	var rig:Skeleton3D=workspace.actor.skeleton
	var parent:=rig.get_bone_parent(workspace.actor.bones.pelvis)
	var basis:Basis=rig.global_basis
	if parent>=0:basis=basis*rig.get_bone_global_pose(parent).basis
	var up:Vector3=(basis.inverse()*Vector3.UP).normalized()
	var right:Vector3=(basis.inverse()*workspace.actor.global_basis.x).normalized()
	var changed:=0
	for track in animation.get_track_count():
		if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
		if str(animation.track_get_path(track)).get_slice(":",1)!="pelvis":continue
		for key in animation.track_get_key_count(track):
			var time:=animation.track_get_key_time(track,key)
			var world_time:=time if full_combo else FLIP_START+time
			var envelope:=smoothstep(0.62,0.82,world_time)*(1-smoothstep(1.04,1.18,world_time))
			var progress:=clampf((world_time-FLIP_START)/FLIP_DURATION,0,1)
			var spin:=Quaternion(up,-TAU*smoothstep(0,1,progress))
			var old:Quaternion=animation.track_get_key_value(track,key)
			var corrected:Quaternion=spin*Quaternion(right,deg_to_rad(70.0)*envelope)*spin.inverse()*old
			assert(absf(old.angle_to(corrected)-deg_to_rad(70.0)*envelope)<0.002)
			animation.track_set_key_value(track,key,corrected.normalized())
			changed+=1
	assert(changed>0,"No pelvis keys corrected")
	animation.set_meta("forward_lean_fixed",true)
	assert(ResourceSaver.save(animation,path)==OK)
	return 1
