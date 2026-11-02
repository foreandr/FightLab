extends RefCounted
## Short, native-pitch accents around actual spell release, never whole-cast stretch.
const MIN_WINDOW:=0.08
const MAX_WINDOW:=0.60
const WINDOW_SHARE:=0.25
static var accents:Dictionary={}
static var peaks:Dictionary={}
static func release_window(spec:Dictionary,profile:Dictionary={})->float:
 var seconds:=float(spec.get("animation_duration",profile.get("duration",1.0)))
 if not is_finite(seconds):seconds=1.0
 return clampf(maxf(0.0,seconds)*WINDOW_SHARE,MIN_WINDOW,MAX_WINDOW)
static func audible_rate()->float:return maxf(0.01,Engine.time_scale)
static func accent(source:AudioStreamWAV,window:float)->AudioStreamWAV:
 if source.format!=AudioStreamWAV.FORMAT_16_BITS or source.stereo:return source
 var key:="%s/%d"%[source.get_instance_id(),roundi(window*1000.0)]
 if accents.has(key):return accents[key]
 var count:=source.data.size()/2
 if count<2:return source
 var source_id:=source.get_instance_id()
 if not peaks.has(source_id):
  var best:=0.0;var peak:=0
  # Strongest short-energy block identifies the release transient, ignoring silence.
  for start in range(0,count,256):
   var energy:=0.0
   for i in range(start,mini(start+256,count),4):
    var value:=float(source.data.decode_s16(i*2))/32768.0
    energy+=value*value
   if energy>best:best=energy;peak=start
  peaks[source_id]=peak
 var lead:=int(minf(0.025,window*0.15)*source.mix_rate)
 var begin:=maxi(0,int(peaks[source_id])-lead)
 var size:=mini(int(window*source.mix_rate),count-begin)
 var data:=source.data.slice(begin*2,(begin+size)*2)
 var fade_in:=maxi(1,int(source.mix_rate*0.003))
 var fade_out:=maxi(1,int(source.mix_rate*minf(0.025,window*0.2)))
 for i in size:
  var envelope:=minf(1.0,float(i)/fade_in)*minf(1.0,float(size-1-i)/fade_out)
  data.encode_s16(i*2,int(source.data.decode_s16((begin+i)*2)*envelope))
 var stream:=AudioStreamWAV.new();stream.format=source.format;stream.mix_rate=source.mix_rate;stream.data=data
 if accents.size()>=64:accents.erase(accents.keys()[0])
 accents[key]=stream
 return stream
