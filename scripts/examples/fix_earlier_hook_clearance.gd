extends "res://scripts/examples/open_saved_aerial_combo.gd"
const Clearance=preload("res://scripts/examples/aerial_arm_clearance.gd")
var arm:Dictionary
var corrected:Animation
var original_clip:String
var original_path:String

func build_demo() -> void:
	await super.build_demo()
	workspace.set_process(false)
	workspace.set_physics_process(false)
	for clip in workspace.timeline_clips:
		if str(clip.get("track",""))=="RIGHT ARM":arm=clip
	assert(not arm.is_empty())
	original_clip=str(arm.clip)
	original_path=str(arm.animation_resource)
	corrected=(load(original_path) as Animation).duplicate(true)
	var source_in:=float(arm.source_in)
	var speed:=float(arm.get("speed",1.0))
	var start:=float(arm.start)
	var duration:=float(arm.duration)
	var tracks:Dictionary={}
	for track in corrected.get_track_count():
		if corrected.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
		var bone:=str(corrected.track_get_path(track)).get_slice(":",1)
		if bone in ["upperarm_r","lowerarm_r"]:tracks[bone]=track
	for track in tracks.values():
		for key in range(corrected.track_get_key_count(track)-1,-1,-1):
			var key_time:=corrected.track_get_key_time(track,key)
			if key_time>=source_in and key_time<=source_in+duration*speed:corrected.track_remove_key(track,key)
	var previous:Array=[]
	var worst_before:=0.0
	var worst_after:=0.0
	var changed:=0
	for frame in range(ceili(duration*120)+1):
		var elapsed:=minf(duration-0.000001,float(frame)/120.0)
		workspace._apply_timeline_at(start+elapsed,true)
		workspace.actor.skeleton.force_update_all_bone_transforms()
		var result:=Clearance.solve(workspace.actor,previous)
		previous=result.corrections
		worst_before=maxf(worst_before,result.before)
		worst_after=maxf(worst_after,result.after)
		if frame in [0,12,24,36,48,56]:print("ARM SAMPLE ",frame," correction deg ",rad_to_deg((result.corrections[0] as Quaternion).get_angle())," / ",rad_to_deg((result.corrections[1] as Quaternion).get_angle()))
		if result.before>0.002:changed+=1
		for bone in tracks:
			corrected.rotation_track_insert_key(tracks[bone],source_in+elapsed*speed,workspace.actor.skeleton.get_bone_pose_rotation(workspace.actor.bones[bone]))
	print("CLEARANCE SOLVED: start=",start," duration=",duration," before=",worst_before," after=",worst_after," affected_frames=",changed)
	var path:="user://authored_animations/earlier_hook_arm_clearance_"+str(Time.get_ticks_usec())+".tres"
	assert(ResourceSaver.save(corrected,path)==OK)
	arm.animation_resource=path
	arm.clip="authored_demo/earlier_hook_arm_clearance_"+str(Time.get_ticks_usec())
	workspace._ensure_animation_source(arm)
	var worst_between:=0.0
	for frame in range(ceili(duration*240)):
		workspace._apply_timeline_at(start+float(frame)/240.0,true)
		worst_between=maxf(worst_between,Clearance.measure(workspace.actor).worst)
	print("BETWEEN-FRAME MAX PENETRATION: ",worst_between)
	for sample in [0.55,0.60,0.65,0.70,0.75,0.80,0.90]:
		await capture_comparison(sample)
	if "--apply-clearance" in OS.get_cmdline_user_args():
		assert(worst_between<0.008,"Arm still intersects torso")
		arm.provenance=Credits.derive([Credits.source(arm)],"animation",str(arm.title),Credits.creator_name(),"reroute right shoulder and elbow around torso; preserve user start time, speed and duration")
		workspace.save_timeline()
		refresh_shop_combo()
		print("ARM CLEARANCE SAVED: timing unchanged; original animation preserved")
	workspace.set_process(true)
	workspace.set_physics_process(true)
	workspace._on_timeline_scrubbed(0.0)
	frame_camera()
	if "--review-only" in OS.get_cmdline_user_args():quit()

func capture_comparison(time:float) -> void:
	var new_path:String=arm.animation_resource
	var new_clip:String=arm.clip
	for version in ["before","after"]:
		arm.animation_resource=original_path if version=="before" else new_path
		arm.clip=original_clip if version=="before" else new_clip
		workspace._apply_timeline_at(time,true)
		workspace._blend_unit_pose_targets(1.0)
		var center:Vector3=workspace.focused_unit.global_position+Vector3.UP*(-0.2)
		workspace.field.camera.global_position=center+Vector3(3,0.8,4)
		workspace.field.camera.look_at(center)
		workspace.field.camera.h_offset=-1.0
		workspace.field.camera.v_offset=0.0
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/forea/Documents/Codex/2026-10-30/if-w/work/clearance_"+version+"_"+str(time)+".png")

func refresh_shop_combo() -> void:
	var snapshot:Dictionary={}
	for saved in workspace.timeline_library:
		if str(saved.get("name",""))==workspace.timeline_name.text:snapshot=saved.duplicate(true)
	assert(not snapshot.is_empty())
	bake_prefix="user://authored_animations/earlier_hook_clear_combo_"+str(Time.get_ticks_usec())
	var resource:=bake("full_combo",workspace.timeline_duration,sample_combo)
	var updated:=0
	for entry in workspace.store_library.taken.values():
		if str(entry.get("title",""))!=workspace.timeline_name.text:continue
		entry.animation_resource=resource.path
		entry.clip=resource.clip
		entry.duration=workspace.timeline_duration
		entry.source_duration=workspace.timeline_duration
		entry.composed_timeline=snapshot.duplicate(true)
		entry.provenance=Credits.derive([Credits.source(entry)],"animation",str(entry.title),Credits.creator_name(),"preserve earlier user timing; right arm routed around torso")
		updated+=1
	assert(workspace.store_library.save())
	print("SHOP COMBO UPDATED: ",updated," existing entries; no duplicates")

func sample_combo(time:float) -> Dictionary:
	workspace._apply_timeline_at(minf(time,workspace.timeline_duration-0.00001),true)
	var pose:=capture_pose()
	var rig:Skeleton3D=workspace.actor.skeleton
	var parent:=rig.get_bone_parent(workspace.actor.bones.pelvis)
	var parent_basis:Basis=rig.global_basis
	if parent>=0:parent_basis=parent_basis*rig.get_bone_global_pose(parent).basis
	var height:float=workspace.focused_unit.global_position.y-workspace.timeline_unit_origin.y
	pose.positions.pelvis+=(parent_basis.inverse()*Vector3.UP*height)
	return pose