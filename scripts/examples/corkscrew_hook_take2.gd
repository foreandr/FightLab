extends "res://scripts/examples/corkscrew_open_hand_hook_demo.gd"

func demo_name() -> String:
	return "Corkscrew Open Hand Melee Hook Take 2"

func half_spin_angle(time:float) -> float:
	var progress:=clampf(time/FLIP_DURATION,0,1)
	return -TAU*smoothstep(0,1,progress)

func sample_flip(time:float) -> Dictionary:
	var progress:=clampf(time/FLIP_DURATION,0,1)
	# Slow through inversion without ever freezing or restarting the flip.
	var phase:float
	if progress<0.20:phase=hermite(progress/0.20,0.0,inverted_phase-0.035,0.0,0.12*0.20)
	elif progress<0.78:phase=lerpf(inverted_phase-0.035,inverted_phase+0.035,(progress-0.20)/0.58)
	else:phase=hermite((progress-0.78)/0.22,inverted_phase+0.035,1.0,0.12*0.22,0.0)
	var pose:=sample_source(flip_source,phase)
	var rig:Skeleton3D=workspace.actor.skeleton
	var parent_index:=rig.get_bone_parent(workspace.actor.bones.pelvis)
	var parent_basis:Basis=rig.global_basis
	if parent_index>=0:parent_basis=parent_basis*rig.get_bone_global_pose(parent_index).basis
	var world_time:=FLIP_START+time
	var lean:=deg_to_rad(-35.0)*smoothstep(0.62,0.82,world_time)*(1-smoothstep(1.04,1.18,world_time))
	var up:Vector3=(parent_basis.inverse()*Vector3.UP).normalized()
	var right:Vector3=(parent_basis.inverse()*workspace.actor.global_basis.x).normalized()
	pose.rotations.pelvis=Quaternion(up,half_spin_angle(time))*Quaternion(right,lean)*(pose.rotations.pelvis as Quaternion)
	return pose

func hermite(t:float,a:float,b:float,ma:float,mb:float) -> float:
	return (2*t*t*t-3*t*t+1)*a+(t*t*t-2*t*t+t)*ma+(-2*t*t*t+3*t*t)*b+(t*t*t-t*t)*mb

func sample_swing(time:float) -> Dictionary:
	var phase:=clampf((time-HOOK_DELAY-EXTRA_DELAY)/HOOK_LENGTH,0,1)
	# A short, strong middle accent with a gradual follow-through.
	var source_phase:=phase
	if phase<0.3:source_phase=0.2*phase/0.3
	elif phase<0.62:source_phase=lerpf(0.2,0.85,smoothstep(0.3,0.62,phase))
	else:source_phase=lerpf(0.85,1.0,smoothstep(0.62,1.0,phase))
	var pose:=super.sample_swing(HOOK_DELAY+EXTRA_DELAY+source_phase*HOOK_LENGTH)
	# Redirect the open-hand follow-through diagonally forward while inverted.
	var actor:Node=workspace.actor
	var rig:Skeleton3D=actor.skeleton
	for bone in pose.rotations:rig.set_bone_pose_rotation(actor.bones[bone],pose.rotations[bone])
	rig.force_update_all_bone_transforms()
	var root:=joint_point("upperarm_r")
	var direction:=Vector3(0,-0.65,-0.76).normalized()
	var arm_length:=root.distance_to(joint_point("lowerarm_r"))+joint_point("lowerarm_r").distance_to(joint_point("hand_r"))
	var weight:=smoothstep(0.22,0.58,phase)
	var before:Quaternion=rig.get_bone_pose_rotation(actor.bones.upperarm_r)
	turn_joint("upperarm_r","hand_r",root+direction*arm_length)
	rig.set_bone_pose_rotation(actor.bones.upperarm_r,before.slerp(rig.get_bone_pose_rotation(actor.bones.upperarm_r),weight))
	rig.force_update_all_bone_transforms()
	return capture_pose()

func derived_entry(source:Dictionary,title:String,resource:Dictionary,group:String,category:String,step:String,parents:Array,operation:String) -> Dictionary:
	var entry:=super.derived_entry(source,title,resource,group,category,step,parents,operation)
	if step=="Flip":entry.title="Continuous corkscrew · leaned back"
	elif group=="Attack":entry.title="Open hand throw · Take 2"
	else:entry.title="Melee Hook body accent · Take 2"
	entry.provenance=Credits.derive([entry.provenance],"animation",entry.title,Credits.creator_name(),"Take 2: continuous rotation through descent, 35-degree whole-body lean, accented forward open-hand throw")
	return entry
