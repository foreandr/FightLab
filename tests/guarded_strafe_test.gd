extends SceneTree
const Channels=preload("res://scripts/animation_channels.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("GUARDED STRAFE FAILED: "+message)
	quit(1)
	return false
func same_track(a:Animation,ai:int,b:Animation,bi:int) -> bool:
	if ai<0 or bi<0 or a.track_get_key_count(ai)!=b.track_get_key_count(bi):return false
	if a.track_get_interpolation_type(ai)!=b.track_get_interpolation_type(bi):return false
	for key in a.track_get_key_count(ai):
		if not is_equal_approx(a.track_get_key_time(ai,key),b.track_get_key_time(bi,key)):return false
		if a.track_get_key_value(ai,key)!=b.track_get_key_value(bi,key):return false
	return true
func run() -> void:
	var library:AnimationLibrary=load("res://assets/combat/animations/duel.res")
	var donor:=library.get_animation("walk_back")
	var original:Animation=donor.get_meta("arm_sway_source",null)
	if not check(original!=null,"Missing preserved source for repeatable sway edit"):return
	var repeated:Animation=preload("res://scripts/vendor/copy_strafe_guard.gd").sway(donor)
	var shoulders:=0
	for track in donor.get_track_count():
		if donor.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
		var bone:=str(donor.track_get_path(track)).get_slice(":",1)
		if bone not in ["upperarm_l","upperarm_r"]:continue
		shoulders+=1
		var source_track:=original.find_track(donor.track_get_path(track),Animation.TYPE_ROTATION_3D)
		var repeat_track:=repeated.find_track(donor.track_get_path(track),Animation.TYPE_ROTATION_3D)
		for progress in [0.0,0.25,0.5,0.75,1.0]:
			var current:=donor.rotation_track_interpolate(track,progress*donor.length)
			var clean:=original.rotation_track_interpolate(source_track,progress*original.length)
			var expected:=deg_to_rad(4.0)*sin(progress*TAU)*(1.0 if bone.ends_with("_l") else -1.0)
			if not check(absf((clean.inverse()*current).get_euler().x-expected)<0.0001,"Sway amplitude/alternating phase is incorrect"):return
			if not check(absf(current.dot(repeated.rotation_track_interpolate(repeat_track,progress*repeated.length)))>0.99999,"Rerunning tool stacks arm sway"):return
	if not check(shoulders==2,"Shoulder sway missing on one arm"):return
	var arms:Animation=Channels.filtered(donor,"duel/walk_back","arm_l").duplicate(true)
	var right:=Channels.filtered(donor,"duel/walk_back","arm_r")
	for track in right.get_track_count():right.copy_track(track,arms)
	for name_ in ["strafe_left","strafe_right"]:
		var clip:=library.get_animation(name_)
		if not check(clip.loop_mode==Animation.LOOP_LINEAR and clip.get_meta("arm_source","")=="duel/walk_back","Copied clip missing loop/source metadata"):return
		for track in arms.get_track_count():
			var index:=clip.find_track(arms.track_get_path(track),arms.track_get_type(track))
			if not check(index>=0,"Copied arm track missing"):return
			for time in [0.0,0.25,0.5,0.75,0.999]:
				if arms.track_get_type(track)==Animation.TYPE_ROTATION_3D:
					if not check(absf(clip.rotation_track_interpolate(index,time*clip.length).dot(arms.rotation_track_interpolate(track,time*arms.length)))>0.99999,"Arm/finger pose does not match backward-walk source"):return
		# Copying is non-destructive, even when the same resource is both inputs.
		var count:=clip.get_track_count()
		var copied:=Channels.replace_channels(clip,clip,name_,["arm_l"])
		if not check(copied!=clip and clip.get_track_count()==count,"Tool mutates cached/source animation"):return
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():
		var before:AnimationLibrary=load(args[0])
		if not check(before.get_animation_list()==library.get_animation_list(),"Library gained/lost unrelated animations"):return
		for name_ in before.get_animation_list():
			var old:=before.get_animation(name_)
			var current:=library.get_animation(name_)
			for track in old.get_track_count():
				var index:=current.find_track(old.track_get_path(track),old.track_get_type(track))
				if name_ in ["strafe_left","strafe_right","walk_back"] and arms.find_track(old.track_get_path(track),old.track_get_type(track))>=0:continue
				if not check(same_track(old,track,current,index),"Changed non-arm track: %s %s"%[name_,old.track_get_path(track)]):return
	change_scene_to_file("res://scenes/fight.tscn")
	await process_frame
	await process_frame
	var field=current_scene
	field.set_physics_process(false)
	var actor=field.fighters[0]
	for name_ in ["strafe_left","strafe_right"]:
		for time in [0.0,0.25,0.5,0.75]:
			Pose.pose(actor,{"clip":"duel/walk_back","store_raw":true},time)
			var reference:Dictionary={}
			for track in arms.get_track_count():
				if arms.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
				var bone:=str(arms.track_get_path(track)).get_slice(":",1)
				if actor.bones.has(bone):reference[bone]=actor.skeleton.get_bone_pose_rotation(actor.bones[bone])
			Pose.pose(actor,{"clip":"duel/"+name_,"store_raw":true},time)
			for bone in reference:
				if not check(absf(actor.skeleton.get_bone_pose_rotation(actor.bones[bone]).dot(reference[bone]))>0.99999,"Live strafe arms differ from backward walk"):return
	if DisplayServer.get_name()!="headless":
		for index in field.fighters.size():
			var unit=field.fighters[index]
			unit.global_position=Vector3((index-1)*2.2,0.02,0)
			unit.rotation.y=0.0
			Pose.pose(unit,{"clip":"duel/"+["strafe_left","walk_back","strafe_right"][index%3],"store_raw":true},0.25)
		field.camera.position=Vector3(5,3.2,7)
		field.camera.look_at(Vector3(0,1.1,0))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://logs/guarded_strafe.png")
	print("GUARDED STRAFE PASSED: backward-walk arms/fingers match both live strafe clips, looping, immutable sources and baseline leg/root/unrelated-track preservation")
	quit()
