extends RefCounted
## Deterministic body-volume projection: preserve the requested pose as far as
## possible, then ease its rotations back toward the supplied safe reference.
## Root/leg travel, animation resources and gameplay costs are never changed.
const Collision=preload("res://scripts/pose_self_collision.gd")
const UPPER_BODY=["spine_01","spine_02","spine_03","neck_01","Head","clavicle_l","clavicle_r","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r"]
const PARTS=["torso","head","arm_l","arm_r","forearm_l","forearm_r","hand_l","hand_r"]
const TOLERANCE:=0.005
static func capture(actor:Node,names:Array=UPPER_BODY) -> Dictionary:
 var result:Dictionary={}
 for name_ in names:
  var index:int=actor.skeleton.find_bone(name_)
  if index>=0:result[index]=actor.skeleton.get_bone_pose_rotation(index)
 return result
static func _apply_blend(rig:Skeleton3D,reference:Dictionary,desired:Dictionary,weight:float) -> void:
 for index in reference:rig.set_bone_pose_rotation(index,(reference[index] as Quaternion).slerp(desired[index],weight))
 rig.force_update_all_bone_transforms()
static func _clear(rig:Skeleton3D,baseline:Dictionary,parts:Array) -> bool:
 var contacts:=Collision.penetrations(rig,parts)
 for pair in contacts:
  if float(contacts[pair])>maxf(TOLERANCE,float(baseline.get(pair,0.0)))+0.00001:return false
 return true
static func constrain(actor:Node,reference:Dictionary) -> float:
 if reference.is_empty():return 1.0
 var rig:Skeleton3D=actor.skeleton
 var parts:Array=[]
 for index in reference:
  var name_:=rig.get_bone_name(index)
  if name_.begins_with("lowerarm_"):
   var side:=name_.right(1)
   parts.append("forearm_"+side);parts.append("hand_"+side)
  else:
   parts=PARTS
   break
 var desired:Dictionary={}
 var changed:=false
 for index in reference:
  desired[index]=rig.get_bone_pose_rotation(index)
  if not (reference[index] as Quaternion).is_equal_approx(desired[index]):changed=true
 if not changed:return 1.0
 _apply_blend(rig,reference,desired,0.0)
 var baseline:=Collision.penetrations(rig,parts)
 _apply_blend(rig,reference,desired,1.0)
 if _clear(rig,baseline,parts):return 1.0
 var low:=0.0
 var high:=1.0
 # For a blocked request, find its first feasible boundary from the reference
 # instead of allowing the correction to jump through a body volume.
 for step in range(1,5):
  var weight:=step/4.0
  _apply_blend(rig,reference,desired,weight)
  if not _clear(rig,baseline,parts):
   high=weight
   break
  low=weight
 if low>=1.0:return 1.0
 for iteration in 5:
  var middle:=(low+high)*0.5
  _apply_blend(rig,reference,desired,middle)
  if _clear(rig,baseline,parts):low=middle
  else:high=middle
 _apply_blend(rig,reference,desired,low)
 return low

## Limit bending/twist inside authored clips too, not only their aim layer.
## The spine has a 90-degree total local budget. Limit by distributing the
## correction across its joints; root/pelvis flips remain intact.
static func limit_torso(actor:Node) -> void:
 var rig:Skeleton3D=actor.skeleton
 var joints:Array[int]=[]
 var offsets:Array[Quaternion]=[]
 var total:=0.0
 for name_ in ["spine_01","spine_02","spine_03"]:
  var index:int=rig.find_bone(name_)
  if index<0:continue
  var rest:=rig.get_bone_rest(index).basis.get_rotation_quaternion()
  var offset:Quaternion=(rest.inverse()*rig.get_bone_pose_rotation(index)).normalized()
  total+=Quaternion.IDENTITY.angle_to(offset)
  joints.append(index);offsets.append(offset)
 var limited:=deg_to_rad(90.0)
 if total<=limited:return
 for i in joints.size():
  var rest:=rig.get_bone_rest(joints[i]).basis.get_rotation_quaternion()
  rig.set_bone_pose_rotation(joints[i],rest*Quaternion.IDENTITY.slerp(offsets[i],limited/total))
 rig.force_update_all_bone_transforms()
