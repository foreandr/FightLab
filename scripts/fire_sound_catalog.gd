extends RefCounted
## Original synthesized fire Foley. Cached on first use by the shared audio service.
const DEFAULT_ID:="fire_whoosh"
const ENTRIES:=[
 {"id":"fire_whoosh","title":"Flame whoosh · Default","length":0.65,"tone":90.0,"rush":0.72,"crackle":0.20},
 {"id":"fire_ignite","title":"Quick ignition","length":0.32,"tone":145.0,"rush":0.55,"crackle":0.45},
 {"id":"fire_roar","title":"Deep fire roar","length":1.15,"tone":48.0,"rush":0.95,"crackle":0.12},
 {"id":"fire_crackle","title":"Crackling flame","length":0.95,"tone":110.0,"rush":0.38,"crackle":0.85},
 {"id":"fire_burst","title":"Fire burst","length":0.50,"tone":65.0,"rush":0.85,"crackle":0.55},
 {"id":"fire_hiss","title":"Searing hiss","length":0.80,"tone":220.0,"rush":0.30,"crackle":0.08},
 {"id":"fire_surge","title":"Rising inferno","length":1.30,"tone":72.0,"rush":0.90,"crackle":0.35}
]
static func find(id:String)->Dictionary:
 for entry in ENTRIES:
  if entry.id==id:return entry
 return {}
static func resolve(spec:Dictionary)->String:
 if str(spec.get("projectile_element","None"))!="Fire":return "dash"
 var id:=str(spec.get("sound_id",spec.get("appearance",{}).get("sound_id",DEFAULT_ID)))
 return id if not find(id).is_empty() else DEFAULT_ID
static func synthesize(id:String)->AudioStreamWAV:
 var entry:=find(id)
 if entry.is_empty():return null
 var rate:=22050
 var duration:float=entry.length
 var count:=int(rate*duration)
 var data:=PackedByteArray();data.resize(count*2)
 var rng:=RandomNumberGenerator.new();rng.seed=abs(id.hash())
 var low:=0.0;var middle:=0.0;var spark:=0.0
 for i in count:
  var t:=float(i)/rate
  var phase:=t/duration
  var noise:=rng.randf_range(-1,1)
  low=lerpf(low,noise,0.045)
  middle=lerpf(middle,noise,0.32)
  if rng.randf()<0.003+float(entry.crackle)*0.012:spark=rng.randf_range(0.35,1.0)
  spark*=0.94
  var envelope:=pow(sin(PI*phase),0.65)*exp(-phase*1.5)
  if id=="fire_ignite" or id=="fire_burst":envelope=minf(t*100,1.0)*exp(-phase*4.0)
  if id=="fire_surge":envelope=pow(sin(PI*phase),1.5)
  var bass:=sin(TAU*(float(entry.tone)*t-18*t*t))*exp(-phase*5)
  var value:float=(low*float(entry.rush)*2.2+middle*0.35+bass*0.17+noise*spark*float(entry.crackle))*envelope
  if id=="fire_hiss":value=(noise-middle)*0.42*envelope
  value*=minf(t*350,1.0)*minf((duration-t)*100,1.0)
  data.encode_s16(i*2,int(clampf(value,-0.9,0.9)*30000))
 var stream:=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=data
 return stream
