extends "res://scripts/examples/corkscrew_delayed_melee_hook_demo.gd"
const EXTRA_DELAY:=0.12

func build_demo() -> void:
	await super.build_demo()
	if "--verify-only" in OS.get_cmdline_user_args():return
	var resource:=bake("open_hand_melee_hook",HOOK_LENGTH,func(time:float):return sample_swing(time+HOOK_DELAY+EXTRA_DELAY))
	var entry:=derived_entry(hook_source,"Open hand Melee Hook",resource,"Attack","Punch","Hook",swing_credits(),"open hand knee-directed hook")
	entry.title="Open hand Melee Hook"
	entry.attack_bone="hand_r"
	assert(workspace.store_library.take(entry,"Attack","Punch"),"Could not save reusable hook variant")
	workspace.select_category("Punch",true)
	workspace._on_timeline_scrubbed(0.96)
	print("OPEN HAND HOOK SAVED: reusable Punch variant; swing starts at 0.70s; spin continues to -360 degrees")

func demo_name() -> String:
	return "Corkscrew Open Hand Melee Hook"

func half_spin_angle(time:float) -> float:
	var global_time:=FLIP_START+time
	# Continue the same turn after the strike: -180 to -360, never unwind.
	return -PI*smoothstep(0.32,0.78,global_time)-PI*smoothstep(1.04,1.18,global_time)

func sample_flip(time:float) -> Dictionary:
	var progress:=clampf(time/FLIP_DURATION,0,1)
	var phase:float
	if progress<0.20:phase=lerpf(0,inverted_phase-0.035,smoothstep(0,0.20,progress))
	elif progress<0.78:phase=lerpf(inverted_phase-0.035,inverted_phase+0.035,smoothstep(0.20,0.78,progress))
	else:phase=lerpf(inverted_phase+0.035,1,smoothstep(0.78,1,progress))
	var pose:=sample_source(flip_source,phase)
	var swing_time:=FLIP_START+time-ATTACK_START
	if swing_time>=0 and swing_time<=ATTACK_DURATION:
		var swing:=sample_swing(swing_time)
		var weight:=smoothstep(0,0.06,swing_time)*(1-smoothstep(ATTACK_DURATION-0.08,ATTACK_DURATION,swing_time))
		var hip_delta:Quaternion=neutral_hip.inverse()*swing.rotations.pelvis
		pose.rotations.pelvis=(pose.rotations.pelvis as Quaternion)*Quaternion.from_euler(Vector3(0,hip_delta.get_euler().y*weight,0))
	var rig:Skeleton3D=workspace.actor.skeleton
	var parent_index:=rig.get_bone_parent(workspace.actor.bones.pelvis)
	var parent_basis:Basis=rig.global_basis
	if parent_index>=0:parent_basis=parent_basis*rig.get_bone_global_pose(parent_index).basis
	pose.rotations.pelvis=Quaternion((parent_basis.inverse()*Vector3.UP).normalized(),half_spin_angle(time))*(pose.rotations.pelvis as Quaternion)
	return pose

