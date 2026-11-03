extends RefCounted
## Opt-in headless experiment. Compile base-clip collision tracks, then use the
## normal live aiming, authored edits, safety, blending and impact layers.
## Native locomotion, layered Story players and ragdolls keep their full path.
const NAMES:=["pelvis","spine_01","spine_02","spine_03","neck_01","Head","clavicle_l","clavicle_r","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r","thigh_l","thigh_r","calf_l","calf_r","foot_l","foot_r","ball_l","ball_r"]
static var tables:Dictionary={}
static var hits:=0
static var builds:=0
static var build_usec:=0
static func enabled(actor:Node)->bool:
 return DisplayServer.get_name()=="headless" and bool(actor.get_tree().get_meta("cpu_training_view",false)) and bool(actor.get_tree().get_meta("collision_pose_cache",false)) and not is_instance_valid(actor.get("ragdoll"))
static func rig_info(actor:Node)->Dictionary:
 var rig:Skeleton3D=actor.skeleton
 var info:Dictionary=actor.get_meta("collision_pose_rig",{})
 if info.get("instance",0)==rig.get_instance_id():return info
 var needed:Dictionary={}
 for name_ in NAMES:
  var index:=rig.find_bone(name_)
  while index>=0:
   needed[index]=true;index=rig.get_bone_parent(index)
 var indices:Array=needed.keys();indices.sort()
 var rest:Array[Transform3D]=[];var signature:Array=[]
 for index in indices:
  rest.append(rig.get_bone_rest(index));signature.append([rig.get_bone_name(index),rig.get_bone_parent(index),rig.get_bone_rest(index)])
 info={"instance":rig.get_instance_id(),"indices":indices,"rest":rest,"signature":hash(signature)}
 actor.set_meta("collision_pose_rig",info)
 return info
static func invalidate()->void:tables.clear()
static func watch(animation:Animation)->void:
 if not animation.changed.is_connected(invalidate):animation.changed.connect(invalidate)
static func tracks(actor:Node,animation:Animation,slots:Dictionary)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for track in animation.get_track_count():
  var path:=animation.track_get_path(track)
  if path.get_subname_count()==0:continue
  var name_:=str(path.get_subname(0))
  if not actor.bones.has(name_) or not slots.has(actor.bones[name_]):continue
  var kind:=animation.track_get_type(track)
  if kind in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:result.append({"track":track,"slot":slots[actor.bones[name_]],"kind":kind})
 return result
static func write_tracks(animation:Animation,selected:Array[Dictionary],time:float,positions:PackedVector3Array,rotations:Array[Quaternion])->void:
 for item in selected:
  if item.kind==Animation.TYPE_POSITION_3D:positions[item.slot]=animation.position_track_interpolate(item.track,time)
  else:rotations[item.slot]=animation.rotation_track_interpolate(item.track,time).normalized()
static func table_for(actor:Node,clip:String)->Dictionary:
 var info:=rig_info(actor);var animation:Animation=actor.player.get_animation(clip)
 var guard:Animation=actor.player.get_animation("fight/guard") if actor.player.has_animation("fight/guard") else null
 var key:="%s/%s/%s"%[info.signature,animation.get_instance_id(),guard.get_instance_id() if guard!=null else 0]
 if tables.has(key):return tables[key]
 var start:=Time.get_ticks_usec();watch(animation)
 if guard!=null:watch(guard)
 var slots:Dictionary={}
 for i in info.indices.size():slots[info.indices[i]]=i
 var selected:=tracks(actor,animation,slots)
 var base_positions:=PackedVector3Array();var base_rotations:Array[Quaternion]=[];var scales:=PackedVector3Array()
 for pose:Transform3D in info.rest:
  base_positions.append(pose.origin);base_rotations.append(pose.basis.get_rotation_quaternion());scales.append(pose.basis.get_scale())
 if guard!=null:write_tracks(guard,tracks(actor,guard,slots),0.0,base_positions,base_rotations)
 # Preserve the original curve interpolation, including sharp key boundaries.
 # A fixed-rate resample can alter close contacts even below a millimetre.
 var table:Dictionary={"indices":info.indices,"positions":base_positions,"rotations":base_rotations,"scales":scales,"tracks":selected,"animation":animation}
 tables[key]=table;builds+=1;build_usec+=Time.get_ticks_usec()-start
 return table
static func sample(actor:Node,clip:String,time:float)->bool:
 if not enabled(actor) or not actor.player.has_animation(clip):return false
 var table:=table_for(actor,clip);var rig:Skeleton3D=actor.skeleton
 var positions:PackedVector3Array=table.positions.duplicate()
 var rotations:Array[Quaternion]=table.rotations.duplicate()
 write_tracks(table.animation,table.tracks,time,positions,rotations)
 var count:int=table.indices.size()
 for slot in count:
  var index:int=table.indices[slot]
  rig.set_bone_pose_position(index,positions[slot])
  rig.set_bone_pose_rotation(index,rotations[slot])
  rig.set_bone_pose_scale(index,table.scales[slot])
 hits+=1
 return true
