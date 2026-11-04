extends RefCounted
## Offline, source-time cleanup. Duration, key times and gameplay remain intact.
const VERSION:=1
static func prepare(source:Animation,rig:Skeleton3D)->Dictionary:
 if source==null:return {"ok":false,"reason":"Missing animation"}
 var animation:Animation=source.duplicate(true)
 var repaired:=0;var discontinuities:=0;var samples:=0;var max_before:=0.0;var max_after:=0.0
 for track in animation.get_track_count():
  if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
  var keys:Array[Quaternion]=[]
  for key in animation.track_get_key_count(track):
   var value:Quaternion=animation.track_get_key_value(track,key)
   if not value.is_finite() or value.length()<0.001:return {"ok":false,"reason":"Invalid joint rotation"}
   keys.append(value.normalized())
  var fixed:=keys.duplicate()
  for key in range(1,keys.size()-1):
   var midpoint:Quaternion=keys[key-1].slerp(keys[key+1],0.5)
   if keys[key-1].angle_to(keys[key+1])<deg_to_rad(20) and keys[key].angle_to(midpoint)>deg_to_rad(40):
    fixed[key]=midpoint;repaired+=1
  for key in keys.size():
   var value:Quaternion=fixed[key]
   if key>0 and key+1<keys.size():
    # Preserve rapid authored strikes; only soften smaller frame noise.
    if maxf(fixed[key-1].angle_to(value),value.angle_to(fixed[key+1]))<deg_to_rad(25):
     value=value.slerp(fixed[key-1].slerp(fixed[key+1],0.5),0.35)
   animation.track_set_key_value(track,key,value.normalized())
   if key==0:continue
   var dt:=animation.track_get_key_time(track,key)-animation.track_get_key_time(track,key-1)
   if dt<=0:return {"ok":false,"reason":"Invalid animation timing"}
   var before:=keys[key-1].angle_to(keys[key]);max_before=maxf(max_before,rad_to_deg(before)/dt)
   var after:float=(animation.track_get_key_value(track,key-1) as Quaternion).angle_to(value)
   max_after=maxf(max_after,rad_to_deg(after)/dt);samples+=1
   if after>deg_to_rad(90) and dt<0.05:discontinuities+=1
 if discontinuities>=3:return {"ok":false,"reason":"Persistent joint snapping after conditioning","discontinuities":discontinuities}
 var quality:=preload("res://scripts/animation_quality_gate.gd").inspect(animation,rig)
 if not quality.ok:return quality
 var report={"version":VERSION,"repaired_spikes":repaired,"discontinuities":discontinuities,"max_joint_degrees_per_second_before":max_before,"max_joint_degrees_per_second_after":max_after,"samples":samples}
 animation.set_meta("motion_conditioning",report)
 return {"ok":true,"animation":animation,"report":report}
