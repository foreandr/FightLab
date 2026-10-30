extends "res://scripts/examples/inverted_hook_slash_demo.gd"
## Retain only the first half of the airborne Twist's procedural turn.
## Bake it into the backflip pelvis so arm/torso overlays cannot erase the turn.
func demo_name() -> String:
	return "Corkscrew Melee Hook Right Slash"

func half_spin_angle(time:float) -> float:
	var global_time:=FLIP_START+time
	# The airborne Twist turns TAU over its source interval. Split at 50%,
	# discard the second half, and hold that 180-degree orientation for the strike.
	var retained_source_progress:=0.5*smoothstep(0.32,0.74,global_time)
	var angle:=TAU*smoothstep(0.0,1.0,retained_source_progress)
	return angle*(1.0-smoothstep(1.00,FLIP_START+FLIP_DURATION,global_time))

func sample_flip(time:float) -> Dictionary:
	var pose:=super.sample_flip(time)
	var rig:Skeleton3D=workspace.actor.skeleton
	var parent_index:=rig.get_bone_parent(workspace.actor.bones.pelvis)
	var parent_basis:Basis=rig.global_basis
	if parent_index>=0:parent_basis=parent_basis*rig.get_bone_global_pose(parent_index).basis
	var up_axis:Vector3=(parent_basis.inverse()*Vector3.UP).normalized()
	pose.rotations.pelvis=Quaternion(up_axis,half_spin_angle(time))*(pose.rotations.pelvis as Quaternion)
	return pose

func derived_entry(source:Dictionary,title:String,resource:Dictionary,group:String,category:String,step:String,parents:Array,operation:String) -> Dictionary:
	if step=="Flip":
		for entry in Catalog.entries():
			if entry.step=="Twist":
				parents=parents.duplicate()
				parents.append(Credits.source(entry))
				break
		title="Backflip + half airborne twist"
		operation+="; retain first half of airborne Twist, discard second half; hold facing through slash, unwind on recovery"
		assert(is_equal_approx(half_spin_angle(0.86-FLIP_START),PI))
		assert(is_zero_approx(half_spin_angle(FLIP_DURATION)))
	return super.derived_entry(source,title,resource,group,category,step,parents,operation)
