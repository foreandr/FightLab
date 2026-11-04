extends RefCounted
## CPU intent only: press the same one-shot recovery action as a human.
var target_progress:=-1.0
func clear()->void:target_progress=-1.0
func step(actor:Node,timing:RefCounted)->void:
 if actor.player_controlled or actor.health<=0.0 or not timing.waiting() or not is_instance_valid(actor.ragdoll):return
 if target_progress<0.0:
  target_progress=actor.rng.randf_range(0.05,1.0)
 if timing.progress()>=target_progress:actor.try_quick_recovery()
