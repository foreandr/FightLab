extends RefCounted
## CPU intent only: press the same one-shot recovery action as a human.
const ATTEMPT_CHANCE:=0.25
var target_progress:=-1.0
func clear()->void:target_progress=-1.0
func step(actor:Node,timing:RefCounted)->void:
 if actor.player_controlled or actor.health<=0.0 or not timing.waiting() or not is_instance_valid(actor.ragdoll):return
 if target_progress<0.0:
  target_progress=actor.rng.randf_range(0.05,0.95) if actor.rng.randf()<ATTEMPT_CHANCE else 2.0 # One decision per knockdown; otherwise get up naturally.
 if timing.progress()>=target_progress:actor.try_quick_recovery()
