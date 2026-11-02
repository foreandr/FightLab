extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const AudioRules=preload("res://scripts/spell_audio_rules.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 if not check(AudioRules.playback_rate({})==1.0 and AudioRules.playback_rate({}, {"duration":2.0})==0.5,"Legacy/profile audio fallback"):return
 if not check(is_finite(AudioRules.playback_rate({"animation_duration":0.0})) and AudioRules.playback_rate({"animation_duration":INF})==1.0,"Invalid duration audio safety"):return
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO);actor.practice_god_mode=true
 var base:=Rules.projectile_base("Fire");base.sound_id="lentikula_fire_4"
 var first_voice:AudioStreamPlayer3D
 for seconds in [0.1,0.5,1.0,2.0,60.0]:
  var spec:=Rules.author(base,seconds,0.3,true)
  var snapshot:=spec.duplicate(true)
  if not check(spec.animation_duration==seconds and world.combat().release(actor,spec,Vector3.UP),"Actual release loses authored timing"):return
  var voice:AudioStreamPlayer3D=world.audio.voices[(world.audio.cursor-1)%world.audio.voices.size()]
  if not check(is_equal_approx(voice.pitch_scale,1.0/seconds) and world.shots.back().spec.animation_duration==seconds,"Cast playback rate does not follow duration"):return
  if seconds==1.0:first_voice=voice
  if not check(spec==snapshot,"Audio mutated authored spell"):return
 # Changing another spell's duration leaves the existing voice's timing alone.
 if not check(first_voice.pitch_scale==1.0,"Later cast retimes earlier sound"):return
 Engine.time_scale=0.25
 world.audio._process(0.0)
 if not check(is_equal_approx(first_voice.pitch_scale,0.25),"Slow mo ignores active cast sound"):return
 world.audio.impact("land",Vector3.ZERO)
 var foley:AudioStreamPlayer3D=world.audio.voices[(world.audio.cursor-1)%world.audio.voices.size()]
 var foley_rate:float=foley.pitch_scale
 var burn=preload("res://scripts/burning_audio.gd").new();world.add_child(burn);burn.setup(world.audio);burn.set_burning(true)
 world.audio._process(0.0)
 if not check(foley.pitch_scale==foley_rate and burn.pitch_scale==1.0,"Animation timing leaks into Foley or burning loop"):return
 Engine.time_scale=1.0;world.audio._process(0.0)
 if not check(first_voice.pitch_scale==1.0,"Slow mo off fails to restore rate"):return
 var overrides=preload("res://scripts/spell_test_overrides.gd").new()
 overrides.seed(Rules.author(base,1.0,0.3,true),1.0,0.3);overrides.set_value("duration",4.0)
 if not check(AudioRules.playback_rate(overrides.apply(base))==0.25,"Limiter-off duration not coupled"):return
 print("SPELL AUDIO TIMING PASS: actual release at 0.1/0.5/1/2/60s; legacy/profile fallback; immutable concurrent casts; slow mo in/out; burning and Foley independent; limiter-off duration")
 quit()
