extends RefCounted
## CPU intent only: press the same one-shot recovery action as a human.
var target_progress:=-1.0
func clear()->void:target_progress=-1.0
func step(actor:Node,timing:RefCounted)->void:
 if actor.player_controlled or actor.health<=0.0 or not timing.waiting() or not is_instance_valid(actor.ragdoll):return
 if target_progress<0.0:
  var roll:float=actor.rng.randf()
  if roll<0.35:target_progress=actor.rng.randf_range(0.88,0.99)
  elif roll<0.80:target_progress=actor.rng.randf_range(0.68,0.84)
  elif roll<0.95:target_progress=actor.rng.randf_range(0.25,0.60)
  else:target_progress=1.1 # Sometimes miss the window altogether.
 if timing.progress()>=target_progress:actor.try_quick_recovery()
