extends RefCounted
## Cast audio follows authored animation timing, independent of projectile velocity.
const NORMAL_DURATION:=1.0
const MIN_AUDIO_DURATION:=0.1
static func playback_rate(spec:Dictionary,profile:Dictionary={})->float:
 var seconds:=float(spec.get("animation_duration",profile.get("duration",NORMAL_DURATION)))
 if not is_finite(seconds):seconds=NORMAL_DURATION
 return NORMAL_DURATION/maxf(MIN_AUDIO_DURATION,seconds)
static func audible_rate(base_rate:float)->float:
 return maxf(0.01,base_rate*maxf(0.0,Engine.time_scale))
