extends RefCounted
## Required movement authored alongside a pose; all modes use actor gravity.
const GRAVITY:=22.0
const SOURCES:={
 "fight/tornado_kick":{"minimum_duration":1.65,"takeoff":0.12,"landing":0.72},
 "fight/rising_uppercut":{"minimum_duration":1.35,"takeoff":0.12,"landing":0.62},
 "fight/rising_kick":{"minimum_duration":1.40,"takeoff":0.14,"landing":0.70},
 "fight/hurricane_kicks":{"minimum_duration":1.85,"takeoff":0.12,"landing":0.68}}
static func settings(profile:Dictionary)->Dictionary:
 var declared:Variant=profile.get("jump_motion",{})
 return declared.duplicate(true) if declared is Dictionary and not declared.is_empty() else SOURCES.get(str(profile.get("clip","")),{}).duplicate(true)
static func minimum(profile:Dictionary)->float:return float(settings(profile).get("minimum_duration",0.1))
static func playback_rate(profile:Dictionary,duration:float,requested:float)->float:
 return minf(requested,duration/minimum(profile)) if not settings(profile).is_empty() else requested
static func launch_speed(duration:float,motion:Dictionary)->float:
 return GRAVITY*maxf(0.0,duration)*(float(motion.get("landing",0.7))-float(motion.get("takeoff",0.12)))*0.5
static func stamina(duration:float,motion:Dictionary)->float:
 if motion.is_empty():return 0.0
 var speed:=launch_speed(duration,motion)
 return maxf(4.0,12.0*speed*speed/(10.8*10.8))
static func begin(actor:Node)->void:actor.authored_jump_launched=not actor.is_on_floor()
static func advance(actor:Node,profile:Dictionary,time:float,duration:float)->void:
 if actor.authored_jump_launched:return
 var jump:=settings(profile)
 if jump.is_empty() or time<duration*float(jump.takeoff):return
 actor.authored_jump_launched=true
 if not actor.is_on_floor():return
 actor.velocity.y=launch_speed(duration,jump)
 actor.air_momentum=Vector3(actor.drive_velocity.x,0,actor.drive_velocity.z)
 actor.air_clock=0.0;actor.jump_kind="authored_jump"
 actor.arena.movement_burst(actor,false)
 actor.arena.events.append({"time":actor.arena.elapsed,"event":"animation_jump","team":actor.team,"clip":str(profile.get("clip","")),"launch_speed":actor.velocity.y,"minimum_duration":float(jump.minimum_duration),"jump_stamina":stamina(duration,jump)})
static func normalize_pose(actor:Node,profile:Dictionary)->void:
 if settings(profile).is_empty() or not actor.bones.has("pelvis"):return
 var clip:=str(profile.get("clip",""))
 if not actor.player.has_animation(clip):return
 var animation:Animation=actor.player.get_animation(clip)
 for track in animation.get_track_count():
  var path:=animation.track_get_path(track)
  if animation.track_get_type(track)!=Animation.TYPE_POSITION_3D or path.get_subname_count()==0 or str(path.get_subname(0))!="pelvis":continue
  var index:int=actor.bones.pelvis
  var base:=animation.position_track_interpolate(track,0.0)
  var parent:int=actor.skeleton.get_bone_parent(index)
  var basis:Basis=actor.skeleton.global_basis*(actor.skeleton.get_bone_global_pose(parent).basis if parent>=0 else Basis.IDENTITY)
  var shift:Vector3=basis*(actor.skeleton.get_bone_pose_position(index)-base)
  actor.skeleton.set_bone_pose_position(index,base+basis.inverse()*(Vector3.UP*clampf(shift.y,-0.08,0.08)))
  return
