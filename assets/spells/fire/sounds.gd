extends RefCounted
## Shared synthesized and source-credited downloaded fire sounds; cached on demand.
const DEFAULT_ID:="fire_whoosh"
const ENTRIES:=[
 {"id":"fire_whoosh","title":"Flame whoosh · Default","length":0.65,"tone":90.0,"rush":0.72,"crackle":0.20},
 {"id":"fire_ignite","title":"Quick ignition","length":0.32,"tone":145.0,"rush":0.55,"crackle":0.45},
 {"id":"fire_roar","title":"Deep fire roar","length":1.15,"tone":48.0,"rush":0.95,"crackle":0.12},
 {"id":"fire_crackle","title":"Crackling flame","length":0.95,"tone":110.0,"rush":0.38,"crackle":0.85},
 {"id":"fire_burst","title":"Fire burst","length":0.50,"tone":65.0,"rush":0.85,"crackle":0.55},
 {"id":"fire_hiss","title":"Searing hiss","length":0.80,"tone":220.0,"rush":0.30,"crackle":0.08},
 {"id":"fire_surge","title":"Rising inferno","length":1.30,"tone":72.0,"rush":0.90,"crackle":0.35},
 {"id": "lentikula_fire_1", "title": "Fire impact 1", "file": "res://assets/spells/fire/audio/lentikula_fire_1.wav", "length": 2.997333333333333, "author": "lentikula", "source": "https://lentikula.itch.io/freecc0-basic-spell-impacts-sfx", "license": "CC0-1.0", "source_sha256": "0ed8aa723a1189da00f115d7402508a291906bd249a80036e71a59f1020e67eb", "sha256": "cea7e7c3e35ae5d2069cbb228993a020fd836f9651d93fe64b328d1b607e0462", "original_file": "Fire Spell Impact 1.wav", "conversion": "Original rate/timing/pitch; mono PCM16 downmix, no synthetic variants"},
 {"id": "lentikula_fire_2", "title": "Fire impact 2", "file": "res://assets/spells/fire/audio/lentikula_fire_2.wav", "length": 3.005541666666667, "author": "lentikula", "source": "https://lentikula.itch.io/freecc0-basic-spell-impacts-sfx", "license": "CC0-1.0", "source_sha256": "4031d7b2b5577f310275dacaa902beb0a53d0849915cc17669abf3ff0f727269", "sha256": "8c2fa55f01e1e948c4b4785eece1b05d28b691d989653a8ce12d8fea54994285", "original_file": "Fire Spell Impact 2.wav", "conversion": "Original rate/timing/pitch; mono PCM16 downmix, no synthetic variants"},
 {"id": "lentikula_fire_3", "title": "Fire impact 3", "file": "res://assets/spells/fire/audio/lentikula_fire_3.wav", "length": 1.875, "author": "lentikula", "source": "https://lentikula.itch.io/freecc0-basic-spell-impacts-sfx", "license": "CC0-1.0", "source_sha256": "5d54547593efd13eeda5ca237118774117591769ebc3421f0f06f9755b7b514d", "sha256": "cc990153b2b95cc499765f0ee9c1b8c2a8b08abf9f36c4d5fbce3c1bc6c00b5f", "original_file": "Fire Spell Impact 3.wav", "conversion": "Original rate/timing/pitch; mono PCM16 downmix, no synthetic variants"},
 {"id": "lentikula_fire_4", "title": "Fire impact 4", "file": "res://assets/spells/fire/audio/lentikula_fire_4.wav", "length": 1.875, "author": "lentikula", "source": "https://lentikula.itch.io/freecc0-basic-spell-impacts-sfx", "license": "CC0-1.0", "source_sha256": "76c83a8a62b5250169a46a88288ceaf98879e50fceb5a2475b328ffd79de9c11", "sha256": "9b0d6b02b8cc1058bccb2ae3d3b995c4f98ae34a52eaf655a0fa591a059db560", "original_file": "Fire Spell Impact 4.wav", "conversion": "Original rate/timing/pitch; mono PCM16 downmix, no synthetic variants"},
 {"id": "lentikula_fire_5", "title": "Fire impact 5", "file": "res://assets/spells/fire/audio/lentikula_fire_5.wav", "length": 1.875, "author": "lentikula", "source": "https://lentikula.itch.io/freecc0-basic-spell-impacts-sfx", "license": "CC0-1.0", "source_sha256": "3ccc4743cdcfc8b7c1bd500472ebb1567e40b9bedb37ac99df25924fed45046d", "sha256": "f41b59b8d77601f9c46f2abaaa481c1615f5115cd4c5850cf487daef5b0b88ef", "original_file": "Fire Spell Impact 5.wav", "conversion": "Original rate/timing/pitch; mono PCM16 downmix, no synthetic variants"},
 {"id": "artisticdude_flare", "title": "Flare discharge", "file": "res://assets/spells/fire/audio/artisticdude_flare.wav", "length": 1.3749886621315193, "author": "artisticdude", "source": "https://opengameart.org/content/fire-evil-spell", "license": "CC-BY-3.0", "source_sha256": "c3ec40473d0f96be79354d156dd503f685ec841fed301e1b4f102bca0575c3bd", "sha256": "230475d3f0efafb460a0be7c66df42010f7602e6238efd22548469ad0f5a8c9b", "original_file": "Fire.aif", "conversion": "Original rate/timing/pitch; mono PCM16 downmix, no synthetic variants"}
]
static func find(id:String)->Dictionary:
 for entry in ENTRIES:
  if entry.id==id:return entry
 return {}
static func resolve(spec:Dictionary)->String:
 return preload("res://scripts/spell_asset_library.gd").sound_for(spec)
static var streams:Dictionary={}
static func synthesize(id:String)->AudioStreamWAV:
 if streams.has(id):return streams[id]
 var entry:=find(id)
 if entry.is_empty():return null
 if entry.has("file"):
  var recorded:AudioStreamWAV=load(str(entry.file))
  streams[id]=recorded
  return recorded
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
 streams[id]=stream
 return stream
