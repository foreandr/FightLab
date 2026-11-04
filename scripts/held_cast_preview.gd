extends RefCounted
## Experimental input adapter. Shared Rules/CombatRuntime still own all costs.
var active:=false
var preparing:=false
var seconds:=0.0
var follow_through:=false
var feedback:Node
var limits:=Vector2(0.7,1.6)
const CHARGE_SECONDS:=1.0
const HOLD_FRACTION:=0.035
const RELEASE_FRACTION:=0.10

static func duration_range(profile:Dictionary)->Vector2:
 var native:=clampf(float(profile.get("source_duration",profile.get("duration",profile.get("source_length",1.0)))),0.1,60.0)
 var minimum:=clampf(maxf(preload("res://scripts/animation_jump_motion.gd").minimum(profile),float(profile.get("min_duration",native*0.7))),0.1,60.0)
 return Vector2(minimum,clampf(float(profile.get("max_duration",native*1.6)),minimum,60.0))

func begin(builder:Node)->void:
 if not builder.demo_choice_selected or builder.cast_committed():return
 builder.set_preview_repeat(false)
 limits=duration_range(builder.casting_animation)
 builder.demo_duration=limits.x
 builder.casting_animation.duration=limits.x
 seconds=0.0;preparing=true
 builder.play_demo_preview()
 preparing=false
 if not builder.playing:return
 active=true;seconds=0.0;follow_through=false
 feedback=builder.editor.actor.get_node_or_null("CastChargeFeedback")
 if not is_instance_valid(feedback):
  feedback=preload("res://scripts/cast_charge_feedback.gd").new();builder.editor.actor.add_child(feedback);feedback.setup(builder.editor.actor)
 feedback.begin(preload("res://scripts/combat_aim.gd").emitter(builder.playback_animation()))
 feedback.show_quote(builder.demo_preview_spec())

func update(builder:Node,delta:float)->void:
 if not active:return
 if not builder.playing or builder.editor.actor.combat_reaction_active() or not builder.get_viewport().get_window().has_focus() or builder.editor.camera_text_editing() or preload("res://scripts/combat_pointer.gd").dialog_open(builder.get_viewport()):
  builder.interrupt_preview_cast();builder.playing=false;builder.begin_demo_exit();return
 seconds=minf(60.0,seconds+maxf(0.0,delta))
 if is_instance_valid(feedback):feedback.progress(seconds/CHARGE_SECONDS)
 # The source declares its duration limits; holding only selects within them.
 builder.demo_duration=lerpf(limits.x,limits.y,clampf(seconds/CHARGE_SECONDS,0.0,1.0))
 builder.casting_animation.duration=builder.demo_duration
 builder.refresh_demo_timing()
 var fraction:float=HOLD_FRACTION*(1.0-exp(-seconds*4.0))
 builder.elapsed=builder.cast_duration()*fraction
 var quote:Dictionary=builder.demo_preview_spec()
 if is_instance_valid(feedback):feedback.show_quote(quote)
 if is_instance_valid(builder.cast_attempt_actor):
  if not builder.editor.field.combat().retime_cast_attempt(builder.cast_attempt_actor,quote,builder.cast_duration()*RELEASE_FRACTION,builder.elapsed):
   builder.interrupt_preview_cast();builder.playing=false;builder.begin_demo_exit()

func release(builder:Node)->void:
 if not active:return
 active=false;follow_through=true
 if is_instance_valid(feedback):feedback.finish()
 builder.demo_duration=lerpf(limits.x,limits.y,clampf(seconds/CHARGE_SECONDS,0.0,1.0))
 builder.casting_animation.duration=builder.demo_duration
 builder.refresh_demo_timing()
 var spec:Dictionary=builder.demo_preview_spec()
 if is_instance_valid(feedback):feedback.show_quote(spec)
 if builder.previews_spell_release() and not builder.editor.field.combat().can_start_cast(builder.editor.actor,spec):
  builder.interrupt_preview_cast();builder.playing=false;builder.begin_demo_exit();return
 if is_instance_valid(builder.cast_attempt_actor):
  builder.editor.field.combat().retime_cast_attempt(builder.cast_attempt_actor,spec,builder.cast_duration()*RELEASE_FRACTION,builder.elapsed)
 # Keep the exact held pose; key-up resumes forward into the strike.
 follow_through=true

func tail_rate(builder:Node)->float:
 # Holding stretches anticipation, not an interminably slow post-strike tail.
 var native:=float(builder.casting_animation.get("source_duration",1.0))
 var recovery:=maxf(0.35,native*(1.0-RELEASE_FRACTION))
 return maxf(1.0,builder.playback_duration()*(1.0-RELEASE_FRACTION)/recovery) if follow_through else 1.0

func cancel()->void:
 active=false;follow_through=false
 if is_instance_valid(feedback):feedback.finish()
