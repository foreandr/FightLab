extends RefCounted
## One original seamless burn bed shared by every burning source.
static var cached:AudioStreamWAV
static func stream()->AudioStreamWAV:
 if cached!=null:return cached
 var rate:=22050
 var count:=rate*3
 var samples:=PackedFloat32Array();samples.resize(count)
 var rng:=RandomNumberGenerator.new();rng.seed=732910
 var low:=0.0;var spark:=0.0
 for i in count:
  var t:=float(i)/rate
  var noise:=rng.randf_range(-1.0,1.0)
  low=lerpf(low,noise,0.065)
  if rng.randf()<0.002:spark=rng.randf_range(0.25,0.7)
  spark*=0.965
  samples[i]=(low*1.7+noise*spark*0.55)*(0.75+0.15*sin(TAU*t/3.0)+0.1*sin(TAU*t*4.0/3.0))
 # Blend the tail into the opening segment; avoid a click at the loop seam.
 var blend:=2205
 for i in blend:
  samples[count-blend+i]=lerpf(samples[count-blend+i],samples[i],float(i)/blend)
 var used:=count-blend
 var data:=PackedByteArray();data.resize(used*2)
 for i in used:data.encode_s16(i*2,int(clampf(samples[i+blend],-0.9,0.9)*30000))
 cached=AudioStreamWAV.new()
 cached.format=AudioStreamWAV.FORMAT_16_BITS;cached.mix_rate=rate;cached.data=data
 cached.loop_mode=AudioStreamWAV.LOOP_FORWARD;cached.loop_begin=0;cached.loop_end=used
 return cached