func sample_swing(time:float) -> Dictionary:
	var phase:=clampf((time-HOOK_DELAY-EXTRA_DELAY)/HOOK_LENGTH,0,1)
	sample_source(hook_source,phase)
	var actor:Node=workspace.actor
	var rig:Skeleton3D=actor.skeleton
	var original:Dictionary=capture_pose()
	var shoulder:=joint_point("upperarm_r")
	var elbow:=joint_point("lowerarm_r")
	var hand:=joint_point("hand_r")
	var upper_length:=shoulder.distance_to(elbow)
	var lower_length:=elbow.distance_to(hand)
	# In the upright source pose the arm reaches towards the knee; inverted,
	# that becomes a vertical reach upward rather than a downward hook.
	var knee:=joint_point("calf_r")
	var reach:=minf(shoulder.distance_to(knee),upper_length+lower_length-0.01)
	var target:=shoulder+Vector3.DOWN*reach
	var distance:=shoulder.distance_to(target)
	var axis:Vector3=(target-shoulder).normalized()
	var along:float=(upper_length*upper_length+distance*distance-lower_length*lower_length)/(2*distance)
	var height:=sqrt(maxf(0,upper_length*upper_length-along*along))
	var pole:Vector3=(elbow-shoulder)-axis*(elbow-shoulder).dot(axis)
	if pole.length()<0.001:pole=Vector3.FORWARD
	turn_joint("upperarm_r","lowerarm_r",shoulder+axis*along+pole.normalized()*height)
	turn_joint("lowerarm_r","hand_r",target)
	var weight:=smoothstep(0.18,0.55,phase)
	for bone in ["upperarm_r","lowerarm_r"]:
		var index:int=actor.bones[bone]
		rig.set_bone_pose_rotation(index,(original.rotations[bone] as Quaternion).slerp(rig.get_bone_pose_rotation(index),weight))
	preload("res://scripts/hand_pose.gd").apply(actor,{"r":{"absolute":1.0,"straight":1.0,"thumb":0,"index":0,"middle":0,"ring":0,"pinky":0}})
	rig.force_update_all_bone_transforms()
	return capture_pose()

func joint_point(bone:String) -> Vector3:
	return preload("res://scripts/pose_drag_solver.gd").point(workspace.actor,bone)

func turn_joint(bone:String,end:String,target:Vector3) -> void:
	var actor:Node=workspace.actor
	var rig:Skeleton3D=actor.skeleton
	var index:int=actor.bones[bone]
	var pivot:=joint_point(bone)
	var turn:=Quaternion((joint_point(end)-pivot).normalized(),(target-pivot).normalized())
	var parent:int=rig.get_bone_parent(index)
	var parent_basis:Basis=rig.global_basis*rig.get_bone_global_pose(parent).basis
	var desired:Basis=Basis(turn)*rig.global_basis*rig.get_bone_global_pose(index).basis
	rig.set_bone_pose_rotation(index,(parent_basis.inverse()*desired).orthonormalized().get_rotation_quaternion())
	rig.force_update_all_bone_transforms()

func derived_entry(source:Dictionary,title:String,resource:Dictionary,group:String,category:String,step:String,parents:Array,operation:String) -> Dictionary:
	# Bypass the older half-turn builder's unwind assertions and descriptions.
	var credits:Array=[Credits.source(hook_source)]
	if step=="Flip":
		title="Backflip + continuous corkscrew"
		credits.append(Credits.source(flip_source))
		assert(is_equal_approx(half_spin_angle(FLIP_DURATION),-TAU))
		var previous:=0.0
		for frame in range(61):
			var angle:=half_spin_angle(FLIP_DURATION*float(frame)/60)
			assert(angle<=previous+0.0001,"Spin reversed direction")
			previous=angle
	else:
		title="Open hand Melee Hook · torso" if group=="Motion" else "Open hand Melee Hook · right arm"
		if group=="Attack":step="Hook"
	var entry:Dictionary={"title":title,"clip":resource.clip,"animation_resource":resource.path,"duration":resource.duration,"source_duration":resource.duration,"group":group,"category":category,"step":step,"store_raw":true,"source_timing":"native_v1"}
	entry.provenance=Credits.derive(credits,"animation",title,Credits.creator_name(),"Melee Hook variant: straight open right fingers, knee-directed vertical reach, extra 0.12s delay; continuous full corkscrew")
	workspace._ensure_animation_source(entry)
	return entry

func make_clip(editor:Node,entry:Dictionary,id:int,track:String,start:float,duration:float,priority:int,stamina:float) -> Dictionary:
	var clip:=super.make_clip(editor,entry,id,track,start,duration,priority,stamina)
	if id in [3,4]:
		clip.start+=EXTRA_DELAY
		clip.source_in+=EXTRA_DELAY
		# Keep the original hook duration; the baked source must include its end.
	return clip

func bake(name_:String,duration:float,sampler:Callable) -> Dictionary:
	if name_=="melee_hook_to_right_slash":duration=HOOK_DELAY+EXTRA_DELAY+HOOK_LENGTH
	return super.bake(name_,duration,sampler)
