extends RefCounted
## Experimental input adapter. Shared Rules/CombatRuntime still own all costs.
var active:=false
var seconds:=0.0
var follow_through:=false
var limits:=Vector2(0.7,1.6)
const CHARGE_SECONDS:=1.0

static func duration_range(profile:Dictionary)->Vector2:
 var native:=clampf(float(profile.get("source_duration",profile.get("duration",1.0))),0.1,60.0)
 var minimum:=clampf(maxf(preload("res://scripts/animation_jump_motion.gd").minimum(profile),float(profile.get("min_duration",native*0.7))),0.1,60.0)
 return Vector2(minimum,clampf(float(profile.get("max_duration",native*1.6)),minimum,60.0))

func begin(builder:Node)->void:
 if not builder.demo_choice_selected or builder.cast_committed():return
 builder.set_preview_repeat(false)
 limits=duration_range(builder.casting_animation)
 builder.demo_duration=limits.x
 builder.casting_animation.duration=limits.x
 builder.play_demo_preview()
 if not builder.playing:return
 active=true;seconds=0.0;follow_through=false

func update(builder:Node,delta:float)->void:
 if not active:return
 if not builder.playing or builder.editor.actor.combat_reaction_active() or not builder.get_viewport().get_window().has_focus() or builder.editor.camera_text_editing() or preload("res://scripts/combat_pointer.gd").dialog_open(builder.get_viewport()):
  builder.interrupt_preview_cast();builder.playing=false;builder.begin_demo_exit();return
 seconds=minf(CHARGE_SECONDS,seconds+delta)
 # The source declares its duration limits; holding only selects within them.
 builder.demo_duration=lerpf(limits.x,limits.y,seconds/CHARGE_SECONDS)
 builder.casting_animation.duration=builder.demo_duration
 builder.refresh_demo_timing()
 var fraction:float=builder.release_fraction*(1.0-exp(-seconds*4.0))*0.95
 builder.elapsed=builder.cast_duration()*fraction
 if is_instance_valid(builder.cast_attempt_actor):
  if not builder.editor.field.combat().retime_cast_attempt(builder.cast_attempt_actor,builder.demo_preview_spec(),builder.cast_duration()*builder.release_fraction,builder.elapsed):
   builder.interrupt_preview_cast();builder.playing=false;builder.begin_demo_exit()

func release(builder:Node)->void:
 if not active:return
 active=false
 builder.demo_duration=lerpf(limits.x,limits.y,seconds/CHARGE_SECONDS)
 builder.casting_animation.duration=builder.demo_duration
 builder.refresh_demo_timing()
 var spec:Dictionary=builder.demo_preview_spec()
 if builder.previews_spell_release() and not builder.editor.field.combat().can_start_cast(builder.editor.actor,spec):
  builder.interrupt_preview_cast();builder.playing=false;builder.begin_demo_exit();return
 if is_instance_valid(builder.cast_attempt_actor):
  builder.editor.field.combat().retime_cast_attempt(builder.cast_attempt_actor,spec,maxf(seconds,0.001),seconds)
 builder.elapsed=builder.cast_duration()*builder.release_fraction
 follow_through=true

func tail_rate(builder:Node)->float:
 # Holding stretches anticipation, not an interminably slow post-strike tail.
 var native:=float(builder.casting_animation.get("source_duration",1.0))
 var recovery:=maxf(0.35,native*(1.0-builder.release_fraction))
 return maxf(1.0,builder.playback_duration()*(1.0-builder.release_fraction)/recovery) if follow_through else 1.0

func cancel()->void:
 active=false;follow_through=false
