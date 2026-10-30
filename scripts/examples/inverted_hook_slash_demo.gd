extends "res://scripts/examples/jump_backflip_slash_demo.gd"
## Bake derivatives from the exact Melee Hook, backflip and right body slash.
const Rig=preload("res://scripts/editor_rig_pose.gd")
const FLIP_START:=0.30
const FLIP_DURATION:=0.88
const ATTACK_START:=0.44
const ATTACK_DURATION:=0.66
var workspace:Node
var flip_source:Dictionary
var hook_source:Dictionary
var slash_source:Dictionary
var inverted_phase:=0.5
var neutral_hip:=Quaternion.IDENTITY
var bake_prefix:=""

func build_demo() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	for frame in range(600):
		await process_frame
		workspace=current_scene
		if workspace!=null and is_instance_valid(workspace.get("slow_button")):break
	assert(workspace!=null and is_instance_valid(workspace.get("slow_button")))
	workspace.actor.editor_pose_locked=true
	var jump:Dictionary
	for entry in Catalog.entries():
		if entry.step=="Jump":jump=entry.duplicate(true)
		if entry.step=="Flip":flip_source=entry.duplicate(true)
		if entry.title=="Right body slash":slash_source=entry.duplicate(true)
	for entry in workspace.load_custom_motion("Jump"):
		if entry.title=="Jump2 Variant":jump=entry.duplicate(true)
	for entry in workspace.load_custom_motion("Acrobatics"):
		if entry.title=="Backflip Copy":flip_source=entry.duplicate(true)
	for entry in workspace.store_library.entries_for("Attack","Punch"):
		if str(entry.title).nocasecmp_to("Melee Hook")==0:hook_source=entry.duplicate(true);break
	if hook_source.is_empty():hook_source={"title":"Melee Hook","clip":"store_preview/Melee_Hook","source_animation":"Melee_Hook","duration":0.46666667,"group":"Attack","category":"Punch","step":"Idle","store_raw":true}
	for entry in [jump,flip_source,hook_source,slash_source]:workspace._ensure_animation_source(entry)
	var right_energy:=0.0
	var left_energy:=0.0
	var first:=sample_source(hook_source,0.0)
	for index in range(1,21):
		var pose:=sample_source(hook_source,float(index)/20)
		right_energy+=first.rotations.upperarm_r.angle_to(pose.rotations.upperarm_r)
		left_energy+=first.rotations.upperarm_l.angle_to(pose.rotations.upperarm_l)
	if left_energy>right_energy*1.1:hook_source.mirrored=not bool(hook_source.get("mirrored",false))
	print("Exact hook: ",hook_source.title," / ",hook_source.clip," right movement=",right_energy," left=",left_energy," mirrored for right-hand delivery=",hook_source.get("mirrored",false))
	neutral_hip=sample_source(hook_source,0.0).rotations.pelvis
	var lowest:=1.0
	for index in range(101):
		sample_source(flip_source,float(index)/100)
		var up:=body_up()
		if up<lowest:lowest=up;inverted_phase=float(index)/100
	assert(lowest<-0.5,"Backflip source never becomes inverted")
	bake_prefix="user://authored_animations/inverted_hook_slash_"+str(Time.get_unix_time_from_system()).replace(".","_")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://authored_animations"))
	var flip_resource:=bake("hang_backflip",FLIP_DURATION,func(time:float):return sample_flip(time))
	var swing_resource:=bake("melee_hook_to_right_slash",ATTACK_DURATION,func(time:float):return sample_swing(time))
	var flip_entry:=derived_entry(flip_source,"Delayed backflip · inverted hold",flip_resource,"Motion","Acrobatics","Flip",[Credits.source(flip_source)],"retimed to hold inversion and unwind slowly; Melee Hook hip and counterbalance motion")
	flip_entry.provenance=Credits.derive([flip_entry.provenance,Credits.source(hook_source),Credits.source(slash_source)],"animation",flip_entry.title,Credits.creator_name(),"retimed inverted backflip with hook-to-slash body dynamics")
	var torso_entry:=derived_entry(hook_source,"Melee Hook → slash · torso",swing_resource,"Motion","Pose layers","Pose",[Credits.source(hook_source),Credits.source(slash_source)],"Melee Hook torso swing blended into right body slash")
	var arm_entry:=derived_entry(slash_source,"Melee Hook → fast RIGHT slash",swing_resource,"Attack","Punch","Body Slash",[Credits.source(hook_source),Credits.source(slash_source)],"right-hand Melee Hook windup blended into accelerated right body slash")
	arm_entry.attack_bone="hand_r"
	var clips:Array[Dictionary]=[
		make_clip(workspace,jump,1,"BODY",0,1.5,1,85),
		make_clip(workspace,flip_entry,2,"BODY",FLIP_START,FLIP_DURATION,2,3),
		make_clip(workspace,torso_entry,3,"TORSO",ATTACK_START,ATTACK_DURATION,3,0),
		make_clip(workspace,arm_entry,4,"RIGHT ARM",ATTACK_START,ATTACK_DURATION,4,12)]
	var bot:CharacterBody3D=workspace.spawn_editor_unit(Vector3(0,0.02,0))
	bot.rotation.y=0
	var target:CharacterBody3D=workspace.spawn_editor_unit(Vector3(0,0.02,1.1))
	target.rotation.y=PI
	workspace.focus_editor_unit(0)
	workspace.actor.global_basis=bot.global_basis
	workspace.timeline_name.text=""
	workspace.timeline_clips.assign(clips)
	workspace.timeline_duration=1.5
	workspace.timeline_serial=4
	workspace.timeline_length_input.set_value_no_signal(1.5)
	workspace._capture_timeline_origin()
	workspace._rebuild_timeline_tracks()
	var inverted_count:=0
	for index in range(61):
		workspace._apply_timeline_at(FLIP_START+FLIP_DURATION*float(index)/61,true)
		if body_up()<0:inverted_count+=1
	var inverted_fraction:=float(inverted_count)/61
	workspace._apply_timeline_at(0.86,true)
	assert(body_up()<-0.2,"Main slash is not happening upside down")
	assert(workspace.timeline_active["TORSO"].id==3 and workspace.timeline_active["RIGHT ARM"].id==4)
	assert(inverted_fraction>0.5,"Flip should be inverted for most of its duration")
	for clip in clips:assert(not clip.has("attached_spell"))
	workspace.actor.player.remove_animation_library("authored_demo")
	for clip in clips:workspace._ensure_animation_source(clip)
	assert(workspace.actor.player.has_animation(arm_entry.clip),"Baked animation could not reload")
	workspace.reset_timeline()
	workspace.play_timeline()
	var deadline:=Time.get_ticks_msec()+7000
	while (workspace.timeline_playing or not workspace.jump_tails.is_empty()) and Time.get_ticks_msec()<deadline:await process_frame
	assert(not workspace.timeline_playing and workspace.jump_tails.is_empty())
	assert(absf(bot.global_position.y-0.02)<0.02)
	workspace.reset_timeline()
	bot.stamina=bot.MAX_STAMINA
	if "--capture-review" in OS.get_cmdline_user_args():
		frame_camera()
		workspace.set_process(false)
		workspace.set_physics_process(false)
		workspace._apply_timeline_at(0.86,true)
		workspace._blend_unit_pose_targets(1.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://inverted_hook_slash_review.png")
		workspace.set_process(true)
		workspace.set_physics_process(true)
		workspace.reset_timeline()
	if "--verify-only" in OS.get_cmdline_user_args():
		print("INVERTED HOOK SLASH VERIFIED: ",inverted_fraction*100,"% of flip inverted; exact Melee Hook; impact inverted; 4 clips; landing complete; no spells")
		quit();return
	var name_:=demo_name()
	var existing:Array=[]
	for saved in workspace.timeline_library:existing.append(str(saved.get("name","")))
	name_=preload("res://scripts/animation_store_library.gd").unique_name(name_,existing)
	workspace.timeline_name.text=name_
	workspace.save_timeline()
	workspace._rebuild_timeline_library_menu()
	workspace.TIMELINE_PIXELS_PER_SECOND=maxf(workspace.TIMELINE_PIXELS_PER_SECOND,500)
	workspace._update_time_zoom_label()
	workspace._rebuild_timeline_tracks()
	workspace.select_group("Attack")
	workspace.select_category("Punch",true)
	workspace._apply_timeline_at(0,true)
	frame_camera()
	workspace._show_library_notice(name_+" · press Play or Take Control")
	root.show();root.grab_focus();root.request_attention()
	print("INVERTED HOOK SLASH SAVED AND READY: ",name_)

func frame_camera() -> void:
	workspace.field.camera.global_position=Vector3(5,5,9)
	workspace.field.camera.look_at(Vector3(0,1.3,0.5))
	workspace.field.camera.h_offset=-2.0
	workspace.field.camera.v_offset=0.5
	workspace.camera_initialized=true
	workspace.inspection_camera.capture_view(workspace.field.camera,7.5)

func demo_name() -> String:
	return "Inverted Melee Hook Right Slash"

func sample_source(entry:Dictionary,progress:float) -> Dictionary:
	workspace._sample_row_animation(entry,clampf(progress,0,0.99999)*float(workspace._animation_timeline_duration(entry)))
	return capture_pose()

func capture_pose() -> Dictionary:
	var result:Dictionary={"rotations":{},"positions":{}}
	var rig:Skeleton3D=workspace.actor.skeleton
	for index in rig.get_bone_count():
		var bone:=rig.get_bone_name(index)
		result.rotations[bone]=rig.get_bone_pose_rotation(index)
		result.positions[bone]=rig.get_bone_pose_position(index)
	return result

func sample_swing(time:float) -> Dictionary:
	if time<=0.22:return sample_source(hook_source,0.72*smoothstep(0,0.22,time))
	if time<0.32:
		var phase:=clampf((time-0.22)/0.10,0,1)
		var hook:=sample_source(hook_source,lerpf(0.72,0.94,phase))
		var slash:=sample_source(slash_source,phase*0.18)
		return blend_poses(hook,slash,smoothstep(0,1,phase))
	return sample_source(slash_source,lerpf(0.18,1.0,clampf((time-0.32)/(ATTACK_DURATION-0.32),0,1)))

func sample_flip(time:float) -> Dictionary:
	var progress:=clampf(time/FLIP_DURATION,0,1)
	var phase:float
	if progress<0.20:phase=lerpf(0,inverted_phase-0.035,smoothstep(0,0.20,progress))
	elif progress<0.62:phase=lerpf(inverted_phase-0.035,inverted_phase+0.035,smoothstep(0.20,0.62,progress))
	else:phase=lerpf(inverted_phase+0.035,1,smoothstep(0.62,1,progress))
	var pose:=sample_source(flip_source,phase)
	var swing_time:=FLIP_START+time-ATTACK_START
	if swing_time>=0 and swing_time<=ATTACK_DURATION:
		var swing:=sample_swing(swing_time)
		var weight:=smoothstep(0,0.06,swing_time)*(1-smoothstep(ATTACK_DURATION-0.08,ATTACK_DURATION,swing_time))
		var hip_delta:Quaternion=neutral_hip.inverse()*swing.rotations.pelvis
		pose.rotations.pelvis=(pose.rotations.pelvis as Quaternion)*Quaternion.from_euler(Vector3(0,hip_delta.get_euler().y*weight,0))
		for bone in pose.rotations:
			if str(bone).ends_with("_l") and (str(bone).contains("arm") or str(bone).contains("hand") or str(bone).begins_with("clavicle")):
				pose.rotations[bone]=(pose.rotations[bone] as Quaternion).slerp(swing.rotations[bone],weight)
	return pose

func blend_poses(a:Dictionary,b:Dictionary,weight:float) -> Dictionary:
	var result:=a.duplicate(true)
	for bone in result.rotations:
		result.rotations[bone]=(a.rotations[bone] as Quaternion).slerp(b.rotations[bone],weight)
		result.positions[bone]=(a.positions[bone] as Vector3).lerp(b.positions[bone],weight)
	return result

func body_up() -> float:
	var rig:Skeleton3D=workspace.actor.skeleton
	rig.force_update_all_bone_transforms()
	return (rig.get_bone_global_pose(workspace.actor.bones.Head).origin-rig.get_bone_global_pose(workspace.actor.bones.pelvis).origin).normalized().y

func bake(name_:String,duration:float,sampler:Callable) -> Dictionary:
	var animation:=Animation.new()
	animation.length=duration
	var rig:Skeleton3D=workspace.actor.skeleton
	var root_node:Node=workspace.actor.player.get_node(workspace.actor.player.root_node)
	var rig_path:=str(root_node.get_path_to(rig))
	var tracks:Dictionary={}
	for index in rig.get_bone_count():
		var bone:=str(rig.get_bone_name(index))
		var rotation:=animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(rotation,NodePath(rig_path+":"+bone))
		var position:=animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(position,NodePath(rig_path+":"+bone))
		tracks[bone]=[rotation,position]
	for frame in range(ceili(duration*60)+1):
		var time:=minf(duration,float(frame)/60)
		var pose:Dictionary=sampler.call(time)
		for bone in tracks:
			animation.rotation_track_insert_key(tracks[bone][0],time,pose.rotations[bone])
			animation.position_track_insert_key(tracks[bone][1],time,pose.positions[bone])
	var path:=bake_prefix+"_"+name_+".tres"
	assert(ResourceSaver.save(animation,path)==OK,"Failed to save derived animation")
	return {"path":path,"clip":"authored_demo/"+name_+"_"+str(Time.get_ticks_usec()),"duration":duration}

func derived_entry(source:Dictionary,title:String,resource:Dictionary,group:String,category:String,step:String,parents:Array,operation:String) -> Dictionary:
	var entry:Dictionary={"title":title,"clip":resource.clip,"animation_resource":resource.path,"duration":resource.duration,"source_duration":resource.duration,"group":group,"category":category,"step":step,"store_raw":true,"source_timing":"native_v1"}
	entry.provenance=Credits.derive(parents,"animation",title,Credits.creator_name(),operation)
	workspace._ensure_animation_source(entry)
	return entry
