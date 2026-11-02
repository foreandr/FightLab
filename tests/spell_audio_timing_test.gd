extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const AudioRules=preload("res://scripts/spell_audio_rules.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 if not check(AudioRules.release_window({})==0.25 and AudioRules.release_window({}, {"duration":2.0})==0.5,"Legacy/profile local window"):return
 if not check(AudioRules.release_window({"animation_duration":0.0})>0 and AudioRules.release_window({"animation_duration":INF})==0.25,"Invalid duration audio safety"):return
 # The audible event must not keep a source file's long empty lead-in.
 var fixture:=AudioStreamWAV.new();fixture.mix_rate=22050;fixture.format=AudioStreamWAV.FORMAT_16_BITS
 var bytes:=PackedByteArray();bytes.resize(22050*3*2)
 for i in range(22050,22050+4410):bytes.encode_s16(i*2,16000 if i%2==0 else -16000)
 fixture.data=bytes
 var excerpt:=AudioRules.accent(fixture,0.25)
 var start_energy:=0.0
 for i in 1102:start_energy+=absf(float(excerpt.data.decode_s16(i*2)))
 if not check(excerpt.get_length()<=0.251 and start_energy>1000000 and excerpt.mix_rate==fixture.mix_rate,"Release transient stays delayed/silent or changes source pitch"):return
 if not check(AudioRules.accent(fixture,0.25)==excerpt,"Release excerpt is not cached"):return
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO);actor.practice_god_mode=true
 var base:=Rules.projectile_base("Fire");base.sound_id="lentikula_fire_4"
 var first_voice:AudioStreamPlayer3D
 var windows:Array[float]=[]
 for seconds in [0.1,0.5,1.0,2.0,60.0]:
  var spec:=Rules.author(base,seconds,0.3,true)
  var snapshot:=spec.duplicate(true)
  var window:=AudioRules.release_window(spec)
  if not check(world.combat().release(actor,spec,Vector3.UP),"Actual release failed"):return
  var voice:AudioStreamPlayer3D=world.audio.voices[(world.audio.cursor-1)%world.audio.voices.size()]
  if not check(voice.pitch_scale==1.0 and voice.stream.get_length()<=window+0.001,"Cast is still stretched across whole animation"):return
  windows.append(voice.stream.get_length())
  if seconds==1.0:first_voice=voice
  if not check(spec==snapshot,"Audio mutated authored spell"):return
 if not check(windows.back()<=0.601 and first_voice.pitch_scale==1.0,"Long cast drags sound / later cast retimes old sound"):return
 Engine.time_scale=0.25;world.audio._process(0.0)
 if not check(is_equal_approx(first_voice.pitch_scale,0.25),"Slow mo ignores active accent"):return
 world.audio.impact("land",Vector3.ZERO)
 var foley:AudioStreamPlayer3D=world.audio.voices[(world.audio.cursor-1)%world.audio.voices.size()]
 var foley_rate:float=foley.pitch_scale
 var burn=preload("res://scripts/burning_audio.gd").new();world.add_child(burn);burn.setup(world.audio);burn.set_burning(true)
 world.audio._process(0.0)
 if not check(foley.pitch_scale==foley_rate and burn.pitch_scale==1.0,"Cast timing leaks into Foley or burn"):return
 Engine.time_scale=1.0;world.audio._process(0.0)
 if not check(first_voice.pitch_scale==1.0,"Slow mo off fails to restore rate"):return
 var overrides=preload("res://scripts/spell_test_overrides.gd").new()
 overrides.seed(Rules.author(base,1.0,0.3,true),1.0,0.3);overrides.set_value("duration",60.0)
 if not check(AudioRules.release_window(overrides.apply(base))<=0.6,"Limiter-off long cast creates a long sound"):return
 actor.practice_god_mode=false;actor.mana=0;actor.stamina=0
 var cursor:int=world.audio.cursor
 if not check(not world.combat().release(actor,Rules.author(base,1.0,0.3,true),Vector3.UP) and world.audio.cursor==cursor,"Failed release plays cast audio"):return
 print("SPELL AUDIO WINDOW PASS: release transient skips silence; native pitch; short 0.08–0.60s windows across 0.1–60s casts; cached, immutable/concurrent, slow mo, failed release, independent burn/Foley")
 quit()
